import Foundation

/// Port — activate/focus the terminal window that owns a session.
public protocol TerminalFocuserPort: AnyObject, Sendable {
    func focus(session: Session) async throws
    func canFocus(terminalInfo: TerminalInfo) -> Bool
}
