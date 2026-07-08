import Foundation
import Observation

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

    public func stop() { refreshTask?.cancel() }

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
        sessions = all.filter { isAlive($0) }
        menuBarStatus = MenuBarStatus(from: sessions)
    }

    private func isAlive(_ session: Session) -> Bool {
        if let pid = session.claudePID {
            return kill(pid, 0) == 0
        }
        return session.lastEventAt > Date().addingTimeInterval(-1800)
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

// MARK: - Menu Bar Status

public enum MenuBarStatus {
    case idle        // gray dot  — no active sessions
    case running     // blue dot  — sessions actively working
    case waiting     // orange dot — session waiting for input
    case permission  // red dot   — session blocked on approval

    /// Priority: permission > waiting > running > idle
    init(from sessions: [Session]) {
        if sessions.contains(where: { $0.status == .permissionRequest }) {
            self = .permission
        } else if sessions.contains(where: { $0.status == .idle && $0.lastEventAt > Date().addingTimeInterval(-300) }) {
            // recently went idle = likely waiting for next input
            self = .waiting
        } else if sessions.contains(where: { $0.status == .running }) {
            self = .running
        } else {
            self = .idle
        }
    }
}
