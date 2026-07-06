import Foundation

/// Port — manage the app's LaunchAgent registration.
public protocol LaunchAgentPort: AnyObject, Sendable {
    func enable() async throws
    func disable() async throws
    func isEnabled() async -> Bool
}
