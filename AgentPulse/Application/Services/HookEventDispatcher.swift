import Foundation

/// Dispatches raw JSON payloads from the socket to the registered providers.
public actor HookEventDispatcher {
    private let providers: [String: any AgentProviderPort]
    private let processUseCase: ProcessHookEventUseCase

    public init(
        providers: [any AgentProviderPort],
        processUseCase: ProcessHookEventUseCase
    ) {
        self.providers = Dictionary(uniqueKeysWithValues: providers.map { ($0.name, $0) })
        self.processUseCase = processUseCase
    }

    /// Called by the socket server for every incoming raw payload.
    public func dispatch(rawPayload: [String: any Sendable], receivedAt: Date) async {
        for provider in providers.values {
            if let event = provider.parse(rawPayload: rawPayload, receivedAt: receivedAt) {
                await processUseCase.execute(event)
                return
            }
        }
        // No provider recognised this payload — silently ignore.
    }
}
