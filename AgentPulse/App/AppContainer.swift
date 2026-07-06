import Foundation
import UserNotifications

/// Wires every dependency. Owns all long-lived objects.
/// This is the single place that knows which concrete adapters are used.
@MainActor
public final class AppContainer {
    // MARK: - Shared instance
    public static let shared = AppContainer()

    // MARK: - Infrastructure
    private let socketPath: String = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("AgentPulse")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("daemon.sock").path
    }()

    public let sessionRepository: any SessionRepositoryPort = InMemorySessionRepository()
    public let settingsRepository: any SettingsRepositoryPort = UserDefaultsSettingsRepository()
    public let notificationAdapter: UNNotificationAdapter = UNNotificationAdapter()
    public let terminalFocuser: any TerminalFocuserPort = MacOSTerminalFocuser()
    public let terminalDetector: any TerminalDetectorPort = MacOSTerminalDetector()
    public let launchAgent: any LaunchAgentPort = SMAppServiceLaunchAgent()

    // Kept alive so the delegate is not deallocated
    private var notificationResponseHandler: NotificationResponseHandler?

    // MARK: - Agent Providers
    private lazy var claudeProvider: ClaudeProvider = {
        let installer = ClaudeHookInstaller()
        return ClaudeProvider(hookInstaller: installer)
    }()

    public lazy var providers: [any AgentProviderPort] = [claudeProvider]

    // MARK: - Application Services
    public lazy var notificationEngine: NotificationEngine = {
        NotificationEngine(
            notificationPort: notificationAdapter,
            settingsRepository: settingsRepository,
            sessionRepository: sessionRepository
        )
    }()

    public lazy var processHookEventUseCase: ProcessHookEventUseCase = {
        ProcessHookEventUseCase(
            sessionRepository: sessionRepository,
            notificationEngine: notificationEngine,
            providers: providers,
            terminalDetector: terminalDetector
        )
    }()

    public lazy var hookEventDispatcher: HookEventDispatcher = {
        HookEventDispatcher(providers: providers, processUseCase: processHookEventUseCase)
    }()

    public lazy var focusSessionUseCase: FocusSessionUseCase = {
        FocusSessionUseCase(sessionRepository: sessionRepository, terminalFocuser: terminalFocuser)
    }()

    public lazy var purgeExpiredSessionsUseCase: PurgeExpiredSessionsUseCase = {
        PurgeExpiredSessionsUseCase(sessionRepository: sessionRepository, settingsRepository: settingsRepository)
    }()

    public lazy var installHooksUseCase: InstallHooksUseCase = {
        let execPath = hookExecutablePath()
        return InstallHooksUseCase(providers: providers, hookExecutablePath: execPath)
    }()

    // MARK: - Socket server
    public lazy var socketServer: UnixSocketServer = {
        UnixSocketServer(socketPath: socketPath)
    }()

    // MARK: - View Model
    public lazy var sessionViewModel: SessionViewModel = {
        SessionViewModel(
            sessionRepository: sessionRepository,
            focusUseCase: focusSessionUseCase,
            settingsRepository: settingsRepository,
            launchAgent: launchAgent
        )
    }()

    // MARK: - Startup

    public func bootstrap() async {
        // 1. Set notification delegate first so action responses are received
        let handler = NotificationResponseHandler(
            focusUseCase: focusSessionUseCase,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository
        )
        notificationResponseHandler = handler
        UNUserNotificationCenter.current().delegate = handler

        // 2. Request permission — must happen after delegate is set
        try? await notificationAdapter.requestAuthorization()

        // 3. Wire dispatcher before starting the server — avoids the async race
        await socketServer.setDispatcher(hookEventDispatcher)

        // 4. Start socket listener
        try? await socketServer.start()

        // 5. Install hooks
        await installHooksUseCase.execute()

        // 6. Schedule periodic purge
        schedulePurge()
    }

    // MARK: - Private

    private func schedulePurge() {
        Task {
            while true {
                try? await Task.sleep(for: .seconds(300))
                await purgeExpiredSessionsUseCase.execute()
            }
        }
    }

    private func hookExecutablePath() -> String {
        // Always use the stable /Applications path for the hook so that
        // DerivedData rebuilds don't break the registered hook command.
        return "/Applications/AgentPulse.app/Contents/Resources/agentpulse-hook"
    }
}
