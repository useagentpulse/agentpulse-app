import Foundation
import AppKit

/// Focuses the exact terminal window/tab that owns a session.
/// Uses TTY matching via AppleScript for precise window targeting.
public final class MacOSTerminalFocuser: TerminalFocuserPort, @unchecked Sendable {

    private static let knownTerminals: [String] = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "com.microsoft.VSCode"
    ]

    public init() {}

    public func focus(session: Session) async throws {
        guard let info = session.terminalInfo, let bundleID = info.bundleID else {
            if let name = session.terminalName { await activateByName(name) }
            return
        }

        // Resolve TTY at click time from the Claude PID — more reliable than hook-time capture
        let tty = session.claudePID.flatMap { ttyForProcess(pid: $0) }
                   ?? info.tty

        print("[Focus] bundleID=\(bundleID) claudePID=\(String(describing: session.claudePID)) tty=\(tty ?? "nil")")

        if let tty, !tty.isEmpty {
            let focused = await focusByTTY(tty: tty, bundleID: bundleID)
            print("[Focus] focusByTTY result: \(focused)")
            if focused { return }
        }
        await activateApp(bundleID: bundleID)
    }

    /// Gets the controlling TTY of a process using `ps` — works for any live process.
    private func ttyForProcess(pid: Int32) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/ps")
        proc.arguments = ["-p", "\(pid)", "-o", "tty="]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        let raw = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty, raw != "??" else { return nil }
        return raw.hasPrefix("/dev/") ? raw : "/dev/\(raw)"
    }

    public func canFocus(terminalInfo: TerminalInfo) -> Bool {
        guard let bundleID = terminalInfo.bundleID else { return false }
        return Self.knownTerminals.contains(bundleID)
    }

    // MARK: - TTY-based focus

    @MainActor
    private func focusByTTY(tty: String, bundleID: String) -> Bool {
        // Normalize tty: strip /dev/ prefix
        let ttyShort = tty.hasPrefix("/dev/") ? String(tty.dropFirst(5)) : tty

        switch bundleID {
        case "com.apple.Terminal":
            return runAppleScript("""
                tell application "Terminal"
                    repeat with w in windows
                        repeat with t in tabs of w
                            if tty of t contains "\(ttyShort)" then
                                set selected tab of w to t
                                set frontmost of w to true
                                activate
                                return true
                            end if
                        end repeat
                    end repeat
                    activate
                end tell
            """)

        case "com.googlecode.iterm2":
            return runAppleScript("""
                tell application "iTerm2"
                    repeat with w in windows
                        repeat with tab_ in tabs of w
                            repeat with s in sessions of tab_
                                if tty of s contains "\(ttyShort)" then
                                    tell w
                                        select tab_
                                        select s
                                    end tell
                                    activate
                                    return true
                                end if
                            end repeat
                        end repeat
                    end repeat
                    activate
                end tell
            """)

        case "com.mitchellh.ghostty":
            return runAppleScript("""
                tell application "Ghostty"
                    activate
                end tell
            """)

        case "dev.warp.Warp-Stable":
            return runAppleScript("""
                tell application "Warp"
                    activate
                end tell
            """)

        case "com.microsoft.VSCode":
            return runAppleScript("""
                tell application "Visual Studio Code"
                    activate
                end tell
            """)

        default:
            return false
        }
    }

    @MainActor
    private func activateApp(bundleID: String) {
        NSWorkspace.shared.runningApplications
            .first { $0.bundleIdentifier == bundleID }?
            .activate()
    }

    @MainActor
    private func activateByName(_ name: String) {
        NSWorkspace.shared.runningApplications
            .first { $0.localizedName == name }?
            .activate()
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> Bool {
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        if let error {
            print("[Focus] AppleScript error: \(error)")
        } else {
            print("[Focus] AppleScript result: \(result?.stringValue ?? "nil")")
        }
        return error == nil
    }
}
