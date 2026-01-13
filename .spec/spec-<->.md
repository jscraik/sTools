# Trustworthy Skills Inspector — PRD + Technical Spec
Owner: sTools PM/Eng Lead  
Date: 2026-01-12  
Audience: sTools core team, security reviewers

## 1) Goal and Scope
- Goal: Ship a macOS Skills Inspector that installs/updates/publishes skills with explicit consent, cryptographic verification, reproducible builds, versioned history, and unified compatibility across Codex, Claude Code, and GitHub Copilot.
- In scope: artifact trust (signatures + hashes), guarded preview/download UX, reproducible publishing pipeline, compatibility shims for the three IDEs, versioned store with automatic changelog, offline-safe validation, opt-in minimal telemetry.
- Out of scope (v1): multi-platform GUI beyond macOS; real-time marketplace analytics; enterprise policy engine.

## 2) Users and Stories
- Skill Maintainer — “As a maintainer, I want publishing to use a pinned, reproducible toolchain so consumers get identical artifacts.”
- Security-Conscious Developer — “As a developer, I want installs to fail closed on signature mismatch and show provenance so I can trust what I run.”
- Evaluator — “As an evaluator, I want to preview SKILL.md without writing to disk until I consent, so browsing is safe.”
- Cross-IDE User — “As a user, I want one install to register the skill for Codex, Claude Code, and Copilot so I don’t repeat steps.”
- Auditor — “As an auditor, I need a signed changelog of installs/updates with versions and hashes so I can trace incidents.”

## 3) Success Metrics (30d targets)
| Metric | Target | Window | Source |
| --- | ---: | --- | --- |
| Verified install success rate | >=95% | 30d | telemetry/logs |
| Blocked unsafe downloads (sig/hash fail) | >=5 captured, 0 executed | 30d | safety log |
| Publish runs using pinned tool | 100% | 30d | pipeline log |
| Cross-IDE registration success | >=90% | 30d | post-install checks |
| Crash-free sessions | >=99.5% | 30d | crash reporter |

## 4) Functional Requirements
### Install/Update
- Require manifest containing checksum (sha256) and signer key ID; verify before unzip; fail closed.
- Support detached Ed25519 signatures; allow multiple trusted keys per skill for rotation; maintain `revokedKeys` list per skill.
- Size/MIME limits and archive structure validation (no symlinks, no absolute paths, bounded file count).
- Consent gate: API-based preview labeled “Safe preview from server”; integrity only confirmed on download+verify.
- Rollback: keep last-good version and restore automatically on failure.

### Publish
- Replace `bunx ...@latest` with pinned version plus checksum; vendor or lock via SRI; record tool hash.
- Produce deterministic zip with recorded build info (tool version, hash, timestamp).
- Emit signed attestation (in-toto style manifest) stored alongside artifact; dry-run mode supported.

### Versioning and Changelog
- Local append-only ledger (SQLite) of installs/updates/removals with version, hash, signer key, source, IDE targets, and per-target result.
- Auto-generate markdown changelog per skill from ledger entries.

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
- Detail side-panel for remote skills with inline SKILL.md preview, changelog, and signer provenance before download. Include a “Safe preview from server” label.
- Toolbar actions for bulk operations (Verify All, Update All Verified, Export Changelog).

### Telemetry (opt-in)
- Capture counts of verified installs, blocked downloads, publish runs; include app version and anonymized install ID; no PII. Metrics are recorded only when telemetryOptIn is enabled (default off). Retain telemetry locally for 30 days.

## 5) Non-Functional Requirements
- Security: OWASP Top 10:2025 A8 Software Integrity; fail-closed verification; local trust store at `~/Library/Application Support/SkillsInspector/trust.json`.
- Performance: Verify 10 MB artifact in <300 ms on M3; enforce download size cap (default 50 MB) and file-count cap (e.g., 2,000 entries).
- Reliability: Atomic install (stage to temp, then move); rollback on verification or adapter failure.
- Accessibility: WCAG 2.2 AA; keyboard navigation for consent, badges, and rollback controls.
- Privacy: Telemetry off by default; when on, redact paths and user identifiers.

## 6) Architecture
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

## 7) Data Contracts
- Manifest fields: name, version, sha256, size, signature, signerKeyId, trustedSigners[], revokedKeys[], builtWith {tool, version, hash}, targets [codex|claude|copilot], minAppVersion.
- Ledger schema (SQLite): events(id, ts, action, skill_id, version, hash, signer_key_id, source, result, targets, per_target_results, notes).
- Trust store: `~/Library/Application Support/SkillsInspector/trust.json` (allowlisted key IDs + public keys + revocations).

## 8) Edge Cases and Mitigations
- Zip bombs/oversized archives: reject if size/file-count exceeds caps.
- MITM: enforce HTTPS + signature verification; optional CA pinning toggle.
- Key rotation: accept multiple trustedSigners per skill; TrustStore manages revocations.
- Adapter drift: per-target validation with explicit failure surfacing and rollback.
- Cache poisoning: validate cached preview against manifest hash; expire by ETag/time.

## 9) Delivery Plan (next 14 days)
1. Trust foundations: manifest schema, TrustStore, verifier, sanitizer, policy config, tests for tampered/oversized archives.
2. Consentful preview: API-based safe preview labeling; “Download and verify” gate; size/MIME limits; UX wiring.
3. Pinned publishing: vendor/lock CLI with checksum; deterministic zip; attestation output. Pin `clawdhub@0.1.0` with integrity `sha512-LZ0mRf61F5SjgprrMwgyLRqMOKxC5sQZYF1tZGgZCawiaVfb79A8cp0Fl32/JNRqiRI7TB0/EuPJPMJ4evmK0g==`.
4. Ledger + changelog: append-only log; markdown generator; rollback support.
5. Remote detail caching + preview panel: cache SKILL.md/changelog metadata to avoid repeated downloads; surface provenance badges in list + detail; cache TTL/eviction policy (e.g., 7 days or 50MB).
6. Adapters MVP: write to Codex/`~/.claude/skills/`/`~/.copilot/skills/`; add validation stubs and ledger recording.
7. Telemetry stub + privacy notice; feature flag to disable.

## 10) Testing and Validation
- Unit: hash/signature verification, archive sanitization, manifest parsing, TrustStore allow/deny, ledger writes.
- Integration: end-to-end install (good/bad signatures), rollback path, publish producing deterministic hash, per-IDE adapter status.
- UX: snapshot coverage for provenance badges and consent dialogs; accessibility labels present.
- Security: Semgrep/AST checks for unsafe file operations; zip-bomb fixture test.
- Performance: verify latency <300 ms for 10 MB; download concurrency caps.

## 11) Open Questions
- None currently (signer model, trust store location, and adapter paths confirmed).

## 12) Assumptions
- Skill sources can provide manifest with hash + signature; otherwise a metadata proxy can supply it.
- Users accept opt-in telemetry; default remains off.
- Claude Code and Copilot accept the mirrored skill layout under their respective directories.

## 13) Rollout and Governance
- Feature flags: `skillVerification`, `pinnedPublishing`, `crossIDEAdapters`, `telemetryOptIn`, `bulkActions`.
- ADRs: artifact trust model; publishing tool pinning; adapter layout for Claude/Copilot; preview cache policy.
- ORR/Launch: complete ORR and Launch checklists before enabling verification-by-default.

## 14) Backend Design Alignment (Implementation Notes)
- Architecture pattern: Hexagonal (domain core + ports/adapters), to keep verification and policy separate from UI/CLI and network transports.
- Domain model invariants: installs are idempotent by (slug, version, archive hash, targets); strict mode requires manifest + signature + allowlisted key; rollback restores last-good.
- Ports/adapters:
  - RemoteCatalogPort: fetchLatest/search/fetchManifest/download (Clawdhub HTTP).
  - VerificationPort: verify(archive, manifest, policy, trustStore) -> outcome.
  - InstallerPort: install(archive, targets) -> per-target status + hashes.
  - LedgerPort: append/query.
  - PublishPort: build+attest using pinned tool.
- CLI contract (skillsctl): add preview/verify/install/publish subcommands with JSON errors and explicit exit codes; align output to existing schema validation.
- Reliability: timeouts (5s connect/30s body), retries with jitter for GETs only, circuit breaker on remote 5xx, staging + atomic move, rollback on partial target failures.
- Observability: structured logs {service:"sTools", action, slug, version, targets, result, duration_ms, verification} and opt-in metrics (verified installs, blocked downloads, publish runs).
- Performance caps: archive <= 50MB, extracted <= 50MB, files <= 2000, concurrent downloads <= 2. Preview cache capped with TTL/size limits.
- UI alignment: adopt split-view navigation and detail preview patterns from CodexSkillManager; add a bulk action toolbar and inline provenance badges.

=== Debate Complete ===
Document: PRD + Technical Specification
Rounds: 2
Models: PM, Security, Reliability, Cost/Scale
Key refinements:
- Replaced HEAD/Range preview with API-based “Safe preview from server” and clarified integrity boundary.
- Updated ledger schema to include signer_key_id and per-target results.
- Added telemetry opt-in + retention guidance and cache TTL/size limits.

[AGREE]
