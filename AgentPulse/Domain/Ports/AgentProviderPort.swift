import Foundation

/// Port — extension point for any agent CLI provider (Claude, Gemini, Codex …).
/// Conformers live in Infrastructure; the Domain never imports them.
public protocol AgentProviderPort: AnyObject, Sendable {
    /// Human-readable identifier, e.g. "claude", "gemini".
    var name: String { get }

    /// Single letter shown in the provider badge, e.g. "C", "G".
    var badgeLetter: String { get }

    /// Brand color as (red, green, blue) in 0–1 range.
    var brandColor: (r: Double, g: Double, b: Double) { get }

    /// Parse a raw JSON dictionary into a `HookEvent` — return nil if unrecognised.
    func parse(rawPayload: [String: any Sendable], receivedAt: Date) -> HookEvent?

    /// Hook installer specific to this provider.
    var hookInstaller: any HookInstallerPort { get }
}
