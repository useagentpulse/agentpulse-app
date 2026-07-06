import Foundation

/// Orchestrates notification delivery with deduplication.
/// Rule: only fire once per session until status changes back to running.
public actor NotificationEngine {
    private let notificationPort: any NotificationPort
    private let settingsRepository: any SettingsRepositoryPort
    private let sessionRepository: any SessionRepositoryPort

    public init(
        notificationPort: any NotificationPort,
        settingsRepository: any SettingsRepositoryPort,
        sessionRepository: any SessionRepositoryPort
    ) {
        self.notificationPort = notificationPort
        self.settingsRepository = settingsRepository
        self.sessionRepository = sessionRepository
    }

    public func process(session: Session, previousStatus: SessionStatus?) async {
        let settings = await settingsRepository.load()
        guard settings.notificationsEnabled else { return }
        guard session.status.triggersNotification else { return }
        guard session.status != previousStatus else { return } // no duplicate

        let body: String
        switch session.status {
        case .permissionRequest: body = "\(session.projectName) / Input required"
        default:                 body = session.projectName
        }

        let request = NotificationRequest(
            sessionID: session.id,
            title: "Claude needs your attention",
            body: body,
            status: session.status,
            projectName: session.projectName
        )
        await notificationPort.deliver(request)

        // Record notification time
        var updated = session
        updated.lastNotifiedAt = Date()
        await sessionRepository.save(updated)
    }
}
