import Foundation
import AppKit

/// Focuses the terminal window that owns a session, using the parent-process chain.
public final class MacOSTerminalFocuser: TerminalFocuserPort, @unchecked Sendable {

    // Known terminal bundle identifiers
    private static let knownTerminals: [String] = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "com.microsoft.VSCode"
    ]

    public init() {}

    public func focus(session: Session) async throws {
        guard let info = session.terminalInfo else {
            // No terminal info — try to find by walking parent processes of session PID
            return
        }
        try await focusUsing(info: info)
    }

    public func canFocus(terminalInfo: TerminalInfo) -> Bool {
        guard let bundleID = terminalInfo.bundleID else { return false }
        return Self.knownTerminals.contains(bundleID)
    }

    // MARK: - Private

    private func focusUsing(info: TerminalInfo) async throws {
        if let bundleID = info.bundleID {
            await activateApp(bundleID: bundleID)
            return
        }
        // Walk the process tree to find the terminal
        if let bundleID = findTerminalBundleID(from: info.ppid) {
            await activateApp(bundleID: bundleID)
        }
    }

    @MainActor
    private func activateApp(bundleID: String) {
        let apps = NSWorkspace.shared.runningApplications
        if let app = apps.first(where: { $0.bundleIdentifier == bundleID }) {
            app.activate()
        }
    }

    private func findTerminalBundleID(from pid: Int32) -> String? {
        var current = pid
        for _ in 0..<10 { // safety: max 10 levels up
            if let bundleID = bundleID(forPID: current),
               Self.knownTerminals.contains(bundleID) {
                return bundleID
            }
            let parent = parentPID(of: current)
            guard parent > 1 else { break }
            current = parent
        }
        return nil
    }

    private func bundleID(forPID pid: Int32) -> String? {
        NSWorkspace.shared.runningApplications
            .first { $0.processIdentifier == pid }
            .flatMap { $0.bundleIdentifier }
    }

    private func parentPID(of pid: Int32) -> Int32 {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        sysctl(&mib, 4, &info, &size, nil, 0)
        return info.kp_eproc.e_ppid
    }
}
