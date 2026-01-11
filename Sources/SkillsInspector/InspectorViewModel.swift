import Foundation
import SkillsCore

@MainActor
final class InspectorViewModel: ObservableObject {
    @Published var codexRoots: [URL] {
        didSet { persistSettings() }
    }
    @Published var claudeRoot: URL {
        didSet { persistSettings() }
    }
    @Published var recursive = false {
        didSet { persistSettings() }
    }
    @Published var excludeInput: String = "" {
        didSet { persistSettings() }
    }
    @Published var excludeGlobInput: String = "" {
        didSet { persistSettings() }
    }
    @Published var maxDepth: Int? = nil {
        didSet { persistSettings() }
    }
    @Published var watchMode = false {
        didSet {
            if watchMode {
                startWatching()
            } else {
                stopWatching()
            }
        }
    }
    @Published var findings: [Finding] = []
    @Published var isScanning = false
    @Published var scanTask: Task<Void, Never>?
    @Published var lastScanAt: Date?
    @Published var lastScanDuration: TimeInterval?
    @Published var scanProgress: Double = 0
    @Published var filesScanned = 0
    @Published var totalFiles = 0
    @Published var cacheHits = 0

    private var currentScanID: UUID = UUID()
    private var fileWatcher: FileWatcher?
    private var lastWatchTrigger: Date = Date()
    private let settingsKey = "com.stools.settings"

    static let defaultExcludes = [".git", ".system", "__pycache__", ".DS_Store"]
    private static let suspiciousPaths = ["/System", "/Library", "/usr", "/bin", "/sbin"]

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(UserSettings.self, from: data) {
            codexRoots = saved.codexRoots.isEmpty ? Self.defaultCodexRoots(home: home) : saved.codexRoots
            claudeRoot = saved.claudeRoot
            recursive = saved.recursive
            excludeInput = saved.excludeInput
            excludeGlobInput = saved.excludeGlobInput
            maxDepth = saved.maxDepth
        } else {
            codexRoots = Self.defaultCodexRoots(home: home)
            claudeRoot = home.appendingPathComponent(".claude/skills", isDirectory: true)
        }
    }

    /// Backwards-compatible single-root accessor for tests and legacy call sites.
    var codexRoot: URL {
        get { codexRoots.first ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex/skills", isDirectory: true) }
        set {
            if codexRoots.isEmpty {
                codexRoots = [newValue]
            } else {
                codexRoots[0] = newValue
            }
        }
    }

    var effectiveExcludes: [String] {
        let user = excludeInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return Array(Set(Self.defaultExcludes).union(user))
    }

    var effectiveGlobExcludes: [String] {
        excludeGlobInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    func scan() async {
        // Cancel any ongoing scan
        scanTask?.cancel()
        scanTask = nil

        // Generate unique scan ID to track this specific scan
        let scanID = UUID()
        currentScanID = scanID

        // Reset scan state
        isScanning = true
        scanProgress = 0
        filesScanned = 0
        totalFiles = 0
        cacheHits = 0
        let started = Date()

        let codexRootsCopy = codexRoots
        let claude = claudeRoot
        let recursiveFlag = recursive

        scanTask = Task { [weak self] in
            guard Task.isCancelled == false else { return }

            // Build roots from all Codex directories plus Claude
            var roots: [ScanRoot] = codexRootsCopy.map { url in
                ScanRoot(agent: .codex, rootURL: url, recursive: recursiveFlag)
            }
            roots.append(ScanRoot(agent: .claude, rootURL: claude, recursive: recursiveFlag))
            
            // Set up cache
            let cacheURL = Self.findRepoRoot(from: codexRootsCopy.first ?? claude) ?? Self.findRepoRoot(from: claude)
            let cacheManager: CacheManager?
            if let cacheRoot = cacheURL {
                let cachePath = cacheRoot.appendingPathComponent(".skillsctl/cache.json")
                cacheManager = CacheManager(cacheURL: cachePath, configHash: nil)
            } else {
                cacheManager = nil
            }

            // Use async scanner
            let (findings, stats) = await AsyncSkillsScanner.scanAndValidate(
                roots: roots,
                excludeDirNames: Set(Self.defaultExcludes),
                excludeGlobs: [],
                policy: nil,
                cacheManager: cacheManager,
                maxConcurrency: ProcessInfo.processInfo.activeProcessorCount
            )
            
            // Generate suggested fixes for findings
            let findingsWithFixes = await withTaskGroup(of: Finding.self) { group in
                for finding in findings {
                    group.addTask {
                        var updatedFinding = finding
                        // Try to load file content and generate fix
                        if let content = try? String(contentsOf: finding.fileURL, encoding: .utf8) {
                            updatedFinding.suggestedFix = FixEngine.suggestFix(for: finding, content: content)
                        }
                        return updatedFinding
                    }
                }
                
                var result: [Finding] = []
                for await finding in group {
                    result.append(finding)
                }
                return result
            }
            
            // Save cache
            if let cacheManager {
                await cacheManager.save()
            }

            guard let self = self, currentScanID == scanID else { return }
            guard Task.isCancelled == false else { return }

            await MainActor.run {
                self.findings = findingsWithFixes.sorted(by: { lhs, rhs in
                    if lhs.severity != rhs.severity { return lhs.severity.rawValue < rhs.severity.rawValue }
                    if lhs.agent != rhs.agent { return lhs.agent.rawValue < rhs.agent.rawValue }
                    return lhs.fileURL.path < rhs.fileURL.path
                })
                self.cacheHits = stats.cacheHits
                self.filesScanned = stats.scannedFiles
                self.totalFiles = stats.scannedFiles
                self.isScanning = false
                self.scanTask = nil
                self.lastScanAt = Date()
                self.lastScanDuration = Date().timeIntervalSince(started)
                self.scanProgress = 1.0
            }
        }
    }
    
    private static func findRepoRoot(from url: URL) -> URL? {
        var current = url
        while current.path != "/" {
            let gitPath = current.appendingPathComponent(".git").path
            if FileManager.default.fileExists(atPath: gitPath) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return nil
    }
    
    private func startWatching() {
        stopWatching()
        
        var roots = codexRoots
        roots.append(claudeRoot)
        fileWatcher = FileWatcher(roots: roots)
        fileWatcher?.onChange = { [weak self] in
            guard let self else { return }
            
            // Debounce: only trigger if 500ms have passed
            let now = Date()
            guard now.timeIntervalSince(self.lastWatchTrigger) > 0.5 else { return }
            self.lastWatchTrigger = now
            
            Task { @MainActor in
                await self.scan()
            }
        }
        fileWatcher?.start()
    }
    
    private func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }
    
    func clearCache() async {
        // Find cache location
        let cacheURL = Self.findRepoRoot(from: codexRoots.first ?? claudeRoot) ?? Self.findRepoRoot(from: claudeRoot)
        if let cacheRoot = cacheURL {
            let cachePath = cacheRoot.appendingPathComponent(".skillsctl/cache.json")
            try? FileManager.default.removeItem(at: cachePath)
        }
        cacheHits = 0
    }

    func validateRoot(_ url: URL) -> Bool {
        guard PathUtil.existsDir(url) else { return false }
        let path = url.path
        for suspicious in Self.suspiciousPaths {
            if path.hasPrefix(suspicious) { return false }
        }
        return true
    }

    private func persistSettings() {
        let settings = UserSettings(
            codexRoots: codexRoots,
            claudeRoot: claudeRoot,
            recursive: recursive,
            excludeInput: excludeInput,
            excludeGlobInput: excludeGlobInput,
            maxDepth: maxDepth
        )
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private static func defaultCodexRoots(home: URL) -> [URL] {
        let potentialRoots: [URL] = [
            home.appendingPathComponent(".codex/skills", isDirectory: true),
            home.appendingPathComponent(".codex/public/skills", isDirectory: true)
        ]
        var seenPaths = Set<String>()
        var resolvedRoots: [URL] = []
        for url in potentialRoots {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let resolved = (try? FileManager.default.destinationOfSymbolicLink(atPath: url.path))
                .map { URL(fileURLWithPath: $0, isDirectory: true) }
                ?? url
            let canonicalPath = resolved.standardized.path
            if !seenPaths.contains(canonicalPath) {
                seenPaths.insert(canonicalPath)
                resolvedRoots.append(resolved)
            }
        }
        let primaryCodex = home.appendingPathComponent(".codex/skills", isDirectory: true)
        if FileManager.default.fileExists(atPath: primaryCodex.path) {
            return [primaryCodex]
        }
        return resolvedRoots.isEmpty ? [primaryCodex] : resolvedRoots
    }
}

// Private helper for scan results with scan ID tracking
private struct ScanResult: Sendable {
    let findings: [Finding]
    let scanID: UUID
}

private struct UserSettings: Codable {
    let codexRoots: [URL]
    let claudeRoot: URL
    let recursive: Bool
    let excludeInput: String
    let excludeGlobInput: String
    let maxDepth: Int?
}
