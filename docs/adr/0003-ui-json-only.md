# ADR 0003: UI JSON-Only Implementation

**Status:** Accepted
**Date:** 2026-01-27
**Decision:** The Tauri UI will only render CLI JSON output and will never implement validation logic directly. All scan/sync-check operations invoke the bundled CLI binary and display its results.
**Authors:** Jamie Craik

## Context

The Tauri UI needs to display validation findings from the skillsctl CLI. There are two possible approaches:
1. **JSON-Only:** UI calls CLI, captures JSON output, and renders it
2. **Direct Integration:** UI imports CLI modules and runs validation in-process

## Decision

**UI JSON-Only Implementation:**
- The UI shell is a pure viewer of CLI JSON output
- All scan/sync-check operations invoke the bundled `skillsctl` binary via Tauri IPC
- UI never directly calls validation functions or file scanners
- CLI outputs are cached in the app data directory for "Open JSON" functionality
- Fix actions in the UI are implemented as CLI command display (not direct file writes)

### Implementation Details

```typescript
// UI invokes CLI via IPC
const scanResult = await invoke('run_scan', {
  args: ['--repo', repoPath, '--format', 'json', '--schema-version', '1']
});

// Result contains CLI stdout, stderr, and exit code
// UI renders the parsed JSON findings
```

### Security Boundaries

- UI can only execute CLI commands explicitly allowlisted in Tauri config
- File access is restricted to app data directory and user-selected repo roots
- No direct file reads from repo contents in UI process
- Path validation happens in CLI before any file operations

## Rationale

1. **Trust Boundary:** Repo contents are untrusted input. Validation should happen in a controlled CLI process.
2. **Consistency:** UI and CLI always show identical results because they use the same source.
3. **Simplicity:** No need to synchronize validation logic between two codebases.
4. **CLI Primacy:** The CLI is the stable interface for CI/CD. UI is optional.

## Alternatives Considered

### Alternative 1: Shared TypeScript Module
**Description:** Extract validation logic into a shared module that both CLI and UI import directly.

**Pros:**
- No subprocess overhead
- UI could implement "live" validation

**Cons:**
- Adds complexity to module structure
- Risk of UI creating divergent validation paths
- Harder to enforce CLI-only testing discipline
- Subprocess spawning is actually fast enough for this use case

**Rejected because:** CLI-first architecture (ADR 0001) requires CLI as the single source of truth. Shared modules would create dual paths.

### Alternative 2: Rust Core with FFI
**Description:** Implement validation in Rust, expose to both CLI (via binary) and UI (via FFI).

**Pros:**
- Single native codebase
- Performance

**Cons:**
- FFI complexity for UI
- Team's primary stack is TypeScript
- Adds learning curve and build complexity
- Still requires careful parity testing

**Rejected because:** TypeScript/Node.js is the established stack. Rust adds complexity without clear benefit for v1.

## Tradeoffs

### What We Gain
- Absolute guarantee of CLI/UI consistency (they use the same binary)
- Clear security boundary (CLI process vs UI process)
- Simpler mental model for developers
- Easier rollback (can disable UI without affecting CLI)

### What We Give Up
- "Instant" validation feedback in UI (must wait for CLI subprocess)
- Ability to implement UI-specific validation logic
- Some performance optimization (subprocess overhead)

### Performance Consideration
- Subprocess spawning overhead is acceptable for scan operations (which are I/O bound anyway)
- CLI execution time dominates; subprocess overhead is negligible
- UI shows loading states during CLI execution

## Implementation Notes

### Tauri IPC Commands (v1)
- `run_scan(args)`: Execute bundled skillsctl scan, return stdout/stderr/exit
- `run_sync_check(args)`: Execute bundled skillsctl sync-check
- `get_scan_history()`: Read from SQLite run history
- `open_cached_json(path_id)`: Read cached JSON output from app data dir

### Cache Policy
- JSON outputs are cached in app data directory
- Cache key: hash of command arguments + repo state
- Retention: 30 days (aligned with run history retention)
- "Open JSON" action opens cached file in default editor

### Error Handling
- CLI exit codes map to UI error states (0=success, 1=errors, 2=fatal)
- Stderr is captured and displayed in error banner
- UI never suppresses CLI errors; it reflects them faithfully

## Consequences

### Positive
- No risk of UI showing different results than CLI
- Security audits can focus on CLI code
- UI bugs cannot affect validation correctness
- Clear ownership: CLI team owns correctness, UI team owns presentation

### Negative
- UI cannot optimize long-running scans without CLI changes
- Adding UI-specific validation requires changing CLI first
- All validation actions go through subprocess (minor overhead)

### Migration Path
If future requirements demand in-process validation:
1. Add validation module to CLI as first step
2. Update CLI to use shared module (maintaining compatibility)
3. Only then allow UI to import the same module
4. Maintain subprocess mode as fallback for testing

## Related Decisions

- See [ADR 0001: CLI-First Architecture](./0001-cli-first-architecture.md) for overall architecture
- See [ADR 0002: Scope v1 Minimal UI](./0002-scope-v1-minimal-ui.md) for what features are included

## References

- Tech Spec: `.spec/tech-spec-2026-01-26-skillsinspector-react-tauri-v1.md` (Tauri IPC + Security Boundaries)
- UX Spec: `.spec/ux-2026-01-25-skillsinspector-react-tauri-v1.md` (Affordances section)
- CLI Spec: `.spec/cli-spec-2026-01-25-skillsinspector-react-tauri-v1.md` (Output rules)
