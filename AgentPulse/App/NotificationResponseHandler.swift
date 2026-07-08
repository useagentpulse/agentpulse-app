import Foundation
import UserNotifications
import AppKit

/// Handles notification response actions (Open Session / Dismiss).
public final class NotificationResponseHandler: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let focusUseCase: FocusSessionUseCase

    public init(focusUseCase: FocusSessionUseCase) {
        self.focusUseCase = focusUseCase
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let sessionID = userInfo["sessionID"] as? String else { return }

        switch response.actionIdentifier {
        case "OPEN_SESSION", UNNotificationDefaultActionIdentifier:
            try? await focusUseCase.execute(sessionID: sessionID)

        case "DISMISS", UNNotificationDismissActionIdentifier:
            break

        default:
            break
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Always show even when app is in foreground
        return [.banner, .sound]
    }
}
