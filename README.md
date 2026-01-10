# SkillsTools

SwiftPM package providing:
- **SkillsCore**: scan/validate Codex + Claude skill trees (SKILL.md), sync report, config/baseline.
- **skillsctl** CLI: scan, sync-check, JSON output, config/baseline/ignore.
- **SkillsInspector** SwiftUI macOS app: interactive validate/sync UI.
- **SkillsLintPlugin**: SwiftPM command plugin (`swift package plugin skills-lint`) for repo CI.

## Prerequisites
- macOS 26 SDK (Xcode 26 / Xcode-beta 26)
- Swift 6.2 toolchain

## Build & Test
```bash
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" swift test
```

## CLI quickstart
```bash
# Scan repo-scoped skills (preferred for CI)
skillsctl scan --repo . --format json

# Scan home scopes
skillsctl scan --codex ~/.codex/skills --claude ~/.claude/skills --default-excludes

# Sync-check
skillsctl sync-check --repo .
```
Common flags: `--config <path>`, `--baseline <path>`, `--ignore <path>`, `--plain`, `--log-level <level>`, `--schema-version 1`.

## SwiftPM plugin (CI)
```bash
swift package plugin skills-lint
```
Runs `skillsctl scan --repo . --format json` and surfaces diagnostics.

## SkillsInspector app
Run with SwiftPM:
```bash
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" swift run SkillsInspector
```
Modes: Validate (scan + filters), Sync (compare Codex/Claude trees with diff/copy), Index (placeholder).

## Configuration
- `.skillsctl/config.json` (see `docs/config-schema.json`)
- `.skillsctl/baseline.json` (see `docs/baseline-schema.json`)
- Ignore file (same shape as baseline) supported via `--ignore`.

## DocC
Generate DocC for SkillsCore:
```bash
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer" \
swift package generate-documentation --target SkillsCore \
  --disable-indexing --output-path Docs.doccarchive
```
Open in DocC viewer:
```bash
open Docs.doccarchive
```

## Project structure
- `Sources/SkillsCore`: core scanning/validation/sync engine
- `Sources/skillsctl`: CLI
- `Sources/SkillsInspector`: SwiftUI app
- `Plugins/SkillsLintPlugin`: SwiftPM command plugin
- `docs/`: schemas and usage notes
- `Tests/`: unit tests (core + inspector view models)

## Verification
- Unit tests: `swift test`
- JSON schema references: `docs/schema/findings-schema.json`, `docs/config-schema.json`, `docs/baseline-schema.json`

## License
MIT
