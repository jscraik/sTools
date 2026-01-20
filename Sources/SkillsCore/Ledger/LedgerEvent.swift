import Foundation

public struct LedgerEvent: Identifiable, Sendable {
    public let id: Int64
    public let timestamp: Date
    public let eventType: LedgerEventType
    public let skillName: String
    public let skillSlug: String?
    public let version: String?
    public let agent: AgentKind?
    public let status: LedgerEventStatus
    public let note: String?
    public let source: String?
    public let verification: RemoteVerificationMode?
    public let manifestSHA256: String?
    public let targetPath: String?
    public let targets: [AgentKind]?
    public let perTargetResults: [AgentKind: String]?
    public let signerKeyId: String?

    // Network resilience metrics (P3)
    public let timeoutCount: Int?
    public let retryCount: Int?
    public let timeoutDuration: TimeInterval?  // in seconds

    public init(
        id: Int64,
        timestamp: Date,
        eventType: LedgerEventType,
        skillName: String,
        skillSlug: String?,
        version: String?,
        agent: AgentKind?,
        status: LedgerEventStatus,
        note: String?,
        source: String?,
        verification: RemoteVerificationMode?,
        manifestSHA256: String?,
        targetPath: String?,
        targets: [AgentKind]?,
        perTargetResults: [AgentKind: String]?,
        signerKeyId: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.skillName = skillName
        self.skillSlug = skillSlug
        self.version = version
        self.agent = agent
        self.status = status
        self.note = note
        self.source = source
        self.verification = verification
        self.manifestSHA256 = manifestSHA256
        self.targetPath = targetPath
        self.targets = targets
        self.perTargetResults = perTargetResults
        self.signerKeyId = signerKeyId
        self.timeoutCount = nil
        self.retryCount = nil
        self.timeoutDuration = nil
    }

    public init(
        id: Int64,
        timestamp: Date,
        eventType: LedgerEventType,
        skillName: String,
        skillSlug: String? = nil,
        version: String? = nil,
        agent: AgentKind? = nil,
        status: LedgerEventStatus,
        note: String? = nil,
        source: String? = nil,
        verification: RemoteVerificationMode? = nil,
        manifestSHA256: String? = nil,
        targetPath: String? = nil,
        targets: [AgentKind]? = nil,
        perTargetResults: [AgentKind: String]? = nil,
        signerKeyId: String? = nil,
        timeoutCount: Int? = nil,
        retryCount: Int? = nil,
        timeoutDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.skillName = skillName
        self.skillSlug = skillSlug
        self.version = version
        self.agent = agent
        self.status = status
        self.note = note
        self.source = source
        self.verification = verification
        self.manifestSHA256 = manifestSHA256
        self.targetPath = targetPath
        self.targets = targets
        self.perTargetResults = perTargetResults
        self.signerKeyId = signerKeyId
        self.timeoutCount = timeoutCount
        self.retryCount = retryCount
        self.timeoutDuration = timeoutDuration
    }
}
