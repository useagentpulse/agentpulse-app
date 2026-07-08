import Foundation

/// Port — detect which terminal or IDE owns a given process.
public protocol TerminalDetectorPort: Sendable {
    func detect(fromPID pid: Int32, tty: String?) -> (terminalName: String?, terminalInfo: TerminalInfo?)
}
