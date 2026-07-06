import Testing
import Foundation
@testable import AgentPulse

@Suite("ClaudeHookInstaller")
struct ClaudeHookInstallerTests {

    @Test("installs hook and marks as installed")
    func installAndDetect() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir.appendingPathComponent(".claude"),
                                                 withIntermediateDirectories: true)

        let installer = ClaudeHookInstaller(homeDirectory: tmpDir)
        #expect(await installer.isInstalled() == false)

        try await installer.install(hookExecutablePath: "/usr/local/bin/agentpulse-hook")
        #expect(await installer.isInstalled() == true)
    }

    @Test("uninstall removes hook")
    func uninstall() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir.appendingPathComponent(".claude"),
                                                 withIntermediateDirectories: true)

        let installer = ClaudeHookInstaller(homeDirectory: tmpDir)
        try await installer.install(hookExecutablePath: "/usr/local/bin/agentpulse-hook")
        try await installer.uninstall()
        #expect(await installer.isInstalled() == false)
    }

    @Test("install is idempotent — does not duplicate hook entries")
    func idempotent() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir.appendingPathComponent(".claude"),
                                                 withIntermediateDirectories: true)

        let installer = ClaudeHookInstaller(homeDirectory: tmpDir)
        try await installer.install(hookExecutablePath: "/usr/local/bin/agentpulse-hook")
        try await installer.install(hookExecutablePath: "/usr/local/bin/agentpulse-hook")

        let settingsPath = tmpDir.appendingPathComponent(".claude/settings.json")
        let data = try Data(contentsOf: settingsPath)
        let root = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let hooks = root["hooks"] as! [String: Any]
        let notifHooks = hooks["Notification"] as! [[String: Any]]

        // Should have exactly one AgentPulse entry
        let agentPulseEntries = notifHooks.filter { entry in
            let innerHooks = entry["hooks"] as? [[String: Any]] ?? []
            return innerHooks.contains { ($0["command"] as? String)?.contains("agentpulse") == true }
        }
        #expect(agentPulseEntries.count == 1)
    }

    @Test("preserves pre-existing hooks when installing")
    func preservesExistingHooks() async throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let claudeDir = tmpDir.appendingPathComponent(".claude")
        try FileManager.default.createDirectory(at: claudeDir, withIntermediateDirectories: true)

        // Write settings with an existing hook
        let existing: [String: Any] = [
            "hooks": [
                "Notification": [
                    ["matcher": "", "hooks": [["type": "command", "command": "some-other-tool"]]]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: existing)
        try data.write(to: claudeDir.appendingPathComponent("settings.json"))

        let installer = ClaudeHookInstaller(homeDirectory: tmpDir)
        try await installer.install(hookExecutablePath: "/usr/local/bin/agentpulse-hook")

        let settingsPath = claudeDir.appendingPathComponent("settings.json")
        let resultData = try Data(contentsOf: settingsPath)
        let root = try JSONSerialization.jsonObject(with: resultData) as! [String: Any]
        let hooks = root["hooks"] as! [String: Any]
        let notifHooks = hooks["Notification"] as! [[String: Any]]

        let commands = notifHooks.flatMap { entry in
            (entry["hooks"] as? [[String: Any]] ?? []).compactMap { $0["command"] as? String }
        }
        #expect(commands.contains("some-other-tool"))
        #expect(commands.contains(where: { $0.contains("agentpulse") }))
    }
}
