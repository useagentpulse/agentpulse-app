import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var launchAtLogin: Bool
    public var notificationsEnabled: Bool
    public var playSoundOnNotification: Bool
    public var autoFocusTerminal: Bool
    public var sessionRetentionMinutes: Int
    public var theme: AppTheme

    public static let `default` = AppSettings(
        launchAtLogin: true,
        notificationsEnabled: true,
        playSoundOnNotification: true,
        autoFocusTerminal: false,
        sessionRetentionMinutes: 30,
        theme: .system
    )

    public init(
        launchAtLogin: Bool,
        notificationsEnabled: Bool,
        playSoundOnNotification: Bool,
        autoFocusTerminal: Bool,
        sessionRetentionMinutes: Int,
        theme: AppTheme
    ) {
        self.launchAtLogin = launchAtLogin
        self.notificationsEnabled = notificationsEnabled
        self.playSoundOnNotification = playSoundOnNotification
        self.autoFocusTerminal = autoFocusTerminal
        self.sessionRetentionMinutes = sessionRetentionMinutes
        self.theme = theme
    }
}

public enum AppTheme: String, Codable, CaseIterable, Equatable, Sendable {
    case system, light, dark
}
