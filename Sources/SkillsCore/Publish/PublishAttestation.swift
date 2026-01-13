import Foundation

public struct PublishAttestation: Codable, Sendable {
    public let schemaVersion: Int
    public let skillName: String
    public let version: String?
    public let artifactSHA256: String
    public let toolName: String
    public let toolHash: String
    public let builtAt: String
    public let signatureAlgorithm: String
    public let signature: String

    public init(
        schemaVersion: Int = 1,
        skillName: String,
        version: String?,
        artifactSHA256: String,
        toolName: String,
        toolHash: String,
        builtAt: String,
        signatureAlgorithm: String,
        signature: String
    ) {
        self.schemaVersion = schemaVersion
        self.skillName = skillName
        self.version = version
        self.artifactSHA256 = artifactSHA256
        self.toolName = toolName
        self.toolHash = toolHash
        self.builtAt = builtAt
        self.signatureAlgorithm = signatureAlgorithm
        self.signature = signature
    }
}

public struct PublishAttestationPayload: Codable, Sendable {
    public let schemaVersion: Int
    public let skillName: String
    public let version: String?
    public let artifactSHA256: String
    public let toolName: String
    public let toolHash: String
    public let builtAt: String

    public init(
        schemaVersion: Int = 1,
        skillName: String,
        version: String?,
        artifactSHA256: String,
        toolName: String,
        toolHash: String,
        builtAt: String
    ) {
        self.schemaVersion = schemaVersion
        self.skillName = skillName
        self.version = version
        self.artifactSHA256 = artifactSHA256
        self.toolName = toolName
        self.toolHash = toolHash
        self.builtAt = builtAt
    }
}
