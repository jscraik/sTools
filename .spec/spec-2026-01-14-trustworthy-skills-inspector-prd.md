---
schema_version: 1
document: PRD
title: Trustworthy Skills Inspector
owner: sTools PM/Eng Lead
date: 2026-01-14
audience: sTools core team, security reviewers
status: draft
related_tech_spec: .spec/tech-spec-output.md
---

# Trustworthy Skills Inspector — PRD

## 1) Executive Summary
The Skills Inspector will let macOS users install, update, and publish skills with verifiable provenance, explicit consent, and reliable rollback. The product addresses a concrete trust gap: today’s skill distribution relies on unaudited downloads, unclear signer identity, and non-deterministic publishing steps that make forensic audits difficult after incidents.

This release focuses on cryptographic verification, reproducible publishing, cross-IDE registration, and a safety-first UX that makes trust boundaries obvious. The app will work offline, preserve a signed local ledger of changes, and keep telemetry opt-in and privacy-preserving. It is deliberately scoped to macOS and excludes enterprise policy engines and marketplace analytics in v1.

## 2) Goal and Scope
**Goal:** Ship a macOS Skills Inspector that installs/updates/publishes skills with explicit consent, cryptographic verification, reproducible builds, versioned history, and unified compatibility across Codex, Claude Code, and GitHub Copilot.

**In scope:**
- Artifact trust (signatures + hashes) and provenance UI.
- Guarded preview/download UX with consent gate.
- Reproducible publishing pipeline with attestation.
- Compatibility shims for Codex, Claude Code, and GitHub Copilot.
- Versioned store with automatic changelog.
- Offline-safe validation and cache.
- Opt-in minimal telemetry.

**Out of scope (v1):**
- Multi-platform GUI beyond macOS.
- Real-time marketplace analytics.
- Enterprise policy engine.

## 3) Personas
- **Maya (Skill Maintainer):** ships updates weekly; wants deterministic publishing and a verifiable audit trail. Pain points: tool version drift, unclear artifact integrity.
- **Arjun (Security-Conscious Developer):** installs third-party skills; wants fail-closed verification and signer transparency. Pain points: spoofed sources, unclear provenance.
- **Lin (Evaluator):** reviews skills before enabling; wants safe preview without disk writes. Pain points: preview risking side effects.
- **Quinn (Cross-IDE User):** uses multiple IDEs; wants one install to register everywhere. Pain points: repetitive manual setup and drift.
- **Casey (Auditor):** investigates incidents; needs a signed changelog with versions, hashes, and signer IDs. Pain points: missing change history and unverifiable installs.

## 4) Success Metrics (30d targets)
| Metric | Target | Window | Source |
| --- | ---: | --- | --- |
| Verified install success rate | >=95% | 30d | telemetry/logs |
| Blocked unsafe downloads (sig/hash fail) | >=5 captured, 0 executed | 30d | safety log |
| Publish runs using pinned tool | 100% | 30d | pipeline log |
| Cross-IDE registration success | >=90% | 30d | post-install checks |
| Crash-free sessions | >=99.5% | 30d | crash reporter |

## 5) User Stories
### STORY-001 — As a Skill Maintainer, I want publishing to use a pinned, reproducible toolchain so that consumers get identical artifacts.
**Priority:** Must
**Acceptance criteria:**
- [ ] A publish run records the tool version and checksum used.
- [ ] Re-running publish with the same inputs produces a byte-identical artifact.
- [ ] A signed attestation is stored alongside the published artifact.

### STORY-002 — As a Security-Conscious Developer, I want installs to fail closed on signature mismatch so that I never execute untrusted code.
**Priority:** Must
**Acceptance criteria:**
- [ ] An invalid signature prevents install and leaves the previous version intact.
- [ ] The UI shows the failing signer key ID and reason.
- [ ] The failure is recorded in the local ledger with outcome = failed.

### STORY-003 — As an Evaluator, I want to preview SKILL.md without writing to disk until I consent so that browsing is safe.
**Priority:** Must
**Acceptance criteria:**
- [ ] Preview requests do not write the artifact to disk.
- [ ] The UI labels preview as “Safe preview from server.”
- [ ] Download only occurs after an explicit user action.

### STORY-004 — As a Cross-IDE User, I want one install to register the skill for Codex, Claude Code, and Copilot so that I do not repeat steps.
**Priority:** Should
**Acceptance criteria:**
- [ ] A successful install writes to all selected IDE targets; if any target fails, all targets roll back to the last-good version.
- [ ] Each target records its outcome in the ledger, including rollback reasons where applicable.
- [ ] The UI surfaces per-IDE status and rollback summary after install.

### STORY-005 — As an Auditor, I want a signed changelog of installs and updates so that I can trace incidents to exact versions.
**Priority:** Should
**Acceptance criteria:**
- [ ] The changelog includes version, hash, signer ID, and timestamp.
- [ ] The changelog entries are derived from the append-only ledger.
- [ ] Exporting a changelog creates a signed artifact.

### STORY-006 — As a user, I want clear, accessible install states and errors so that I can trust and recover from failures.
**Priority:** Must
**Acceptance criteria:**
- [ ] Each skill row shows a single primary state (verified, unverified, failed, updating) with a human-readable reason on failure.
- [ ] Consent prompts are explicit and reversible (Cancel keeps the current version).
- [ ] All primary actions are keyboard accessible with visible focus states.

## 6) Functional Requirements
### Install/Update
- Require manifest containing checksum (sha256) and signer key ID; verify before unzip; fail closed.
- Support detached Ed25519 signatures; allow multiple trusted keys per skill for rotation; maintain `revokedKeys` list per skill.
- Size/MIME limits and archive structure validation (zip only, no symlinks, no absolute paths, bounded file count).
- Consent gate: API-based preview labeled “Safe preview from server”; integrity only confirmed on download + verify.
- Rollback: keep last-good version and restore automatically on failure; multi-target installs are all-or-nothing with rollback across all targets.
- ACIP scanning: scan remote skill contents before install; quarantine or block on high/critical matches with a review queue.

### Publish
- Replace `bunx ...@latest` with pinned version plus checksum; vendor or lock via SRI; record tool hash.
- Produce deterministic zip with recorded build info (tool version, hash, timestamp).
- Emit signed attestation (in-toto style manifest) stored alongside artifact; dry-run mode supported.

### Versioning and Changelog
- Local append-only ledger (SQLite) of installs/updates/removals with version, hash, signer key, source, IDE targets, and per-target result.
- Auto-generate markdown changelog per skill from ledger entries.
- Changelog exports are signed (Ed25519) with public key included for audit verification.

### Cross-IDE Unification
- Adapter layer writes validated artifacts into:
  - Codex: existing sTools skill layout.
  - Claude Code: `~/.claude/skills/`.
  - GitHub Copilot: `~/.copilot/skills/`.
- Post-install validation hooks per target; ledger records success/failure per IDE.

### UX and Safety
- Provenance badge (verified/unknown/failing) with human-readable signer.
- Explicit “Download and verify” CTA; progress with failure reasons.
- Clear trust prompt: “Trust signer for this skill” with per-skill cache.
- Offline-friendly: cached manifests and last-known-good installs.
- Split-view navigation with a local/remote source toggle to make context explicit.
- Detail side panel for remote skills with inline SKILL.md preview, changelog, and signer provenance before download. Include a “Safe preview from server” label.
- Toolbar actions for bulk operations (Verify All, Update All Verified, Export Changelog).
- Dedicated empty states for: no local skills, no remote results, offline mode, and verification failures.
- Error language is actionable (what failed, how to retry) and never suggests that an unverified skill is safe.
- Bulk actions require confirmation with a per-skill summary and allow per-skill opt-out.
- Rollback prompts show the version being restored and the failure reason.

### UI/UX Decisions
- Default landing view is Remote; remember last selection per user and restore on launch.
- Trust prompt copy uses a two-line format: a short action header plus a single-sentence risk clarification.

### UI/UX Acceptance Checklist (for testing + snapshots)
- Split-view layout renders with local/remote toggle visible and focusable.
- Skill rows show a single primary state with the expected badge and status text.
- Consent prompt appears only on download/verify; cancel keeps current version.
- Error state copy includes: what failed, what can be retried, and a safe fallback action.
- Offline mode shows a dedicated empty state and disables download actions.
- Bulk actions show a summary with per-skill opt-out.
- Rollback dialog includes target version + failure reason.
- Snapshot coverage includes: verified, unverified, failed, updating, offline, and empty states.

### UI Copy Guide (Trust + Error States)
- Trust prompt header: “Trust signer for this skill?”\n  Body: “You are about to install code signed by {SignerName}. Verification happens before install.”\n  Secondary: “Cancel keeps the current version.”
- Verification failure: “Verification failed — signature mismatch.”\n  Guidance: “Download again or choose a different version. The current version remains installed.”
- Unverified state badge tooltip: “Unverified — not safe to run until verified.”
### Telemetry (opt-in)
- Capture counts of verified installs, blocked downloads, publish runs; include app version and anonymized install ID; no PII. Metrics are recorded only when telemetryOptIn is enabled (default off). Retain telemetry locally for 30 days.
- When telemetryOptIn is off, the app performs no network telemetry calls and does not enqueue outbound payloads.
- Telemetry schema is allowlisted (eventName, timestamp, appVersion, anonymizedInstallId, counts) and rejected if extra fields are present.
### Key Distribution
- Fetch a signed keyset from the catalog; update local trust store only when the keyset signature verifies against a pinned root key.

## 7) Non-Functional Requirements
- Security: OWASP Top 10:2025 A8 Software Integrity; fail-closed verification; local trust store at `~/Library/Application Support/SkillsInspector/trust.json`.
- Performance: Verify 10 MB artifact in <300 ms on M3; enforce download size cap (default 50 MB) and file-count cap (2,000 entries).
- Reliability: Atomic install (stage to temp, then move); rollback on verification or adapter failure.
- Accessibility: WCAG 2.2 AA; keyboard navigation for consent, badges, and rollback controls.
- Privacy: Telemetry off by default; when on, redact paths and user identifiers.
- Observability: structured logs include {service:"sTools", action, slug, version, targets, result, duration_ms, verification}.

## 8) Architecture (Conceptual)
- Components: TrustStore (allowlist + revocations), Preview API client (safe preview from server), ArtifactFetcher (guarded download), Verifier (hash + signature), Sanitizer (archive checks), Installer (staging + atomic move), Adapters (Codex/Claude/Copilot), Publisher (pinned tool runner + attestation), Ledger (append-only), UI (SwiftUI shell with provenance badges).

```mermaid
flowchart TD
  UI[Select skill] -->|Preview| FetchMeta[Preview API client (safe preview)]
  FetchMeta --> UI
  UI -->|Download & verify| FetchZip[ArtifactFetcher (full)]
  FetchZip --> Verifier
  Verifier -->|fail| UI
  Verifier -->|pass| Sanitizer[Archive Sanitizer]
  Sanitizer --> Installer
  Installer --> Ledger
  Installer --> Adapters[Adapters: Codex/Claude/Copilot]
  Ledger --> Changelog[Changelog exporter]
```

## 9) Risks and Mitigations
- **Risk:** Signer key compromise allows malicious skills to be verified. **Mitigation:** revocation list updates, multi-signer threshold policy option, alert on key changes.
- **Risk:** Preview API compromised and serves misleading content. **Mitigation:** preview labeled as non-verified; integrity only confirmed on download + verify.
- **Risk:** Cross-IDE adapter drift causes partial installs. **Mitigation:** per-target validation hooks and rollback to last-good.
- **Risk:** Telemetry accidentally includes identifiers. **Mitigation:** strict allowlist schema and local-only storage with opt-in gate.
- **Risk:** Key distribution is tampered or stale, causing incorrect trust decisions. **Mitigation:** signed keyset with root key, keyset expiry, and forced refresh before trust changes.
- **Risk:** Copilot/Claude paths change or are unsupported. **Mitigation:** targets are user-selectable, validation is per-target, and failures do not block other targets.
- **Risk:** Changelog signing keys are lost or rotated without continuity. **Mitigation:** key export and rotation policy, plus optional org-managed signing key.
- **Risk:** Trust prompts create consent fatigue and are dismissed reflexively. **Mitigation:** concise prompts, consistent badge language, and fewer prompts via per-signer trust cache.

## 10) Open Questions
- What is the authoritative source for signer key distribution (signed keyset endpoint or bundled root key), and who operates it?
- What is the verified, supported integration contract for Claude Code and GitHub Copilot skill directories?
- Should changelog signing use a per-device keypair in Keychain or an org-managed key, and how is verification shared with auditors?
- Do we require catalog authentication (API key/OAuth) for preview/manifest access, or keep it public?

## 11) Assumptions
- Skill sources can provide manifest with hash + signature; otherwise a metadata proxy can supply it.
- Users accept opt-in telemetry; default remains off.
- Claude Code and Copilot accept a mirrored skill layout or provide a documented local skill directory.
- The catalog can provide a signed keyset or equivalent trust anchor for signer keys.

## 12) Rollout and Governance
- ADRs: artifact trust model; publishing tool pinning; adapter layout for Claude/Copilot; preview cache policy.
- ORR/Launch: complete ORR and Launch checklists before enabling verification-by-default.

=== Debate Complete ===
Document: PRD
Rounds: 3
Models: PM, UI/UX, Frontend, API, Backend, Security, Reliability/SRE, Cost/Scale
Key refinements:
- Normalized PRD format with personas, STORY-### entries, and acceptance criteria.
- Clarified trust boundaries with explicit preview labeling.
- Added key distribution, Copilot/Claude compatibility, changelog signing, telemetry scope, and API auth questions/risks.
- Added UI/UX state clarity requirements, empty states, and consent fatigue mitigation.

[AGREE]
