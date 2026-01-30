schema_version: 1
# sTools Foundation Spec (PRD) — 2026-01-22

## 0) One-Sentence Summary
sTools is a correctness-first developer toolkit that validates, syncs, and secures AI skill trees across Codex and Claude via app, CLI, and SwiftPM plugin. Evidence: README.md

## 1) Problem & Job (JTBD-lite)
### Problem
Maintainers of AI skill trees lack a reliable, unified way to validate SKILL.md content, detect drift between agents, and enforce security scanning across local and CI workflows. Evidence: README.md

### Job-to-be-done
As an internal maintainer, I need to scan, fix, and re-scan skill trees so that validation is accurate, security issues are surfaced, and CI can trust the results. Evidence: docs/usage.md

### Current workaround
Teams run ad-hoc CLI scans or manual file checks, which are inconsistent and error-prone at scale. Evidence gap: No explicit workaround doc found.

### Why now
The project has multiple execution paths and recent remote/verification work; correctness-first stabilization is now required to reduce validation risk. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md

## 2) Target User & Context
Primary user: internal developers/maintainers operating local + CI workflows for skills. Evidence: README.md
Context: macOS-based tooling with SwiftPM for CLI/app/plugin distribution. Evidence: README.md

## 3) Success Criteria
### Primary metric
Workflow success rate: scan → fix → re-scan completes with zero errors (or expected, documented exceptions). Evidence: README.md

### Activation definition
A repo scan completes successfully, produces deterministic output, and can be re-run in CI without manual intervention. Evidence: docs/usage.md

### Guardrails
- False positives/negatives stay below an agreed threshold (tracked via validation tests). Evidence gap: No metrics defined.
- Security scan findings are reported deterministically and do not regress between runs. Evidence: README.md

## 4) Scope (MVP)
### In scope
- Core validation (scan, findings, fixes), sync-check, index generation. Evidence: README.md
- Security scan + diagnostics bundle export. Evidence: README.md
- CLI + SwiftPM plugin + macOS app parity for core workflows. Evidence: README.md

### Out of scope (deferred)
- Remote lifecycle expansion (preview/verify/install/update) beyond already implemented verification features, until validation gates pass. Evidence: docs/ExecPlan-CodexSkillManager.md
- New UI affordances unrelated to the core validation loop. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md

## 5) Primary Journey (Happy Path)
1) User runs repo scan (CLI or app) and receives findings. Evidence: docs/usage.md
2) User applies fixes and re-runs scan. Evidence: docs/FEATURE_IMPLEMENTATION.md
3) Scan completes with zero errors and results are suitable for CI. Evidence: README.md

## 6) User Stories + Acceptance Criteria (Given/When/Then)
### Story 1
As a maintainer, I want to scan a repo so that I can see validation findings. Evidence: docs/usage.md
- Given a repo with skills, when I run `skillsctl scan --repo .`, then I receive findings and an exit code of 0/1/2 based on severity. Evidence: README.md

### Story 2
As a maintainer, I want quick fixes so that I can resolve common issues quickly. Evidence: docs/FEATURE_IMPLEMENTATION.md
- Given a finding with an auto-fix, when I apply the fix, then the file is updated atomically and re-scan reflects the change. Evidence: docs/FEATURE_IMPLEMENTATION.md

### Story 3
As a maintainer, I want sync-check so that Codex and Claude trees are consistent. Evidence: docs/usage.md
- Given two roots, when I run `skillsctl sync-check --repo .`, then I see a diff report for only-in-Codex/Claude and mismatched skills. Evidence: docs/usage.md

### Story 4
As a maintainer, I want security scanning so that secrets and command injection risks are surfaced. Evidence: README.md
- Given a skill with unsafe patterns, when I run `skillsctl security --repo-path .`, then I receive security findings and optional SARIF output. Evidence: README.md

## 7) Positioning Constraints (3 bullets)
- User awareness: maintainers already believe validation is necessary but doubt tooling consistency. Evidence gap: No survey data.
- Alternatives: ad-hoc scripts, manual review, or custom linters. Evidence gap: No alternatives doc.
- V1 emphasis: SAFE and EASY over BIG. Evidence gap: No explicit positioning doc.

## 8) Assumptions
- Core workflows are more valuable than remote lifecycle features for near-term stability. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
- Correctness trumps speed and flexibility for v1. Evidence gap: No explicit decision record found outside the updated plans.

## 9) Risks & Mitigations (Top 3)
- Risk: Chart snapshot tests crash in headless runs. Mitigation: run chart snapshots in Xcode GUI until fixed. Evidence: docs/ui-snapshot-testing.md
- Risk: Remote verification path test instability. Mitigation: prioritize deterministic validation gates. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
- Risk: Scope drift across multiple plans. Mitigation: use docs/PLANS.md as the single source of truth. Evidence: docs/PLANS.md

## Evidence Gaps
- No formal PRD/roadmap existed prior to this document. Evidence gap: Not found in repo.
- No explicit activation or guardrail metrics documented. Evidence gap: Not found in repo.
- No user feedback or adoption analytics available. Evidence gap: Not provided.

## Evidence Map
| Evidence | Description | Why used |
| --- | --- | --- |
| README.md | Product overview, workflows, verification | Vision + scope |
| docs/usage.md | CLI/app usage and expected outputs | User stories + journey |
| docs/FEATURE_IMPLEMENTATION.md | Quick fix feature evidence | Story 2 |
| docs/ExecPlan-Trustworthy-Skills-Inspector.md | Validation gates + risks | Risks + scope |
| docs/ExecPlan-CodexSkillManager.md | Deferred remote scope | Out-of-scope |
| docs/PLANS.md | Single source of truth plan | Mitigation |
| docs/ui-snapshot-testing.md | Snapshot guidance + crash note | Risk 1 |
