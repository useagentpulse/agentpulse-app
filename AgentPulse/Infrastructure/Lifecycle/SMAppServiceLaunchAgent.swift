import Foundation
import ServiceManagement

/// Manages the app's LaunchAgent via SMAppService (macOS 13+).
public final class SMAppServiceLaunchAgent: LaunchAgentPort, @unchecked Sendable {
    private let service = SMAppService.mainApp

    public init() {}

    public func enable() async throws {
        try service.register()
    }

    public func disable() async throws {
        try await service.unregister()
    }

    public func isEnabled() async -> Bool {
        service.status == .enabled
    }
}
