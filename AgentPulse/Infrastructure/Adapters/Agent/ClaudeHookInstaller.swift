import Foundation

/// Installs/removes the AgentPulse hooks in ~/.claude/settings.json.
/// Registers three hooks:
///   Notification  — permission prompts and idle state
///   PreToolUse    — session resumed/running (fires before every tool call)
///   Stop          — session finished
public actor ClaudeHookInstaller: HookInstallerPort {
    public let providerName = "claude"

    private let settingsPath: URL
    private let backupPath: URL

    // The three Claude hook events we care about
    private static let hookNames = ["Notification", "PreToolUse", "PostToolUse", "Stop", "UserPromptSubmit"]

    public init(homeDirectory: URL = URL(fileURLWithPath: NSHomeDirectory())) {
        let claudeDir = homeDirectory.appendingPathComponent(".claude")
        self.settingsPath = claudeDir.appendingPathComponent("settings.json")
        self.backupPath = claudeDir.appendingPathComponent("settings.agentpulse.bak.json")
    }

    public func install(hookExecutablePath: String) async throws {
        var root = try readOrCreateSettings()
        try writeAtomically(root, to: backupPath)

        var hooks = root["hooks"] as? [String: Any] ?? [:]

        for hookName in Self.hookNames {
            var entries = hooks[hookName] as? [[String: Any]] ?? []
            // Idempotent: remove existing AgentPulse entry before re-adding
            entries.removeAll { isAgentPulseEntry($0) }
            entries.append(makeEntry(hookExecutablePath: hookExecutablePath))
            hooks[hookName] = entries
        }

        root["hooks"] = hooks
        try writeAtomically(root, to: settingsPath)
        try validate(root)
    }

    public func uninstall() async throws {
        guard var root = try? readOrCreateSettings(),
              var hooks = root["hooks"] as? [String: Any]
        else { return }

        for hookName in Self.hookNames {
            var entries = hooks[hookName] as? [[String: Any]] ?? []
            entries.removeAll { isAgentPulseEntry($0) }
            hooks[hookName] = entries.isEmpty ? nil : entries
        }

        root["hooks"] = hooks
        try writeAtomically(root, to: settingsPath)
    }

    public func isInstalled() async -> Bool {
        guard
            let root = try? readOrCreateSettings(),
            let hooks = root["hooks"] as? [String: Any],
            let notifHooks = hooks["Notification"] as? [[String: Any]]
        else { return false }
        return notifHooks.contains { isAgentPulseEntry($0) }
    }

    // MARK: - Private helpers

    private func makeEntry(hookExecutablePath: String) -> [String: Any] {
        ["matcher": "", "hooks": [["type": "command", "command": hookExecutablePath]]]
    }

    private func isAgentPulseEntry(_ entry: [String: Any]) -> Bool {
        let inner = entry["hooks"] as? [[String: Any]] ?? []
        return inner.contains { ($0["command"] as? String)?.contains("agentpulse") == true }
    }

    private func readOrCreateSettings() throws -> [String: Any] {
        let dir = settingsPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard FileManager.default.fileExists(atPath: settingsPath.path) else { return [:] }
        let data = try Data(contentsOf: settingsPath)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HookInstallerError.invalidSettingsFormat
        }
        return json
    }

    private func writeAtomically(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
    }

    private func validate(_ root: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: root)
        guard (try? JSONSerialization.jsonObject(with: data)) != nil else {
            throw HookInstallerError.validationFailed
        }
    }
}

public enum HookInstallerError: Error, LocalizedError {
    case invalidSettingsFormat
    case validationFailed

    public var errorDescription: String? {
        switch self {
        case .invalidSettingsFormat: return "~/.claude/settings.json is not valid JSON"
        case .validationFailed:      return "Written settings.json failed re-parse validation"
        }
    }
}
