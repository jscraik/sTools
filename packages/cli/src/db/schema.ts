import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

/**
 * Scan runs table - stores metadata about each scan execution
 */
export const scanRuns = sqliteTable("scan_runs", {
  id: text("id").primaryKey(), // UUID
  startedAt: integer("started_at", { mode: "timestamp" }).notNull(),
  finishedAt: integer("finished_at", { mode: "timestamp" }).notNull(),
  exitCode: integer("exit_code").notNull(),
  schemaVersion: integer("schema_version").notNull(),
  repoPath: text("repo_path").notNull(),
  command: text("command").notNull(),
  durationMs: integer("duration_ms").notNull(),
  cachePath: text("cache_path"),
});

/**
 * Findings table - stores individual findings from scan runs
 */
export const findings = sqliteTable("findings", {
  id: text("id").primaryKey(), // UUID
  runId: text("run_id")
    .notNull()
    .references(() => scanRuns.id, { onDelete: "cascade" }),
  ruleId: text("rule_id").notNull(),
  severity: text("severity", { enum: ["error", "warning", "info"] }).notNull(),
  filePath: text("file_path").notNull(),
  line: integer("line"),
  column: integer("column"),
  agent: text("agent", {
    enum: ["codex", "claude", "copilot", "codexSkillManager"],
  }).notNull(),
  message: text("message").notNull(),
  fixable: integer("fixable", { mode: "boolean" }).notNull().default(false),
});

/**
 * Sync reports table - stores sync-check results
 */
export const syncReports = sqliteTable("sync_reports", {
  id: text("id").primaryKey(), // UUID
  runId: text("run_id")
    .notNull()
    .references(() => scanRuns.id, { onDelete: "cascade" }),
  onlyInCodex: integer("only_in_codex").notNull().default(0),
  onlyInClaude: integer("only_in_claude").notNull().default(0),
  mismatched: integer("mismatched").notNull().default(0),
});

/**
 * Schema version table - tracks database schema version
 */
export const schemaVersion = sqliteTable("schema_version", {
  id: integer("id").primaryKey(),
  version: integer("version").notNull(),
  appliedAt: integer("applied_at", { mode: "timestamp" }).notNull(),
});

/**
 * Type exports
 */
export type ScanRun = typeof scanRuns.$inferSelect;
export type NewScanRun = typeof scanRuns.$inferInsert;
export type Finding = typeof findings.$inferSelect;
export type NewFinding = typeof findings.$inferInsert;
export type SyncReport = typeof syncReports.$inferSelect;
export type NewSyncReport = typeof syncReports.$inferInsert;
