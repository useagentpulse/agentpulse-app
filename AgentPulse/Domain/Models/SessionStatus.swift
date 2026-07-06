import Foundation

public enum SessionStatus: String, Codable, Sendable, CaseIterable {
    case running          = "running"
    case idle             = "idle"
    case permissionRequest = "permission_request"
    case finished         = "finished"
    case unknown          = "unknown"

    public var displayName: String {
        switch self {
        case .running:           return "Running"
        case .idle:              return "Idle"
        case .permissionRequest: return "Input Required"
        case .finished:          return "Finished"
        case .unknown:           return "Unknown"
        }
    }

    public var triggersNotification: Bool {
        switch self {
        case .permissionRequest: return true
        default: return false
        }
    }
}
