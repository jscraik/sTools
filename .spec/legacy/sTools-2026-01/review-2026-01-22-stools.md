# sTools Project Review Report (Product-Spec Review Mode)

Date: 2026-01-22
Mode: Review (no implementation)
Focus: Balanced (Product + UX + Engineering + Ops)
Constraint: Simplicity, correctness-first
Output Depth: Balanced

## Executive Summary
sTools is a SwiftPM-based developer toolkit for validating, syncing, and managing AI agent skills across Codex and Claude, delivered as a macOS app, CLI, and SwiftPM plugin with a shared core engine. Evidence: README.md
The repo is feature-rich and well documented, but validation for newer remote/verification flows remains incomplete, and multiple ExecPlans indicate overlapping scopes without a single reconciled product review anchor. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
Given the correctness-first priority and internal-dev-tool audience, the highest leverage work is stabilizing core workflows, tightening validation gates, and simplifying scope around remote lifecycle features. Evidence: README.md

## Reconstructed Vision
Primary user: internal developers/maintainers who need reliable validation, sync, and indexing across AI skill trees and CI environments. Evidence: README.md
Primary job: ensure skill trees are correct, consistent across agents, and safely managed via CLI/UI/plugin entry points. Evidence: docs/usage.md
Success signal: user-visible workflow success (clean scans, correct diffs, verified installs), rather than metrics. Evidence gap: No explicit success metric or activation definition found.

## Current Capabilities (Observed)
Core features include scanning/validation, sync-check, indexing, security scanning, diagnostics bundle export, analytics, caching, and watch mode. Evidence: README.md
The project provides three interfaces: sTools app, skillsctl CLI, and SkillsLintPlugin for CI use. Evidence: README.md
Recent feature additions include quick fixes, stats dashboard, export formats, markdown preview, and multi-editor integration. Evidence: docs/FEATURE_IMPLEMENTATION.md
QA guidance exists for UI snapshot determinism and chart snapshots. Evidence: docs/ui-snapshot-testing.md

## State of Build & Execution Risk
The Trustworthy Skills Inspector plan indicates remote verification features were implemented but validation steps remain open, with prior test failures due to dependency fetch and build path permissions. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
The foundational plan in docs/PLANS.md reports early-phase completion, but it predates remote verification work and may not reflect current risk. Evidence: docs/PLANS.md
This supports the current assessment of “mostly WIP/experimental” with correctness risk concentrated in remote/verification flows. Evidence gap: Interview responses are not stored in repo.

## Key Gaps & Risks (Prioritized)
1) Validation debt in remote/verification flows: tests reported failing or blocked, with validation outstanding. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
2) Scope ambiguity across multiple ExecPlans (remote parity vs trustworthy verification) without a reconciled product review anchor. Evidence: docs/ExecPlan-CodexSkillManager.md
3) Success criteria are behaviorally described but not formalized with activation/guardrail metrics. Evidence gap: No PRD/metrics doc found.
4) Documentation governance gaps (Vale/markdownlint, schema integration) remain open. Evidence: docs/DOCUMENTATION_QUALITY_SUMMARY.md

## Recommendations (Correctness + Simplicity First)
1) Consolidate review scope: reconcile ExecPlans into a single source of truth (update existing plan docs only; avoid new documentation artifacts unless explicitly approved). Evidence: docs/ExecPlan-CodexSkillManager.md
2) Close validation gaps: reproduce and resolve remote/verification test failures; document root cause and fix in the existing ExecPlan. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
3) Define explicit success criteria for core workflows (scan/sync/security/index) with expected outputs and failure handling. Evidence: README.md
4) Implement documentation linting plan and schema linkage per the documentation quality summary. Evidence: docs/DOCUMENTATION_QUALITY_SUMMARY.md

## Recovery Plan (Stop / Continue / Start)
Stop: expanding remote feature scope until remote verification tests are deterministic and green. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
Continue: core validation/sync/CLI/app workflows that already constitute primary product value. Evidence: README.md
Start: a short, focused validation-unblock sprint that resolves dependency fetch and build-path issues affecting tests. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md

### Top Actions (Next 14 Days)
- Action 1: Reproduce and resolve remote verification test failures; document fix in docs/ExecPlan-Trustworthy-Skills-Inspector.md. Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
- Action 2: Define minimal success criteria and acceptance conditions for scan/sync/security workflows. Evidence: README.md
- Action 3: Decide if remote catalog parity remains in scope or is deferred; update docs/ExecPlan-CodexSkillManager.md accordingly. Evidence: docs/ExecPlan-CodexSkillManager.md

### Done When
- Remote verification tests pass (or have documented, time-boxed mitigations). Evidence: docs/ExecPlan-Trustworthy-Skills-Inspector.md
- Success criteria for core workflows are stated with measurable acceptance conditions. Evidence: README.md
- Documentation linting plan is scheduled or implemented as per docs/DOCUMENTATION_QUALITY_SUMMARY.md. Evidence: docs/DOCUMENTATION_QUALITY_SUMMARY.md

## Evidence Gaps
- No explicit PRD/tech spec/roadmap identified as the current source of truth. Evidence gap: Not found in repo.
- No user feedback, analytics, or adoption data available. Evidence gap: Not provided.
- Product-spec skill validation scripts and templates were not found in this repo. Evidence gap: Required paths missing locally.

## Evidence Map
| Evidence | Description | Why used |
| --- | --- | --- |
| README.md | Product definition, features, workflows, verification | Vision + capabilities |
| docs/usage.md | Operational usage and expected outputs | Workflow coverage |
| docs/PLANS.md | Foundational ExecPlan | Core scope + historical completion |
| docs/ExecPlan-Trustworthy-Skills-Inspector.md | Remote verification plan + validation issues | Key risks + recovery |
| docs/ExecPlan-CodexSkillManager.md | Remote parity scope and backlog | Scope ambiguity |
| docs/FEATURE_IMPLEMENTATION.md | Implemented features summary | Feature evidence |
| docs/DOCUMENTATION_QUALITY_SUMMARY.md | Documentation review | Governance gaps |
| docs/ui-snapshot-testing.md | UI snapshot testing guidance | QA posture |
