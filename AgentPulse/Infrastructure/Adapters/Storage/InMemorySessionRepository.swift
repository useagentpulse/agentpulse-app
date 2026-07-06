import Foundation

/// In-memory session store with thread-safe actor isolation.
public actor InMemorySessionRepository: SessionRepositoryPort {
    private var sessions: [SessionID: Session] = [:]

    public init() {}

    public func all() async -> [Session] {
        Array(sessions.values).sorted { $0.startedAt < $1.startedAt }
    }

    public func find(id: SessionID) async -> Session? {
        sessions[id]
    }

    public func save(_ session: Session) async {
        if let existing = sessions[session.id] {
            // Preserve immutable fields from the original session
            sessions[session.id] = Session(
                id: session.id,
                cwd: session.cwd,
                projectName: session.projectName,
                startedAt: existing.startedAt,
                lastEventAt: session.lastEventAt,
                status: session.status,
                terminalInfo: session.terminalInfo ?? existing.terminalInfo,
                lastNotifiedAt: session.lastNotifiedAt,
                terminalName: session.terminalName ?? existing.terminalName,
                transcriptPath: session.transcriptPath ?? existing.transcriptPath,
                title: session.title,
                providerName: session.providerName
            )
        } else {
            sessions[session.id] = session
        }
    }

    public func remove(id: SessionID) async {
        sessions.removeValue(forKey: id)
    }

    public func removeExpired(before date: Date) async {
        sessions = sessions.filter { _, session in
            guard session.status == .finished else { return true }
            return session.lastEventAt > date
        }
    }
}
