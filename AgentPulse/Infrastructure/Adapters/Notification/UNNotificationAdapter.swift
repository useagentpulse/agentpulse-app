import Foundation
import UserNotifications

/// macOS UNUserNotificationCenter adapter.
public final class UNNotificationAdapter: NotificationPort, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    public init() {}

    public func requestAuthorization() async throws {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func deliver(_ request: NotificationRequest) async {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.userInfo = [
            "sessionID": request.sessionID,
            "status": request.status.rawValue
        ]

        // Action buttons
        let openAction = UNNotificationAction(
            identifier: "OPEN_SESSION",
            title: "Open Session",
            options: .foreground
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )
        let category = UNNotificationCategory(
            identifier: "AGENT_PULSE_SESSION",
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        content.categoryIdentifier = "AGENT_PULSE_SESSION"

        let notifRequest = UNNotificationRequest(
            identifier: request.sessionID,
            content: content,
            trigger: nil // deliver immediately
        )
        do {
            try await center.add(notifRequest)
        } catch {
            print("[Notifications] Failed to deliver: \(error)")
        }
    }

    public func dismiss(sessionID: SessionID) async {
        center.removeDeliveredNotifications(withIdentifiers: [sessionID])
        center.removePendingNotificationRequests(withIdentifiers: [sessionID])
    }
}
