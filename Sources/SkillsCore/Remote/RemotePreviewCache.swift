import Foundation

/// Lightweight cache for remote SKILL.md previews and metadata.
public struct RemotePreviewCache: Sendable {
    private let cacheRoot: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(cacheRoot: URL? = nil) {
        if let cacheRoot {
            self.cacheRoot = cacheRoot
        } else {
            let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            self.cacheRoot = (base ?? FileManager.default.temporaryDirectory)
                .appendingPathComponent("SkillsInspector", isDirectory: true)
                .appendingPathComponent("remote-preview", isDirectory: true)
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load(
        slug: String,
        version: String?,
        expectedManifestSHA256: String?,
        expectedETag: String?
    ) -> RemoteSkillPreview? {
        let url = cacheURL(slug: slug, version: version)
        guard let data = try? Data(contentsOf: url),
              let preview = try? decoder.decode(RemoteSkillPreview.self, from: data)
        else { return nil }
        if let expectedManifestSHA256, let manifestHash = preview.manifest?.sha256, expectedManifestSHA256 != manifestHash {
            return nil
        }
        if let expectedETag, let etag = preview.etag, expectedETag != etag {
            return nil
        }
        return preview
    }

    public func store(_ preview: RemoteSkillPreview) {
        let url = cacheURL(slug: preview.slug, version: preview.version)
        do {
            try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
            let data = try encoder.encode(preview)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Cache failures should not block installs.
        }
    }

    public func loadManifest(slug: String, version: String?) -> CachedManifest? {
        let url = manifestCacheURL(slug: slug, version: version)
        guard let data = try? Data(contentsOf: url),
              let manifest = try? decoder.decode(CachedManifest.self, from: data)
        else { return nil }
        return manifest
    }

    public func storeManifest(slug: String, version: String?, manifest: RemoteArtifactManifest, etag: String?) {
        let url = manifestCacheURL(slug: slug, version: version)
        do {
            try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
            let payload = CachedManifest(
                slug: slug,
                version: version,
                manifest: manifest,
                etag: etag,
                fetchedAt: Date()
            )
            let data = try encoder.encode(payload)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Cache failures should not block installs.
        }
    }

    private func cacheURL(slug: String, version: String?) -> URL {
        let safeSlug = slug.replacingOccurrences(of: "/", with: "-")
        let safeVersion = (version ?? "latest").replacingOccurrences(of: "/", with: "-")
        return cacheRoot.appendingPathComponent("\(safeSlug)-\(safeVersion).json")
    }

    private func manifestCacheURL(slug: String, version: String?) -> URL {
        let safeSlug = slug.replacingOccurrences(of: "/", with: "-")
        let safeVersion = (version ?? "latest").replacingOccurrences(of: "/", with: "-")
        return cacheRoot.appendingPathComponent("\(safeSlug)-\(safeVersion)-manifest.json")
    }
}

public struct CachedManifest: Codable, Sendable {
    public let slug: String
    public let version: String?
    public let manifest: RemoteArtifactManifest
    public let etag: String?
    public let fetchedAt: Date
}
