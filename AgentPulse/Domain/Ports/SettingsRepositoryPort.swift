import Foundation

/// Port — persist and restore AppSettings.
public protocol SettingsRepositoryPort: AnyObject, Sendable {
    func load() async -> AppSettings
    func save(_ settings: AppSettings) async
}
