import Foundation

/// Port — listen for hook events over any transport.
public protocol HookReceiverPort: AnyObject, Sendable {
    func start() async throws
    func stop() async
}
