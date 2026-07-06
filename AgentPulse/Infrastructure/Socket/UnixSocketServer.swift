import Foundation

/// Listens on a Unix Domain Socket for hook payloads from agentpulse-hook.
/// Uses POSIX BSD sockets — NWListener does not support Unix domain socket server endpoints.
public actor UnixSocketServer: HookReceiverPort {
    private let socketPath: String
    private var serverFD: Int32 = -1
    private var dispatcher: HookEventDispatcher?

    public init(socketPath: String) {
        self.socketPath = socketPath
    }

    public func setDispatcher(_ dispatcher: HookEventDispatcher) {
        self.dispatcher = dispatcher
    }

    public func start() async throws {
        try? FileManager.default.removeItem(atPath: socketPath)

        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw UnixSocketError.socketCreationFailed }

        do {
            try Self.bind(fd: fd, path: socketPath)
        } catch {
            Darwin.close(fd)
            throw error
        }
        serverFD = fd

        let dispatcherRef = dispatcher
        let fdCopy = fd
        let thread = Thread { Self.acceptLoop(serverFD: fdCopy, dispatcher: dispatcherRef) }
        thread.qualityOfService = .utility
        thread.name = "com.agentpulse.socket.accept"
        thread.start()
    }

    public func stop() async {
        if serverFD >= 0 {
            Darwin.close(serverFD)
            serverFD = -1
        }
        try? FileManager.default.removeItem(atPath: socketPath)
    }

    // MARK: - Private (static — runs on background thread, no actor isolation)

    private static func bind(fd: Int32, path: String) throws {
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: 104) { cPtr in
                _ = path.withCString { strlcpy(cPtr, $0, 104) }
            }
        }
        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.bind(fd, $0, size) }
        }
        guard bound == 0 else { throw UnixSocketError.bindFailed(errno) }
        guard Darwin.listen(fd, 16) == 0 else { throw UnixSocketError.listenFailed(errno) }
    }

    private static func acceptLoop(serverFD: Int32, dispatcher: HookEventDispatcher?) {
        while true {
            let clientFD = Darwin.accept(serverFD, nil, nil)
            guard clientFD >= 0 else { return }
            Task.detached(priority: .utility) {
                await readAndDispatch(clientFD: clientFD, dispatcher: dispatcher)
            }
        }
    }

    private static func readAndDispatch(clientFD: Int32, dispatcher: HookEventDispatcher?) async {
        defer { Darwin.close(clientFD) }
        var data = Data()
        var buf = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = Darwin.recv(clientFD, &buf, buf.count, 0)
            if n <= 0 { break }
            data.append(contentsOf: buf[..<n])
        }
        guard !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        let payload = Self.toSendable(json)
        await dispatcher?.dispatch(rawPayload: payload, receivedAt: Date())
    }

    /// Converts a raw JSONSerialization dictionary to [String: any Sendable].
    /// JSONSerialization produces only: NSNull, Bool, Int, Double, String, [Any], [String:Any].
    /// `any Sendable` cannot be used in a conditional cast — we convert each known type explicitly.
    private static func toSendable(_ dict: [String: Any]) -> [String: any Sendable] {
        var result: [String: any Sendable] = [:]
        for (key, value) in dict {
            if let v = sendableValue(value) {
                result[key] = v
            }
        }
        return result
    }

    private static func sendableValue(_ value: Any) -> (any Sendable)? {
        switch value {
        case let v as String:            return v
        case let v as Bool:              return v
        case let v as Int:               return v
        case let v as Double:            return v
        case let v as [String: Any]:     return toSendable(v)
        case let v as [Any]:             return v.compactMap { sendableValue($0) }
        case is NSNull:                  return Optional<String>.none as any Sendable
        default:                         return nil
        }
    }
}

public enum UnixSocketError: Error, LocalizedError {
    case socketCreationFailed
    case bindFailed(Int32)
    case listenFailed(Int32)

    public var errorDescription: String? {
        switch self {
        case .socketCreationFailed:   return "Failed to create Unix domain socket"
        case .bindFailed(let code):   return "Failed to bind socket (errno \(code))"
        case .listenFailed(let code): return "Failed to listen on socket (errno \(code))"
        }
    }
}
