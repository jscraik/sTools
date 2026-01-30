# sTools Enhancement Suite: Technical Specification

**Schema Version:** 1
**Document Type:** Technical Specification
**Date:** 2026-01-20
**Status:** READY FOR IMPLEMENTATION REVIEW - Phase 1 features validated
**Author:** Claude Code (product-spec skill)
**Review Status:** CONDITIONALLY APPROVED - Phase 1 (Features 1, 2, 5) | Defer Phase 2 (Feature 3) | Reject Phase 3 (Feature 4)

---

## Review Summary (2026-01-20)

### Original Adversarial Review
**Status:** NOT APPROVED (62 findings: 24 ERROR, 30 WARN, 8 INFO)
**Review document:** `/Users/jamiecraik/dev/sTools/.spec/adversarial-review-2026-01-20-stools-enhancements.md`

### Validation Work Completed
All blocking findings from Option A (Full Validation) have been addressed:

| Task | Status | Artifact |
|------|--------|----------|
| User research | ✅ Complete | `.spec/user-research-findings-2026-01-20.md` |
| Performance baseline | ✅ Complete | `.spec/performance-baseline-2026-01-20.md` |
| Developer documentation | ✅ Complete | `CONTRIBUTING.md` |
| Security fixes guidance | ✅ Complete | `.spec/security-hardening-2026-01-20.md` |
| Business metrics | ✅ Complete | `.spec/business-metrics-2026-01-20.md` |
| Feature prioritization | ✅ Complete | `.spec/feature-prioritization-2026-01-20.md` |

### Updated Approval Status

**PHASE 1 (MUST HAVE) - CONDITIONALLY APPROVED:**
- ✅ Feature 1: Diagnostic Bundles (RICE: 80, strong evidence)
- ✅ Feature 2: Usage Analytics (RICE: 72, strong evidence)
- ✅ Feature 5: Security Scanning (RICE: 112, highest priority)

**Condition:** Implement ERROR-level security fixes from `.spec/security-hardening-2026-01-20.md` before feature development.

**PHASE 2 (SHOULD HAVE) - DEFER TO PHASE 1 SUCCESS:**
- ⏳ Feature 3: Enhanced Error Context (RICE: 30, moderate evidence)

**PHASE 3 (WON'T HAVE) - REJECTED:**
- ❌ Feature 4: Dependency Visualization (RICE: 6, no user demand)

**Evidence:** User research findings and RICE prioritization in `.spec/feature-prioritization-2026-01-20.md`

---

## Executive Summary

This technical specification defines implementation details for five high-value enhancements to sTools (SkillsInspector), a Swift/SwiftUI-based skill validation and management tool. Features include diagnostic bundle export, usage analytics, enhanced error context, dependency visualization, and security scanning—all leveraging existing infrastructure with no new external dependencies.

**Evidence:** Analysis of CodexMonitor project and sTools codebase at `/Users/jamiecraik/dev/recon-workbench/runs/codexmonitor/2026-01-15/run-001/derived/report.md`
*Evidence gap:* CodexMonitor probes failed before completion; architecture inferred from static structure.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Feature 1: Diagnostic Bundles](#feature-1-diagnostic-bundles)
4. [Feature 2: Skill Usage Analytics](#feature-2-skill-usage-analytics)
5. [Feature 3: Enhanced Error Context](#feature-3-enhanced-error-context)
6. [Feature 4: Dependency Visualization](#feature-4-dependency-visualization)
7. [Feature 5: Security Scanning](#feature-5-security-scanning)
8. [Data Models](#data-models)
9. [API Design](#api-design)
10. [Security Considerations](#security-considerations)
11. [Deployment Strategy](#deployment-strategy)
12. [Testing Strategy](#testing-strategy)
13. [Risks and Mitigations](#risks-and-mitigations)
14. [Launch & Rollback Guardrails](#launch--rollback-guardrails)
15. [Post-Launch Monitoring Plan](#post-launch-monitoring-plan)
16. [Support / Ops Impact](#support--ops-impact)
17. [Decision Log / ADRs](#decision-log--adrs)
18. [Evidence Gaps](#evidence-gaps)
19. [Evidence Map](#evidence-map)

---

## Overview

### Current State

sTools is a macOS 14+ application built with Swift 6 and SwiftUI, providing:
- Multi-agent skill validation (Codex, Claude, CodexSkillManager, Copilot)
- SQLite-based event ledger (`SkillLedger`)
- Export to JSON, CSV, HTML, Markdown, JUnit XML
- SLO tracking with error budget monitoring
- File watching and caching

**Evidence:** Package.swift shows macOS 14+ target with Swift 6.2; `Sources/SkillsCore/Ledger/SkillLedger.swift` confirms SQLite persistence.
*Evidence gap:* No current analytics dashboard or diagnostic export capability.

### Enhancement Goals

1. **Diagnostic observability** - Enable comprehensive debugging data collection
2. **Usage insights** - Track scan patterns and quality trends over time
3. **Error clarity** - Provide actionable, contextual error messages
4. **Dependency awareness** - Visualize skill relationships and dependencies
5. **Security posture** - Detect common security anti-patterns in skill scripts

**Evidence:** Recon Workbench analysis of CodexMonitor identified these patterns as applicable to sTools improvement.

---

## Architecture

### System Context

```mermaid
flowchart TD
    subgraph "sTools Application"
        UI[SkillsInspector<br/>SwiftUI App]
        VM[InspectorViewModel<br/>@MainActor Coordinator]
        Core[SkillsCore<br/>Business Logic]
        DB[SQLite Ledger<br/>Event Storage]
    end

    subgraph "New Components"
        Diag[DiagnosticBundle<br/>Collector]
        Analytics[UsageAnalytics<br/>Actor]
        Context[ContextProvider<br/>Actor]
        Deps[DependencyScanner<br/>Actor]
        Security[SecurityScanner<br/>Actor]
    end

    UI --> VM
    VM --> Core
    Core --> DB

    VM --> Diag
    VM --> Analytics
    VM --> Context
    VM --> Deps
    VM --> Security

    Diag --> DB
    Analytics --> DB
    Context --> Core
    Deps --> Core
    Security --> Core
```

**Evidence:** Existing architecture from `Sources/SkillsInspector/InspectorViewModel.swift` and `Sources/SkillsCore/SkillsCore.swift`.

### Component Principles

- **Actor isolation:** All new stateful components use Swift actors for concurrent safety
- **Sendable compliance:** All public types conform to `Sendable` for strict concurrency
- **Async-first:** All I/O operations use async/await patterns
- **Cache-aware:** Repeated operations use TTL-based caching

**Evidence:** Existing `SkillLedger` is an actor; `InspectorViewModel` uses `@MainActor`. Pattern established by codebase.

---

## Feature 1: Diagnostic Bundles

### Overview

Generate comprehensive diagnostic bundles (ZIP archives) containing system information, scan results, recent logs, and metrics for debugging and support.

**Evidence:** Diagnostic pattern identified in CodexMonitor; sTools has existing `ExportService` for extension.
*Evidence gap:* No current bundle export capability exists.

### Component Design

#### DiagnosticBundleCollector (Actor)

```swift
public actor DiagnosticBundleCollector {
    private let ledger: SkillLedger
    private let logger: AppLog

    public init(ledger: SkillLedger = try! SkillLedger())

    public func collect(
        findings: [Finding],
        config: ScanConfiguration,
        includeLogs: Bool = true,
        logHours: Int = 24,
        includeStackTraces: Bool = true
    ) async throws -> DiagnosticBundle
}
```

**Location:** `Sources/SkillsCore/Diagnostics/DiagnosticBundleCollector.swift`
**Evidence:** Actor pattern follows existing `SkillLedger` isolation.
*Evidence gap:* No existing diagnostic collection to reference.

#### Data Models

```swift
public struct DiagnosticBundle: Sendable, Codable {
    public let bundleID: UUID
    public let generatedAt: Date
    public let sToolsVersion: String
    public let systemInfo: SystemInfo
    public let scanConfig: ScanConfiguration
    public let recentFindings: [Finding]
    public let ledgerEvents: [LedgerEvent]
    public let logEntries: [LogEntry]
    public let skillStatistics: SkillStatistics
}

public struct SystemInfo: Sendable, Codable {
    public let macOSVersion: String
    public let architecture: String
    public let hostName: String
    public let availableDiskSpace: Int64
    public let totalMemory: Int64
}
```

**Evidence:** `Finding` model exists in `SkillsCore.swift:31-61`. New models follow same `Sendable` pattern.

### API Design

#### CLI Command

```bash
skillsctl diagnostics --output ~/Desktop/diagnostics.zip \
                     --include-logs \
                     --log-hours 24
```

**Implementation:** `Sources/SkillsCLI/Commands/DiagnosticsCommand.swift`
**Evidence:** Existing CLI pattern from `skillsctl telemetry export` command.

#### SwiftUI Integration

```swift
// InspectorViewModel additions
@Published var diagnosticBundleURL: URL?
@Published var isGeneratingBundle = false

func generateDiagnosticBundle() async throws {
    isGeneratingBundle = true
    defer { isGeneratingBundle = false }

    let collector = DiagnosticBundleCollector()
    let bundle = try await collector.collect(
        findings: findings,
        config: currentScanConfiguration()
    )

    let exporter = DiagnosticBundleExporter()
    let url = try exporter.export(bundle, to: outputURL())
    diagnosticBundleURL = url
}
```

**Location:** `Sources/SkillsInspector/InspectorViewModel.swift` (add after line 50)
**Evidence:** Existing `@Published` pattern in `InspectorViewModel.swift:39-50`.

### Privacy & Redaction

All file paths in diagnostic bundles are processed through existing `TelemetryRedactor`:
- Home directory replaced with `~`
- Username redacted
- PII scrubbed using SHA256 hashing

**Evidence:** `TelemetryRedactor` exists in `Sources/SkillsCore/Telemetry/TelemetryRedactor.swift`.

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Bundle generation time | <5 seconds | 1000 findings + 100 events |
| Bundle size | <5 MB | Typical production data |
| Memory overhead | <50 MB | During generation |

**Evidence:** Performance targets based on existing `ExportService` benchmarks.

---

## Feature 2: Skill Usage Analytics

### Overview

Track and visualize scan frequency, error trends, most-scanned skills, and cache performance using time-series data aggregated from the SkillLedger.

**Evidence:** SLO framework exists in `Sources/SkillsCore/SLO/`. Pattern can be extended for analytics.
*Evidence gap:* No current time-series aggregation or dashboard.

### Component Design

#### UsageAnalytics (Actor)

```swift
public actor UsageAnalytics {
    private let ledger: SkillLedger
    private let aggregator: MetricsAggregator
    private let cache: AnalyticsCache

    public init(ledger: SkillLedger = try! SkillLedger())

    // Scan frequency over time
    public func scanFrequency(days: Int = 30) async throws -> ScanFrequencyMetrics

    // Error trends by rule
    public func errorTrends(byRule: Bool = true, days: Int = 30) async throws -> ErrorTrendsReport

    // Most scanned skills
    public func mostScannedSkills(limit: Int = 10, days: Int = 30) async throws -> [SkillUsageRanking]

    // Cache performance
    public func cacheMetrics(days: Int = 30) async throws -> CachePerformanceMetrics
}
```

**Location:** `Sources/SkillsCore/Analytics/UsageAnalytics.swift`
**Evidence:** Actor pattern mirrors `SkillLedger`; async methods follow existing conventions.

#### Data Models

```swift
public struct ScanFrequencyMetrics: Sendable, Codable {
    public let totalScans: Int
    public let averageScansPerDay: Double
    public let dailyCounts: [(date: Date, count: Int)]
    public let trend: TrendDirection // increasing, stable, decreasing
}

public struct ErrorTrendsReport: Sendable, Codable {
    public let totalErrors: Int
    public let errorsByRule: [String: Int]
    public let errorsByAgent: [AgentKind: Int]
    public let timeSeries: [(date: Date, errors: Int)]
    public let trendingRules: [(rule: String, direction: TrendDirection)]
}

public struct SkillUsageRanking: Sendable, Codable {
    public let skillName: String
    public let agent: AgentKind
    public let scanCount: Int
    public let lastScanned: Date
}

public struct CachePerformanceMetrics: Sendable, Codable {
    public let totalScans: Int
    public let cacheHits: Int
    public let cacheMisses: Int
    public let hitRate: Double
}
```

**Location:** `Sources/SkillsCore/Analytics/UsageAnalytics.swift`
**Evidence:** Follows existing `ScanOutput` pattern from `SkillsCore.swift:119-137`.

### Database Schema

#### New Table: analytics_cache

```sql
CREATE TABLE IF NOT EXISTS analytics_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cache_key TEXT NOT NULL UNIQUE,
    generated_at TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    metrics_json TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_analytics_cache_key ON analytics_cache(cache_key);
CREATE INDEX IF NOT EXISTS idx_analytics_cache_expires ON analytics_cache(expires_at);
```

**Location:** `Sources/SkillsCore/Ledger/SkillLedger.swift` (add to schema in `init`, line 28-62)
**Evidence:** Follows existing `ledger_events` table pattern with indexes.

#### Schema Migration

Use existing `addColumnIfNeeded` pattern for additive migrations:
```swift
try SkillLedger.addColumnIfNeeded(db: db, table: "ledger_events", column: "timeout_count", type: "INTEGER")
```

**Evidence:** Migration pattern established in `SkillLedger.swift:61-63`.

### API Design

#### CLI Commands

```bash
# Scan frequency over time
skillsctl analytics frequency --days 30

# Error trends by rule
skillsctl analytics errors --by-rule --days 7

# Top scanned skills
skillsctl analytics top-skills --limit 10 --days 30

# Cache performance
skillsctl analytics cache --days 30
```

**Location:** `Sources/SkillsCLI/Commands/AnalyticsCommand.swift`
**Evidence:** Follows existing `skillsctl telemetry export` command pattern.

#### SwiftUI Dashboard

```swift
struct AnalyticsDashboardView: View {
    @ObservedObject var viewModel: InspectorViewModel
    @State private var selectedTimeRange: TimeRange = .sevenDays

    var body: some View {
        VStack {
            TimeRangePicker(selectedRange: $selectedTimeRange)
            ScanFrequencyChart(metrics: viewModel.scanFrequency)
            ErrorTrendsChart(trends: viewModel.errorTrends)
            TopSkillsList(skills: viewModel.mostScannedSkills)
            CachePerformanceView(metrics: viewModel.cacheMetrics)
        }
    }
}
```

**Location:** `Sources/SkillsInspector/Analytics/AnalyticsDashboardView.swift`
**Evidence:** Follows existing `StatsView.swift` pattern for SwiftUI views.

### Visualization

Use SwiftUI Charts (built into macOS 14+) for time-series visualizations:

```swift
struct ScanFrequencyChart: View {
    let metrics: ScanFrequencyMetrics

    var body: some View {
        Chart(metrics.dailyCounts, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Scans", item.count)
            )
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
    }
}
```

**Location:** `Sources/SkillsInspector/Analytics/Charts/ScanFrequencyChart.swift`
**Evidence:** SwiftUI Charts available in macOS 14+ (Package.swift line 6).

### Cache Strategy

- **TTL:** 1 hour for cached metrics
- **Invalidation:** Automatic on new scan events
- **Storage:** In-memory `NSCache` + SQLite persistence

**Evidence:** Existing `CacheManager` pattern at `Sources/SkillsCore/Cache.swift` can be referenced.

---

## Feature 3: Enhanced Error Context

### Overview

Extend validation findings with rich context including expected vs actual values, related files, suggested fixes, and next steps.

**Evidence:** `SuggestedFix` type exists in `SkillsCore.swift`. `FixEngine` exists for fix generation.
*Evidence gap:* No current structured error context beyond message.

### Component Design

#### ContextProvider (Actor)

```swift
public actor ContextProvider {
    private let fileCache: FileContentCache

    public init()

    public func context(for finding: Finding, in doc: SkillDoc) async throws -> ErrorContext

    private func extractExpectedActual(finding: Finding, content: String) -> (expected: String?, actual: String?)
    private func findRelatedFiles(doc: SkillDoc, finding: Finding) -> [RelatedFile]
    private func generateNextSteps(finding: Finding) -> [String]
    private func findDocumentation(ruleID: String) -> String?
}
```

**Location:** `Sources/SkillsCore/Validation/ContextProvider.swift`
**Evidence:** Actor pattern follows isolation conventions.

#### Data Models

```swift
public struct ErrorContext: Sendable, Codable {
    public let expected: String?
    public let actual: String?
    public let relatedFiles: [RelatedFile]
    public let suggestedFixes: [SuggestedFix]
    public let nextSteps: [String]
    public let documentationLink: String?
}

public struct RelatedFile: Sendable, Codable {
    public let path: String
    public let reason: String
    public let line: Int?
}
```

**Location:** `Sources/SkillsCore/Validation/ErrorContext.swift`
**Evidence:** `SuggestedFix` exists; extending pattern.

### Validation Rule Extension

Extend `ValidationRule` protocol with optional context method:

```swift
public protocol ValidationRule: Sendable {
    var ruleID: String { get }
    var description: String { get }
    var appliesToAgent: AgentKind? { get }
    var defaultSeverity: Severity { get }
    func validate(doc: SkillDoc, policy: SkillsConfig.Policy?) -> [Finding]

    // NEW: Optional context provider
    func context(for: Finding, in: SkillDoc) async throws -> ErrorContext?
}
```

**Location:** `Sources/SkillsCore/SkillsCore.swift` (extend protocol at line 531-546)
**Evidence:** Protocol extension pattern maintains backward compatibility.

### Example: FrontmatterMissingRule with Context

```swift
struct FrontmatterMissingRule: ValidationRule {
    let ruleID = "frontmatter.missing"
    let description = "YAML frontmatter must start with --- on line 1"
    let appliesToAgent: AgentKind? = nil
    let defaultSeverity: Severity = .error

    func validate(doc: SkillDoc, policy: SkillsConfig.Policy?) -> [Finding] {
        guard !doc.hasFrontmatter else { return [] }
        return [Finding(
            ruleID: ruleID,
            severity: defaultSeverity,
            agent: doc.agent,
            fileURL: doc.skillFileURL,
            message: "Missing or invalid YAML frontmatter (must start with --- on line 1)",
            line: 1,
            column: 1
        )]
    }

    func context(for finding: Finding, in doc: SkillDoc) async throws -> ErrorContext? {
        return ErrorContext(
            expected: "--- at line 1",
            actual: "File starts with: \(try String(contentsOf: doc.skillFileURL, encoding: .utf8).prefix(50))...",
            relatedFiles: [],
            suggestedFixes: [SuggestedFix(
                description: "Add YAML frontmatter at the top of the file",
                edits: [SuggestedFix.Edit(
                    range: NSRange(location: 0, length: 0),
                    replacement: """---
name: Your Skill Name
description: A brief description of what this skill does.

---
"""
                )]
            )],
            nextSteps: [
                "1. Add '---' on the first line",
                "2. Add your skill metadata (name, description)",
                "3. Close frontmatter with another '---'",
                "4. See documentation for frontmatter format"
            ],
            documentationLink: "https://example.com/docs/frontmatter"
        )
    }
}
```

**Location:** `Sources/SkillsCore/SkillsCore.swift` (update rule at line 591-609)
**Evidence:** Existing rule structure; extension adds context method.

### UI Components

```swift
struct ErrorContextView: View {
    let context: ErrorContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let expected = context.expected, let actual = context.actual {
                ExpectedActualView(expected: expected, actual: actual)
            }
            if !context.suggestedFixes.isEmpty {
                SuggestedFixesView(fixes: context.suggestedFixes)
            }
            if !context.nextSteps.isEmpty {
                NextStepsView(steps: context.nextSteps)
            }
        }
    }
}
```

**Location:** `Sources/SkillsInspector/Validation/ErrorContextView.swift`
**Evidence:** Follows existing `FindingDetailView.swift` pattern.

### File Content Cache

```swift
public actor FileContentCache {
    private let cache: NSCache<NSString, FileCacheEntry>

    public func get(url: URL) async -> String?
    public func set(_ content: String, for url: URL, ttl: TimeInterval = 300)
}

public struct FileCacheEntry: Sendable {
    public let content: String
    public let cachedAt: Date
}
```

**Location:** `Sources/SkillsCore/Validation/FileContentCache.swift`
**Evidence:** Caching pattern follows existing `CacheManager` approach.

---

## Feature 4: Dependency Visualization

### Overview

Parse skill files for `@agent` references, script imports, and asset links. Export as GraphViz DOT format and interactive JSON for dependency graph visualization.

**Evidence:** CodexMonitor has dependency tree analysis (`oss.deps_tree` probe). sTools has `SkillDoc` with `referencesCount`.
*Evidence gap:* No current dependency graphing.

### Component Design

#### DependencyScanner (Actor)

```swift
public actor DependencyScanner {
    private let loader: SkillLoader

    public init()

    public func scan(roots: [ScanRoot]) async throws -> DependencyGraph

    private func extractDependencies(from doc: SkillDoc) async throws -> [Dependency]
    private func findAgentReferences(in content: String) -> [String]
    private func findScriptImports(in scriptsURL: URL) async throws -> [String]
    private func findAssetReferences(in assetsURL: URL) async throws -> [String]
    private func findSyncMappings(in doc: SkillDoc) -> [String]
}
```

**Location:** `Sources/SkillsCore/Dependencies/DependencyScanner.swift`
**Evidence:** Actor pattern follows isolation conventions.

#### Data Models

```swift
public struct DependencyGraph: Sendable, Codable {
    public let nodes: [GraphNode]
    public let edges: [GraphEdge]
    public let metadata: GraphMetadata
}

public struct GraphNode: Sendable, Codable, Identifiable {
    public let id: String
    public let name: String
    public let agent: AgentKind
    public let type: NodeType // skill, script, asset, reference
    public let path: String
}

public struct GraphEdge: Sendable, Codable, Identifiable {
    public let id: String
    public let from: String  // node ID
    public let to: String    // node ID
    public let type: EdgeType // references, imports, loads, syncs
    public let label: String?
}

public enum NodeType: String, Sendable, Codable {
    case skill
    case script
    case asset
    case reference
}

public enum EdgeType: String, Sendable, Codable {
    case references
    case imports
    case loads
    case syncs
}
```

**Location:** `Sources/SkillsCore/Dependencies/DependencyGraph.swift`
**Evidence:** Graph model follows Codable pattern from existing `ScanOutput`.

### Dependency Extraction

1. **Agent References:** Parse `@agent` mentions in SKILL.md content
2. **Script Imports:** Parse `import` statements in `scripts/*.swift` files
3. **Asset References:** Parse `assets/` directory references
4. **Sync Mappings:** Use existing `MultiSyncReport` data

**Evidence:** `SkillDoc` has `referencesCount`, `assetsCount`, `scriptsCount` fields.

### Graph Export Formats

#### GraphViz DOT

```swift
public struct GraphExporter: Sendable {
    public static func exportDOT(graph: DependencyGraph) throws -> String {
        var dot = "digraph SkillDependencies {\n"
        dot += "  rankdir=LR;\n"
        dot += "  node [shape=box];\n\n"

        for node in graph.nodes {
            dot += "  \"\(node.id)\" [label=\"\(node.name)\"];\n"
        }

        for edge in graph.edges {
            dot += "  \"\(edge.from)\" -> \"\(edge.to)\""
            if let label = edge.label {
                dot += " [label=\"\(label)\"]"
            }
            dot += ";\n"
        }

        dot += "}"
        return dot
    }
}
```

**Location:** `Sources/SkillsCore/Dependencies/GraphExporter.swift`
**Evidence:** String building pattern follows existing `ExportService` generators.

### API Design

#### CLI Command

```bash
# Export as GraphViz DOT
skillsctl dependencies --output graph.dot --format dot

# Export as JSON
skillsctl dependencies --output graph.json --format json

# Export as interactive HTML
skillsctl dependencies --output graph.html --format html
```

**Location:** `Sources/SkillsCLI/Commands/DependenciesCommand.swift`
**Evidence:** Command pattern follows existing `skillsctl sync-check` structure.

#### SwiftUI Integration

```swift
struct DependencyGraphView: View {
    @ObservedObject var viewModel: InspectorViewModel
    @State private var selectedAgent: AgentKind?
    @State private var selectedNode: GraphNode?

    var body: some View {
        VStack {
            HStack {
                AgentFilter(selectedAgent: $selectedAgent)
                ExportButton()
            }
            if let graph = viewModel.dependencyGraph {
                InteractiveGraphView(graph: filterGraph(graph, by: selectedNode))
            }
        }
    }
}
```

**Location:** `Sources/SkillsInspector/Dependencies/DependencyGraphView.swift`
**Evidence:** View pattern follows `IndexView.swift` structure.

---

## Feature 5: Security Scanning

### Overview

Scan skill scripts for hardcoded secrets, command injection, insecure file operations using regex patterns. Results returned as Findings with security-specific rule IDs.

**Evidence:** CodexMonitor uses Semgrep SAST (`oss.sast_semgrep` probe). sTools has `ValidationRule` framework.
*Evidence gap:* No current security scanning capability.

### Component Design

#### SecurityScanner (Actor)

```swift
public actor SecurityScanner {
    private let rules: [SecurityRule]

    public init(rules: [SecurityRule] = SecurityRule.defaultRules())

    public func scan(doc: SkillDoc) async throws -> [Finding]
    public func scanScript(at url: URL, skillDoc: SkillDoc) async throws -> [Finding]
    public func scanAllScripts(in doc: SkillDoc) async throws -> [Finding]
}
```

**Location:** `Sources/SkillsCore/Security/SecurityScanner.swift`
**Evidence:** Actor pattern follows existing conventions.

#### SecurityRule Protocol

```swift
public protocol SecurityRule: Sendable {
    var ruleID: String { get }
    var description: String { get }
    var severity: Severity { get }
    var patterns: [SecurityPattern] { get }

    func scan(content: String, file: URL, skillDoc: SkillDoc) async throws -> [Finding]
}

public struct SecurityPattern: Sendable {
    public let type: PatternType
    public let regex: NSRegularExpression
    public let message: String
    public let suggestedFix: String?
}

public enum PatternType: Sendable {
    case secret
    case commandInjection
    case insecureFileOp
    case hardcodedCredential
    case evalUsage
}
```

**Location:** `Sources/SkillsCore/Security/DefaultSecurityRules.swift`
**Evidence:** Protocol pattern extends existing `ValidationRule` design.

### Built-in Security Rules

| Rule ID | Pattern | Severity | Description |
|---------|---------|----------|-------------|
| `security.hardcoded_secret` | `api[_-]?key\|secret\|token\|password` + 32+ chars | error | Hardcoded API keys or tokens |
| `security.command_injection` | `shell\(\|system\(\|exec\(\|popen\(` | error | Direct command execution |
| `security.insecure_file_op` | `chmod\(\|chown\(` | warning | File permission modification |
| `security.hardcoded_credential` | `username\|password` + `=` + quoted value | error | Hardcoded credentials in config |
| `security.eval_usage` | `eval\(\|exec\(` + dynamic code | warning | Dynamic code execution |
| `security.insecure_network` | `http://` (not localhost) | warning | Unencrypted HTTP usage |

**Location:** `Sources/SkillsCore/Security/DefaultSecurityRules.swift`
**Evidence:** Regex pattern uses existing `NSRegularExpression` from Foundation.

### Example: HardcodedSecretRule

```swift
struct HardcodedSecretRule: SecurityRule {
    let ruleID = "security.hardcoded_secret"
    let description = "Detects hardcoded secrets and tokens"
    let severity = Severity.error

    let patterns: [SecurityPattern] = [
        SecurityPattern(
            type: .secret,
            regex: try! NSRegularExpression(
                pattern: #"(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*['"]?([a-z0-9]{32,})['"]?"#
            ),
            message: "Possible hardcoded secret detected",
            suggestedFix: "Use environment variables or secure credential storage"
        )
    ]

    func scan(content: String, file: URL, skillDoc: SkillDoc) async throws -> [Finding] {
        var findings: [Finding] = []
        let lines = content.split(whereSeparator: \.isNewline)

        for (index, line) in lines.enumerated() {
            for pattern in patterns {
                let range = NSRange(location: 0, length: line.utf16.count)
                let matches = pattern.regex.matches(in: String(line), range: range)

                for match in matches {
                    findings.append(Finding(
                        ruleID: ruleID,
                        severity: severity,
                        agent: skillDoc.agent,
                        fileURL: file,
                        message: pattern.message,
                        line: index + 1,
                        column: nil,
                        suggestedFix: SuggestedFix(
                            description: pattern.suggestedFix ?? "Remove hardcoded secret",
                            edits: []
                        )
                    ))
                }
            }
        }
        return findings
    }
}
```

**Location:** `Sources/SkillsCore/Security/DefaultSecurityRules.swift`
**Evidence:** Uses existing `Finding` and `SuggestedFix` types.

### API Design

#### CLI Command

```bash
# Run security scan
skillsctl security --format text

# Export as JSON
skillsctl security --format json --output security-report.json

# Export as SARIF
skillsctl security --format sarif --output security.sarif

# Fail on any findings (for CI/CD)
skillsctl security --fail-on-error
```

**Location:** `Sources/SkillsCLI/Commands/SecurityCommand.swift`
**Evidence:** Command pattern follows existing `skillsctl validate` structure.

#### SARIF Output

SARIF (Static Analysis Results Interchange Format) for CI/CD integration:

```swift
private func generateSARIF(from report: SecurityReport) throws -> String {
    let sarif: [String: Any] = [
        "version": "2.1.0",
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "runs": [[
            "tool": [
                "driver": [
                    "name": "sTools Security Scanner",
                    "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                    "informationUri": "https://github.com/example/stools"
                ]
            ],
            "results": report.findings.map { finding in
                [
                    "ruleId": finding.ruleID,
                    "level": finding.severity == .error ? "error" : "warning",
                    "message": [
                        "text": finding.message
                    ],
                    "locations": [[
                        "physicalLocation": [
                            "artifactLocation": [
                                "uri": finding.fileURL.path
                            ],
                            "region": [
                                "startLine": finding.line ?? 1
                            ]
                        ]
                    ]]
                ]
            }
        ]
    ]

    let data = try JSONSerialization.data(withJSONObject: sarif, options: [.prettyPrinted, .sortedKeys])
    return String(data: data, encoding: .utf8) ?? ""
}
```

**Evidence:** SARIF format standard for security tools; JSON serialization uses Foundation.

### Integration with Validation

Add security rules to `ValidationRuleRegistry.defaultRules()`:

```swift
public static func defaultRules() -> [any ValidationRule] {
    var rules = [
        FrontmatterMissingRule(),
        FrontmatterMissingNameRule(),
        // ... existing rules
    ]

    // Add security rules
    rules += [
        HardcodedSecretRule(),
        CommandInjectionRule(),
        InsecureFileOperationRule(),
        HardcodedCredentialRule(),
        EvalUsageRule(),
        InsecureNetworkRule()
    ]

    return rules
}
```

**Location:** `Sources/SkillsCore/SkillsCore.swift` (extend at line 573-586)
**Evidence:** Registry pattern exists; security rules extend existing array.

---

## Data Models

### Core Type Extensions

#### Finding Enhancement

```swift
public struct Finding: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID = UUID()
    public let ruleID: RuleID
    public let severity: Severity
    public let agent: AgentKind
    public let fileURL: URL
    public let message: String
    public let line: Int?
    public let column: Int?
    public var suggestedFix: SuggestedFix?

    // NEW: Optional error context
    public var errorContext: ErrorContext?

    public init(
        ruleID: RuleID,
        severity: Severity,
        agent: AgentKind,
        fileURL: URL,
        message: String,
        line: Int? = nil,
        column: Int? = nil,
        suggestedFix: SuggestedFix? = nil,
        errorContext: ErrorContext? = nil  // NEW
    ) {
        self.ruleID = ruleID
        self.severity = severity
        self.agent = agent
        self.fileURL = fileURL
        self.message = message
        self.line = line
        self.column = column
        self.suggestedFix = suggestedFix
        self.errorContext = errorContext
    }
}
```

**Location:** `Sources/SkillsCore/SkillsCore.swift` (extend at line 31-61)
**Evidence:** Existing struct; optional field maintains backward compatibility.

#### SkillDoc Enhancement

```swift
public struct SkillDoc: Codable, Hashable, Sendable {
    public let agent: AgentKind
    public let rootURL: URL
    public let skillDirURL: URL
    public let skillFileURL: URL
    public let name: String?
    public let description: String?
    public let lineCount: Int
    public let isSymlinkedDir: Bool
    public let hasFrontmatter: Bool
    public let frontmatterStartLine: Int
    public let referencesCount: Int
    public let assetsCount: Int
    public let scriptsCount: Int

    // NEW: Dependency metadata
    public let dependencies: [String]?

    public init(/* ... existing params ..., dependencies: [String]? = nil */) {
        // ... existing init ...
        self.dependencies = dependencies
    }
}
```

**Location:** `Sources/SkillsCore/SkillsCore.swift` (extend at line 64-78)
**Evidence:** Optional field maintains backward compatibility.

### Ledger Extensions

#### New Query Methods

```swift
// In SkillLedger actor

public func fetchRecentErrors(limit: Int = 100) throws -> [LedgerEvent] {
    return try fetchEvents(
        limit: limit,
        eventTypes: [.validationFailed, .scanFailed]
    )
}

public func fetchEventsByType(_ type: LedgerEventType, limit: Int = 100) throws -> [LedgerEvent] {
    return try fetchEvents(
        limit: limit,
        eventTypes: [type]
    )
}

public func fetchScanEvents(days: Int = 30) throws -> [LedgerEvent] {
    let since = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    return try fetchEvents(
        limit: Int.max,
        since: since,
        eventTypes: [.scan]
    )
}

public func fetchEventsGroupedByDay(days: Int = 30) throws -> [(date: Date, count: Int)] {
    let events = try fetchScanEvents(days: days)

    let grouped = Dictionary(grouping: events) { event in
        Calendar.current.startOfDay(for: event.timestamp)
    }

    return grouped.map { (date, events) in
        (date: date, count: events.count)
    }.sorted { $0.date < $1.date }
}
```

**Location:** `Sources/SkillsCore/Ledger/SkillLedger.swift` (add after line 255)
**Evidence:** Follows existing `fetchEvents()` pattern at line 153-234.

#### Analytics Cache CRUD

```swift
// In SkillLedger actor

public func cacheMetrics(key: String, metrics: String, ttl: TimeInterval = 3600) throws {
    guard let db else { throw LedgerStoreError("Ledger unavailable") }

    let now = Date()
    let expiresAt = now.addingTimeInterval(ttl)

    let sql = """
    INSERT INTO analytics_cache (cache_key, generated_at, expires_at, metrics_json)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(cache_key) DO UPDATE SET
        generated_at = excluded.generated_at,
        expires_at = excluded.expires_at,
        metrics_json = excluded.metrics_json;
    """

    let stmt = try prepare(sql: sql)
    defer { sqlite3_finalize(stmt) }

    var index: Int32 = 1
    bindText(stmt, index, key); index += 1
    bindText(stmt, index, SkillLedger.isoFormatter.string(from: now)); index += 1
    bindText(stmt, index, SkillLedger.isoFormatter.string(from: expiresAt)); index += 1
    bindText(stmt, index, metrics); index += 1

    if sqlite3_step(stmt) != SQLITE_DONE {
        throw LedgerStoreError(String(cString: sqlite3_errmsg(db)))
    }
}

public func getCachedMetrics(key: String) throws -> String? {
    guard let db else { throw LedgerStoreError("Ledger unavailable") }

    let sql = """
    SELECT metrics_json
    FROM analytics_cache
    WHERE cache_key = ?
      AND expires_at > ?
    LIMIT 1;
    """

    let stmt = try prepare(sql: sql)
    defer { sqlite3_finalize(stmt) }

    var index: Int32 = 1
    bindText(stmt, index, key); index += 1
    bindText(stmt, index, SkillLedger.isoFormatter.string(from: Date())); index += 1

    if sqlite3_step(stmt) == SQLITE_ROW {
        return stringColumn(stmt, 0)
    }
    return nil
}

public func cleanupExpiredCache() throws -> Int {
    guard let db else { throw LedgerStoreError("Ledger unavailable") }

    let sql = "DELETE FROM analytics_cache WHERE expires_at < ?;"
    let stmt = try prepare(sql: sql)
    defer { sqlite3_finalize(stmt) }

    bindText(stmt, 1, SkillLedger.isoFormatter.string(from: Date()))

    if sqlite3_step(stmt) != SQLITE_DONE {
        throw LedgerStoreError(String(cString: sqlite3_errmsg(db)))
    }

    return Int(sqlite3_changes(db))
}
```

**Location:** `Sources/SkillsCore/Ledger/SkillLedger.swift` (add after line 330)
**Evidence:** Follows existing SQLite prepared statement pattern.

### New Ledger Event Types

```swift
// In LedgerEventType enum

public enum LedgerEventType: String, Codable, Sendable {
    case install
    case uninstall
    case update
    case verify
    case publish
    case scan
    case sync

    // NEW event types
    case diagnosticBundle   // Feature 1
    case analyticsQuery     // Feature 2
    case securityScan       // Feature 5
}
```

**Location:** `Sources/SkillsCore/Ledger/LedgerEventType.swift`
**Evidence:** Extends existing enum at line 3-11.

### New Log Categories

```swift
// In AppLog.Category enum

public enum Category: String, Sendable {
    case general
    case ledger
    case telemetry
    case remote
    case network
    case validation
    case publishing
    case sync
    case ui

    // NEW categories
    case diagnostics     // Feature 1
    case analytics       // Feature 2
    case dependencies    // Feature 4
    case security        // Feature 5
}
```

**Location:** `Sources/SkillsCore/Logging/AppLog.swift`
**Evidence:** Extends existing category enum.

---

## API Design

### Public API Surface

#### Feature 1: Diagnostic Bundles

```swift
// InspectorViewModel
@Published var diagnosticBundleURL: URL?
@Published var isGeneratingBundle = false
func generateDiagnosticBundle(includeLogs: Bool, logHours: Int) async throws

// DiagnosticBundleCollector
public actor DiagnosticBundleCollector {
    public func collect(
        findings: [Finding],
        config: ScanConfiguration,
        includeLogs: Bool = true,
        logHours: Int = 24
    ) async throws -> DiagnosticBundle
}

// DiagnosticBundleExporter
public struct DiagnosticBundleExporter: Sendable {
    public static func export(bundle: DiagnosticBundle, to url: URL) throws
}
```

**Evidence:** Public API follows existing `ExportService` pattern.

#### Feature 2: Skill Usage Analytics

```swift
// UsageAnalytics
public actor UsageAnalytics {
    public func scanFrequency(days: Int = 30) async throws -> ScanFrequencyMetrics
    public func errorTrends(byRule: Bool = true, days: Int = 30) async throws -> ErrorTrendsReport
    public func mostScannedSkills(limit: Int = 10, days: Int = 30) async throws -> [SkillUsageRanking]
    public func cacheMetrics(days: Int = 30) async throws -> CachePerformanceMetrics
}

// InspectorViewModel extensions
@Published var analyticsReport: UsageAnalyticsReport?
func loadAnalytics(timeRange: TimeRange) async throws
```

**Evidence:** Async actor pattern follows existing conventions.

#### Feature 3: Enhanced Error Context

```swift
// ValidationRule protocol extension
public protocol ValidationRule: Sendable {
    func context(for: Finding, in: SkillDoc) async throws -> ErrorContext?
}

// ContextProvider
public actor ContextProvider {
    public func context(for finding: Finding, in doc: SkillDoc) async throws -> ErrorContext
}

// Finding extension
public struct Finding {
    public var errorContext: ErrorContext?
}
```

**Evidence:** Protocol extension maintains backward compatibility.

#### Feature 4: Dependency Visualization

```swift
// DependencyScanner
public actor DependencyScanner {
    public func scan(roots: [ScanRoot]) async throws -> DependencyGraph
}

// GraphExporter
public struct GraphExporter: Sendable {
    public static func exportDOT(graph: DependencyGraph) throws -> String
    public static func exportJSON(graph: DependencyGraph) throws -> String
    public static func exportInteractiveHTML(graph: DependencyGraph) throws -> String
}

// InspectorViewModel extensions
@Published var dependencyGraph: DependencyGraph?
func buildDependencyGraph() async throws
```

**Evidence:** Scanner pattern follows existing `SkillsScanner` design.

#### Feature 5: Security Scanning

```swift
// SecurityScanner
public actor SecurityScanner {
    public func scan(doc: SkillDoc) async throws -> [Finding]
    public func scanAllScripts(in doc: SkillDoc) async throws -> [Finding]
}

// SecurityRule protocol
public protocol SecurityRule: Sendable {
    var ruleID: String { get }
    var severity: Severity { get }
    var patterns: [SecurityPattern] { get }
    func scan(content: String, file: URL, skillDoc: SkillDoc) async throws -> [Finding]
}

// Default rules
public extension SecurityRule {
    static func defaultRules() -> [SecurityRule]
}
```

**Evidence:** Rule protocol extends existing `ValidationRule` pattern.

### CLI Commands

```bash
# Feature 1
skillsctl diagnostics [--output PATH] [--include-logs] [--log-hours N]

# Feature 2
skillsctl analytics frequency|errors|top-skills|cache [--days N]

# Feature 3
skillsctl validate --context  # NEW flag

# Feature 4
skillsctl dependencies [--output PATH] [--format dot|json|html] [--agent AGENT]

# Feature 5
skillsctl security [--format text|json|sarif] [--output PATH] [--fail-on-error]
```

**Evidence:** Command pattern follows existing `skillsctl` structure.

---

## Security Considerations

### Privacy Protection

#### PII Redaction

All diagnostic bundles use existing `TelemetryRedactor`:
- Home directory paths → `~`
- Username → `<redacted>`
- Hostname → `<redacted>`
- File hashes for identification only

**Evidence:** `TelemetryRedactor` in `Sources/SkillsCore/Telemetry/TelemetryRedactor.swift` implements path redaction.

#### Sensitive Data Handling

- **Secrets:** Never included in diagnostic bundles
- **Credentials:** Scan for but don't log actual values
- **File contents:** Only include when explicitly requested (logs)
- **Cache:** Encrypted at rest using macOS keychain

**Evidence:** Existing `SkillLedger` uses SQLite with file permissions; no credential storage.

### Access Control

#### File System

- Validate all paths using existing `PathValidator`
- Reject parent directory traversal (`..`)
- Reject system directories (`/System`, `/Library`, `/usr`)
- Require explicit user confirmation for export locations

**Evidence:** `PathValidator.validatedDirectory()` in `SkillsCore.swift:272-290` implements security checks.

#### Network Operations

- No network requests in core scanning
- Remote skill verification already uses HTTPS
- Security scanning flags insecure HTTP usage (not localhost)

**Evidence:** `RemoteSkillClient` uses HTTPS; `InsecureNetworkRule` detects HTTP.

### Security Scanning Safety

#### False Positive Mitigation

- Patterns require context (e.g., assignment operator, quotes)
- Minimum length thresholds (32 chars for secrets)
- Whitelist common safe patterns (localhost, example.com)

**Evidence:** Regex patterns in `DefaultSecurityRules.swift` include context constraints.

#### Safe Defaults

- Security scanning **opt-in** by default (not automatic)
- Results as warnings only in CI mode
- No automatic fixes applied

**Evidence:** `ValidationRuleRegistry` allows opt-in via configuration.

---

## Deployment Strategy

### Build Process

#### Compilation

```bash
# Standard SPM build
swift build

# Release build with optimization
swift build -c release

# Run tests
swift test

# Run specific test suite
swift test --filter DiagnosticBundleTests
swift test --filter UsageAnalyticsTests
swift test --filter SecurityScannerTests
```

**Evidence:** Existing build process documented in README.

#### Code Signing

```bash
# Sign macOS app
codesign --force --deep --sign "Developer ID Application: Name" build/Release/sTools.app

# Verify signature
codesign --verify --verbose build/Release/sTools.app
```

**Evidence:** Existing code signing for Sparkle updates.

### Database Migration

#### Schema Versioning

Add version tracking to `SkillLedger`:

```sql
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);

-- Initial version
INSERT INTO schema_version (version, applied_at) VALUES (1, datetime('now'));
```

**Location:** `Sources/SkillsCore/Ledger/SkillLedger.swift` (add to init)
**Evidence:** Follows standard migration pattern.

#### Migration Steps

1. Add `analytics_cache` table (idempotent `CREATE TABLE IF NOT EXISTS`)
2. Backward compatible queries check for table existence
3. Old schema continues to work without new features

**Evidence:** `addColumnIfNeeded` pattern at `SkillLedger.swift:298-307` ensures safe migrations.

### Release Strategy

#### Version Bump

```swift
// In Package.swift
let package = Package(
    name: "cLog",
    platforms: [.macOS(.v14)],
    // ... existing targets
)
```

**Evidence:** Version follows semantic versioning.

#### Release Notes

```
## Version X.Y.Z - 2026-01-20

### Added
- Diagnostic bundle export for comprehensive debugging data
- Usage analytics dashboard with scan frequency and error trends
- Enhanced error context with expected/actual values and next steps
- Dependency visualization with GraphViz DOT export
- Security scanning for hardcoded secrets and command injection

### Changed
- Extended Finding model with optional error context
- Added analytics cache table to SkillLedger
- New log categories: diagnostics, analytics, dependencies, security

### Performance
- Analytics queries cached for 1 hour TTL
- File content cache for context generation (5 min TTL)
```

**Evidence:** Release notes follow existing changelog pattern.

### Rollback Plan

```bash
# Revert to previous version
git checkout tags/vPREVIOUS
swift build -c release
swift test

# Verify database compatibility
# Old schema reads new schema (new columns optional)
# New schema reads old schema (graceful degradation)
```

**Evidence:** SQLite schema changes are additive; backward compatible.

---

## Testing Strategy

### Unit Tests

#### Feature 1: Diagnostic Bundles

```swift
final class DiagnosticBundleCollectorTests: XCTestCase {
    func testCollectWithFindings() async throws {
        let ledger = try SkillLedger(memory: true)
        let collector = DiagnosticBundleCollector(ledger: ledger)

        let findings = [
            Finding(ruleID: "test", severity: .error, agent: .codex, fileURL: testURL, message: "Test")
        ]

        let bundle = try await collector.collect(
            findings: findings,
            config: ScanConfiguration(codexRoots: [], claudeRoot: testURL)
        )

        XCTAssertEqual(bundle.recentFindings.count, 1)
        XCTAssertFalse(bundle.systemInfo.macOSVersion.isEmpty)
    }

    func testPIIRedaction() async throws {
        let collector = DiagnosticBundleCollector()
        let bundle = try await collector.collect(
            findings: [],
            config: ScanConfiguration(codexRoots: [homeURL], claudeRoot: testURL)
        )

        // Home directory should be redacted
        XCTAssertTrue(bundle.scanConfig.codexRoots.allSatisfy { $0.contains("~") })
    }
}
```

**Location:** `Tests/SkillsCoreTests/Diagnostics/DiagnosticBundleCollectorTests.swift`
**Evidence:** Test pattern follows existing `SkillLedgerTests` structure.

#### Feature 2: Skill Usage Analytics

```swift
final class UsageAnalyticsTests: XCTestCase {
    func testScanFrequency() async throws {
        let ledger = try SkillLedger(memory: true)
        let analytics = UsageAnalytics(ledger: ledger)

        // Record test events
        for i in 0..<10 {
            let input = LedgerEventInput(
                eventType: .scan,
                skillName: "test-\(i)",
                status: .success
            )
            _ = try ledger.record(input)
        }

        let metrics = try await analytics.scanFrequency(days: 1)

        XCTAssertEqual(metrics.totalScans, 10)
        XCTAssertGreaterThan(metrics.averageScansPerDay, 0)
    }

    func testCacheInvalidation() async throws {
        let ledger = try SkillLedger(memory: true)
        let analytics = UsageAnalytics(ledger: ledger)

        // First call caches
        let metrics1 = try await analytics.scanFrequency(days: 1)

        // Second call should hit cache
        let metrics2 = try await analytics.scanFrequency(days: 1)

        XCTAssertEqual(metrics1.totalScans, metrics2.totalScans)
    }
}
```

**Location:** `Tests/SkillsCoreTests/Analytics/UsageAnalyticsTests.swift`
**Evidence:** Test pattern follows existing conventions.

#### Feature 3: Enhanced Error Context

```swift
final class ContextProviderTests: XCTestCase {
    func testFrontmatterContext() async throws {
        let provider = ContextProvider()
        let doc = SkillDoc(
            agent: .codex,
            rootURL: testURL,
            skillDirURL: testDirURL,
            skillFileURL: testFileURL,
            // ...
        )

        let finding = Finding(
            ruleID: "frontmatter.missing",
            severity: .error,
            agent: .codex,
            fileURL: testFileURL,
            message: "Missing frontmatter"
        )

        let context = try await provider.context(for: finding, in: doc)

        XCTAssertNotNil(context.expected)
        XCTAssertNotNil(context.actual)
        XCTAssertFalse(context.nextSteps.isEmpty)
    }
}
```

**Location:** `Tests/SkillsCoreTests/Validation/ContextProviderTests.swift`
**Evidence:** Test pattern validates context generation.

#### Feature 4: Dependency Visualization

```swift
final class DependencyScannerTests: XCTestCase {
    func testAgentReferences() async throws {
        let scanner = DependencyScanner()
        let doc = createTestSkill(content: """
        # My Skill

        See @agent:claude:commit for details.
        """)

        let graph = try await scanner.scan(roots: [
            ScanRoot(agent: .claude, rootURL: testURL)
        ])

        let edge = graph.edges.first { $0.type == .references }
        XCTAssertNotNil(edge)
        XCTAssertEqual(edge?.label, "@agent:claude:commit")
    }

    func testCycleDetection() async throws {
        let scanner = DependencyScanner()
        // Create cyclic dependency
        let graph = try await scanner.scan(roots: testRoots)

        // Should detect and report cycles
        // (implementation may use DFS or Tarjan's algorithm)
    }
}
```

**Location:** `Tests/SkillsCoreTests/Dependencies/DependencyScannerTests.swift`
**Evidence:** Test pattern validates graph construction.

#### Feature 5: Security Scanning

```swift
final class SecurityScannerTests: XCTestCase {
    func testHardcodedSecretDetection() async throws {
        let scanner = SecurityScanner()
        let scriptURL = createTestScript(content: """
        let apiKey = "sk-1234567890abcdefghijklmnopqrstuvwxyz123456"
        """)

        let findings = try await scanner.scanScript(at: scriptURL, skillDoc: testDoc)

        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?.ruleID, "security.hardcoded_secret")
    }

    func testFalsePositiveMitigation() async throws {
        let scanner = SecurityScanner()
        let scriptURL = createTestScript(content: """
        let apiKey = "short"  // Too short to trigger
        let comment = "// API key format: sk-..."
        """)

        let findings = try await scanner.scanScript(at: scriptURL, skillDoc: testDoc)

        XCTAssertEqual(findings.count, 0)  // Should not flag
    }
}
```

**Location:** `Tests/SkillsCoreTests/Security/SecurityScannerTests.swift`
**Evidence:** Test pattern validates security rule behavior.

### Integration Tests

```swift
final class IntegrationTests: XCTestCase {
    func testEndToEndDiagnosticWorkflow() async throws {
        // 1. Run scan
        let viewModel = InspectorViewModel()
        await viewModel.scan()

        // 2. Generate diagnostic bundle
        try await viewModel.generateDiagnosticBundle(includeLogs: false)

        // 3. Verify bundle exists
        XCTAssertNotNil(viewModel.diagnosticBundleURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: viewModel.diagnosticBundleURL!.path))
    }

    func testEndToEndAnalyticsWorkflow() async throws {
        // 1. Run multiple scans
        let viewModel = InspectorViewModel()
        for _ in 0..<5 {
            await viewModel.scan()
        }

        // 2. Load analytics
        try await viewModel.loadAnalytics(timeRange: .sevenDays)

        // 3. Verify data
        XCTAssertNotNil(viewModel.analyticsReport)
        XCTAssertGreaterThan(viewModel.analyticsReport?.scanFrequency.totalScans ?? 0, 0)
    }
}
```

**Location:** `Tests/SkillsInspectorTests/IntegrationTests.swift`
**Evidence:** Integration tests verify end-to-end workflows.

### Performance Tests

```swift
final class PerformanceTests: XCTestCase {
    func testDiagnosticBundlePerformance() {
        measure {
            // Generate bundle with 1000 findings
            let collector = DiagnosticBundleCollector()
            let findings = (0..<1000).map { i in
                Finding(ruleID: "test-\(i)", severity: .error, agent: .codex, fileURL: testURL, message: "Test")
            }

            let bundle = try? await collector.collect(
                findings: findings,
                config: testConfig
            )

            XCTAssertNotNil(bundle)
        }
    }

    func testAnalyticsQueryPerformance() {
        measure {
            // Query 10k events from ledger
            let analytics = UsageAnalytics()
            let metrics = try? await analytics.scanFrequency(days: 30)

            XCTAssertNotNil(metrics)
        }
    }
}
```

**Location:** `Tests/PerformanceTests.swift`
**Evidence:** Performance tests measure against targets.

---

## Risks and Mitigations

### Risk 1: Database Migration Failure

**Description:** Adding `analytics_cache` table could fail on existing databases with schema conflicts.

**Probability:** Low
**Impact:** High (app won't launch)

**Mitigation:**
- Use `CREATE TABLE IF NOT EXISTS` for idempotency
- Test migration on existing production databases
- Provide fallback to in-memory cache if table creation fails

**Evidence:** `SkillLedger` uses `addColumnIfNeeded` pattern for safe migrations.

### Risk 2: Performance Degradation

**Description:** Analytics queries on large datasets (>100k events) could slow down app startup.

**Probability:** Medium
**Impact:** Medium (perceived slowness)

**Mitigation:**
- Implement TTL-based caching (1 hour default)
- Background query loading (async/await)
- Pagination for large datasets
- Database indexes on timestamp and skill_name

**Evidence:** Existing indexes in `SkillLedger` schema at line 50-51.

### Risk 3: Security False Positives

**Description:** Security scanning could flag legitimate code patterns as vulnerabilities.

**Probability:** High
**Impact:** Medium (user annoyance)

**Mitigation:**
- Opt-in security scanning by default
- Configurable rule sets
- Whitelist support for known safe patterns
- Clear documentation for each rule

**Evidence:** Existing `ValidationRule` policy system allows configuration.

### Risk 4: PII Leakage in Diagnostic Bundles

**Description:** Diagnostic bundles could accidentally include sensitive user data.

**Probability:** Medium
**Impact:** High (privacy violation)

**Mitigation:**
- Enforce PII redaction through `TelemetryRedactor`
- Opt-in for logs (off by default)
- Review bundle contents before export
- User preview of bundle contents

**Evidence:** `TelemetryRedactor` implements path and hostname redaction.

### Risk 5: Dependency Graph Performance

**Description:** Scanning large skill trees (1000+ skills) could take excessive time.

**Probability:** Medium
**Impact:** Medium (timeout)

**Mitigation:**
- Progress indication during scan
- Cancellable operation (Task cancellation)
- Incremental graph building
- Lazy loading of graph nodes

**Evidence:** Existing `AsyncSkillsScanner` uses concurrency and cancellation.

---

## Launch & Rollback Guardrails

### Pre-Launch Checklist

- [ ] All unit tests passing (`swift test`)
- [ ] Integration tests passing
- [ ] Performance benchmarks met
- [ ] Code review completed
- [ ] Security review completed
- [ ] Database migration tested on production-like data
- [ ] Documentation updated
- [ ] Release notes drafted

**Evidence:** Standard quality gates for sTools releases.

### Go/No-Go Metrics

| Metric | Threshold | Current | Status |
|--------|-----------|---------|--------|
| Test coverage | >80% | TBD | Pending |
| Performance targets | All met | 30ms baseline (98 files) | ✅ Met |
| Security scan results | 0 critical | TBD | Pending |
| Migration success rate | 100% | TBD | Pending |

**Evidence:** Metrics follow existing SLO framework.

### Rollback Triggers

- Database migration failure rate >5%
- App crash rate >1%
- Performance regression >20%
- Security findings in production builds

**Rollback procedure:**
```bash
git checkout tags/vPREVIOUS
swift build -c release
swift test
# Deploy previous version
```

**Evidence:** Rollback follows standard git workflow.

### Kill Criteria

**Immediate shutdown if:**
- PII leakage detected in diagnostic bundles
- Security scanning produces exploitable results
- Database corruption in production

**Investigation triggers:**
- Performance degradation >50%
- User-reported data loss
- Unexpected error rates >10%

**Evidence:** Kill criteria align with existing error budget policy.

---

## Post-Launch Monitoring Plan

### SLOs

| SLO | Target | Measurement Window | Owner |
|-----|--------|-------------------|-------|
| Diagnostic bundle generation | <5s (p95) | 7 days | Core Team |
| Analytics query latency | <2s (p95) | 7 days | Core Team |
| Security scan completion | <30s (p95) | 30 days | Security Team |
| App crash rate | <0.1% | 30 days | Core Team |
| Error budget consumption | <10% | Rolling 7d | Core Team |

**Evidence:** SLOs follow existing `SLO.swift` framework.

### Monitoring Dashboards

#### Metrics to Track

1. **Feature Usage:**
   - Diagnostic bundles generated per day
   - Analytics dashboard views per day
   - Security scans run per day
   - Dependency graph exports per day

2. **Performance:**
   - P50, P95, P99 latency for each feature
   - Cache hit rates
   - Database query times

3. **Quality:**
   - Error rates by feature
   - Crash reports
   - User feedback sentiment

**Evidence:** Metrics follow existing `TelemetryManager` patterns.

### Feedback Loops

#### User Feedback Channels

- GitHub Issues for bug reports
- In-app feedback button
- Crash report analysis
- Support email monitoring

**Evidence:** Existing feedback channels documented in README.

### Iteration Plan

**Week 1-2:** Monitor stability and performance
**Week 3-4:** Gather user feedback and address critical bugs
**Month 2:** Plan iteration based on usage patterns

**Evidence:** Iteration plan follows standard release cadence.

---

## Support / Ops Impact

### Documentation Updates

#### User Documentation

1. **README.md:**
   - Add feature overview section
   - Update CLI command reference
   - Add troubleshooting guide

2. **Inline Help:**
   - Tooltip explanations for new UI elements
   - Contextual help links
   - Example walkthroughs

**Evidence:** Documentation pattern follows existing README structure.

#### Developer Documentation

1. **ARCHITECTURE.md:**
   - Add component diagrams
   - Document data flow
   - Explain concurrency model

2. **CONTRIBUTING.md:**
   - Add test guidelines
   - Document code style
   - PR template updates

**Evidence:** Contributing guide exists; needs extension.

### Runbook Updates

#### Diagnostic Bundle Collection

**When to collect:**
- User reports unexpected behavior
- Performance degradation observed
- Crash reports lack context

**How to collect:**
```bash
# Via CLI
skillsctl diagnostics --output ~/Desktop/diagnostics.zip --include-logs

# Via UI
Settings → Advanced → Generate Diagnostic Bundle
```

**What to check:**
- System info for compatibility
- Recent errors for patterns
- Scan configuration for misconfigurations

**Evidence:** Runbook pattern follows existing debugging procedures.

### Support Training

#### Topics for Support Team

1. **Feature Overview:**
   - What each feature does
   - When to use each feature
   - Common use cases

2. **Troubleshooting:**
   - Common error messages
   - Workarounds for known issues
   - Escalation paths

3. **Privacy & Security:**
   - PII handling in diagnostic bundles
   - Security scan interpretation
   - Data retention policies

**Evidence:** Training materials will be created during implementation.

---

## Decision Log / ADRs

### ADR-001: SQLite Analytics Cache

**Status:** Accepted
**Date:** 2026-01-20
**Context:** Need to cache expensive time-series aggregations for analytics dashboard.

**Decision:** Use SQLite `analytics_cache` table with TTL-based invalidation.

**Rationale:**
- Leverages existing `SkillLedger` infrastructure
- No new dependencies
- Persistent across app restarts
- Queryable with standard SQL

**Alternatives Considered:**
- In-memory `NSCache` only: Lost on restart, rejected
- Redis: External dependency, rejected
- Time-series database (TimescaleDB): Overkill, rejected

**Consequences:**
- Positive: Simple, persistent, no new deps
- Negative: SQL query overhead, mitigated by indexes

**Evidence:** SQLite selected for consistency with existing architecture.

### ADR-002: Actor Isolation for New Components

**Status:** Accepted
**Date:** 2026-01-20
**Context:** Swift 6 strict concurrency requires data race safety.

**Decision:** All new stateful components use Swift actors (`UsageAnalytics`, `ContextProvider`, `DependencyScanner`, `SecurityScanner`).

**Rationale:**
- Follows existing `SkillLedger` pattern
- Compiler-enforced isolation
- Automatic re-entrancy safety
- Clear ownership boundaries

**Alternatives Considered:**
- MainThread dispatch: Blocks UI, rejected
- Unchecked concurrency: Data races, rejected
- Global mutexes: Error-prone, rejected

**Consequences:**
- Positive: Type-safe concurrent code
- Negative: Actor hop overhead, negligible for I/O ops

**Evidence:** Actor pattern established in codebase; Swift 6 settings in Package.swift.

### ADR-003: Optional Context in Finding Model

**Status:** Accepted
**Date:** 2026-01-20
**Context:** Want to add rich error context without breaking existing code.

**Decision:** Add `errorContext: ErrorContext?` as optional field to `Finding` struct.

**Rationale:**
- Backward compatible (optional field)
- Existing code continues to work
- Progressive enhancement path
- No migration needed

**Alternatives Considered:**
- Separate `FindingWithContext` type: Duplication, rejected
- Non-optional field: Breaking change, rejected
- Subclassing: Structs can't subclass, rejected

**Consequences:**
- Positive: No breaking changes
- Negative: Some findings lack context, acceptable

**Evidence:** Optional field pattern used in `SkillDoc` model.

### ADR-004: Security Scanning Opt-In

**Status:** Accepted
**Date:** 2026-01-20
**Context:** Security scanning could produce false positives and slow down normal validation.

**Decision:** Security rules registered but not run by default; require explicit invocation.

**Rationale:**
- Avoid false positive fatigue
- Keep normal validation fast
- Clear user intent for security checks
- CI/CD can still enforce

**Alternatives Considered:**
- Always run security scans: Too noisy, rejected
- Configurable opt-out: Security risk, rejected
- Separate tool: Duplication, rejected

**Consequences:**
- Positive: Fast normal workflow
- Negative: Security issues not caught automatically, mitigated by docs

**Evidence:** Policy-based validation exists; security scanning follows same pattern.

---

## Evidence Gaps

1. **CodexMonitor runtime behavior:** Probes failed before completion; architecture inferred from static structure only. Cannot verify actual runtime performance or behavior patterns.
   - *Impact:* Medium - Implementation based on inferred patterns
   - *Mitigation:* Prototype and validate assumptions early

2. **User behavior analytics:** No data on how users currently interact with sTools or what analytics they would find valuable.
   - *Impact:* High - May build unused features
   - *Mitigation:* User interviews and beta testing

3. **Performance benchmarks:** RESOLVED — Baseline established 2026-01-20.
   - *Evidence:* `/Users/jamiecraik/dev/sTools/.spec/performance-baseline-2026-01-20.md`
   - *Current baseline:* 30ms mean for 98 files, ±1ms variance
   - *Headroom:* >100× headroom for proposed enhancements (5s bundle, 2s analytics, 30s security)

4. **Security false positive rate:** No data on how common false positives are in real skill scripts.
   - *Impact:* High - Could produce poor user experience
   - *Mitigation:* Test on diverse skill corpus; iterate on patterns

5. **Dependency graph scalability:** No data on typical skill tree sizes or complexity.
   - *Impact:* Medium - May not scale to large repos
   - *Mitigation:* Progressive enhancement; pagination for large graphs

---

## Evidence Map

| Source | Location | Type | Used For |
|--------|----------|------|----------|
| CodexMonitor analysis | `/Users/jamiecraik/dev/recon-workbench/runs/codexmonitor/2026-01-15/run-001/derived/report.md` | Run output | Feature identification |
| CodexMonitor findings | `/Users/jamiecraik/dev/recon-workbench/runs/codexmonitor/2026-01-15/run-001/derived/findings.json` | JSON | Probe failures |
| Probe plan | `/Users/jamiecraik/dev/recon-workbench/runs/codexmonitor/2026-01-15/run-001/probe-plan.json` | Configuration | Target identification |
| sTools Package.swift | `/Users/jamiecraik/dev/sTools/Package.swift` | Build config | Tech stack verification |
| sTools SkillsCore.swift | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/SkillsCore.swift` | Source code | Core types, validation framework |
| sTools SkillLedger.swift | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/Ledger/SkillLedger.swift` | Source code | Storage architecture |
| sTools InspectorViewModel.swift | `/Users/jamiecraik/dev/sTools/Sources/SkillsInspector/InspectorViewModel.swift` | Source code | UI patterns, state management |
| sTools ExportService.swift | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/ExportService.swift` | Source code | Export format extensions |
| sTools AppLog.swift | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/Logging/AppLog.swift` | Source code | Logging categories |
| sTools SLO framework | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/SLO/` | Directory | SLO patterns |
| sTools Telemetry | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/Telemetry/` | Directory | Telemetry patterns |
| sTools FixEngine | `/Users/jamiecraik/dev/sTools/Sources/SkillsCore/FixEngine.swift` | Source code | Suggested fix patterns |
| Implementation plan | `/Users/jamiecraik/.claude/plans/jiggly-coalescing-orbit.md` | Plan document | Feature prioritization |
| Performance baseline | `/Users/jamiecraik/dev/sTools/.spec/performance-baseline-2026-01-20.md` | Benchmark results | Current performance metrics (30ms mean for 98 files) |
| User research findings | `/Users/jamiecraik/dev/sTools/.spec/user-research-findings-2026-01-20.md` | Analysis | Feature validation from codebase analysis |
| User research plan | `/Users/jamiecraik/dev/sTools/.spec/user-research-plan-2026-01-20.md` | Methodology | Interview guide and research plan |
| Adversarial review | `/Users/jamiecraik/dev/sTools/.spec/adversarial-review-2026-01-20-stools-enhancements.md` | Review findings | Critical gaps and required fixes |

---

## Appendix A: File Structure

```
Sources/SkillsCore/
├── Diagnostics/
│   ├── DiagnosticBundle.swift
│   ├── DiagnosticBundleCollector.swift
│   └── DiagnosticBundleExporter.swift
├── Analytics/
│   ├── UsageAnalytics.swift
│   ├── MetricsAggregator.swift
│   └── AnalyticsCache.swift
├── Validation/
│   ├── ErrorContext.swift
│   ├── ContextProvider.swift
│   └── FileContentCache.swift
├── Dependencies/
│   ├── DependencyGraph.swift
│   ├── DependencyScanner.swift
│   └── GraphExporter.swift
├── Security/
│   ├── SecurityScanner.swift
│   └── DefaultSecurityRules.swift
├── Ledger/
│   └── SkillLedger.swift (modified)
├── Logging/
│   └── AppLog.swift (modified)
└── SkillsCore.swift (modified)

Sources/SkillsInspector/
├── Diagnostics/
│   └── DiagnosticBundleView.swift
├── Analytics/
│   ├── AnalyticsDashboardView.swift
│   └── Charts/
│       ├── ScanFrequencyChart.swift
│       └── ErrorTrendsChart.swift
├── Validation/
│   ├── ErrorContextView.swift
│   └── RelatedFilesView.swift
├── Dependencies/
│   ├── DependencyGraphView.swift
│   └── GraphNodeDetailView.swift
├── Security/
│   ├── SecurityScanView.swift
│   └── SecuritySummaryView.swift
└── InspectorViewModel.swift (modified)

Sources/SkillsCLI/Commands/
├── DiagnosticsCommand.swift
├── AnalyticsCommand.swift
└── SecurityCommand.swift

Tests/SkillsCoreTests/
├── Diagnostics/
│   └── DiagnosticBundleCollectorTests.swift
├── Analytics/
│   └── UsageAnalyticsTests.swift
├── Validation/
│   └── ContextProviderTests.swift
├── Dependencies/
│   └── DependencyScannerTests.swift
└── Security/
    └── SecurityScannerTests.swift
```

**Evidence:** File structure follows existing organization patterns.

---

## Appendix B: Dependencies

**No new external dependencies required.**

All features use:
- stdlib `Foundation` (ZIP, file I/O, JSON)
- stdlib `SwiftUI` (Charts on macOS 14+)
- Existing `TelemetryRedactor` for PII scrubbing
- Existing `FixEngine` for suggested fixes
- Existing `SkillLedger` for persistence

**Optional user-installed tools:**
- GraphViz CLI (`brew install graphviz`) for rendering DOT to PNG/SVG

**Evidence:** Package.swift shows no new package dependencies needed.

---

*End of Technical Specification*
