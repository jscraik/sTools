import { eq, desc, gte, lt } from "drizzle-orm";

import { randomUUID } from "node:crypto";
import type { ScanOutput, ScanOptions } from "../types.js";
import { createDb, getDbPath, RETENTION_DAYS } from "./index.js";
import { scanRuns, findings, type NewScanRun, type NewFinding } from "./schema.js";

/**
 * Save scan run to database
 *
 * @param scanOutput - Scan output to save
 * @param options - Scan options used
 * @param exitCode - Exit code from scan
 * @param startedAt - Scan start timestamp
 * @returns The ID of the created scan run
 */
export async function saveScanRun(
  scanOutput: ScanOutput,
  options: ScanOptions,
  exitCode: number,
  startedAt: Date
): Promise<string> {
  const { db, sqlite } = createDb();

  try {
    const finishedAt = new Date();
    const durationMs = finishedAt.getTime() - startedAt.getTime();
    const runId = randomUUID();

    // Insert scan run
    const newRun: NewScanRun = {
      id: runId,
      startedAt,
      finishedAt,
      exitCode,
      schemaVersion: parseInt(scanOutput.schemaVersion, 10),
      repoPath: options.repo,
      command: `scan --repo ${options.repo} --format ${options.format}`,
      durationMs,
    };

    await db.insert(scanRuns).values(newRun);

    // Insert findings
    if (scanOutput.findings.length > 0) {
      const newFindings: NewFinding[] = scanOutput.findings.map((finding) => ({
        id: randomUUID(),
        runId,
        ruleId: finding.ruleID,
        severity: finding.severity,
        filePath: finding.file,
        line: finding.line,
        column: finding.column,
        agent: finding.agent,
        message: finding.message,
        fixable: false,
      }));

      await db.insert(findings).values(newFindings);
    }

    return runId;
  } finally {
    sqlite.close();
  }
}

/**
 * Get scan run by ID
 *
 * @param runId - Run ID to fetch
 * @returns Scan run or null if not found
 */
export async function getScanRun(runId: string) {
  const { db, sqlite } = createDb();

  try {
    const run = await db
      .select()
      .from(scanRuns)
      .where(eq(scanRuns.id, runId))
      .get();

    if (!run) {
      return null;
    }

    const runFindings = await db
      .select()
      .from(findings)
      .where(eq(findings.runId, runId))
      .orderBy(findings.filePath, findings.line, findings.ruleId)
      .all();

    return {
      ...run,
      findings: runFindings,
    };
  } finally {
    sqlite.close();
  }
}

/**
 * List scan runs for a repository
 *
 * @param repoPath - Repository path to filter by (optional)
 * @param limit - Maximum number of runs to return
 * @returns Array of scan runs
 */
export async function listScanRuns(repoPath?: string, limit = 50) {
  const { db, sqlite } = createDb();

  try {
    const whereClause = repoPath ? eq(scanRuns.repoPath, repoPath) : undefined;

    const runs = await db
      .select()
      .from(scanRuns)
      .where(whereClause)
      .orderBy(desc(scanRuns.startedAt))
      .limit(limit)
      .all();

    // Get summary counts for each run
    const runsWithCounts = await Promise.all(
      runs.map(async (run) => {
        const findingsList = await db
          .select()
          .from(findings)
          .where(eq(findings.runId, run.id))
          .all();

        return {
          ...run,
          errorCount: findingsList.filter((f) => f.severity === "error").length,
          warningCount: findingsList.filter((f) => f.severity === "warning").length,
          infoCount: findingsList.filter((f) => f.severity === "info").length,
        };
      })
    );

    return runsWithCounts;
  } finally {
    sqlite.close();
  }
}

/**
 * Get recent scan runs across all repositories
 *
 * @param days - Number of days to look back
 * @param limit - Maximum number of runs to return
 * @returns Array of recent scan runs
 */
export async function getRecentRuns(days = 7, limit = 20) {
  const { db, sqlite } = createDb();

  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);

    const runs = await db
      .select()
      .from(scanRuns)
      .where(gte(scanRuns.startedAt, cutoffDate))
      .orderBy(desc(scanRuns.startedAt))
      .limit(limit)
      .all();

    return runs;
  } finally {
    sqlite.close();
  }
}

/**
 * Get scan statistics for a repository
 *
 * @param repoPath - Repository path
 * @returns Statistics object
 */
export async function getScanStats(repoPath: string) {
  const { db, sqlite } = createDb();

  try {
    const runs = await db
      .select()
      .from(scanRuns)
      .where(eq(scanRuns.repoPath, repoPath))
      .orderBy(desc(scanRuns.startedAt))
      .all();

    const allFindings = await Promise.all(
      runs.map(async (run) => {
        return db
          .select()
          .from(findings)
          .where(eq(findings.runId, run.id))
          .all();
      })
    );

    const flatFindings = allFindings.flat();

    return {
      totalRuns: runs.length,
      totalFindings: flatFindings.length,
      errorCount: flatFindings.filter((f) => f.severity === "error").length,
      warningCount: flatFindings.filter((f) => f.severity === "warning").length,
      infoCount: flatFindings.filter((f) => f.severity === "info").length,
      lastScan: runs[0] || null,
    };
  } finally {
    sqlite.close();
  }
}

/**
 * Delete old scan runs based on retention policy
 *
 * @param retentionDays - Number of days to retain (default: 30)
 * @returns Number of deleted runs
 */
export async function pruneOldRuns(retentionDays = RETENTION_DAYS): Promise<number> {
  const { db, sqlite } = createDb();

  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    // Find runs to delete
    const oldRuns = await db
      .select({ id: scanRuns.id })
      .from(scanRuns)
      .where(lt(scanRuns.startedAt, cutoffDate))
      .all();

    if (oldRuns.length === 0) {
      return 0;
    }

    // Delete runs (cascade will delete associated findings)
    for (const run of oldRuns) {
      await db.delete(scanRuns).where(eq(scanRuns.id, run.id)).run();
    }

    // Vacuum database to reclaim space
    sqlite.exec("VACUUM");

    return oldRuns.length;
  } finally {
    sqlite.close();
  }
}

/**
 * Get database file size
 *
 * @returns Database file size in bytes
 */
export function getDbSize(): number {
  const fs = require("node:fs");
  const dbPath = getDbPath();

  try {
    const stats = fs.statSync(dbPath);
    return stats.size;
  } catch {
    return 0;
  }
}
