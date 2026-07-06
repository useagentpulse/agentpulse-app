import Foundation

/// Use case: process an incoming hook event, upsert the session, and trigger notifications.
public actor ProcessHookEventUseCase {
    private let sessionRepository: any SessionRepositoryPort
    private let notificationEngine: NotificationEngine
    private let terminalDetector: any TerminalDetectorPort

    public init(
        sessionRepository: any SessionRepositoryPort,
        notificationEngine: NotificationEngine,
        providers: [any AgentProviderPort],
        terminalDetector: any TerminalDetectorPort
    ) {
        self.sessionRepository = sessionRepository
        self.notificationEngine = notificationEngine
        self.terminalDetector = terminalDetector
    }

    public func execute(_ event: HookEvent) async {
        let existing = await sessionRepository.find(id: event.sessionID)
        let previousStatus = existing?.status
        let session = upsert(event: event, existing: existing)
        await sessionRepository.save(session)
        await notificationEngine.process(session: session, previousStatus: previousStatus)
    }

    private func upsert(event: HookEvent, existing: Session?) -> Session {
        let status = SessionStatus(notificationType: event.notificationType)
        let projectName = Self.projectName(from: event.cwd)
        let transcriptPath = event.rawPayload["transcript_path"] as? String

        // Detect terminal from injected PID only on first event for this session
        var terminalName = existing?.terminalName
        var terminalInfo = existing?.terminalInfo
        if terminalName == nil, let hookPPID = event.rawPayload["_hook_ppid"] as? Int {
            let detected = terminalDetector.detect(fromPID: Int32(hookPPID))
            terminalName = detected.terminalName
            terminalInfo = detected.terminalInfo
        }

        return Session(
            id: event.sessionID,
            cwd: event.cwd,
            projectName: projectName,
            startedAt: existing?.startedAt ?? event.receivedAt,
            lastEventAt: event.receivedAt,
            status: status,
            terminalInfo: terminalInfo,
            lastNotifiedAt: existing?.lastNotifiedAt,
            terminalName: terminalName,
            transcriptPath: transcriptPath ?? existing?.transcriptPath,
            title: event.title.isEmpty ? projectName : event.title,
            providerName: event.providerName
        )
    }

    private static func projectName(from cwd: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if cwd == home { return "~" }
        return URL(fileURLWithPath: cwd).lastPathComponent
    }
}

private extension SessionStatus {
    init(notificationType: String) {
        switch notificationType {
        case "permission_prompt":        self = .permissionRequest
        case "idle", "waiting":          self = .idle
        case "run_start", "run_resume":  self = .running
        case "stop":                     self = .idle
        case "run_end", "done":          self = .finished
        default:                         self = .running
        }
    }
}
