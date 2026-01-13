import Foundation

/// Installs a verified skill archive into multiple targets with rollback on partial failure.
public struct MultiTargetSkillInstaller: Sendable {
    private let installer: RemoteSkillInstaller

    public init(installer: RemoteSkillInstaller = RemoteSkillInstaller()) {
        self.installer = installer
    }

    public func install(
        archiveURL: URL,
        targets: [SkillInstallTarget],
        overwrite: Bool,
        manifest: RemoteArtifactManifest,
        policy: RemoteVerificationPolicy = .default,
        trustStore: RemoteTrustStore = .ephemeral,
        skillSlug: String? = nil
    ) async throws -> MultiTargetInstallOutcome {
        var successes: [AgentKind: RemoteSkillInstallResult] = [:]
        var failures: [AgentKind: String] = [:]
        var installedPaths: [URL] = []

        for target in targets {
            do {
                let result = try await installer.install(
                    archiveURL: archiveURL,
                    target: target,
                    overwrite: overwrite,
                    manifest: manifest,
                    policy: policy,
                    trustStore: trustStore,
                    skillSlug: skillSlug
                )
                successes[target.agentKind] = result
                installedPaths.append(result.skillDirectory)
            } catch {
                failures[target.agentKind] = error.localizedDescription
                rollback(paths: installedPaths)
                return MultiTargetInstallOutcome(
                    successes: [:],
                    failures: failures,
                    didRollback: true
                )
            }
        }

        return MultiTargetInstallOutcome(
            successes: successes,
            failures: failures,
            didRollback: false
        )
    }

    private func rollback(paths: [URL]) {
        for path in paths {
            try? FileManager.default.removeItem(at: path)
        }
    }
}

public struct MultiTargetInstallOutcome: Sendable {
    public let successes: [AgentKind: RemoteSkillInstallResult]
    public let failures: [AgentKind: String]
    public let didRollback: Bool

    public init(successes: [AgentKind: RemoteSkillInstallResult], failures: [AgentKind: String], didRollback: Bool) {
        self.successes = successes
        self.failures = failures
        self.didRollback = didRollback
    }
}

public extension SkillInstallTarget {
    var agentKind: AgentKind {
        switch self {
        case .codex: return .codex
        case .claude: return .claude
        case .copilot: return .copilot
        case .custom: return .codex
        }
    }
}
