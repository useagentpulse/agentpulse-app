import Foundation

/// Core aggregate — all business logic around a Claude (or future) agent session.
public struct Session: Identifiable, Sendable {
    public let id: SessionID
    public var cwd: String
    public var projectName: String
    public let startedAt: Date
    public var lastEventAt: Date
    public var status: SessionStatus
    public var terminalInfo: TerminalInfo?
    public var lastNotifiedAt: Date?
    public var terminalName: String?
    public var transcriptPath: String?
    public var title: String
    public var providerName: String

    public init(
        id: SessionID,
        cwd: String,
        projectName: String,
        startedAt: Date,
        lastEventAt: Date,
        status: SessionStatus,
        terminalInfo: TerminalInfo? = nil,
        lastNotifiedAt: Date? = nil,
        terminalName: String? = nil,
        transcriptPath: String? = nil,
        title: String,
        providerName: String
    ) {
        self.id = id
        self.cwd = cwd
        self.projectName = projectName
        self.startedAt = startedAt
        self.lastEventAt = lastEventAt
        self.status = status
        self.terminalInfo = terminalInfo
        self.lastNotifiedAt = lastNotifiedAt
        self.terminalName = terminalName
        self.transcriptPath = transcriptPath
        self.title = title
        self.providerName = providerName
    }

    /// Whether this session requires immediate user attention.
    public var needsAttention: Bool {
        status == .permissionRequest
    }}

public typealias SessionID = String
