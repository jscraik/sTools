import { glob } from "glob";
import { readFile, realpath, stat } from "node:fs/promises";
import { join, relative, resolve } from "node:path";
import type { Finding, ScanOutput, ScanOptions } from "./types.js";
import { EXIT_CODES } from "./exit.js";
import { validateOutput } from "./validator.js";

/**
 * Maximum allowed path length to prevent DoS
 */
const MAX_PATH_LENGTH = 4096;

/**
 * Error types for validation failures
 */
export enum ScanError {
  EmptyPath = "Repository path cannot be empty",
  PathTooLong = "Repository path exceeds maximum length",
  InvalidCharacters = "Repository path contains invalid characters",
  PathTraversal = "Repository path contains path traversal sequences",
  NotFound = "Repository path does not exist",
  NotDirectory = "Repository path is not a directory",
  InvalidFormat = "Format must be 'json' or 'text'",
}

/**
 * Validate that a path string is safe to use
 */
export function validatePathString(path: string): void {
  // Check for empty path
  if (!path || path.trim().length === 0) {
    throw new Error(ScanError.EmptyPath);
  }

  // Check path length
  if (path.length > MAX_PATH_LENGTH) {
    throw new Error(ScanError.PathTooLong);
  }

  // Check for null bytes (prevents various attacks)
  if (path.includes("\0")) {
    throw new Error(ScanError.InvalidCharacters);
  }

  // Check for path traversal attempts
  if (path.includes("..") || path.includes("~/")) {
    throw new Error(ScanError.PathTraversal);
  }
}

/**
 * Validate and canonicalize a repository path
 */
export async function validateRepoPath(path: string): Promise<string> {
  // First validate the string itself
  validatePathString(path);

  const resolvedPath = resolve(path);

  // Check if path exists
  const pathStat = await stat(resolvedPath).catch(() => null);
  if (!pathStat) {
    throw new Error(ScanError.NotFound);
  }

  // Verify it's a directory
  if (!pathStat.isDirectory()) {
    throw new Error(ScanError.NotDirectory);
  }

  // Resolve any symlinks
  let realPath: string;
  try {
    realPath = await realpath(resolvedPath);
  } catch {
    realPath = resolvedPath;
  }

  return realPath;
}

/**
 * Validate format parameter
 */
export function validateFormat(format: string): void {
  if (format !== "json" && format !== "text") {
    throw new Error(ScanError.InvalidFormat);
  }
}

/**
 * Patterns that indicate AI agent usage
 * Each pattern maps to a specific rule, severity, and agent type
 */
const AGENT_PATTERNS = {
  // Claude Code / Anthropic patterns
  claude: [
    {
      pattern: /anthropic.*api[_-]?key/i,
      ruleID: "CLAUDE-001",
      message: "Possible Anthropic API key exposure",
    },
    {
      pattern: /claude[_-]?api[_-]?key/i,
      ruleID: "CLAUDE-002",
      message: "Possible Claude API key exposure",
    },
    {
      pattern: /@anthropic/i,
      ruleID: "CLAUDE-003",
      message: "Anthropic SDK import detected",
    },
    {
      pattern: /anthropic\.bedrock/i,
      ruleID: "CLAUDE-004",
      message: "Anthropic Bedrock runtime usage detected",
    },
  ],

  // Codex patterns
  codex: [
    {
      pattern: /codex[_-]?session[_-]?log/i,
      ruleID: "CODEX-001",
      message: "Codex session log detected",
    },
    {
      pattern: /@?\*?claude[-_]?code[-_]?\*?/i,
      ruleID: "CODEX-002",
      message: "Claude Code reference detected",
    },
    {
      pattern: /\.codex\//i,
      ruleID: "CODEX-003",
      message: "Codex configuration directory reference",
    },
    {
      pattern: /codex[-_]?(cli|tool)/i,
      ruleID: "CODEX-004",
      message: "Codex CLI/tool reference detected",
    },
  ],

  // GitHub Copilot patterns
  copilot: [
    {
      pattern: /github\.copilot/i,
      ruleID: "COPILOT-001",
      message: "GitHub Copilot API usage detected",
    },
    {
      pattern: /copilot[-_]?(cli|extension)/i,
      ruleID: "COPILOT-002",
      message: "GitHub Copilot extension reference",
    },
  ],

  // Codex Skill Manager patterns
  codexSkillManager: [
    {
      pattern: /skill[-_]?manager/i,
      ruleID: "CSM-001",
      message: "Skill Manager reference detected",
    },
    {
      pattern: /\.skill/i,
      ruleID: "CSM-002",
      message: "Skill file reference detected",
    },
  ],
} as const;

type AgentType = keyof typeof AGENT_PATTERNS;

/**
 * Scan a repository for AI agent usage patterns
 *
 * @param options - Scan options from CLI
 * @returns Scan output with findings and exit code
 */
export async function scanRepo(options: ScanOptions): Promise<{ output: ScanOutput; exitCode: number }> {
  // Validate format
  validateFormat(options.format);

  // Validate and canonicalize the repository path
  const repoPath = await validateRepoPath(options.repo);

  const findings: Finding[] = [];

  // File extensions to scan
  const extensions = [
    "js",
    "jsx",
    "ts",
    "tsx",
    "py",
    "rs",
    "go",
    "java",
    "kt",
    "swift",
    "sh",
    "bash",
    "zsh",
    "yaml",
    "yml",
    "toml",
    "json",
  ];

  // Build glob pattern
  const pattern = join(repoPath, "**", `*.{${extensions.join(",")}}`);

  // Find all matching files
  const files = await glob(pattern, {
    absolute: false,
    cwd: repoPath,
    ignore: [
      "**/node_modules/**",
      "**/dist/**",
      "**/build/**",
      "**/.git/**",
      "**/target/**",
      "**/*.min.js",
      "**/vendor/**",
    ],
  });

  // Scan each file
  for (const file of files) {
    const fileFindings = await scanFile(join(repoPath, file), repoPath);
    findings.push(...fileFindings);
  }

  // Count by severity
  const errors = findings.filter((f) => f.severity === "error").length;
  const warnings = findings.filter((f) => f.severity === "warning").length;

  // Build output
  const output: ScanOutput = {
    schemaVersion: "1",
    toolVersion: "0.1.0",
    generatedAt: new Date().toISOString(),
    scanned: files.length,
    errors,
    warnings,
    findings: sortFindings(findings),
  };

  // Validate output against schema
  const validation = validateOutput(output);
  if (!validation.valid) {
    console.error("Schema validation failed:", validation.errors);
    return { output, exitCode: EXIT_CODES.FatalError };
  }

  // Determine exit code based on findings
  const exitCode = errors > 0 ? EXIT_CODES.ErrorsFound : EXIT_CODES.Success;

  return { output, exitCode };
}

/**
 * Scan a single file for agent patterns
 */
async function scanFile(filePath: string, repoPath: string): Promise<Finding[]> {
  const findings: Finding[] = [];
  const relativePath = relative(repoPath, filePath);

  try {
    // Read as buffer first to validate UTF-8
    const buffer = await readFile(filePath);

    // Validate UTF-8 encoding with fatal mode
    const decoder = new TextDecoder("utf-8", { fatal: true });
    let content: string;

    try {
      content = decoder.decode(buffer);
    } catch {
      // File is not valid UTF-8, skip it
      return [{
        ruleID: "SCAN-UTF8",
        severity: "warning",
        agent: "codex",
        file: relativePath,
        message: "File contains invalid UTF-8 encoding",
      }];
    }

    const lines = content.split("\n");

    for (let lineNum = 0; lineNum < lines.length; lineNum++) {
      const line = lines[lineNum];
      const lineFindings = scanLine(line, relativePath, lineNum + 1);
      findings.push(...lineFindings);
    }
  } catch (error) {
    // Report file read errors as findings
    const errorMsg = error instanceof Error ? error.message : String(error);
    findings.push({
      ruleID: "SCAN-ERROR",
      severity: "warning",
      agent: "codex",
      file: relativePath,
      message: `Failed to scan file: ${errorMsg}`,
    });
  }

  return findings;
}

/**
 * Scan a single line for agent patterns
 */
function scanLine(line: string, file: string, lineNum: number): Finding[] {
  const findings: Finding[] = [];

  for (const [agent, patterns] of Object.entries(AGENT_PATTERNS)) {
    for (const { pattern, ruleID, message } of patterns) {
      if (pattern.test(line)) {
        findings.push({
          ruleID,
          severity: "error",
          agent: agent as AgentType,
          file,
          message,
          line: lineNum,
        });
      }
    }
  }

  return findings;
}

/**
 * Sort findings deterministically for stable output
 * Sort order: file, line, ruleID, agent
 */
function sortFindings(findings: Finding[]): Finding[] {
  return [...findings].sort((a, b) => {
    if (a.file !== b.file) return a.file.localeCompare(b.file);
    if ((a.line ?? 0) !== (b.line ?? 0)) return (a.line ?? 0) - (b.line ?? 0);
    if (a.ruleID !== b.ruleID) return a.ruleID.localeCompare(b.ruleID);
    return a.agent.localeCompare(b.agent);
  });
}

/**
 * Run sync-check to validate repo state
 * Currently a placeholder that returns success
 */
export async function syncCheck(): Promise<{ output: ScanOutput; exitCode: number }> {
  const output: ScanOutput = {
    schemaVersion: "1",
    toolVersion: "0.1.0",
    generatedAt: new Date().toISOString(),
    scanned: 0,
    errors: 0,
    warnings: 0,
    findings: [],
  };

  return { output, exitCode: EXIT_CODES.Success };
}
