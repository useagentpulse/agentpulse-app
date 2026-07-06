import Foundation

/// Port — deliver a user-visible notification.
public protocol NotificationPort: AnyObject, Sendable {
    func requestAuthorization() async throws
    func deliver(_ request: NotificationRequest) async
    func dismiss(sessionID: SessionID) async
}
