import Testing
import Foundation
@testable import AgentPulse

@Suite("NotificationEngine deduplication")
struct NotificationEngineTests {

    @Test("fires notification on running → permissionRequest transition")
    func firesOnPermissionRequest() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository()
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let session = makeSession(id: "s1", status: .permissionRequest)
        await sessionRepo.save(session)
        await engine.process(session: session, previousStatus: .running)

        #expect(notifAdapter.deliverCount == 1)
    }

    @Test("does not fire twice for same status")
    func noDuplicateNotification() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository()
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let session = makeSession(id: "s1", status: .permissionRequest)
        await sessionRepo.save(session)
        await engine.process(session: session, previousStatus: .running)
        await engine.process(session: session, previousStatus: .permissionRequest)

        #expect(notifAdapter.deliverCount == 1)
    }

    @Test("does not fire for idle status")
    func doesNotFireForIdle() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository()
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let session = makeSession(id: "s1", status: .idle)
        await sessionRepo.save(session)
        await engine.process(session: session, previousStatus: .running)

        #expect(notifAdapter.deliverCount == 0)
    }

    @Test("does not fire when notifications disabled")
    func respectsNotificationsDisabled() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository(notificationsEnabled: false)
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let session = makeSession(id: "s1", status: .permissionRequest)
        await sessionRepo.save(session)
        await engine.process(session: session, previousStatus: .running)

        #expect(notifAdapter.deliverCount == 0)
    }
}

// MARK: - Helpers

private func makeSession(id: String, status: SessionStatus) -> Session {
    Session(id: id, cwd: "/tmp", projectName: "test", startedAt: .now,
            lastEventAt: .now, status: status, title: "test", providerName: "claude")
}

private actor SpyNotificationAdapter: NotificationPort {
    private(set) var deliverCount = 0
    func requestAuthorization() async throws {}
    func deliver(_ request: NotificationRequest) async { deliverCount += 1 }
    func dismiss(sessionID: SessionID) async {}
}

private actor StubSettingsRepository: SettingsRepositoryPort {
    private var settings: AppSettings
    init(notificationsEnabled: Bool = true) {
        var s = AppSettings.default
        s.notificationsEnabled = notificationsEnabled
        self.settings = s
    }
    func load() async -> AppSettings { settings }
    func save(_ settings: AppSettings) async { self.settings = settings }
}
