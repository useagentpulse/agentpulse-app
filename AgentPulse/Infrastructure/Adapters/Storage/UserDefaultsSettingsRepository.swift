import Foundation

/// UserDefaults-backed settings repository.
public actor UserDefaultsSettingsRepository: SettingsRepositoryPort {
    private let defaults: UserDefaults
    private let key = "com.agentpulse.settings"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() async -> AppSettings {
        guard
            let data = defaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    public func save(_ settings: AppSettings) async {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
