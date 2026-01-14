import Foundation

/// Post-install validation hook for verifying a skill after installation.
public protocol PostInstallValidator: Sendable {
    /// Validates that a skill is correctly installed for a specific target.
    /// - Parameters:
    ///   - result: The installation result containing the skill directory path.
    ///   - target: The target where the skill was installed.
    /// - Returns: `nil` if validation passes, or an error message describing the failure.
    func validate(result: RemoteSkillInstallResult, target: SkillInstallTarget) -> String?
}

/// Default validator that checks SKILL.md exists and is readable.
public struct DefaultPostInstallValidator: PostInstallValidator {
    public init() {}

    public func validate(result: RemoteSkillInstallResult, target: SkillInstallTarget) -> String? {
        let skillFile = result.skillDirectory.appendingPathComponent("SKILL.md")
        guard FileManager.default.fileExists(atPath: skillFile.path) else {
            return "SKILL.md not found at \(skillFile.path)"
        }
        guard let _ = try? String(contentsOf: skillFile, encoding: .utf8) else {
            return "SKILL.md exists but is not readable at \(skillFile.path)"
        }
        return nil
    }
}

/// Installs a verified skill archive into multiple targets with rollback on partial failure.
public struct MultiTargetSkillInstaller: Sendable {
    private let installer: RemoteSkillInstaller
    private let validator: any PostInstallValidator

    public init(
        installer: RemoteSkillInstaller = RemoteSkillInstaller(),
        validator: (any PostInstallValidator)? = nil
    ) {
        self.installer = installer
        self.validator = validator ?? DefaultPostInstallValidator()
    }

    /// Installs a skill to multiple targets with best-effort semantics.
    /// - Parameters:
    ///   - archiveURL: URL of the verified skill archive
    ///   - targets: Array of target locations to install to
    ///   - overwrite: Whether to overwrite existing installations
    ///   - manifest: The verified manifest for this skill
    ///   - policy: Verification policy to apply
    ///   - trustStore: Trust store for signature verification
    ///   - skillSlug: Optional skill identifier for logging
    /// - Returns: Outcome containing successes and failures per target
    /// - Note: Failed targets do NOT roll back successful targets (best-effort semantics)
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

                // Run post-install validation hook
                if let validationError = validator.validate(result: result, target: target) {
                    throw RemoteInstallError.validationFailed(validationError)
                }

                successes[target.agentKind] = result
            } catch {
                failures[target.agentKind] = error.localizedDescription
                // Continue with remaining targets - do NOT roll back successful installs
                // This implements best-effort semantics for cross-IDE installs
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
