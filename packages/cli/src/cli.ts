#!/usr/bin/env node
import { Command } from "commander";
import { readFileSync } from "node:fs";
import { scanRepo, syncCheck } from "./scanner.js";
import { EXIT_CODES } from "./exit.js";
import { runMigrations, saveScanRun, listScanRuns, getScanStats, pruneOldRuns } from "./db/index.js";
import type { ScanOutput } from "./types.js";

const program = new Command();

// Get version from package.json
const pkg = JSON.parse(readFileSync(new URL("../package.json", import.meta.url), "utf-8"));

program
  .name("skillsctl")
  .description("SkillsInspector CLI - scan and validate codebases for AI agent usage patterns")
  .version(pkg.version);

// Initialize database on startup
let dbInitialized = false;

async function ensureDb() {
  if (!dbInitialized) {
    await runMigrations();
    dbInitialized = true;
  }
}

/**
 * Scan command - scan a repository for AI agent usage
 */
program
  .command("scan")
  .description("Scan a repository for AI agent usage patterns")
  .option("--repo <path>", "Repository path to scan", ".")
  .option("--format <format>", "Output format (json or text)", "json")
  .option("--schema-version <version>", "Schema version to use", "1")
  .option("--output <path>", "Write output to file")
  .option("--no-save", "Don't save run to history")
  .action(async (options) => {
    const startedAt = new Date();
    try {
      await ensureDb();

      const scanOptions = {
        repo: options.repo,
        format: options.format,
        schemaVersion: options.schemaVersion,
        output: options.output,
      };

      const result = await scanRepo(scanOptions);

      // Save run to history
      if (options.save !== false) {
        await saveScanRun(result.output, scanOptions, result.exitCode, startedAt);
      }

      // Format and output
      const output = formatOutput(result.output, options.format);

      if (options.output) {
        await writeOutput(options.output, output);
      } else {
        console.log(output);
      }

      process.exit(result.exitCode);
    } catch (error) {
      console.error("Fatal error:", error instanceof Error ? error.message : String(error));
      process.exit(EXIT_CODES.FatalError);
    }
  });

/**
 * Sync-check command - validate repository state
 */
program
  .command("sync-check")
  .description("Check repository synchronization state")
  .option("--repo <path>", "Repository path to check", ".")
  .option("--format <format>", "Output format (json or text)", "json")
  .option("--output <path>", "Write output to file")
  .action(async (options) => {
    try {
      await ensureDb();

      const result = await syncCheck({ repo: options.repo });

      // Format and output
      const output = formatOutput(result.output, options.format);

      if (options.output) {
        await writeOutput(options.output, output);
      } else {
        console.log(output);
      }

      process.exit(result.exitCode);
    } catch (error) {
      console.error("Fatal error:", error instanceof Error ? error.message : String(error));
      process.exit(EXIT_CODES.FatalError);
    }
  });

/**
 * History command - view scan run history
 */
program
  .command("history")
  .description("View scan run history")
  .option("--repo <path>", "Filter by repository path")
  .option("--limit <number>", "Maximum number of runs to show", "50")
  .option("--format <format>", "Output format (json or text)", "text")
  .action(async (options) => {
    try {
      await ensureDb();

      const runs = await listScanRuns(options.repo, parseInt(options.limit, 10));

      if (options.format === "json") {
        console.log(JSON.stringify(runs, null, 2));
      } else {
        if (runs.length === 0) {
          console.log("No scan history found.");
          return;
        }

        console.log(`Scan History (${runs.length} runs)`);
        console.log("=".repeat(60));
        console.log();

        for (const run of runs) {
          const date = new Date(run.startedAt);
          console.log(`Run ID: ${run.id}`);
          console.log(`  Date: ${date.toLocaleString()}`);
          console.log(`  Repo: ${run.repoPath}`);
          console.log(`  Command: ${run.command}`);
          console.log(`  Exit: ${run.exitCode}`);
          console.log(`  Duration: ${run.durationMs}ms`);
          console.log(`  Findings: ${run.errorCount} errors, ${run.warningCount} warnings, ${run.infoCount} info`);
          console.log();
        }
      }
    } catch (error) {
      console.error("Fatal error:", error instanceof Error ? error.message : String(error));
      process.exit(EXIT_CODES.FatalError);
    }
  });

/**
 * Stats command - view scan statistics for a repository
 */
program
  .command("stats")
  .description("View scan statistics for a repository")
  .option("--repo <path>", "Repository path", ".")
  .action(async (options) => {
    try {
      await ensureDb();

      const stats = await getScanStats(options.repo);

      console.log(`Scan Statistics for: ${options.repo}`);
      console.log("=".repeat(60));
      console.log(`Total scans: ${stats.totalRuns}`);
      console.log(`Total findings: ${stats.totalFindings}`);
      console.log(`Errors: ${stats.errorCount}`);
      console.log(`Warnings: ${stats.warningCount}`);
      console.log(`Info: ${stats.infoCount}`);

      if (stats.lastScan) {
        const lastScanDate = new Date(stats.lastScan.startedAt);
        console.log(`Last scan: ${lastScanDate.toLocaleString()}`);
      }
    } catch (error) {
      console.error("Fatal error:", error instanceof Error ? error.message : String(error));
      process.exit(EXIT_CODES.FatalError);
    }
  });

/**
 * Prune command - remove old scan history
 */
program
  .command("prune")
  .description("Remove scan runs older than retention period (30 days)")
  .option("--days <number>", "Retention period in days", "30")
  .option("--dry-run", "Show what would be deleted without deleting")
  .action(async (options) => {
    try {
      await ensureDb();

      const retentionDays = parseInt(options.days, 10);

      if (options.dryRun) {
        const { getRecentRuns } = await import("./db/history.js");
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

        const allRuns = await getRecentRuns(365, 1000);
        const oldRuns = allRuns.filter((run) => new Date(run.startedAt) < cutoffDate);

        console.log(`Would delete ${oldRuns.length} runs older than ${retentionDays} days.`);
      } else {
        const deleted = await pruneOldRuns(retentionDays);
        console.log(`Deleted ${deleted} runs older than ${retentionDays} days.`);
      }
    } catch (error) {
      console.error("Fatal error:", error instanceof Error ? error.message : String(error));
      process.exit(EXIT_CODES.FatalError);
    }
  });

/**
 * Format scan output as JSON or text
 */
function formatOutput(output: ScanOutput, format: string): string {
  if (format === "json") {
    return JSON.stringify(output, null, 2);
  }

  // Text format
  const lines = [
    `SkillsInspector Scan Results`,
    `=${"=".repeat(40)}`,
    ``,
    `Scanned: ${output.scanned} files`,
    `Errors: ${output.errors}`,
    `Warnings: ${output.warnings}`,
    ``,
  ];

  if (output.findings.length > 0) {
    lines.push(`Findings:`);
    lines.push(`-${"-".repeat(40)}`);

    for (const finding of output.findings) {
      const location = finding.line ? `${finding.file}:${finding.line}` : finding.file;
      lines.push(`[${finding.severity.toUpperCase()}] ${finding.ruleID}: ${finding.message}`);
      lines.push(`  Agent: ${finding.agent}`);
      lines.push(`  File: ${location}`);
      lines.push("");
    }
  } else {
    lines.push(`No findings found.`);
  }

  return lines.join("\n");
}

/**
 * Write output to file
 */
async function writeOutput(path: string, content: string): Promise<void> {
  const { writeFile } = await import("node:fs/promises");
  await writeFile(path, content, "utf-8");
}

// Parse and execute
program.parseAsync(process.argv).catch((error) => {
  console.error("CLI error:", error);
  process.exit(EXIT_CODES.FatalError);
});
