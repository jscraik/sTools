# SkillsInspector v1: A Project Guide for Jamie

## The Big Picture

**SkillsInspector** is a codebase validation tool that scans your repositories for AI assistant patterns (Codex skills, Claude prompts, etc.) and reports inconsistencies, missing files, and structural problems.

Think of it like a linter, but for AI assistant code patterns instead of JavaScript style issues.

### The Problem It Solves

When you're working with AI assistants that use skills/prompts (Codex, Claude, Copilot), maintaining consistency across repositories is hard:

- Did you update all prompt files after that API change?
- Are skill definitions matching between assistants?
- Is there drift between what Codex expects and what Claude provides?

SkillsInspector scans your codebase and answers these questions automatically.

---

## Technical Architecture

### CLI-First Design (The "One Source of Truth" Principle)

The most important architectural decision is that **the CLI is the engine, the UI is just a viewer**.

```
┌─────────────────────────────────────────────────────────────┐
│                     User Workflow                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  CLI Mode:           skillsctl scan --repo . --format json   │
│  ─────────►          ┌─────────────────────────────────┐    │
│                      │  Scanner Logic (TypeScript)      │    │
│                      │  ┌─────────────────────────────┐ │    │
│                      │  │  • File walking             │ │    │
│                      │  │  • Pattern matching         │ │    │
│                      │  │  • Validation rules         │ │    │
│                      │  │  • JSON serialization       │ │    │
│                      │  └─────────────────────────────┘ │    │
│                      └─────────────────────────────────┘    │
│                               │                               │
│                               ▼                               │
│                      ┌─────────────────────────────────┐    │
│                      │  JSON Output (structured data)  │    │
│                      │  { findings: [...], errors: [] }│    │
│                      └─────────────────────────────────┘    │
│                               │                               │
│               ┌───────────────┴───────────────┐            │
│               ▼                               ▼             │
│         ┌─────────────┐                 ┌─────────────┐    │
│         │  Terminal   │                 │  Tauri UI   │    │
│         │  (text)     │                 │  (viewer)   │    │
│         └─────────────┘                 └─────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Why this matters:** If you run `skillsctl scan` in your terminal OR you click "Scan" in the desktop app, **the exact same code runs**. The UI just calls the CLI and displays the JSON output beautifully.

This means:
- No duplicate logic between CLI and UI
- No "works in CLI but broken in UI" bugs
- You can use the CLI in CI/CD pipelines
- The UI is optional—CLI is the core product

---

## Project Structure

```
skillsinspector/
├── packages/
│   └── cli/                    # Core CLI tool (TypeScript)
│       ├── src/
│       │   ├── cli.ts          # Command entry point
│       │   ├── commands/
│       │   │   ├── scan.ts     # Scan command implementation
│       │   │   ├── sync-check.ts
│       │   │   ├── history.ts
│       │   │   └── stats.ts
│       │   ├── scanner/        # File walking and pattern matching
│       │   ├── schema.ts       # JSON output schema definition
│       │   └── validator.ts    # Validation rules
│       └── test/               # CLI tests (Vitest)
│
├── src-tauri/                  # Desktop app (Rust + React)
│   ├── src/
│   │   ├── lib.rs              # Rust backend (IPC commands)
│   │   ├── lib_tests.rs        # Rust unit tests
│   │   └── lib_tests.rs        # ← Custom tempfile module
│   ├── Cargo.toml              # Rust dependencies
│   └── tauri.conf.json         # Tauri config
│
├── src/                        # Frontend (React + TypeScript)
│   ├── components/             # UI components
│   ├── App.tsx                 # Main app
│   └── main.tsx                # React entry point
│
├── docs/
│   ├── adr/                    # Architecture Decision Records
│   │   ├── 0001-cli-first-architecture.md
│   │   ├── 0002-scope-v1-minimal-ui.md
│   │   ├── 0003-ui-json-only.md
│   │   └── 0004-fix-command-cli-only.md
│   └── schema/
│       └── findings-schema.json # JSON Schema for validation
│
├── .spec/                      # Specification documents
├── .github/workflows/          # CI/CD
├── package.json                # Root package.json
├── pnpm-workspace.yaml         # Monorepo config
└── FORJAMIE.md                 # ← This file!
```

---

## The Tech Stack (Why These Choices?)

### Frontend: React + Tauri

| Technology | Why We Chose It |
|------------|-----------------|
| **React** | You already know it, huge ecosystem, great for UIs |
| **Tauri** | Desktop apps with web tech, but **much smaller** than Electron (10MB vs 200MB) |
| **TypeScript** | Type safety catches bugs before runtime |
| **Tailwind CSS v4** | Rapid styling without writing CSS files |
| **Vite** | Super-fast dev server and builds |
| **Biome** | Faster replacement for ESLint + Prettier |

### CLI: TypeScript + Node.js

| Technology | Why We Chose It |
|------------|-----------------|
| **TypeScript** | Same language as frontend, no context switching |
| **Commander.js** | CLI argument parsing (industry standard) |
| **Vitest** | Fast testing that works with Vite |
| **better-sqlite3** | Embedded SQLite for run history (no separate database needed) |

### Backend (Tauri): Rust

| Technology | Why We Chose It |
|------------|-----------------|
| **Rust** | Tauri uses Rust for the desktop shell—memory-safe, fast |
| **serde** | JSON serialization (like JSON.parse/stringify but typed) |
| **std::process::Command** | Spawning the CLI subprocess from Rust |

### Testing (CLI)

**Important: Database tests require Node 22 on this machine**

The `better-sqlite3` package uses native bindings that are compiled for specific Node versions. On this machine, the native bindings don't build under Node 25, so database tests must be run using Node 22.

**To rebuild and run tests using Node 22:**

```bash
# From packages/cli/
PATH=/opt/homebrew/opt/node@22/bin:$PATH npm rebuild better-sqlite3
PATH=/opt/homebrew/opt/node@22/bin:$PATH npm test
```

**Why this is necessary:**
- Native modules like `better-sqlite3` contain C++ code compiled against specific Node.js ABI versions
- Node 22 (LTS) has better prebuilt binary support than Node 25 (current)
- When switching Node versions, you must rebuild native modules
- The PATH prepending ensures the correct Node version is used for both rebuild and test execution

**How to avoid this issue:**
- Use Node.js LTS versions (like 22) for development
- Avoid using the absolute latest Node version for projects with native dependencies
- Consider using `nvm` or `mise` to manage Node versions per project

---

## Key Technical Decisions (The ADRs)

I documented four major architecture decisions in `docs/adr/`. These explain **why** the project is built this way:

### ADR 0001: CLI-First Architecture
**Decision:** CLI is the source of truth, UI just renders JSON output.
**TL;DR:** No duplicate validation logic—CLI and UI always agree.

### ADR 0002: Scope v1 Minimal UI
**Decision:** v1 only includes Validate + Sync-check modes. No Stats, Index, Remote, etc.
**TL;DR:** Ship something solid and small first. Add fancy stuff later based on user feedback.

### ADR 0003: UI JSON-Only Implementation
**Decision:** UI never runs validation directly—it always calls the CLI subprocess.
**TL;DR:** Clear security boundary (CLI process vs UI process), easier to audit.

### ADR 0004: Fix Command - CLI-Only in v1
**Decision:** UI displays fix suggestions, but you run them via terminal.
**TL;DR:** Safer (no accidental file writes from UI), auditable (shell history).

---

## How It Works: Deep Dive

### 1. The Scan Pipeline

When you run `skillsctl scan --repo .`:

```typescript
// 1. Parse arguments
const options = parseArgs(process.argv)

// 2. Validate the repo path
const validatedPath = validateRepoPath(options.repo)
// → Checks: exists, is directory, is git repo, no path traversal attacks

// 3. Walk the filesystem
const files = await walkDirectory(validatedPath)
// → Finds all files matching patterns (codex/**/*.md, claude/**/*.json, etc.)

// 4. Run validators on each file
const findings = []
for (const file of files) {
  const result = validate(file, rules)
  findings.push(...result.findings)
}

// 5. Serialize to JSON
const output = {
  schemaVersion: "1",
  toolVersion: "1.0.0",
  generatedAt: new Date().toISOString(),
  scanned: { files: files.length },
  findings: findings,
  errors: [],
  warnings: []
}

// 6. Print to stdout
console.log(JSON.stringify(output, null, 2))
```

### 2. The Tauri IPC Bridge

The React UI talks to Rust via **Tauri invoke commands**:

```typescript
// React (src/App.tsx)
import { invoke } from '@tauri-apps/api/core';

const scanResult = await invoke('run_scan', {
  options: {
    repo: '/path/to/repo',
    format: 'json'
  }
});
```

```rust
// Rust (src-tauri/src/lib.rs)
#[tauri::command]
async fn run_scan(options: ScanOptions) -> Result<ScanResult, String> {
    // 1. Validate inputs
    let validated_path = validate_repo_path(&options.repo)?;

    // 2. Get CLI path
    let cli_path = get_cli_path()?;

    // 3. Spawn CLI subprocess
    let output = Command::new(&cli_path)
        .arg("scan")
        .arg("--repo")
        .arg(&validated_path)
        .arg("--format")
        .arg(&options.format)
        .output()?;

    // 4. Return stdout, stderr, exit code to UI
    Ok(ScanResult {
        success: output.status.success(),
        output: String::from_utf8_lossy(&output.stdout).to_string(),
        exit_code: output.status.code().unwrap_or(1),
        error: if output.stderr.is_empty() { None } else { Some(...) },
    })
}
```

**The key insight:** The UI doesn't scan files—it just launches the CLI and shows the results.

---

## Security: Path Validation

One of the trickiest parts was preventing **path traversal attacks**. If someone passes `--repo ../../../../etc`, we don't want to scan system files.

Here's how we prevent it:

```rust
// 1. Check string for dangerous patterns
fn validate_path_string(path: &str) -> Result<(), ValidationError> {
    // Empty path?
    if path.trim().is_empty() {
        return Err(ValidationError::EmptyPath);
    }

    // Too long (DoS prevention)?
    if path.len() > MAX_PATH_LENGTH {
        return Err(ValidationError::PathTooLong);
    }

    // Null bytes (various attacks)?
    if path.contains('\0') {
        return Err(ValidationError::InvalidCharacters);
    }

    // Path traversal attempts?
    if path.contains("..") || path.contains("~/") {
        return Err(ValidationError::PathTraversal);
    }

    Ok(())
}

// 2. Resolve to absolute path and verify
fn validate_repo_path(path: &str) -> Result<PathBuf, ValidationError> {
    validate_path_string(path)?;  // Check string first

    let canonical = Path::new(path)
        .canonicalize()?;  // Resolve symlinks, relative components

    // Must exist, be directory, be git repo
    if !canonical.exists() {
        return Err(ValidationError::NotFound);
    }

    Ok(canonical)  // Return safe, absolute path
}
```

**Why `canonicalize()` matters:** It turns `../repo` into `/Users/jamie/actual/repo`, eliminating any ambiguity about what we're scanning.

---

## Testing Strategy

### Three Layers of Tests

1. **CLI Tests** (`packages/cli/test/`): Test scanner logic with fixtures
   - Mock file system with test repos
   - Validate output schema
   - Test error handling

2. **Rust Unit Tests** (`src-tauri/src/lib_tests.rs`): Test validation functions
   - Path validation (empty, too long, null bytes, traversal)
   - Repo validation (not found, not git repo, success)
   - Format validation (json vs text)
   - Serialization (ScanOptions, ScanResult)

3. **Integration Tests** (Future): CLI + Tauri together
   - Run actual scan commands
   - Verify IPC communication
   - Test error flows

### The tempfile Module

Rust's `tempfile` crate has issues on macOS, so we wrote a custom tempfile module:

```rust
// Minimal tempfile implementation
pub struct TempDir {
    path: PathBuf,
}

impl TempDir {
    pub fn path(&self) -> &Path {
        &self.path
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        // Best-effort cleanup on test exit
        let _ = fs::remove_dir_all(&self.path);
    }
}

pub fn tempdir() -> io::Result<TempDir> {
    let base_path = std::env::var("TMPDIR").unwrap_or("/tmp".to_string());
    let unique_name = format!("skillsinspector_test_{}", std::process::id());
    let dir_path = PathBuf::from(base_path).join(unique_name);

    fs::create_dir(&dir_path)?;
    Ok(TempDir { path: dir_path })
}
```

**Why this works:** Uses platform-specific temp directory (`/tmp` on macOS, `%TEMP%` on Windows) and adds the process ID for uniqueness.

---

## Lessons Learned (Things That Went Wrong)

### Bug #1: Path Traversal Via Symlinks

**Problem:** Initial validation just checked for `..` in strings. But a symlink could still escape the repo:

```bash
# Inside /safe/repo
ln -s /etc/passwd secret_file
# Now scanning /safe/repo includes /etc/passwd!
```

**Fix:** Use `canonicalize()` to resolve symlinks before scanning. This converts all symlinks to their real paths.

### Bug #2: tempfile Crate Failing on macOS

**Problem:** Rust's `tempfile` crate has issues with macOS temp directories. Tests failed randomly.

**Fix:** Wrote a custom tempfile module that respects `$TMPDIR` and uses process IDs for uniqueness.

### Bug #3: Duplicate tempfile Module

**Problem:** I initially nested the `tempfile` module inside the `#[cfg(test)]` tests module, which Rust didn't like.

**Fix:** Moved `tempfile` to top-level module, then included tests via `include!("lib_tests.rs")`.

### Lesson: Security Layers Matter

Each validation function adds a layer:
1. String validation (no `..`, no null bytes)
2. Path canonicalization (resolve symlinks)
3. Existence check (path actually exists)
4. Type check (is it a directory?)
5. Git check (does `.git` exist?)

If any layer fails, the whole operation stops. Defense in depth.

---

## CI/CD Pipeline

The `.github/workflows/ci.yml` file runs on every push and PR:

| Job | Purpose |
|-----|---------|
| `frontend-lint` | Biome lint + TypeScript typecheck |
| `cli-build` | Build CLI, run tests, test scan command |
| `tauri-build` | Build desktop app (Rust + frontend) |
| `test` | Run CLI tests |
| `storybook-build` | Ensure Storybook compiles (Argos deferred) |
| `audit` | Security audit (pnpm audit + cargo audit) |
| `sbom` | Generate Software Bill of Materials |

**Key insight:** The `tauri-build` job compiles Rust on Ubuntu, which catches any Rust compilation errors before they reach your machine.

---

## Monorepo: pnpm Workspaces

This project uses **pnpm workspaces** for the monorepo:

```yaml
# pnpm-workspace.yaml
packages:
  - 'packages/*'
```

```json
// package.json (root)
{
  "scripts": {
    "build:cli": "pnpm --filter @skillsinspector/cli build",
    "test": "pnpm --filter @skillsinspector/cli test"
  }
}
```

**Why workspaces?**
- Single `node_modules` folder (saves disk space)
- Can run commands in specific packages
- Local packages can import each other without publishing

---

## JSON Schema: The Contract

The `docs/schema/findings-schema.json` file defines the exact structure of scan output:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "skillsctl scan output",
  "type": "object",
  "required": ["schemaVersion", "toolVersion", "generatedAt", "scanned", "findings"],
  "properties": {
    "schemaVersion": { "type": "string", "enum": ["1"] },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["ruleID", "severity", "agent", "file", "message"],
        "properties": {
          "severity": { "enum": ["error", "warning", "info"] },
          "agent": { "enum": ["codex", "claude", "copilot", "codexSkillManager"] }
        }
      }
    }
  }
}
```

**Why this matters:**
- Tools can validate scan output against this schema
- Breaking changes to output format require bumping `schemaVersion`
- Documents the exact contract between CLI and UI

---

## Development Workflow

### Running the Project

```bash
# Install dependencies
pnpm install

# Run dev server (frontend + Tauri)
pnpm tauri:dev

# Build CLI only
pnpm build:cli

# Run CLI scan
pnpm skillsctl scan --repo . --format json

# Run tests
pnpm test

# Typecheck
pnpm typecheck

# Lint
pnpm lint
```

### Common Commands

| Task | Command |
|------|---------|
| Dev mode | `pnpm tauri:dev` |
| Build CLI | `pnpm build:cli` |
| Run scan | `pnpm skillsctl scan --repo .` |
| Run tests | `pnpm test` |
| Typecheck | `pnpm typecheck` |
| Lint | `pnpm lint` |
| Format | `pnpm fmt` |

---

## What's Next? (Post-v1 Ideas)

The v1 scope is intentionally minimal. Here are things we might add later:

### v1.1
- Fix command: "Open in Terminal" action (pre-fills command)
- Better error messages in UI
- Scan history UI

### v1.2
- In-app fix execution with confirmation modal
- Batch fix operations
- Diff viewer for fix preview

### v2.0
- Full undo/rollback support
- Stats, Index, Remote modes
- Command palette (Cmd+K)
- Saved filter presets

**The principle:** Ship a solid v1, learn from usage, then iterate based on real needs.

---

## Glossary

| Term | Meaning |
|------|---------|
| **ADR** | Architecture Decision Record—a document explaining why we made a technical choice |
| **IPC** | Inter-Process Communication—how React talks to Rust (via Tauri) |
| **Subprocess** | Running one program from another (Rust spawns the CLI) |
| **Canonical path** | Absolute, symlink-resolved path (`../repo` → `/Users/jamie/repo`) |
| **Path traversal** | Attack using `..` to escape intended directory |
| **Schema** | Defined structure for data (like a TypeScript interface, but for JSON) |
| **Monorepo** | Multiple packages in one git repository |
| **Workspace** | pnpm's monorepo feature |
| **pnpm** | Fast, disk-efficient package manager (alternative to npm/yarn) |

---

## Quick Reference: File Locations

| What You Want | File |
|---------------|------|
| CLI entry point | `packages/cli/src/cli.ts` |
| Scan command | `packages/cli/src/commands/scan.ts` |
| Rust IPC commands | `src-tauri/src/lib.rs` |
| Rust tests | `src-tauri/src/lib_tests.rs` |
| React app | `src/App.tsx` |
| CI config | `.github/workflows/ci.yml` |
| Architecture docs | `docs/adr/*.md` |
| JSON schema | `docs/schema/findings-schema.json` |
| Root package.json | `package.json` |

---

## Final Thoughts

This project is built around **simplicity and correctness**:

1. **CLI-first** means one source of truth
2. **Minimal v1** means we ship faster and learn from usage
3. **Security layers** means we validate inputs at every step
4. **Good docs** means ADRs explain why, not just what

The patterns here (CLI-first, JSON-only UI, ADRs, schema validation) are applicable to many projects. They're not SkillsInspector-specific—they're just good engineering practices.

---

*Last updated: 2026-01-27*
*Version: 1.0.0*
