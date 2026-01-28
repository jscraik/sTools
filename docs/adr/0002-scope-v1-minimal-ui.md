# ADR 0002: Scope v1 Minimal UI

**Status:** Accepted
**Date:** 2026-01-27
**Decision:** SkillsInspector v1 will include only Validate and Sync-check modes with a minimal UI shell that renders CLI JSON output. All other Swift app modes and advanced UX features are deferred to post-v1.
**Authors:** Jamie Craik

## Context

The existing Swift app has multiple modes (Validate, Sync-check, Stats, Index, Remote, Changelog) and a rich set of UX features. Re-implementing all of this in v1 would significantly delay delivery and increase risk. We need to define a minimal viable v1 scope that preserves CLI parity while enabling future UI enhancements.

## Decision

### v1 In-Scope Features

**Modes:**
- **Validate:** Run scans, view findings, apply fixes (CLI-only)
- **Sync-check:** View drift between Codex and Claude skill trees

**UI Components:**
- Sidebar with mode selection and scan roots management
- Findings list with filters (severity, agent)
- Detail panel showing selected finding
- Toolbar with scan controls (Run Scan, Stop, Export)
- Basic keyboard navigation (Cmd+R, arrow keys)
- Core error states (loading, empty, error, success)

**Explicitly Out-of-Scope (Deferred):**
- Fix command in UI (CLI-only in v1)
- Stats, Index, Remote, and Changelog modes
- Command palette (Cmd+K)
- Diff viewer for fix preview
- Saved filter presets
- Activity feed / timeline view
- Advanced search
- Bulk operations
- Settings modal
- Onboarding flow beyond minimal first-run guidance
- Workspace/project concepts
- Analytics dashboard

### Scope Justification

The v1 goal is **CLI parity with a viewer**, not full feature parity with the Swift app. By deferring advanced UX features, we:

1. Reduce implementation risk
2. Ship a stable CLI-first foundation faster
3. Validate the architecture before adding complexity
4. Allow user feedback to inform post-v1 priorities

## Rationale

1. **Focus on Correctness:** CLI validation is the core value. UI is a viewer.
2. **Learn from Usage:** Real usage patterns will inform which deferred features matter most.
3. **Avoid Over-Engineering:** Building features before understanding need wastes effort.
4. **Incremental Delivery:** A solid v1 foundation enables faster iteration on v1.1, v1.2, etc.

## Alternatives Considered

### Alternative 1: Full Feature Parity in v1
**Description:** Re-implement all Swift app modes and UX features in React-Tauri.

**Pros:**
- No user-facing feature gaps
- Complete replacement from day one

**Cons:**
- Much longer development timeline
- Higher risk of bugs in complex features
- Delayed CLI parity validation

**Rejected because:** CLI parity is the primary success criterion. Full UI parity can wait.

### Alternative 2: Web-Based UI First
**Description:** Build a web UI before desktop Tauri shell.

**Pros:**
- Easier deployment and updates
- Cross-platform from day one

**Cons:**
- Adds web security concerns
- Loses desktop integration benefits
- Different architecture than target state

**Rejected because:** The target is a desktop app. Web-first would require re-architecting later.

## Tradeoffs

### What We Gain
- Faster time to stable CLI release
- Lower bug surface area
- Clearer MVP definition
- Ability to iterate based on real usage

### What We Give Up
- Some users will miss advanced features from Swift app
- Competitive position may appear weaker on feature checklist
- Need to communicate v1 scope clearly to users

## Implementation Notes

- Deferred features are tracked in the UX roadmap (see UX Spec "Deferred UX Enhancements")
- Post-v1 features will be prioritized based on user feedback and metrics
- The architecture (CLI-first) supports adding richer UI later without breaking CLI

## Consequences

### Positive
- Smaller, more focused team can deliver faster
- Easier to verify correctness (smaller test surface)
- Clear upgrade path for post-v1 features

### Negative
- Some users may be disappointed by missing features
- May need to maintain Swift app alongside v1 for power users
- Requires clear communication about v1 scope

## Related Decisions

- See [ADR 0001: CLI-First Architecture](./0001-cli-first-architecture.md) for overall architecture
- See [ADR 0003: UI JSON-Only](./0003-ui-json-only.md) for UI implementation details

## References

- Foundation Spec: `.spec/foundation-2026-01-25-skillsinspector-react-tauri-v1.md` (Scope sections)
- Build Plan: `.spec/build-plan-2026-01-25-skillsinspector-react-tauri-v1.md` (Epic: Minimal Tauri shell)
- UX Spec: `.spec/ux-2026-01-25-skillsinspector-react-tauri-v1.md` (Deferred UX Enhancements)
