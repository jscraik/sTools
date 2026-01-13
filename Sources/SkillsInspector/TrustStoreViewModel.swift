import Foundation
import SkillsCore

@MainActor
final class TrustStoreViewModel: ObservableObject {
    @Published private(set) var keys: [RemoteTrustStore.TrustedKey] = []
    @Published private(set) var revokedKeyIds: Set<String> = []
    @Published var errorMessage: String?

    private let storeURL: URL

    init(storeURL: URL? = nil) {
        if let storeURL {
            self.storeURL = storeURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            self.storeURL = (base ?? FileManager.default.temporaryDirectory)
                .appendingPathComponent("SkillsInspector", isDirectory: true)
                .appendingPathComponent("trust.json")
        }
        load()
    }

    var trustStore: RemoteTrustStore {
        let allowed = keys.filter { !revokedKeyIds.contains($0.keyId) }
        return RemoteTrustStore(keys: allowed)
    }

    func isTrusted(keyId: String, slug: String?) -> Bool {
        guard let key = keys.first(where: { $0.keyId == keyId }) else { return false }
        if revokedKeyIds.contains(keyId) { return false }
        if let slug, let allowed = key.allowedSlugs, !allowed.contains(slug) {
            return false
        }
        return true
    }

    func addTrustedKey(keyId: String, publicKeyBase64: String, allowedSlugs: [String]? = nil) {
        guard !keyId.isEmpty, !publicKeyBase64.isEmpty else { return }
        if let index = keys.firstIndex(where: { $0.keyId == keyId }) {
            keys[index] = RemoteTrustStore.TrustedKey(keyId: keyId, publicKeyBase64: publicKeyBase64, allowedSlugs: allowedSlugs ?? keys[index].allowedSlugs)
        } else {
            keys.append(RemoteTrustStore.TrustedKey(keyId: keyId, publicKeyBase64: publicKeyBase64, allowedSlugs: allowedSlugs))
        }
        revokedKeyIds.remove(keyId)
        save()
    }

    func revokeKey(keyId: String) {
        revokedKeyIds.insert(keyId)
        save()
    }

    func clearError() {
        errorMessage = nil
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storeURL)
            let payload = try JSONDecoder().decode(TrustStorePayload.self, from: data)
            keys = payload.keys
            revokedKeyIds = Set(payload.revokedKeyIds)
        } catch {
            // First-run is expected; only surface if file exists but fails to parse.
            if FileManager.default.fileExists(atPath: storeURL.path) {
                errorMessage = "Failed to load trust store: \(error.localizedDescription)"
            }
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let payload = TrustStorePayload(keys: keys, revokedKeyIds: Array(revokedKeyIds))
            let data = try JSONEncoder().encode(payload)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            errorMessage = "Failed to save trust store: \(error.localizedDescription)"
        }
    }
}

private struct TrustStorePayload: Codable {
    let keys: [RemoteTrustStore.TrustedKey]
    let revokedKeyIds: [String]
}
