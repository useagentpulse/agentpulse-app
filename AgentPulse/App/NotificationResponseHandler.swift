import Foundation
import UserNotifications
import AppKit

/// Handles notification response actions (Open Session / Dismiss).
public final class NotificationResponseHandler: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let focusUseCase: FocusSessionUseCase
    private let sessionRepository: any SessionRepositoryPort
    private let settingsRepository: any SettingsRepositoryPort

    public init(
        focusUseCase: FocusSessionUseCase,
        sessionRepository: any SessionRepositoryPort,
        settingsRepository: any SettingsRepositoryPort
    ) {
        self.focusUseCase = focusUseCase
        self.sessionRepository = sessionRepository
        self.settingsRepository = settingsRepository
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let sessionID = userInfo["sessionID"] as? String else { return }

        switch response.actionIdentifier {
        case "OPEN_SESSION", UNNotificationDefaultActionIdentifier:
            let settings = await settingsRepository.load()
            if settings.autoFocusTerminal {
                try? await focusUseCase.execute(sessionID: sessionID)
            }
            // Bring the app to the front
            await MainActor.run { NSApplication.shared.activate(ignoringOtherApps: true) }

        case "DISMISS", UNNotificationDismissActionIdentifier:
            break // nothing to do

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
