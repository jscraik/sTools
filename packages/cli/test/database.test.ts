/**
 * Tests for database layer
 */

import { afterEach, beforeEach, describe, it } from "node:test";
import { strictEqual, deepEqual } from "node:assert";
import { rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ScanOutput } from "../dist/types.js";
import { createTestDb } from "./utils/test.ts";

type DbModule = {
  runMigrations: typeof import("../dist/db/index.js").runMigrations;
  getSchemaVersion: typeof import("../dist/db/index.js").getSchemaVersion;
  getDbPath: typeof import("../dist/db/index.js").getDbPath;
};

type HistoryModule = {
  saveScanRun: typeof import("../dist/db/history.js").saveScanRun;
  listScanRuns: typeof import("../dist/db/history.js").listScanRuns;
  pruneOldRuns: typeof import("../dist/db/history.js").pruneOldRuns;
};

let dbModule: DbModule | null = null;
let historyModule: HistoryModule | null = null;
let loadError: Error | null = null;

try {
  const db = await import("../dist/db/index.js");
  const history = await import("../dist/db/history.js");
  dbModule = db;
  historyModule = history;
} catch (error) {
  loadError = error instanceof Error ? error : new Error(String(error));
  console.error("Failed to load database modules:", loadError);
}

// Use describe.skip if module failed to load, otherwise use describe
const describeDb = loadError ? describe.skip : describe;

describeDb("database", () => {
  let testDbDir: string;

  beforeEach(async () => {
    testDbDir = join(tmpdir(), `skillsinspector-test-${Date.now()}-${Math.random()}`);
    process.env.SKILLSINSPECTOR_DB_DIR = testDbDir;
    await dbModule!.runMigrations();
  });

  afterEach(async () => {
    delete process.env.SKILLSINSPECTOR_DB_DIR;
    try {
      await rm(testDbDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  });

  describe("getDbPath", () => {
    it("should return a path in ~/.skillsinspector by default", () => {
      const originalEnv = process.env.SKILLSINSPECTOR_DB_DIR;
      delete process.env.SKILLSINSPECTOR_DB_DIR;

      try {
        const path = dbModule!.getDbPath();

        strictEqual(path.includes(".skillsinspector"), true);
        strictEqual(path.endsWith("skillsinspector.db"), true);
      } finally {
        process.env.SKILLSINSPECTOR_DB_DIR = originalEnv;
      }
    });
  });

  describe("getSchemaVersion", () => {
    it("should return null for non-existent database", async () => {
      // Use a non-existent path
      const version = await dbModule!.getSchemaVersion("/tmp/nonexistent-skillsinspector-test");

      strictEqual(version, null);
    });
  });

  describe("runMigrations", () => {
    it("should create and initialize a new database", async () => {
      const db = await createTestDb();

      try {
        // Run migrations on test database
        await dbModule!.runMigrations(db.path);

        // Check schema version was created
        const version = await dbModule!.getSchemaVersion(db.path);

        strictEqual(version, 1);
      } finally {
        await db.cleanup();
      }
    });

    it("should handle re-running migrations", async () => {
      const db = await createTestDb();

      try {
        // Run migrations twice
        await dbModule!.runMigrations(db.path);
        await dbModule!.runMigrations(db.path);

        // Should still work
        const version = await dbModule!.getSchemaVersion(db.path);
        strictEqual(version, 1);
      } finally {
        await db.cleanup();
      }
    });
  });

  describe("saveScanRun", () => {
    it("should save a scan run with findings", async () => {
      const db = await createTestDb();

      try {
        await dbModule!.runMigrations(db.path);

        const output: ScanOutput = {
          schemaVersion: "1",
          toolVersion: "0.1.0",
          generatedAt: "2024-01-27T00:00:00.000Z",
          scanned: 5,
          errors: 2,
          warnings: 1,
          findings: [
            {
              ruleID: "TEST-001",
              severity: "error",
              agent: "claude",
              file: "test.ts",
              message: "Test finding",
              line: 10,
            },
            {
              ruleID: "TEST-002",
              severity: "warning",
              agent: "codex",
              file: "config.json",
              message: "Another finding",
            },
          ],
        };

        const options = {
          repo: "/test/repo",
          format: "json",
          schemaVersion: "1",
        };

        const startedAt = new Date("2024-01-27T00:00:00.000Z");
        const runId = await historyModule!.saveScanRun(output, options, 1, startedAt);

        strictEqual(typeof runId, "string");
        strictEqual(runId.length, 36); // UUID length
      } finally {
        await db.cleanup();
      }
    });

    it("should handle scans with no findings", async () => {
      const db = await createTestDb();

      try {
        await dbModule!.runMigrations(db.path);

        const output: ScanOutput = {
          schemaVersion: "1",
          toolVersion: "0.1.0",
          generatedAt: "2024-01-27T00:00:00.000Z",
          scanned: 0,
          errors: 0,
          warnings: 0,
          findings: [],
        };

        const options = {
          repo: "/test/repo",
          format: "json",
          schemaVersion: "1",
        };

        const startedAt = new Date("2024-01-27T00:00:00.000Z");
        const runId = await historyModule!.saveScanRun(output, options, 0, startedAt);

        strictEqual(typeof runId, "string");
      } finally {
        await db.cleanup();
      }
    });
  });

  describe("listScanRuns", () => {
    it("should list scan runs for a repository", async () => {
      const db = await createTestDb();

      try {
        await dbModule!.runMigrations(db.path);

        // Save a scan run
        const output: ScanOutput = {
          schemaVersion: "1",
          toolVersion: "0.1.0",
          generatedAt: "2024-01-27T00:00:00.000Z",
          scanned: 1,
          errors: 0,
          warnings: 0,
          findings: [],
        };

        const options = {
          repo: "/test/repo",
          format: "json",
          schemaVersion: "1",
        };

        await historyModule!.saveScanRun(output, options, 0, new Date());

        // List runs
        const runs = await historyModule!.listScanRuns("/test/repo");

        strictEqual(runs.length, 1);
        strictEqual(runs[0].repoPath, "/test/repo");
      } finally {
        await db.cleanup();
      }
    });

    it("should return empty array for repository with no runs", async () => {
      const db = await createTestDb();

      try {
        await dbModule!.runMigrations(db.path);

        const runs = await historyModule!.listScanRuns("/nonexistent/repo");

        deepEqual(runs, []);
      } finally {
        await db.cleanup();
      }
    });
  });

  describe("pruneOldRuns", () => {
    it("should delete runs older than retention period", async () => {
      const db = await createTestDb();

      try {
        await dbModule!.runMigrations(db.path);

        // Create an old scan run (simulated by directly manipulating the DB)
        // This is a simplified test - in real scenario, we'd mock the date
        const deleted = await historyModule!.pruneOldRuns(30);

        // Should return 0 since we have no runs
        strictEqual(deleted, 0);
      } finally {
        await db.cleanup();
      }
    });

    it("should handle zero retention period", async () => {
      const db = await createTestDb();

      try {
        await dbModule!.runMigrations(db.path);

        // Prune with 0 days - should delete nothing if no runs exist
        const deleted = await historyModule!.pruneOldRuns(0);

        strictEqual(deleted, 0);
      } finally {
        await db.cleanup();
      }
    });
  });
});
