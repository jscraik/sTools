schema_version: 1
# Build Plan — sTools Core Validation Loop

## 0) Outcome → opportunities → solution
- Outcome: Deterministic, correctness-first validation workflows across app/CLI/plugin that complete scan → fix → re-scan successfully. Evidence: README.md
- Top user opportunities: reduce validation drift, make fixes safe and fast, and enable CI-friendly outputs. Evidence: README.md
- Chosen solution: prioritize core validation/sync/security paths, tighten validation gates, and keep remote lifecycle deferred until tests are green. Evidence: docs/PLANS.md
- Why alternatives were rejected: expanding remote catalog parity adds risk and complexity before correctness gates are stable. Evidence: docs/ExecPlan-CodexSkillManager.md

## 0.1) Key assumptions & risks (top 3–5)
| Assumption | Impact | Uncertainty | Mitigation |
| --- | --- | --- | --- |
| Core validation value > remote lifecycle value in MVP | High | Medium | Defer remote parity until gates pass | Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md |
| Correctness-first scope is acceptable to users | High | Medium | Document behavior + acceptance criteria in PRD/UX spec | Evidence: .spec/foundation-2026-01-22-stools.md |
| Chart snapshot tests require Xcode GUI | Medium | Medium | Run chart snapshots in Xcode and document headless crash | Evidence: docs/ui-snapshot-testing.md |
| CLI/app/plugin parity can be maintained without new deps | Medium | Low | Reuse existing SkillsCore + tests | Evidence: README.md |

## 1) Epics (sequenced)
Epic 1: Validation gates & stability (core scan/sync/security). Evidence: docs/PLANS.md
Epic 2: UX loop completeness (scan → fix → re-scan) + documentation clarity. Evidence: docs/FEATURE_IMPLEMENTATION.md
Epic 3: Release readiness (CI-friendly outputs, snapshot guidance, and smoke commands). Evidence: docs/ui-snapshot-testing.md

## 2) Stories per epic (each w/ AC)
- Epic 1 Story: Ensure scan/sync/security paths are deterministic and pass tests. Evidence: README.md
  - Acceptance criteria: Given a repo with skills, when `swift test` and CLI scans run, then outputs are stable and exit codes are correct. Evidence: README.md
  - Telemetry/events: Record scan duration, findings count, and cache hit rate in analytics. Evidence: README.md
  - Tests: `swift test` full; targeted tests for sync/security when available. Evidence: README.md

- Epic 1 Story: Document and gate chart snapshot instability. Evidence: docs/ui-snapshot-testing.md
  - Acceptance criteria: Given `ALLOW_CHARTS_SNAPSHOT=1` in headless runs, when the test crashes, then the doc directs Xcode GUI usage and the limitation is recorded. Evidence: docs/ui-snapshot-testing.md
  - Telemetry/events: None (documentation-only). Evidence: docs/ui-snapshot-testing.md
  - Tests: Xcode GUI snapshot run produces a chart hash (manual evidence). Evidence gap: No automated headless pass.

- Epic 2 Story: Fix loop usability (auto-fix preview, confirmation, re-scan guidance). Evidence: docs/FEATURE_IMPLEMENTATION.md
  - Acceptance criteria: Given an auto-fix, when user applies it, then preview/confirm occurs and re-scan reflects fewer errors. Evidence: docs/FEATURE_IMPLEMENTATION.md
  - Telemetry/events: Capture fix applied event and post-fix error count. Evidence gap: Telemetry fields not documented.
  - Tests: Unit tests for FixEngine and view-model flow; snapshot tests for fix UI. Evidence: docs/FEATURE_IMPLEMENTATION.md

- Epic 2 Story: Sync-view conflict clarity (diff buckets + action warnings). Evidence: docs/usage.md
  - Acceptance criteria: Given Codex/Claude drift, when sync-check runs, then only-in-Codex/Claude and mismatched are visible and destructive actions are confirmed. Evidence: docs/usage.md
  - Telemetry/events: Sync diff counts and action confirmations. Evidence gap: Telemetry fields not documented.
  - Tests: SyncViewModel tests covering diff buckets and excludes. Evidence: docs/usage.md

- Epic 3 Story: CI smoke commands and documented outputs. Evidence: README.md
  - Acceptance criteria: Given CLI smoke commands, when run in CI, then outputs match expected formats and exit codes. Evidence: README.md
  - Telemetry/events: None (CI logs). Evidence: README.md
  - Tests: CLI command help and scan command integration checks. Evidence: README.md

## 2.1) TDD Guidance (non-negotiable for non-trivial work)
Write tests before implementation for any story with non-trivial logic; failing tests block completion. Evidence: docs/ui-snapshot-testing.md

## 2.2) Component Registry Guidance
Before new UI, check for an existing component registry or design system; if missing, document the absence and justify any custom component additions. Evidence gap: No component registry doc found.

## 3) Data + contracts (lightweight)
- Entities: Skill, Finding, Rule, Agent, Root, Scan, Report. Evidence: README.md
- Key fields: ruleID, severity, agent, fileURL, message, line/column, exitCode. Evidence: README.md
- API/routes (if any): CLI commands and JSON output schemas for scan/security. Evidence: docs/usage.md
- Permissions/auth: local file access only; no auth expected for MVP. Evidence: README.md

## 4) Test strategy
- Unit: Validate SkillsCore rules, FixEngine, sync logic, security rules. Evidence: docs/PLANS.md
- Integration: CLI end-to-end scan/sync outputs and export formats. Evidence: README.md
- E2E: Scan → fix → re-scan flow in app or CLI. Evidence: docs/FEATURE_IMPLEMENTATION.md
- Failure-mode tests: invalid roots, permission errors, security rule misses, cache corruption. Evidence: docs/usage.md

## TDD Workflow (for non-trivial stories)
Follow write-fail-pass-refactor; do not merge with failing tests. Evidence: docs/ui-snapshot-testing.md

## 5) Release & measurement plan
- Feature flags: none required for MVP; remote lifecycle remains deferred. Evidence: docs/ExecPlan-CodexSkillManager.md
- Rollout: local dev + CI smoke first; Xcode GUI for chart snapshots until headless crash resolved. Evidence: docs/ui-snapshot-testing.md
- Monitoring: analytics for scan duration, findings count, and cache hit rate. Evidence: README.md
- Measurement window + owner: 2 weeks post-PRD approval, owner = sTools maintainers. Evidence gap: No owner doc found.

## Evidence Gaps
- Component registry/design system reference not found. Evidence gap: No registry doc found.
- Telemetry field schema for fix/sync events not documented. Evidence gap: No telemetry spec found.
- Activation/guardrail metrics not specified. Evidence gap: Not found in repo.

## Evidence Map
| Evidence | Description | Why used |
| --- | --- | --- |
| README.md | Features, CLI commands, exit codes | Outcome, scope, entities |
| docs/PLANS.md | Reconciled scope and gates | Epics + assumptions |
| docs/ExecPlan-CodexSkillManager.md | Deferred remote scope | Alternatives rejected |
| docs/ExecPlan-Trustworthy-Skills-Inspector.md | Validation gates + risks | Assumptions/risks |
| docs/FEATURE_IMPLEMENTATION.md | Fix loop evidence | UX story AC |
| docs/usage.md | Sync + CLI behaviors | AC + test strategy |
| docs/ui-snapshot-testing.md | Snapshot guidance | Risks + TDD guidance |
| .spec/foundation-2026-01-22-stools.md | PRD foundations | Assumptions |
