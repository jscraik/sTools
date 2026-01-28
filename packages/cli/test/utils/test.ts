/**
 * Test utilities for CLI tests
 */

import { mkdir, writeFile, rm } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";

export interface TestRepo {
  path: string;
  cleanup: () => Promise<void>;
}

/**
 * Create a temporary git repository for testing
 */
export async function createTestRepo(files: Record<string, string> = {}): Promise<TestRepo> {
  const testId = `test-repo-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const repoPath = join(tmpdir(), testId);

  // Create directory
  await mkdir(repoPath, { recursive: true });

  // Initialize git repo
  const { execSync } = await import("node:child_process");
  try {
    execSync("git init", { cwd: repoPath, stdio: "ignore" });
    execSync('git config user.email "test@test.com"', { cwd: repoPath, stdio: "ignore" });
    execSync('git config user.name "Test User"', { cwd: repoPath, stdio: "ignore" });
  } catch {
    // Git not available, skip git initialization
    // Tests will need to handle this
  }

  // Create files
  for (const [filePath, content] of Object.entries(files)) {
    const fullPath = join(repoPath, filePath);
    const dir = fullPath.slice(0, fullPath.lastIndexOf("/"));
    await mkdir(dir, { recursive: true });
    await writeFile(fullPath, content, "utf-8");
  }

  const cleanup = async () => {
    try {
      await rm(repoPath, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  };

  return { path: repoPath, cleanup };
}

/**
 * Create a test database in a temporary location
 */
export async function createTestDb(): Promise<{ path: string; cleanup: () => Promise<void> }> {
  const testId = `test-db-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const dbPath = join(tmpdir(), testId);

  const cleanup = async () => {
    try {
      await rm(dbPath, { force: true });
    } catch {
      // Ignore cleanup errors
    }
  };

  return { path: dbPath, cleanup };
}

/**
 * Wait for a promise to resolve with timeout
 */
export async function withTimeout<T>(
  promise: Promise<T>,
  ms: number,
  errorMessage = "Operation timed out"
): Promise<T> {
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error(errorMessage)), ms)
  );

  return Promise.race([promise, timeout]);
}

/**
 * Minimal assert functions for tests
 */
export function assert(condition: unknown, message: string): asserts condition {
  if (!condition) {
    throw new Error(`Assertion failed: ${message}`);
  }
}

export function assertEqual<T>(actual: T, expected: T, message?: string): void {
  if (actual !== expected) {
    throw new Error(
      message || `Expected ${JSON.stringify(expected)} but got ${JSON.stringify(actual)}`
    );
  }
}

export function assertDeepEqual<T>(actual: T, expected: T, message?: string): void {
  const actualStr = JSON.stringify(actual, null, 2);
  const expectedStr = JSON.stringify(expected, null, 2);

  if (actualStr !== expectedStr) {
    throw new Error(
      message || `Values not equal:\nExpected: ${expectedStr}\nActual: ${actualStr}`
    );
  }
}

export function assertThrows(
  fn: () => unknown,
  expectedError?: string | RegExp
): void {
  try {
    fn();
    throw new Error("Expected function to throw but it didn't");
  } catch (error) {
    if (expectedError === undefined) return;

    const errorMsg = error instanceof Error ? error.message : String(error);

    if (typeof expectedError === "string") {
      if (!errorMsg.includes(expectedError)) {
        throw new Error(
          `Expected error message to include "${expectedError}" but got "${errorMsg}"`
        );
      }
    } else {
      if (!expectedError.test(errorMsg)) {
        throw new Error(
          `Expected error message to match ${expectedError} but got "${errorMsg}"`
        );
      }
    }
  }
}

export function assertTrue(value: unknown, message?: string): void {
  if (value !== true) {
    throw new Error(message || `Expected true but got ${JSON.stringify(value)}`);
  }
}

export function assertFalse(value: unknown, message?: string): void {
  if (value !== false) {
    throw new Error(message || `Expected false but got ${JSON.stringify(value)}`);
  }
}
