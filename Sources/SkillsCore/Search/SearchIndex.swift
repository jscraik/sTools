import Foundation

/// Helper utilities for search index management
public enum SearchIndex {
    /// Default index locations for each agent
    public static func defaultIndexURL(for agent: AgentKind) -> URL {
        let fm = FileManager.default
        let appSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let supportDir = appSupportURL.appendingPathComponent("SkillsInspector", isDirectory: true)

        if !fm.fileExists(atPath: supportDir.path) {
            try? fm.createDirectory(at: supportDir, withIntermediateDirectories: true)
        }

        return supportDir.appendingPathComponent("skills-fts.db")
    }

    /// Get all standard skill root paths
    public static func standardRootPaths() -> [URL] {
        var roots: [URL] = []

        // Codex
        if let codexRoot = getCodexRoot() {
            roots.append(codexRoot)
        }

        // Claude
        if let claudeRoot = getClaudeRoot() {
            roots.append(claudeRoot)
        }

        // Copilot
        if let copilotRoot = getCopilotRoot() {
            roots.append(copilotRoot)
        }

        return roots
    }

    /// Scan a root path for all skills
    public static func scanRoots(_ roots: [URL]) async throws -> [SkillSearchEngine.Skill] {
        var skills: [SkillSearchEngine.Skill] = []

        for root in roots {
            let found = try scanRoot(root)
            skills.append(contentsOf: found)
        }

        return skills
    }

    /// Scan a single root for skills
    private static func scanRoot(_ root: URL) throws -> [SkillSearchEngine.Skill] {
        var skills: [SkillSearchEngine.Skill] = []
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: nil,
                                                  options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return skills
        }

        for case let dirURL as URL in enumerator {
            guard dirURL.hasDirectoryPath else { continue }

            // Check for SKILL.md
            let skillFile = dirURL.appendingPathComponent("SKILL.md")
            guard fm.fileExists(atPath: skillFile.path) else { continue }

            // Read metadata
            let content = try? String(contentsOf: skillFile, encoding: .utf8)
            let frontmatter = content.map { FrontmatterParser.parseTopBlock($0) } ?? [:]

            // Determine agent from path
            let agent: AgentKind
            let pathLower = dirURL.path.lowercased()
            if pathLower.contains("claude") {
                agent = .claude
            } else if pathLower.contains("copilot") {
                agent = .copilot
            } else {
                agent = .codex
            }

            // Get file size
            let attrs = try? fm.attributesOfItem(atPath: dirURL.path)
            let fileSize = attrs?[.size] as? Int

            let skill = SkillSearchEngine.Skill(
                slug: dirURL.lastPathComponent,
                name: frontmatter["name"],
                description: frontmatter["description"],
                agent: agent,
                rootPath: dirURL.path,
                tags: frontmatter["tags"]?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) },
                rank: nil,
                fileSize: fileSize
            )

            skills.append(skill)
        }

        return skills
    }

    /// Get Codex skills root
    private static func getCodexRoot() -> URL? {
        // Standard Codex location
        let home = FileManager.default.homeDirectoryForCurrentUser
        let codexPath = home.appendingPathComponent(".codex/skills")

        if FileManager.default.fileExists(atPath: codexPath.path) {
            return codexPath
        }

        // Alternative: ~/Skills/codex
        let altPath = home.appendingPathComponent("Skills/codex")
        if FileManager.default.fileExists(atPath: altPath.path) {
            return altPath
        }

        return nil
    }

    /// Get Claude skills root
    private static func getClaudeRoot() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let claudePath = home.appendingPathComponent(".claude/skills")

        if FileManager.default.fileExists(atPath: claudePath.path) {
            return claudePath
        }

        let altPath = home.appendingPathComponent("Skills/claude")
        if FileManager.default.fileExists(atPath: altPath.path) {
            return altPath
        }

        return nil
    }

    /// Get Copilot skills root
    private static func getCopilotRoot() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let copilotPath = home.appendingPathComponent(".copilot/skills")

        if FileManager.default.fileExists(atPath: copilotPath.path) {
            return copilotPath
        }

        let altPath = home.appendingPathComponent("Skills/copilot")
        if FileManager.default.fileExists(atPath: altPath.path) {
            return altPath
        }

        return nil
    }
}
