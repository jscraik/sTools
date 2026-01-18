# Project Review Report: sTools

**Owner:** jamiecraik  
**Date:** 2026-01-17  
**Repo:** /Users/jamiecraik/dev/sTools  
**Audience:** team  
**Inputs reviewed:** README | codebase

---

## 1) Executive Summary
- **Recommendation:** Continue
- **Why:** Core functionality is in place and architecture is coherent, but UI polish and config consistency gaps reduce trust; fixes are targeted and low-risk.
- **Biggest missing pieces:** Validate scan does not honor user exclusions/max depth; Search index size stats are inaccurate; Security/Search UI has inactive affordances.
- **Next 14 days:** Fix scan config parity; repair index metadata; address UI placeholders; investigate launch flicker.

---

## 2) Original Vision (Reconstructed)
- **Vision statement (then):** A native macOS inspector to validate and manage AI agent skills across multiple IDE/agent ecosystems.
- **Problem statement:** Users need a trusted way to scan, sync, and verify skill libraries with clear findings and security review.
- **Target users/personas:** Power users and teams managing multi-agent skill repos (Codex/Claude/Copilot).
- **Hypothesis:** Centralizing validation, indexing, sync, and remote installs reduces error rates and improves governance.
- **Success metrics (intended):** Faster validation cycles, fewer invalid skills, higher adoption of security controls.

Sources:
- README, Sources/SkillsInspector, Sources/SkillsCore

---

## 3) Current State (Reality Check)
- **What exists today:** Validate, Stats, Sync, Index, Remote, Security, Search, Settings flows; remote install/preview; local scan/watch; search index and CLI commands.
- **Who is actually using it (if anyone):** Unknown (no telemetry evidence reviewed).
- **Architecture snapshot:** SwiftUI app with SkillsCore library (scanner, indexer, search, sync, validation rules) and skillsctl CLI.
- **Known constraints/debt:** UI placeholders and disabled actions; inconsistent config application across views; search index metadata accuracy; launch-time flicker/blank states when switching views.

---

## 4) Evidence of Usefulness / Demand
- **User feedback:** None available.
- **Behavioral signals:** None available.
- **Competitive landscape:** Adjacent to script-based validators and repo checkers; differentiator is native UI + multi-agent sync + security review.

If evidence is missing:
- Add lightweight usage events for scans, syncs, installs, and search. Establish a minimal dashboard or local metrics log.

---

## 5) Gap Analysis (What’s missing)
### 5.1 Product gaps
- Missing persona clarity: No explicit personas captured in the repo.
- Missing core user stories: Core flows exist but validation config parity across tabs is inconsistent.
- Missing edge cases / failure UX: Search failures are silent; empty index looks like zero results.
- Missing load-state UX: navigation/view switches briefly show blank panes or stale detail content.
- Missing success metrics instrumentation: No visible metrics or goals.

### 5.2 Engineering gaps
- Missing API/schema definitions: N/A (native app + local data).
- Missing data model constraints/indexes: Search index metadata for file size is inaccurate (directory size used).
- Missing security requirements: Security allowlist/blocklist UI exists but is disabled.
- Missing error handling: Search engine init/search errors are silent.
- Missing performance targets: None defined for scan/index/search.

### 5.3 Operational readiness gaps
- Missing dashboards/alerts: None.
- Missing rollback plan: N/A for local app.
- Missing runbook: Minimal operational documentation for support/troubleshooting.
- Missing SLOs/error budget policy: N/A for local app, but latency budgets for scan/search should be defined.

---

## 6) Viability Assessment
- **Problem severity:** Med (validation and governance are real pain points for skill-heavy workflows).
- **Differentiation / wedge:** Multi-agent, single UI with validation + sync + security in one tool.
- **Feasibility:** High (architecture is in place; remaining gaps are mostly UX + config consistency).
- **Go-to-market path (even small):** Target power users and teams with large skill libraries; ship with strong defaults and security posture.
- **Biggest assumptions:** Users want centralized management; local-first is sufficient; security review features provide value.
- **Kill criteria:** Minimal adoption despite improved UX and marketing; validation accuracy fails to meet expectations.

---

## 7) Realignment Plan
### Updated vision statement (now)
Deliver a polished, reliable macOS skill governance tool that applies consistent scanning rules across all views, surfaces clear feedback, and makes security workflows actionable without dead-end UI.

### Updated scope
- In: Scan config parity, search/index correctness, actionable security UI, flicker investigation.
- Out: Major new features or backend services.

### Updated success metrics
| Metric | Target | Window | Source |
|---|---:|---|---|
| Scan config parity bugs | 0 known issues | 14d | QA checklist |
| Search index accuracy | 100% of stats reflect file metadata | 14d | QA checklist |
| Disabled UI actions | 0 user-visible dead ends | 14d | UI audit |

---

## 8) Recommended Plan (Actionable)
### Top priorities (next 14 days)
1. Fix Validate scan to honor excludes, glob excludes, and maxDepth (Owner: you) — Done when: Validate, Sync, Index produce consistent results for the same roots.
2. Correct search index metadata and surface index errors to users — Done when: stats show accurate index size and search failures display actionable messaging.
3. Remove or implement disabled Security/Search actions — Done when: no disabled affordances without clear rationale.
4. Investigate and fix launch flicker (Owner: you) — Done when: app loads without visibility glitches across 3 clean launches.

### Follow-up deliverables
- [ ] Update PRD (or create new one)
- [ ] Update Tech Spec
- [ ] Add ADR(s) for key decisions
- [ ] Add instrumentation + dashboards
- [ ] Complete ORR checklist before production launch

---

## 9) Adversarial Review (Pre-Implementation)
### PM Review
- **Issue:** Success metrics are qualitative and lack numeric targets tied to user outcomes.  
  **Risk:** Progress looks “good” without measurable impact.  
  **Recommendation:** Define at least 2 numeric targets (scan duration, user task completion time, adoption of security review).

### UX Review
- **Issue:** UI shows stale detail panels while primary content is empty or loading.  
  **Risk:** Trust erosion; users think data is inconsistent.  
  **Recommendation:** Clear selection state on data reset and use explicit loading/empty placeholders.

### Frontend/SwiftUI Review
- **Issue:** Async state updates likely race (selection/view model results) leading to blank panes or flicker.  
  **Risk:** Visible flicker and intermittent blank lists.  
  **Recommendation:** Coalesce state updates and set explicit loading flags before replacing data.

### Security Review
- **Issue:** Allowlist/blocklist UI is visible but disabled.  
  **Risk:** Users assume controls exist; false sense of security.  
  **Recommendation:** Implement flow or hide until ready; document any guardrails.

### Reliability/SRE Review
- **Issue:** No clear error surfaces for search/index failures.  
  **Risk:** Silent failures, hard to debug.  
  **Recommendation:** Surface actionable error banners and log details for diagnosis.

### Cost/Scale Review
- **Issue:** Scan/search performance targets are not defined.  
  **Risk:** Performance regressions go unnoticed.  
  **Recommendation:** Set latency/throughput budgets for scan/search and verify in QA.

---

## 9) Appendix
- Key files/docs reviewed:
  - /Users/jamiecraik/dev/sTools/README.md
  - /Users/jamiecraik/dev/sTools/Sources/SkillsInspector/InspectorViewModel.swift
  - /Users/jamiecraik/dev/sTools/Sources/SkillsInspector/Search/SearchView.swift
  - /Users/jamiecraik/dev/sTools/Sources/SkillsInspector/Search/SearchResultRow.swift
  - /Users/jamiecraik/dev/sTools/Sources/SkillsInspector/Security/SecuritySettingsView.swift
  - /Users/jamiecraik/dev/sTools/Sources/SkillsCore/Search/SearchIndex.swift
- Commands run:
  - rg for TODOs and relevant symbols
  - sed for targeted file reads
- Notes:
  - UI flicker requires repro media or steps for targeted diagnosis.
