import Foundation

/// Use case: install hooks for all registered providers.
public actor InstallHooksUseCase {
    private let providers: [any AgentProviderPort]
    private let hookExecutablePath: String

    public init(providers: [any AgentProviderPort], hookExecutablePath: String) {
        self.providers = providers
        self.hookExecutablePath = hookExecutablePath
    }

    public func execute() async {
        await withTaskGroup(of: Void.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        try await provider.hookInstaller.install(hookExecutablePath: self.hookExecutablePath)
                    } catch {
                        // Log but never crash — must not break Claude
                        print("[HookInstall] Failed for \(provider.name): \(error)")
                    }
                }
            }
        }
    }
}
