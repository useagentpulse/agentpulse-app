import Foundation
import AppKit

/// Walks the parent process chain from a given PID to identify the terminal or IDE.
public final class MacOSTerminalDetector: TerminalDetectorPort, @unchecked Sendable {

    private static let knownApps: [String: String] = [
        "com.apple.Terminal":         "Terminal",
        "com.googlecode.iterm2":      "iTerm2",
        "dev.warp.Warp-Stable":       "Warp",
        "com.mitchellh.ghostty":      "Ghostty",
        "com.microsoft.VSCode":       "VS Code",
        "com.jetbrains.intellij.ce":  "IntelliJ IDEA",
        "com.jetbrains.intellij":     "IntelliJ IDEA",
        "com.jetbrains.pycharm.ce":   "PyCharm",
        "com.jetbrains.webstorm":     "WebStorm",
        "com.apple.dt.Xcode":         "Xcode",
        "com.tinyspeck.slackmacgap":  "Slack",
    ]

    public init() {}

    /// Resolves a human-readable terminal/IDE name and TerminalInfo from a starting PID.
    public func detect(fromPID pid: Int32, tty: String? = nil) -> (terminalName: String?, terminalInfo: TerminalInfo?) {
        var current = pid
        for _ in 0..<15 {
            if let bundleID = bundleID(forPID: current) {
                let name = Self.knownApps[bundleID]
                let info = TerminalInfo(pid: current, ppid: parentPID(of: current),
                                        tty: tty, bundleID: bundleID, windowID: nil)
                return (name ?? appName(forBundleID: bundleID), info)
            }
            let parent = parentPID(of: current)
            guard parent > 1 else { break }
            current = parent
        }
        return (nil, nil)
    }

    // MARK: - Private

    private func bundleID(forPID pid: Int32) -> String? {
        NSWorkspace.shared.runningApplications
            .first { $0.processIdentifier == pid }
            .flatMap { $0.bundleIdentifier }
    }

    private func appName(forBundleID bundleID: String) -> String? {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == bundleID }
            .flatMap { $0.localizedName }
    }

    private func parentPID(of pid: Int32) -> Int32 {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        sysctl(&mib, 4, &info, &size, nil, 0)
        return info.kp_eproc.e_ppid
    }
}
