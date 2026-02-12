import { createClient, type Client } from "@libsql/client";
import { drizzle } from "drizzle-orm/libsql";
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
  const envDir = process.env.SKILLSINSPECTOR_DB_DIR?.trim();
  const dir = dbDir ?? envDir ?? DEFAULT_DB_DIR;

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
 * @returns Drizzle database instance and raw libsql client
 */
export function createDb(dbPath?: string) {
  const path = dbPath ?? getDbPath();

  const client = createClient({
    url: `file:${path}`,
  });

  const db = drizzle(client, { schema });

  return { db, client };
}

/**
 * Run database migrations
 *
 * @param dbPath - Optional custom database path
 */
export async function runMigrations(dbPath?: string) {
  const { client } = createDb(dbPath);

  try {
    // Check if schema_version table exists
    const tableExists = await client.execute(
      `
        SELECT name FROM sqlite_master
        WHERE type='table' AND name='schema_version'
      `
    );

    if (tableExists.rows.length === 0) {
      // Initial schema creation
      await createSchema(client);
      await recordSchemaVersion(client, CURRENT_SCHEMA_VERSION);
    } else {
      // Check current version
      const currentVersion = await client.execute(
        "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1"
      );

      const version = currentVersion.rows[0]?.version as number | undefined;

      if (!version || version < CURRENT_SCHEMA_VERSION) {
        // Run migrations (for now, just recreate schema)
        await createSchema(client);
        await recordSchemaVersion(client, CURRENT_SCHEMA_VERSION);
      }
    }
  } finally {
    client.close();
  }
}

/**
 * Create database schema
 * This is a simple schema creation for v1
 * Future migrations should use drizzle-kit
 */
async function createSchema(client: Client) {
  await client.execute(`
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
  `);

  await client.execute(`
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
  `);

  await client.execute(`
    CREATE TABLE IF NOT EXISTS sync_reports (
      id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL REFERENCES scan_runs(id) ON DELETE CASCADE,
      only_in_codex INTEGER NOT NULL DEFAULT 0,
      only_in_claude INTEGER NOT NULL DEFAULT 0,
      mismatched INTEGER NOT NULL DEFAULT 0
    )
  `);

  await client.execute(`
    CREATE TABLE IF NOT EXISTS schema_version (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version INTEGER NOT NULL,
      applied_at INTEGER NOT NULL
    )
  `);

  // Create indexes for better query performance
  await client.execute("CREATE INDEX IF NOT EXISTS idx_findings_run_id ON findings(run_id)");
  await client.execute("CREATE INDEX IF NOT EXISTS idx_findings_severity ON findings(severity)");
  await client.execute("CREATE INDEX IF NOT EXISTS idx_scan_runs_repo_path ON scan_runs(repo_path)");
  await client.execute("CREATE INDEX IF NOT EXISTS idx_scan_runs_started_at ON scan_runs(started_at)");
}

/**
 * Record schema version
 */
async function recordSchemaVersion(client: Client, version: number) {
  await client.execute({
    sql: "INSERT INTO schema_version (version, applied_at) VALUES (?, ?)",
    args: [version, Date.now()],
  });
}

/**
 * Get current schema version from database
 *
 * @param dbPath - Optional custom database path
 * @returns Current schema version or null if not found
 */
export async function getSchemaVersion(dbPath?: string): Promise<number | null> {
  const { client } = createDb(dbPath);

  try {
    const result = await client.execute(
      "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1"
    );

    return result.rows[0]?.version as number | undefined ?? null;
  } catch (error) {
    if (
      error instanceof Error &&
      error.message.includes("no such table: schema_version")
    ) {
      return null;
    }
    throw error;
  } finally {
    client.close();
  }
}

export { schema };
export * from "./history.js";
