import Foundation

// MARK: - Trust Store Persistence Model

/// A single entry in the persistent trust store.
public struct TrustStoreEntry: Codable, Sendable, Identifiable, Hashable {
    /// Unique identifier: key ID (computed property for Identifiable conformance)
    public var id: String { keyId }
    /// Key identifier (e.g., base64-encoded public key fingerprint)
    public let keyId: String
    /// Optional scope slug (if trust is limited to specific skills)
    public let scopeSlug: String?
    /// When this entry was added
    public let addedAt: Date
    /// Fingerprint of the public key for verification
    public let fingerprint: String

    public init(
        keyId: String,
        scopeSlug: String? = nil,
        addedAt: Date = Date(),
        fingerprint: String
    ) {
        self.keyId = keyId
        self.scopeSlug = scopeSlug
        self.addedAt = addedAt
        self.fingerprint = fingerprint
    }

    private enum CodingKeys: String, CodingKey {
        case keyId
        case scopeSlug
        case addedAt
        case fingerprint
    }
}

/// Complete snapshot of the trust store for persistence.
public struct TrustStoreSnapshot: Codable, Sendable {
    /// Version of the trust store format (for future migrations)
    public let version: Int
    /// All trust entries (sorted for stable serialization)
    public let entries: [TrustStoreEntry]
    /// When the snapshot was created
    public let createdAt: Date

    public init(version: Int = 1, entries: [TrustStoreEntry], createdAt: Date = Date()) {
        self.version = version
        // Stable sort: by keyId, then scopeSlug (if present)
        self.entries = entries.sorted { a, b in
            if a.keyId != b.keyId {
                return a.keyId < b.keyId
            }
            return (a.scopeSlug ?? "") < (b.scopeSlug ?? "")
        }
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case entries
        case createdAt
    }
}

// MARK: - JSON Encoding Helper

extension TrustStoreSnapshot {
    /// Encode to JSON data with stable formatting.
    public func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Decode from JSON data.
    public static func decode(from data: Data) throws -> TrustStoreSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TrustStoreSnapshot.self, from: data)
    }
}

// MARK: - Trust Store Persistence Actor

/// Actor for persistent trust store storage with atomic writes and secure permissions.
public actor TrustStorePersistence: Sendable {
    /// URL to the trust.json file in the Application Support directory.
    public let fileURL: URL

    /// Initialize with a custom file URL (for testing) or default location.
    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            let stoolsDir = appSupport.appendingPathComponent("STools", isDirectory: true)
            self.fileURL = stoolsDir.appendingPathComponent("trust.json")
        }
    }

    /// Save a trust store snapshot to disk with atomic swap and secure permissions.
    /// - Parameter snapshot: The snapshot to persist
    /// - Throws: File I/O errors or encoding errors
    public func save(_ snapshot: TrustStoreSnapshot) throws {
        // Ensure directory exists
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true
        )

        // Encode to JSON
        let data = try snapshot.encode()

        // Write to temporary file first (atomic pattern)
        let tempURL = fileURL.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)

        // Set secure permissions (0600 = owner read/write only)
        var attributes = [FileAttributeKey: Any]()
        attributes[.posixPermissions] = 0o600
        try FileManager.default.setAttributes(attributes, ofItemAtPath: tempURL.path)

        // Atomic swap (replace old file with new one)
        try? FileManager.default.removeItem(at: fileURL) // Remove old if exists
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
    }

    /// Load the trust store from disk, returning an empty snapshot if file doesn't exist.
    /// - Returns: The loaded snapshot, or an empty snapshot if file is missing
    /// - Throws: File I/O errors or decoding errors (if file exists but is corrupt)
    public func load() throws -> TrustStoreSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // File doesn't exist yet - return empty store
            return TrustStoreSnapshot(entries: [])
        }

        let data = try Data(contentsOf: fileURL)
        return try TrustStoreSnapshot.decode(from: data)
    }

    /// Check if the trust store file exists on disk.
    public var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Delete the trust store file from disk.
    /// - Throws: File I/O errors
    public func delete() throws {
        try FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Migration

    /// Result of a migration attempt.
    public enum MigrationResult: Sendable {
        case noMigrationNeeded        // New store already exists
        case noOldStoreFound          // No old store to migrate from
        case migrated(count: Int)     // Migrated N entries
        case failed(Error)            // Migration failed with error
    }

    /// Migrate entries from the old SkillsInspector trust store to the new format.
    /// - Parameters:
    ///   - oldStoreURL: URL to the old trust.json file (defaults to SkillsInspector/trust.json)
    ///   - archiveOld: Whether to move the old file to a .backup suffix after migration
    /// - Returns: Migration result indicating what happened
    public func migrate(from oldStoreURL: URL? = nil, archiveOld: Bool = true) async -> MigrationResult {
        // Skip if new store already exists
        if exists {
            return .noMigrationNeeded
        }

        // Default old store location
        let oldURL: URL
        if let oldStoreURL {
            oldURL = oldStoreURL
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            oldURL = appSupport
                .appendingPathComponent("SkillsInspector", isDirectory: true)
                .appendingPathComponent("trust.json")
        }

        // Check if old store exists
        guard FileManager.default.fileExists(atPath: oldURL.path) else {
            return .noOldStoreFound
        }

        do {
            // Read old format
            let data = try Data(contentsOf: oldURL)
            let oldPayload = try JSONDecoder().decode(OldTrustStorePayload.self, from: data)

            // Convert to new format
            let entries = oldPayload.keys.compactMap { key -> TrustStoreEntry? in
                // Skip revoked keys
                if oldPayload.revokedKeyIds.contains(key.keyId) {
                    return nil
                }
                // Use publicKeyBase64 as fingerprint (for now - could compute SHA256)
                return TrustStoreEntry(
                    keyId: key.keyId,
                    scopeSlug: key.allowedSlugs?.first,  // First allowed slug as scope
                    addedAt: Date(),  // Use current date since old format didn't track this
                    fingerprint: key.publicKeyBase64
                )
            }

            // Save to new location
            let snapshot = TrustStoreSnapshot(entries: entries)
            try save(snapshot)

            // Archive old file if requested
            if archiveOld {
                let backupURL = oldURL.appendingPathExtension("backup")
                try? FileManager.default.removeItem(at: backupURL)  // Remove old backup if exists
                try FileManager.default.moveItem(at: oldURL, to: backupURL)
            }

            return .migrated(count: entries.count)

        } catch {
            return .failed(error)
        }
    }

    /// Old trust store payload format (for migration).
    private struct OldTrustStorePayload: Codable {
        let keys: [OldTrustedKey]
        let revokedKeyIds: [String]

        struct OldTrustedKey: Codable {
            let keyId: String
            let publicKeyBase64: String
            let allowedSlugs: [String]?
        }
    }
}
