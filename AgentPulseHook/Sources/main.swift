import Foundation

/// agentpulse-hook — invoked by Claude Code's Notification hook.
/// Reads JSON from stdin, injects process metadata, forwards to daemon socket, exits immediately.

let socketPath: String = {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home
        .appendingPathComponent("Library/Application Support/AgentPulse/daemon.sock")
        .path
}()

// Read stdin
var inputData = Data()
var chunk = [UInt8](repeating: 0, count: 4096)
while true {
    let n = read(STDIN_FILENO, &chunk, chunk.count)
    if n <= 0 { break }
    inputData.append(contentsOf: chunk[0..<n])
}

guard !inputData.isEmpty,
      var payload = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any]
else { exit(0) }

// Inject process chain so the app can identify the terminal/IDE
payload["_hook_pid"]  = Int(ProcessInfo.processInfo.processIdentifier)
payload["_hook_ppid"] = Int(parentPID(of: ProcessInfo.processInfo.processIdentifier))
payload["_hook_tty"]  = ttyName()

// Serialise
guard let outData = try? JSONSerialization.data(withJSONObject: payload) else { exit(0) }

// Connect — fire-and-forget, silent exit if daemon is not running
let fd = socket(AF_UNIX, SOCK_STREAM, 0)
guard fd >= 0 else { exit(0) }

var addr = sockaddr_un()
addr.sun_family = sa_family_t(AF_UNIX)
withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
    ptr.withMemoryRebound(to: CChar.self, capacity: 104) { cPtr in
        _ = socketPath.withCString { strlcpy(cPtr, $0, 104) }
    }
}

let connected = withUnsafePointer(to: &addr) {
    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
    }
}
guard connected == 0 else { close(fd); exit(0) }

var payload2 = outData
payload2.append(UInt8(ascii: "\n"))
payload2.withUnsafeBytes { _ = write(fd, $0.baseAddress, $0.count) }
close(fd)
exit(0)

// MARK: - Helpers

func parentPID(of pid: Int32) -> Int32 {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.size
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    sysctl(&mib, 4, &info, &size, nil, 0)
    return info.kp_eproc.e_ppid
}

func ttyName() -> String? {
    let name = Darwin.ttyname(STDIN_FILENO)
    return name.map { String(cString: $0) }
}
