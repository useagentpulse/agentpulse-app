import Foundation

/// Claude Code–specific agent provider.
/// Parses the `Notification` hook payload emitted by Claude Code.
public final class ClaudeProvider: AgentProviderPort, @unchecked Sendable {
    public let name = "claude"
    public let badgeLetter = "C"
    // Anthropic terracotta brand color
    public let brandColor = (r: 0.851, g: 0.467, b: 0.341)
    public let hookInstaller: any HookInstallerPort

    public init(hookInstaller: any HookInstallerPort) {
        self.hookInstaller = hookInstaller
    }

    public func parse(rawPayload: [String: any Sendable], receivedAt: Date) -> HookEvent? {
        guard
            let sessionID = rawPayload["session_id"] as? String, !sessionID.isEmpty,
            let cwd = rawPayload["cwd"] as? String
        else { return nil }

        // Derive notification_type from hook_event_name when not explicitly provided
        let hookEventName = rawPayload["hook_event_name"] as? String ?? ""
        let explicitType = rawPayload["notification_type"] as? String ?? ""
        let notificationType = Self.notificationType(hookEventName: hookEventName, explicit: explicitType)

        let title = rawPayload["title"] as? String ?? ""
        let message = rawPayload["message"] as? String ?? ""

        return HookEvent(
            providerName: name,
            sessionID: sessionID,
            cwd: cwd,
            title: title,
            message: message,
            notificationType: notificationType,
            receivedAt: receivedAt,
            rawPayload: rawPayload
        )
    }

    /// Maps Claude's hook_event_name to our internal notification_type.
    private static func notificationType(hookEventName: String, explicit: String) -> String {
        // Notification hook carries its own notification_type — trust it
        if hookEventName == "Notification" && !explicit.isEmpty { return explicit }
        switch hookEventName {
        case "PreToolUse":        return "run_start"
        case "PostToolUse":       return "run_start"
        case "UserPromptSubmit":  return "run_start"
        case "Stop":              return "stop"
        default:                  return explicit.isEmpty ? "run_start" : explicit
        }
    }
}
