import Foundation
import CryptoKit

/// Verification strictness for remote artifact handling.
public enum RemoteVerificationMode: String, Codable, Sendable {
    case permissive
    case strict
}

public extension RemoteVerificationMode {
    var description: String {
        rawValue
    }

    init?(description: String) {
        self.init(rawValue: description.lowercased())
    }
}

/// Limits applied to downloaded and extracted archives to guard against zip bombs and oversized payloads.
public struct RemoteVerificationLimits: Sendable {
    public let maxArchiveBytes: Int64
    public let maxExtractedBytes: Int64
    public let maxFileCount: Int
    public let allowedMIMETypes: Set<String>

    public init(
        maxArchiveBytes: Int64 = 50 * 1024 * 1024,
        maxExtractedBytes: Int64 = 50 * 1024 * 1024,
        maxFileCount: Int = 2_000,
        allowedMIMETypes: Set<String> = ["application/zip", "application/x-zip-compressed"]
    ) {
        self.maxArchiveBytes = maxArchiveBytes
        self.maxExtractedBytes = maxExtractedBytes
        self.maxFileCount = maxFileCount
        self.allowedMIMETypes = allowedMIMETypes
    }

    public static let `default` = RemoteVerificationLimits()
}

/// Manifest describing an artifact’s integrity and provenance.
public struct RemoteArtifactManifest: Codable, Sendable {
    public let sha256: String
    public let size: Int64?
    public let signature: String?
    public let signerKeyId: String?
    public let trustedSigners: [String]?
    public let revokedKeys: [String]?
    public let targets: [AgentKind]?
    public let builtWith: BuiltWith?

    public struct BuiltWith: Codable, Sendable {
        public let tool: String
        public let version: String
        public let hash: String?

        public init(tool: String, version: String, hash: String? = nil) {
            self.tool = tool
            self.version = version
            self.hash = hash
        }
    }

    public init(
        sha256: String,
        size: Int64? = nil,
        signature: String? = nil,
        signerKeyId: String? = nil,
        trustedSigners: [String]? = nil,
        revokedKeys: [String]? = nil,
        targets: [AgentKind]? = nil,
        builtWith: BuiltWith? = nil
    ) {
        self.sha256 = sha256
        self.size = size
        self.signature = signature
        self.signerKeyId = signerKeyId
        self.trustedSigners = trustedSigners
        self.revokedKeys = revokedKeys
        self.targets = targets
        self.builtWith = builtWith
    }
}

/// Outcome of a verification pass.
public struct RemoteVerificationOutcome: Codable, Sendable {
    public let mode: RemoteVerificationMode
    public let checksumValidated: Bool
    public let signatureValidated: Bool
    public let trustedSigner: Bool
    public let issues: [String]

    public init(
        mode: RemoteVerificationMode,
        checksumValidated: Bool,
        signatureValidated: Bool,
        trustedSigner: Bool,
        issues: [String] = []
    ) {
        self.mode = mode
        self.checksumValidated = checksumValidated
        self.signatureValidated = signatureValidated
        self.trustedSigner = trustedSigner
        self.issues = issues
    }
}

/// Local trust store for signer keys.
public struct RemoteTrustStore: Sendable {
    public struct TrustedKey: Codable, Sendable {
        public let keyId: String
        public let publicKeyBase64: String
        public let allowedSlugs: [String]?

        public init(keyId: String, publicKeyBase64: String, allowedSlugs: [String]? = nil) {
            self.keyId = keyId
            self.publicKeyBase64 = publicKeyBase64
            self.allowedSlugs = allowedSlugs
        }
    }

    private var keys: [String: TrustedKey]

    public init(keys: [TrustedKey] = []) {
        self.keys = Dictionary(uniqueKeysWithValues: keys.map { ($0.keyId, $0) })
    }

    public func trustedKey(for keyId: String, scopeSlug: String? = nil) -> TrustedKey? {
        guard let key = keys[keyId] else { return nil }
        if let scopeSlug, let allowed = key.allowedSlugs, !allowed.contains(scopeSlug) {
            return nil
        }
        return key
    }

    public func verifySignature(hexDigest: String, signatureBase64: String, keyId: String, scopeSlug: String? = nil) throws -> Bool {
        guard let key = trustedKey(for: keyId, scopeSlug: scopeSlug) else { return false }
        guard let sigData = Data(base64Encoded: signatureBase64) else { return false }
        guard let keyData = Data(base64Encoded: key.publicKeyBase64) else { return false }
        let message = Data(hexDigest.utf8)
        let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: keyData)
        return pubKey.isValidSignature(sigData, for: message)
    }

    /// In-memory empty store for callers that do not persist trust yet.
    public static let ephemeral = RemoteTrustStore()
}
