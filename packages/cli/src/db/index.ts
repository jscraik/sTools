import Database, { Database as DatabaseType } from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import { join } from "node:path";
import { homedir } from "node:os";
import { existsSync, mkdirSync } from "node:fs";
import * as schema from "./schema.js";

/**
 * Default database directory
 */
const DEFAULT_DB_DIR = join(homedir(), ".skillsinspector");

/**
 * Default database file name
 */
const DB_FILENAME = "skillsinspector.db";

/**
 * Current schema version
 */
export const CURRENT_SCHEMA_VERSION = 1;

/**
 * Retention period in days (default: 30 days)
 */
export const RETENTION_DAYS = 30;

/**
 * Get database file path
 *
 * @param dbDir - Optional custom database directory
 * @returns Full path to database file
 */
export function getDbPath(dbDir?: string): string {
  const dir = dbDir ?? DEFAULT_DB_DIR;

  // Ensure directory exists
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }

  return join(dir, DB_FILENAME);
}

/**
 * Create database connection
 *
 * @param dbPath - Optional custom database path
 * @returns Drizzle database instance and raw sqlite connection
 */
export function createDb(dbPath?: string) {
  const path = dbPath ?? getDbPath();

  const sqlite = new Database(path);

  // Enable foreign keys
  sqlite.pragma("foreign_keys = ON");

  // Enable WAL mode for better concurrency
  sqlite.pragma("journal_mode = WAL");

  const db = drizzle(sqlite, { schema });

  // Return without exposing BetterSqlite3.Database type
  return { db, sqlite: sqlite as DatabaseType };
}

/**
 * Run database migrations
 *
 * @param dbPath - Optional custom database path
 */
export async function runMigrations(dbPath?: string) {
  const { sqlite } = createDb(dbPath);

  try {
    // Check if schema_version table exists
    const tableExists = sqlite
      .prepare(
        `
        SELECT name FROM sqlite_master
        WHERE type='table' AND name='schema_version'
      `
      )
      .get();

    if (!tableExists) {
      // Initial schema creation
      createSchema(sqlite);
      recordSchemaVersion(sqlite, CURRENT_SCHEMA_VERSION);
    } else {
      // Check current version
      const currentVersion = sqlite
        .prepare("SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1")
        .get() as { version: number } | undefined;

      if (!currentVersion || currentVersion.version < CURRENT_SCHEMA_VERSION) {
        // Run migrations (for now, just recreate schema)
        createSchema(sqlite);
        recordSchemaVersion(sqlite, CURRENT_SCHEMA_VERSION);
      }
    }
  } finally {
    sqlite.close();
  }
}

/**
 * Create database schema
 * This is a simple schema creation for v1
 * Future migrations should use drizzle-kit
 */
function createSchema(sqlite: DatabaseType) {
  sqlite.prepare(`
    CREATE TABLE IF NOT EXISTS scan_runs (
      id TEXT PRIMARY KEY,
      started_at INTEGER NOT NULL,
      finished_at INTEGER NOT NULL,
      exit_code INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      repo_path TEXT NOT NULL,
      command TEXT NOT NULL,
      duration_ms INTEGER NOT NULL,
      cache_path TEXT
    )
  `).run();

  sqlite.prepare(`
    CREATE TABLE IF NOT EXISTS findings (
      id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL REFERENCES scan_runs(id) ON DELETE CASCADE,
      rule_id TEXT NOT NULL,
      severity TEXT NOT NULL CHECK(severity IN ('error', 'warning', 'info')),
      file_path TEXT NOT NULL,
      line INTEGER,
      column INTEGER,
      agent TEXT NOT NULL CHECK(agent IN ('codex', 'claude', 'copilot', 'codexSkillManager')),
      message TEXT NOT NULL,
      fixable INTEGER NOT NULL DEFAULT 0
    )
  `).run();

  sqlite.prepare(`
    CREATE TABLE IF NOT EXISTS sync_reports (
      id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL REFERENCES scan_runs(id) ON DELETE CASCADE,
      only_in_codex INTEGER NOT NULL DEFAULT 0,
      only_in_claude INTEGER NOT NULL DEFAULT 0,
      mismatched INTEGER NOT NULL DEFAULT 0
    )
  `).run();

  sqlite.prepare(`
    CREATE TABLE IF NOT EXISTS schema_version (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version INTEGER NOT NULL,
      applied_at INTEGER NOT NULL
    )
  `).run();

  // Create indexes for better query performance
  sqlite.prepare("CREATE INDEX IF NOT EXISTS idx_findings_run_id ON findings(run_id)").run();
  sqlite.prepare("CREATE INDEX IF NOT EXISTS idx_findings_severity ON findings(severity)").run();
  sqlite.prepare("CREATE INDEX IF NOT EXISTS idx_scan_runs_repo_path ON scan_runs(repo_path)").run();
  sqlite.prepare("CREATE INDEX IF NOT EXISTS idx_scan_runs_started_at ON scan_runs(started_at)").run();
}

/**
 * Record schema version
 */
function recordSchemaVersion(sqlite: DatabaseType, version: number) {
  sqlite.prepare(
    `
    INSERT INTO schema_version (version, applied_at)
    VALUES (?, ?)
  `
  ).run(version, Date.now());
}

/**
 * Get current schema version from database
 *
 * @param dbPath - Optional custom database path
 * @returns Current schema version or null if not found
 */
export function getSchemaVersion(dbPath?: string): number | null {
  const { sqlite } = createDb(dbPath);

  try {
    const result = sqlite
      .prepare("SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1")
      .get() as { version: number } | undefined;

    return result?.version ?? null;
  } finally {
    sqlite.close();
  }
}

export { schema };
export * from "./history.js";
