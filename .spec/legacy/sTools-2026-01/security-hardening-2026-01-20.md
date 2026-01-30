# Security Hardening Plan: sTools Enhancements

**Date:** 2026-01-20
**Purpose:** Address ERROR-level security findings from adversarial review
**Status:** Implementation guidance for Phase 1 security fixes

---

## Executive Summary

This document provides concrete implementation guidance for addressing all **ERROR-level security findings** identified in the adversarial review (2026-01-20). These fixes must be implemented **before** any feature development begins.

**Critical Issues:** 5 ERROR-level findings requiring immediate attention
- ReDoS vulnerabilities in security patterns
- Missing symlink validation
- No regex pattern validation
- ZIP archive traversal vulnerabilities
- DOT export injection vulnerabilities

**Evidence:** `/Users/jamiecraik/dev/sTools/.spec/adversarial-review-2026-01-20-stools-enhancements.md` lines 42-60

---

## Fix 1: Regex Pattern Validation (ERROR)

### Finding
> No validation for regex pattern compilation — silent failures possible

**Impact:** Malicious or invalid patterns could crash the scanner or cause unexpected behavior.

### Solution: Add PatternValidator Actor

Create centralized regex validation with compilation verification:

```swift
// Sources/SkillsCore/Validation/PatternValidator.swift

import Foundation

/// Validates and compiles regex patterns safely
actor PatternValidator {
    static let shared = PatternValidator()

    private var validCache: [String: NSRegularExpression] = [:]
    private var invalidCache: Set<String> = []

    /// Validates a regex pattern and returns compiled regex or error
    /// - Parameter pattern: The regex pattern string to validate
    /// - Returns: Compiled NSRegularExpression if valid
    /// - Throws: PatternError if compilation fails
    func validate(_ pattern: String) throws -> NSRegularExpression {
        // Check caches first
        if let cached = validCache[pattern] {
            return cached
        }

        if invalidCache.contains(pattern) {
            throw PatternError.invalidPattern(pattern, "Previously invalidated")
        }

        // Attempt compilation
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            validCache[pattern] = regex
            return regex
        } catch {
            invalidCache.insert(pattern)
            throw PatternError.invalidPattern(pattern, error.localizedDescription)
        }
    }

    /// Batch validate multiple patterns
    func validateAll(_ patterns: [String]) throws -> [String: NSRegularExpression] {
        var result: [String: NSRegularExpression] = [:]
        for pattern in patterns {
            result[pattern] = try validate(pattern)
        }
        return result
    }
}

enum PatternError: LocalizedError {
    case invalidPattern(String, String)

    var errorDescription: String? {
        switch self {
        case .invalidPattern(let pattern, let reason):
            return "Invalid regex pattern '\(pattern)': \(reason)"
        }
    }
}
```

### Usage in ValidationRule

```swift
// Example: SecurityScanner pattern loading
actor SecurityScanner {
    func loadRules(from config: SecurityConfig) throws {
        for rule in config.rules {
            // Validate all patterns during loading
            _ = try await PatternValidator.shared.validate(rule.pattern)
        }

        // Only after validation succeeds, store the rules
        self.rules = config.rules
    }
}
```

### Testing

```swift
// Tests/SkillsCoreTests/Validation/PatternValidatorTests.swift

func testValidate_ValidPattern_ReturnsRegex() throws {
    let regex = try await PatternValidator.shared.validate("[a-z]+")
    XCTAssertNotNil(regex)
}

func testValidate_InvalidPattern_ThrowsError() {
    XCTAssertThrowsError(
        try await PatternValidator.shared.validate("[invalid(")
    ) { error in
        XCTAssertTrue(error is PatternError)
    }
}
```

---

## Fix 2: Symlink Validation (ERROR)

### Finding
> Insufficient directory traversal protection — symlinks not validated

**Impact:** Malicious symlinks could escape the intended scan directory.

### Solution: Add PathValidator with Symlink Checking

```swift
// Sources/SkillsCore/Validation/PathValidator.swift

import Foundation

/// Validates file system paths for security constraints
actor PathValidator {
    /// Validates that a path is within allowed boundaries
    /// - Parameters:
    ///   - path: The path to validate
    ///   - allowedRoot: The root directory that is allowed
    /// - Returns: True if path is safe, false otherwise
    func isValid(path: String, within allowedRoot: String) -> Bool {
        let resolvedPath: String
        do {
            // Resolve all symlinks to get the actual path
            resolvedPath = try FileManager.default
                .destinationOfSymbolicLink(atPath: path)
        } catch {
            // Not a symlink, use original path
            resolvedPath = path
        }

        // Normalize paths for comparison
        let normalizedPath = (resolvedPath as NSString).standardizingPath
        let normalizedRoot = (allowedRoot as NSString).standardizingPath

        // Check if the resolved path starts with the allowed root
        return normalizedPath.hasPrefix(normalizedRoot)
    }

    /// Recursively validates a directory tree
    func validateDirectory(_ path: String, within root: String) throws {
        let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: path),
                                                        includingPropertiesForKeys: [.isSymbolicLinkKey])
        guard let enumerator = enumerator else { return }

        for case let url as URL in enumerator {
            // Check if this is a symlink
            let resourceValues = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
            if let isSymlink = resourceValues.isSymbolicLink, isSymlink {
                // Validate the symlink target
                let targetPath = url.path
                guard isValid(path: targetPath, within: root) else {
                    throw PathError.symlinkEscape(url.path)
                }
            }
        }
    }
}

enum PathError: LocalizedError {
    case symlinkEscape(String)

    var errorDescription: String? {
        switch self {
        case .symlinkEscape(let path):
            return "Security violation: Symlink '\(path)' points outside allowed directory"
        }
    }
}
```

### Integration with Scanner

```swift
// In Scanner.swift
func scan(_ path: String) async throws -> ScanResults {
    // Validate all paths before scanning
    try await PathValidator().validateDirectory(path, within: path)

    // Proceed with scan if validation passes
    // ...
}
```

---

## Fix 3: ReDoS Protection (ERROR)

### Finding
> Security regex patterns vulnerable to ReDoS (regex denial-of-service)

**Impact:** Malicious input could cause exponential backtracking, hanging the scanner.

### Solution: Pattern Timeout and Complexity Analysis

```swift
// Sources/SkillsCore/Security/ReDoSProtector.swift

import Foundation

/// Protects against ReDoS by limiting pattern complexity
enum ReDoSProtector {
    /// Maximum allowed nested quantifiers
    static let maxNestedQuantifiers = 3

    /// Maximum allowed pattern length
    static let maxPatternLength = 1000

    /// Analyzes a pattern for ReDoS vulnerability
    /// - Parameter pattern: The regex pattern to analyze
    /// - Returns: True if pattern is safe, false if potentially vulnerable
    static func isSafe(_ pattern: String) -> Bool {
        // Check length
        guard pattern.count <= maxPatternLength else {
            return false
        }

        // Check for nested quantifiers (common ReDoS pattern)
        var nestingLevel = 0
        var inQuantifier = false

        for char in pattern {
            switch char {
            case "(", "[", "(?=":
                nestingLevel += 1
                inQuantifier = false
            case ")", "]":
                nestingLevel -= 1
                inQuantifier = false
            case "*", "+", "{":
                if inQuantifier && nestingLevel > maxNestedQuantifiers {
                    return false // Too many nested quantifiers
                }
                inQuantifier = true
            default:
                inQuantifier = false
            }
        }

        // Check for catastrophic backtracking patterns
        let dangerousPatterns = [
            "(.+)+", "(.*)*", "(.+)*", "(.*)+",
            "([a-z]+)+", "([a-z]+)*", "(\\d+)+", "(\\d+)*"
        ]

        for dangerous in dangerousPatterns {
            if pattern.contains(dangerous) {
                return false
            }
        }

        return true
    }
}
```

### Update PatternValidator

```swift
func validate(_ pattern: String) throws -> NSRegularExpression {
    // Check for ReDoS before compilation
    guard ReDoSProtector.isSafe(pattern) else {
        throw PatternError.potentialReDoS(pattern)
    }

    // Continue with normal validation...
}
```

---

## Fix 4: ZIP Archive Validation (ERROR)

### Finding
> No validation of ZIP archive contents in diagnostic bundles

**Impact:** Malicious ZIP could contain path traversal attacks (zip bomb).

### Solution: Safe ZIP Entry Extraction

```swift
// Sources/SkillsCore/Diagnostics/SafeZipExtractor.swift

import Foundation

/// Safely extracts ZIP archives with path validation
actor SafeZipExtractor {
    /// Maximum total uncompressed size
    static let maxTotalSize: Int64 = 100 * 1024 * 1024 // 100 MB

    /// Maximum size per file
    static let maxFileSize: Int64 = 10 * 1024 * 1024 // 10 MB

    /// Maximum number of entries
    static let maxEntries: Int = 1000

    /// Extracts ZIP with security validation
    /// - Parameters:
    ///   - zipPath: Path to the ZIP file
    ///   - destination: Where to extract (must not exist)
    /// - Throws: SecurityError if validation fails
    func extract(from zipPath: String, to destination: String) throws {
        guard FileManager.default.fileExists(atPath: zipPath) else {
            throw SecurityError.zipNotFound(zipPath)
        }

        var totalSize: Int64 = 0
        var entryCount = 0

        // First pass: validate all entries
        guard let archive = Archive(url: URL(fileURLWithPath: zipPath), accessMode: .read) else {
            throw SecurityError.zipOpenFailed(zipPath)
        }

        for entry in archive {
            entryCount += 1
            guard entryCount <= Self.maxEntries else {
                throw SecurityError.tooManyEntries(entryCount)
            }

            // Check for path traversal
            let entryPath = entry.path
            if entryPath.contains("..") || entryPath.hasPrefix("/") {
                throw SecurityError.pathTraversal(entryPath)
            }

            // Check file size
            let size = entry.uncompressedSize
            totalSize += size
            guard size <= Self.maxFileSize else {
                throw SecurityError.fileTooLarge(entryPath, size)
            }

            guard totalSize <= Self.maxTotalSize else {
                throw SecurityError.totalSizeExceeded(totalSize)
            }
        }

        // Second pass: extract (validation passed)
        _ = try FileManager.default.createDirectory(atPath: destination,
                                                     withIntermediateDirectories: true)

        for entry in archive {
            let destinationURL = URL(fileURLWithPath: destination)
                .appendingPathComponent(entry.path)

            // Ensure destination is within target directory
            let resolvedPath = destinationURL.resolvingSymlinksInPath()
            let resolvedDest = URL(fileURLWithPath: destination).resolvingSymlinksInPath()

            guard resolvedPath.path.hasPrefix(resolvedDest.path) else {
                throw SecurityError.pathTraversal(entry.path)
            }

            // Extract the entry
            _ = try archive.extract(entry, to: destinationURL)
        }
    }
}

enum SecurityError: LocalizedError {
    case zipNotFound(String)
    case zipOpenFailed(String)
    case pathTraversal(String)
    case fileTooLarge(String, Int64)
    case totalSizeExceeded(Int64)
    case tooManyEntries(Int)

    var errorDescription: String? {
        switch self {
        case .zipNotFound(let path):
            return "ZIP file not found: \(path)"
        case .zipOpenFailed(let path):
            return "Failed to open ZIP: \(path)"
        case .pathTraversal(let path):
            return "Path traversal attempt in ZIP entry: \(path)"
        case .fileTooLarge(let path, let size):
            return "File too large in ZIP: \(path) (\(size) bytes)"
        case .totalSizeExceeded(let size):
            return "ZIP total size exceeded: \(size) bytes"
        case .tooManyEntries(let count):
            return "Too many entries in ZIP: \(count)"
        }
    }
}
```

---

## Fix 5: DOT Export Sanitization (ERROR)

### Finding
> Missing input sanitization for dependency graph DOT exports

**Impact:** Malicious skill names or paths could inject DOT commands, leading to code execution.

### Solution: Escape Special Characters

```swift
// Sources/SkillsCore/Dependencies/DOTSanitizer.swift

import Foundation

/// Sanitizes strings for safe DOT format output
enum DOTSanitizer {
    /// Characters that must be escaped in DOT labels
    private static let specialCharacters: Set<Character> = [
        "\"", "\\",
        "{", "}", "<", ">", "|",
        "[", "]", "(", ")"
    ]

    /// Escapes a string for safe use in DOT label
    /// - Parameter input: The string to sanitize
    /// - Returns: HTML-escaped string safe for DOT format
    static func escape(_ input: String) -> String {
        var result = ""
        for char in input {
            switch char {
            case "\"":
                result += "\\\""
            case "\\":
                result += "\\\\"
            case "<":
                result += "&lt;"
            case ">":
                result += "&gt;"
            case "|":
                result += "\\|"
            case "{", "}", "[", "]", "(", ")":
                result += "\\\(char)"
            default:
                result.append(char)
            }
        }
        return result
    }

    /// Validates that a label doesn't contain DOT commands
    /// - Parameter label: The label to validate
    /// - Returns: True if safe, false if potentially malicious
    static func isValidLabel(_ label: String) -> Bool {
        // Reject labels with DOT directives
        let forbidden = ["graph", "digraph", "node", "edge", "strict",
                         "rankdir", "label", "shape", "color", "style"]

        let lowercase = label.lowercased()
        return !forbidden.contains { lowercase.contains($0) }
    }
}
```

### Usage in GraphExporter

```swift
// In DependencyGraphExporter.swift
func exportDOT(graph: DependencyGraph) throws -> String {
    var dot = "digraph dependencies {\n"
    dot += "  rankdir=LR;\n"

    for node in graph.nodes {
        // Validate and escape each node label
        guard DOTSanitizer.isValidLabel(node.label) else {
            throw GraphError.invalidNodeLabel(node.label)
        }

        let escaped = DOTSanitizer.escape(node.label)
        dot += "  \"\(node.id)\" [label=\"\(escaped)\"];\n"
    }

    dot += "}"
    return dot
}
```

---

## WARN-level Fixes (Recommended)

### 1. Salt for PII Hashing

**Finding:** Salt is hardcoded and public

**Fix:** Generate unique salt per installation

```swift
// In TelemetryRedactor.swift
actor TelemetryRedactor {
    private static let salt: String = {
        // Generate salt on first run, persist to keychain
        if let stored = Keychain.shared.get("pii_salt") {
            return stored
        }
        let newSalt = UUID().uuidString
        Keychain.shared.set(newSalt, key: "pii_salt")
        return newSalt
    }()
}
```

### 2. Security Scanning Default

**Finding:** Opt-in scanning creates passive vulnerability window

**Fix:** Change to warning-level by default (opt-out)

```swift
// In SecurityConfig.swift
struct SecurityConfig {
    var scanMode: ScanMode = .warning // Changed from .optIn
}

enum ScanMode {
    case warning     // Run always, warn only (default)
    case error       // Run always, error on findings
    case optOut      // Run unless explicitly disabled
    case optIn       // Only run if explicitly enabled
}
```

### 3. Rate Limiting

**Finding:** No rate limiting on scanning operations

**Fix:** Add per-scan operation limits

```swift
// In Scanner.swift
struct ScanLimits {
    static let maxFiles = 100_000
    static let maxDuration: TimeInterval = 300 // 5 minutes
    static let maxMemoryBytes: Int = 2_000_000_000 // 2 GB
}
```

---

## Implementation Order

**Phase 1: Critical Fixes (Must implement)**

1. **PatternValidator** (Fix 1) — Foundation for all other validation
2. **PathValidator** (Fix 2) — Prevents path traversal
3. **ReDoSProtector** (Fix 3) — Protects against DoS
4. **SafeZipExtractor** (Fix 4) — Secure bundle exports
5. **DOTSanitizer** (Fix 5) — Safe graph exports

**Phase 2: Recommended Fixes (Should implement)**

1. Unique PII salt generation
2. Security scanning mode change (warning by default)
3. Scan rate limiting

---

## Testing Strategy

### Unit Tests Required

- `PatternValidatorTests.swift` — Pattern validation and caching
- `PathValidatorTests.swift` — Symlink detection and validation
- `ReDoSProtectorTests.swift` — Dangerous pattern detection
- `SafeZipExtractorTests.swift` — ZIP bomb prevention
- `DOTSanitizerTests.swift` — Injection prevention

### Integration Tests Required

- Create malicious skill trees with:
  - Symlinks escaping scan directory
  - Invalid regex patterns in config
  - Large nested quantifier patterns
  - ZIP bombs in test fixtures
  - DOT injection in skill names

### Security Testing

```bash
# Run security-specific tests
swift test --filter Security

# Scan with security checks enabled
swift run skillsctl scan --repo . --security-check

# Validate security patterns
swift run skillsctl validate-rules --security
```

---

## Evidence

**Security review findings:**
`/Users/jamiecraik/dev/sTools/.spec/adversarial-review-2026-01-20-stools-enhancements.md` lines 42-60

**OWASP ASVS 4.0 compliance:**
- Input validation (V1) — Fixed by PatternValidator and PathValidator
- Output encoding (V3) — Fixed by DOTSanitizer
- Denial-of-service (V7) — Fixed by ReDoSProtector
- File handling (V4) — Fixed by SafeZipExtractor

---

## Conclusion

All **ERROR-level security findings** have concrete implementation guidance with:

- ✅ Complete code examples
- ✅ Integration points specified
- ✅ Test requirements defined
- ✅ Compliance mapping (OWASP ASVS 4.0)

**Next Steps:**
1. Implement Phase 1 fixes in order
2. Add comprehensive tests for each fix
3. Run security-specific test suite
4. Update tech spec with security patterns
5. Re-submit for security review

---

*Status:* Ready for implementation
*Priority:* CRITICAL — Must complete before feature development
*Owner:* sTools security lead
