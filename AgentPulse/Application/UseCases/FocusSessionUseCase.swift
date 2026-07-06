import Foundation

/// Use case: focus the terminal window for a session and update session state.
public actor FocusSessionUseCase {
    private let sessionRepository: any SessionRepositoryPort
    private let terminalFocuser: any TerminalFocuserPort

    public init(
        sessionRepository: any SessionRepositoryPort,
        terminalFocuser: any TerminalFocuserPort
    ) {
        self.sessionRepository = sessionRepository
        self.terminalFocuser = terminalFocuser
    }

    public func execute(sessionID: SessionID) async throws {
        guard let session = await sessionRepository.find(id: sessionID) else { return }
        try await terminalFocuser.focus(session: session)
    }
}
