import Foundation

/// Metadata that lets the app re-focus the correct terminal window.
public struct TerminalInfo: Codable, Sendable {
    public let pid: Int32
    public let ppid: Int32
    public let tty: String?
    public let bundleID: String?
    public let windowID: Int?

    public init(pid: Int32, ppid: Int32, tty: String?, bundleID: String?, windowID: Int?) {
        self.pid = pid
        self.ppid = ppid
        self.tty = tty
        self.bundleID = bundleID
        self.windowID = windowID
    }
}
