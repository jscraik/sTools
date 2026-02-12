/**
 * Tests for scanner.ts
 */

import { describe, it } from "node:test";
import { strictEqual, deepEqual } from "node:assert";
import { scanRepo, validatePathString, validateRepoPath, validateFormat, ScanError } from "../dist/scanner.js";
import type { ScanOutput } from "../dist/types.js";
import { createTestRepo } from "./utils/test.ts";

describe("scanner", () => {
  describe("validatePathString", () => {
    it("should accept valid paths", () => {
      // Should not throw
      validatePathString("/path/to/repo");
      validatePathString("./relative/path");
      validatePathString("C:\\Users\\test\\repo");
    });

    it("should reject empty paths", () => {
      strictEqual(
        ScanError.EmptyPath,
        "Repository path cannot be empty"
      );

      try {
        validatePathString("");
        throw new Error("Should have thrown");
      } catch (error) {
        if (error instanceof Error) {
          strictEqual(error.message, ScanError.EmptyPath);
        }
      }
    });

    it("should reject paths with null bytes", () => {
      try {
        validatePathString("/path\0with\0nulls");
        throw new Error("Should have thrown");
      } catch (error) {
        if (error instanceof Error) {
          strictEqual(error.message, ScanError.InvalidCharacters);
        }
      }
    });

    it("should reject path traversal sequences", () => {
      try {
        validatePathString("../../../etc/passwd");
        throw new Error("Should have thrown");
      } catch (error) {
        if (error instanceof Error) {
          strictEqual(error.message, ScanError.PathTraversal);
        }
      }

      validatePathString("~/.cursor");
    });

    it("should reject paths exceeding max length", () => {
      const longPath = "a".repeat(5000);
      try {
        validatePathString(longPath);
        throw new Error("Should have thrown");
      } catch (error) {
        if (error instanceof Error) {
          strictEqual(error.message, ScanError.PathTooLong);
        }
      }
    });
  });

  describe("validateFormat", () => {
    it("should accept valid formats", () => {
      // Should not throw
      validateFormat("json");
      validateFormat("text");
    });

    it("should reject invalid formats", () => {
      try {
        validateFormat("xml");
        throw new Error("Should have thrown");
      } catch (error) {
        if (error instanceof Error) {
          strictEqual(error.message, ScanError.InvalidFormat);
        }
      }
    });
  });

  describe("scanRepo", () => {
    it("should scan a repository and return findings", async () => {
      const repo = await createTestRepo({
        "src/test.ts": `
import { Anthropic } from "@anthropic-ai/sdk";

const apiKey = "sk-ant-test-key";
`,
        "README.md": `
# Test Repository

This is a test file.
`,
      });

      try {
        const result = await scanRepo({
          repo: repo.path,
          format: "json",
          schemaVersion: "1",
        });

        strictEqual(result.exitCode, 1); // Has errors
        strictEqual(result.output.scanned, 1); // Only scanned test.ts (README is not in extensions)
        strictEqual(result.output.errors, 1); // Anthropic SDK import
        strictEqual(result.output.findings.length, 1);
        strictEqual(result.output.findings[0].ruleID, "CLAUDE-003");
        strictEqual(result.output.findings[0].agent, "claude");
      } finally {
        await repo.cleanup();
      }
    });

    it("should handle repositories with no findings", async () => {
      const repo = await createTestRepo({
        "src/index.ts": `
console.log("Hello, world!");
`,
      });

      try {
        const result = await scanRepo({
          repo: repo.path,
          format: "json",
          schemaVersion: "1",
        });

        strictEqual(result.exitCode, 0); // Success
        strictEqual(result.output.errors, 0);
        strictEqual(result.output.warnings, 0);
        strictEqual(result.output.findings.length, 0);
      } finally {
        await repo.cleanup();
      }
    });

    it("should detect multiple agent types", async () => {
      const repo = await createTestRepo({
        "src/claude.ts": `
import { Anthropic } from "@anthropic-ai/sdk";
`,
        "src/copilot.ts": `
// github.copilot extension
`,
        "src/codex.ts": `
// codex_session_log
`,
      });

      try {
        const result = await scanRepo({
          repo: repo.path,
          format: "json",
          schemaVersion: "1",
        });

        strictEqual(result.output.findings.length, 3);

        const agents = result.output.findings.map((f) => f.agent);
        deepEqual(agents.sort(), ["claude", "codex", "copilot"].sort());
      } finally {
        await repo.cleanup();
      }
    });

    it("should produce deterministic output", async () => {
      const repo = await createTestRepo({
        "src/test.ts": `
// Some line
// Another line
`,
      });

      try {
        // Run scan twice
        const result1 = await scanRepo({
          repo: repo.path,
          format: "json",
          schemaVersion: "1",
        });

        const result2 = await scanRepo({
          repo: repo.path,
          format: "json",
          schemaVersion: "1",
        });

        // Output should be identical (ignore generatedAt timestamp)
        const output1 = { ...result1.output, generatedAt: "fixed" };
        const output2 = { ...result2.output, generatedAt: "fixed" };
        deepEqual(output1, output2);
        strictEqual(result1.exitCode, result2.exitCode);
      } finally {
        await repo.cleanup();
      }
    });

    it("should validate format parameter", async () => {
      const repo = await createTestRepo({
        "README.md": "# Test",
      });

      try {
        try {
          await scanRepo({
            repo: repo.path,
            format: "invalid" as any,
            schemaVersion: "1",
          });
          throw new Error("Should have thrown");
        } catch (error) {
          if (error instanceof Error) {
            strictEqual(error.message, ScanError.InvalidFormat);
          }
        }
      } finally {
        await repo.cleanup();
      }
    });
  });
});
