import Foundation

/// Port — install/uninstall the hook configuration for an agent CLI.
public protocol HookInstallerPort: AnyObject, Sendable {
    var providerName: String { get }
    func install(hookExecutablePath: String) async throws
    func uninstall() async throws
    func isInstalled() async -> Bool
}
