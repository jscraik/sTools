/**
 * Finding severity levels
 */
export type Severity = "error" | "warning" | "info";

/**
 * AI agent types that can generate findings
 */
export type Agent = "codex" | "claude" | "copilot" | "codexSkillManager";

/**
 * Individual finding from a scan
 */
export interface Finding {
  ruleID: string;
  severity: Severity;
  agent: Agent;
  file: string;
  message: string;
  line?: number;
  column?: number;
}

/**
 * Complete scan output matching findings-schema.json v1
 */
export interface ScanOutput {
  schemaVersion: "1";
  toolVersion: string;
  generatedAt: string; // ISO 8601 date-time
  scanned: number;
  errors: number;
  warnings: number;
  findings: Finding[];
}

/**
 * Scan options from CLI arguments
 */
export interface ScanOptions {
  repo: string;
  format: "json" | "text";
  schemaVersion: string;
  output?: string;
}

/**
 * Sync-check options from CLI arguments
 */
export interface SyncCheckOptions {
  repo: string;
  format: "json" | "text";
  output?: string;
}

/**
 * Exit codes matching sTools behavior
 */
export enum ExitCode {
  Success = 0,
  ErrorsFound = 1,
  FatalError = 2,
}
