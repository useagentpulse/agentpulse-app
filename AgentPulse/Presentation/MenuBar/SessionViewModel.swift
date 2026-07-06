import Foundation
import Observation

/// Observable view model — the single source of truth for all SwiftUI views.
@MainActor
@Observable
public final class SessionViewModel {
    public private(set) var sessions: [Session] = []
    public private(set) var menuBarStatus: MenuBarStatus = .idle
    public var settings: AppSettings = .default

    private let sessionRepository: any SessionRepositoryPort
    private let focusUseCase: FocusSessionUseCase
    private let settingsRepository: any SettingsRepositoryPort
    private let launchAgent: any LaunchAgentPort
    private var refreshTask: Task<Void, Never>?

    public init(
        sessionRepository: any SessionRepositoryPort,
        focusUseCase: FocusSessionUseCase,
        settingsRepository: any SettingsRepositoryPort,
        launchAgent: any LaunchAgentPort
    ) {
        self.sessionRepository = sessionRepository
        self.focusUseCase = focusUseCase
        self.settingsRepository = settingsRepository
        self.launchAgent = launchAgent
    }

    public func start() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        Task { self.settings = await settingsRepository.load() }
    }

    public func stop() {
        refreshTask?.cancel()
    }

    public func focusSession(_ session: Session) {
        Task { try? await focusUseCase.execute(sessionID: session.id) }
    }

    public func saveSettings() {
        Task { await settingsRepository.save(settings) }
        updateLaunchAtLogin()
    }

    // MARK: - Private

    private func refresh() async {
        let all = await sessionRepository.all()
        // Only drop sessions that have gone stale — no event for >5 min (force-closed terminal).
        // Never drop based on status alone; the session row should stay until the terminal is gone.
        let cutoff = Date().addingTimeInterval(-300)
        sessions = all.filter { $0.lastEventAt > cutoff }
        menuBarStatus = MenuBarStatus(from: sessions)
    }

    private func updateLaunchAtLogin() {
        Task {
            if settings.launchAtLogin {
                try? await launchAgent.enable()
            } else {
                try? await launchAgent.disable()
            }
        }
    }
}

public enum MenuBarStatus {
    case idle       // green
    case permission // red

    init(from sessions: [Session]) {
        if sessions.contains(where: { $0.status == .permissionRequest }) {
            self = .permission
        } else {
            self = .idle
        }
    }
}
