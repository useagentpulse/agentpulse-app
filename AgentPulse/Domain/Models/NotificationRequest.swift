import Foundation

public struct NotificationRequest: Sendable {
    public let sessionID: SessionID
    public let title: String
    public let body: String
    public let status: SessionStatus
    public let projectName: String

    public init(
        sessionID: SessionID,
        title: String,
        body: String,
        status: SessionStatus,
        projectName: String
    ) {
        self.sessionID = sessionID
        self.title = title
        self.body = body
        self.status = status
        self.projectName = projectName
    }
}
