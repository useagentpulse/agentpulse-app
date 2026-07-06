import Foundation

/// Use case: purge expired sessions from the registry.
public actor PurgeExpiredSessionsUseCase {
    private let sessionRepository: any SessionRepositoryPort
    private let settingsRepository: any SettingsRepositoryPort

    public init(
        sessionRepository: any SessionRepositoryPort,
        settingsRepository: any SettingsRepositoryPort
    ) {
        self.sessionRepository = sessionRepository
        self.settingsRepository = settingsRepository
    }

    public func execute() async {
        let settings = await settingsRepository.load()
        let cutoff = Date().addingTimeInterval(-Double(settings.sessionRetentionMinutes) * 60)
        await sessionRepository.removeExpired(before: cutoff)
    }
}
