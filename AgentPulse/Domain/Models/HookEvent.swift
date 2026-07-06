import Foundation

/// Raw event received from a hook payload (provider-agnostic).
public struct HookEvent: Sendable {
    public let providerName: String
    public let sessionID: SessionID
    public let cwd: String
    public let title: String
    public let message: String
    public let notificationType: String
    public let receivedAt: Date
    public let rawPayload: [String: any Sendable]

    public init(
        providerName: String,
        sessionID: SessionID,
        cwd: String,
        title: String,
        message: String,
        notificationType: String,
        receivedAt: Date,
        rawPayload: [String: any Sendable]
    ) {
        self.providerName = providerName
        self.sessionID = sessionID
        self.cwd = cwd
        self.title = title
        self.message = message
        self.notificationType = notificationType
        self.receivedAt = receivedAt
        self.rawPayload = rawPayload
    }
}
