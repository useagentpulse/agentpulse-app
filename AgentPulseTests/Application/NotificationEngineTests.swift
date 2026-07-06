import Testing
import Foundation
@testable import AgentPulse

@Suite("NotificationEngine deduplication")
struct NotificationEngineTests {

    @Test("does not fire twice for same status transition")
    func noDuplicateNotification() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository()
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let session = makeSession(id: "s1", status: .waiting)
        await sessionRepo.save(session)

        // First time: running → waiting
        await engine.process(session: session, previousStatus: .running)
        // Second time: waiting → waiting (same, should not fire)
        await engine.process(session: session, previousStatus: .waiting)

        #expect(notifAdapter.deliverCount == 1)
    }

    @Test("fires again after status resets to running then waiting")
    func firesAfterReset() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository()
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let waiting = makeSession(id: "s1", status: .waiting)
        await sessionRepo.save(waiting)
        await engine.process(session: waiting, previousStatus: .running) // fires

        let running = makeSession(id: "s1", status: .running)
        await sessionRepo.save(running)
        await engine.process(session: running, previousStatus: .waiting) // does not fire

        let waiting2 = makeSession(id: "s1", status: .waiting)
        await sessionRepo.save(waiting2)
        await engine.process(session: waiting2, previousStatus: .running) // fires again

        #expect(notifAdapter.deliverCount == 2)
    }

    @Test("does not fire when notifications disabled in settings")
    func respectsNotificationsDisabled() async {
        let notifAdapter = SpyNotificationAdapter()
        let settingsRepo = StubSettingsRepository(notificationsEnabled: false)
        let sessionRepo = InMemorySessionRepository()
        let engine = NotificationEngine(
            notificationPort: notifAdapter,
            settingsRepository: settingsRepo,
            sessionRepository: sessionRepo
        )

        let session = makeSession(id: "s1", status: .waiting)
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

// MARK: - Spies / Stubs

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
