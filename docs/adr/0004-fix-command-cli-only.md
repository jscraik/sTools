# ADR 0004: Fix Command - CLI-Only in v1

**Status:** Accepted
**Date:** 2026-01-27
**Decision:** The fix command will remain CLI-only in v1. The Tauri UI will display fix suggestions and provide the CLI command to run, but will not execute fixes directly.
**Authors:** Jamie Craik

## Context

The existing Swift app implements the fix command directly in the UI, allowing users to apply fixes with a single click. For the React-Tauri v1 implementation, we need to decide whether to:

1. **UI Fix Integration:** Implement fix command execution directly in the Tauri UI
2. **CLI-Only:** Require users to run fix commands via the CLI, with the UI only displaying suggestions

## Decision

**Fix Command - CLI-Only in v1:**
- The UI will display fix suggestions alongside findings
- The UI will provide the exact CLI command to run for each fix
- Users must execute fixes via the terminal using the displayed command
- Fix execution happens only through the CLI, ensuring auditability
- Post-v1: Consider in-app fix execution with user confirmation

### Implementation Details

```typescript
// UI displays fix command, does not execute it
const FixDisplay = ({ finding }: { finding: Finding }) => (
  <div className="fix-suggestion">
    <p>Fix: {finding.fix?.suggestion}</p>
    <code>
      skillsctl fix --rule {finding.ruleID} --file {finding.file}
    </code>
    <CopyButton text={`skillsctl fix --rule ${finding.ruleID} --file ${finding.file}`} />
  </div>
);
```

### Security Boundaries

- UI never writes directly to user files
- Fix execution is always explicit (user types command in terminal)
- Fix commands are visible in shell history for audit
- No risk of UI bugs causing unintended file modifications

## Rationale

1. **Trust Boundary:** File modifications are high-risk operations. Explicit terminal commands make intent clear.
2. **Audit Trail:** CLI execution leaves shell history. In-app fixes would require additional logging.
3. **Liability:** Accidental mass-fixes in UI could damage repos. Terminal execution forces review.
4. **Simplicity:** v1 focus is on validation and display. Fix execution is edge-case workflow.

## Alternatives Considered

### Alternative 1: In-App Fix Execution with Confirmation
**Description:** UI executes fix commands after user confirms via modal dialog.

**Pros:**
- More convenient for users (no terminal needed)
- Consistent with Swift app UX

**Cons:**
- Requires careful handling of file permissions
- Need to implement undo/rollback for safety
- Adds significant complexity to v1 scope
- Risk of users clicking through confirmations without reading

**Rejected because:** v1 scope is validation + display. Fix execution is an advanced feature that can wait.

### Alternative 2: Fix Preview + Diff Viewer
**Description:** Show before/after diff in UI before applying fix.

**Pros:**
- Users can see exactly what will change
- Safer than blind fix execution

**Cons:**
- Requires implementing diff viewer (deferred to post-v1)
- Still has file write complexity
- Larger implementation effort

**Rejected because:** Diff viewer is explicitly deferred in ADR 0002. Fix command should follow same pattern.

### Alternative 3: Background Fix Service
**Description:** Run fix commands as background job, notify when complete.

**Pros:**
- Non-blocking UX
- Can batch multiple fixes

**Cons:**
- Hardest to implement (job queue, notifications)
- Opaque execution - user can't see what's happening
- Difficult to debug when things go wrong

**Rejected because:** Most complex option with unclear benefit for v1.

## Tradeoffs

### What We Gain
- **Simplicity:** No file write complexity in UI
- **Safety:** Users must explicitly run each fix command
- **Auditability:** Shell history records all fix operations
- **Focus:** v1 remains focused on validation, not modification

### What We Give Up
- **Convenience:** Users must switch to terminal to apply fixes
- **Parity:** Swift app had in-app fixes, v1 does not
- **Speed:** Multi-fix workflows are slower (copy/paste vs click-through)

### Risk Mitigation
- Provide "Copy Command" button for easy fix application
- Display fix suggestions clearly in findings detail panel
- Document CLI fix workflow in user guide
- Track fix usage metrics to inform post-v1 priorities

## Implementation Notes

### v1 Fix Display
- Findings detail panel shows fix suggestion text
- Read-only code block with exact CLI command
- Copy-to-clipboard button for command
- Link to CLI documentation for fix usage

### Post-v1 Enhancement Path
1. **v1.1:** Add "Open in Terminal" action that pre-fills fix command
2. **v1.2:** Implement in-app fix execution with confirmation modal
3. **v1.3:** Add batch fix execution with selective apply
4. **v2.0:** Full undo/rollback support

### CLI Fix Command (v1)
```bash
# Apply single fix
skillsctl fix --rule codex-ts-001 --file src/components/Button.tsx

# Apply all fixes in repo
skillsctl fix --repo . --apply-all

# Dry-run (show what would change)
skillsctl fix --rule codex-ts-001 --file src/components/Button.tsx --dry-run
```

## Consequences

### Positive
- No risk of UI bugs causing file corruption
- Clear audit trail via shell history
- Simpler v1 implementation (less code to maintain)
- Users must review fix before applying (copy = read)

### Negative
- Less convenient than one-click fix in Swift app
- May discourage fix usage for minor issues
- Requires terminal access (expected for CLI tool)

## Related Decisions

- See [ADR 0002: Scope v1 Minimal UI](./0002-scope-v1-minimal-ui.md) for overall v1 scope
- See [ADR 0003: UI JSON-Only](./0003-ui-json-only.md) for security boundaries

## References

- CLI Spec: `.spec/cli-spec-2026-01-25-skillsinspector-react-tauri-v1.md` (Fix command)
- UX Spec: `.spec/ux-2026-01-25-skillsinspector-react-tauri-v1.md` (Fix affordances)
- Build Plan: `.spec/build-plan-2026-01-25-skillsinspector-react-tauri-v1.md` (Fix implementation notes)
