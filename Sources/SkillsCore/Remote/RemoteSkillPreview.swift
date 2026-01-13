import Foundation

/// Cached preview data for a remote skill.
public struct RemoteSkillPreview: Codable, Sendable {
    public let slug: String
    public let version: String?
    public let skillMarkdown: String?
    public let changelog: String?
    public let signerKeyId: String?
    public let manifest: RemoteArtifactManifest?
    public let etag: String?
    public let fetchedAt: Date

    public init(
        slug: String,
        version: String?,
        skillMarkdown: String?,
        changelog: String?,
        signerKeyId: String?,
        manifest: RemoteArtifactManifest?,
        etag: String?,
        fetchedAt: Date
    ) {
        self.slug = slug
        self.version = version
        self.skillMarkdown = skillMarkdown
        self.changelog = changelog
        self.signerKeyId = signerKeyId
        self.manifest = manifest
        self.etag = etag
        self.fetchedAt = fetchedAt
    }
}
