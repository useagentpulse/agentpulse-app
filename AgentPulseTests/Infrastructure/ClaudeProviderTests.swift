import Testing
import Foundation
@testable import AgentPulse

@Suite("ClaudeProvider payload parsing")
struct ClaudeProviderTests {

    private let installer = StubHookInstaller()
    private lazy var provider = ClaudeProvider(hookInstaller: installer)

    @Test("parses a valid Claude Notification payload")
    mutating func parsesValidPayload() {
        let payload: [String: any Sendable] = [
            "session_id": "abc-123",
            "cwd": "/Users/test/my-project",
            "title": "backend-api",
            "message": "Waiting for input",
            "notification_type": "idle"
        ]
        let event = provider.parse(rawPayload: payload, receivedAt: .now)
        #expect(event != nil)
        #expect(event?.sessionID == "abc-123")
        #expect(event?.cwd == "/Users/test/my-project")
        #expect(event?.notificationType == "idle")
        #expect(event?.providerName == "claude")
    }

    @Test("returns nil for payload missing session_id")
    mutating func rejectsPayloadMissingSessionID() {
        let payload: [String: any Sendable] = ["cwd": "/Users/test"]
        let event = provider.parse(rawPayload: payload, receivedAt: .now)
        #expect(event == nil)
    }

    @Test("returns nil for empty payload")
    mutating func rejectsEmptyPayload() {
        let event = provider.parse(rawPayload: [:], receivedAt: .now)
        #expect(event == nil)
    }
}

// MARK: - Stub

private final class StubHookInstaller: HookInstallerPort, @unchecked Sendable {
    let providerName = "claude"
    func install(hookExecutablePath: String) async throws {}
    func uninstall() async throws {}
    func isInstalled() async -> Bool { false }
}
