/**
 * Tests for validator.ts
 */

import { describe, it } from "node:test";
import { strictEqual, deepEqual } from "node:assert";
import { validateOutput, createOutputValidator } from "../dist/validator.js";
import type { ScanOutput } from "../dist/types.js";

describe("validator", () => {
  describe("validateOutput", () => {
    const validOutput: ScanOutput = {
      schemaVersion: "1",
      toolVersion: "0.1.0",
      generatedAt: "2024-01-27T00:00:00.000Z",
      scanned: 10,
      errors: 2,
      warnings: 1,
      findings: [
        {
          ruleID: "CLAUDE-001",
          severity: "error",
          agent: "claude",
          file: "test.ts",
          message: "Test finding",
          line: 10,
        },
      ],
    };

    it("should validate correct output", () => {
      const result = validateOutput(validOutput);

      strictEqual(result.valid, true);
      deepEqual(result.errors, undefined);
    });

    it("should reject output with wrong schema version", () => {
      const invalidOutput = {
        ...validOutput,
        schemaVersion: "2" as any,
      };

      const result = validateOutput(invalidOutput);

      strictEqual(result.valid, false);
      strictEqual(result.errors && result.errors.length > 0, true);
    });

    it("should reject output with missing required fields", () => {
      const incompleteOutput = {
        schemaVersion: "1",
        toolVersion: "0.1.0",
        generatedAt: "2024-01-27T00:00:00.000Z",
        scanned: 10,
        errors: 0,
        warnings: 0,
        // Missing findings field
      } as any;

      const result = validateOutput(incompleteOutput);

      strictEqual(result.valid, false);
    });

    it("should reject output with invalid severity", () => {
      const invalidSeverityOutput = {
        ...validOutput,
        findings: [
          {
            ruleID: "TEST-001",
            severity: "critical" as any,
            agent: "claude",
            file: "test.ts",
            message: "Test",
          },
        ],
      };

      const result = validateOutput(invalidSeverityOutput);

      strictEqual(result.valid, false);
    });

    it("should reject output with invalid agent", () => {
      const invalidAgentOutput = {
        ...validOutput,
        findings: [
          {
            ruleID: "TEST-001",
            severity: "error",
            agent: "unknown" as any,
            file: "test.ts",
            message: "Test",
          },
        ],
      };

      const result = validateOutput(invalidAgentOutput);

      strictEqual(result.valid, false);
    });

    it("should reject output with invalid date-time format", () => {
      const invalidDateOutput = {
        ...validOutput,
        generatedAt: "not-a-date" as any,
      };

      const result = validateOutput(invalidDateOutput);

      strictEqual(result.valid, false);
    });
  });

  describe("createOutputValidator", () => {
    it("should create a reusable validator function", () => {
      const validator = createOutputValidator();

      const validOutput: ScanOutput = {
        schemaVersion: "1",
        toolVersion: "0.1.0",
        generatedAt: new Date().toISOString(),
        scanned: 0,
        errors: 0,
        warnings: 0,
        findings: [],
      };

      strictEqual(validator(validOutput), true);

      const invalidOutput = {
        ...validOutput,
        schemaVersion: "2" as any,
      };

      strictEqual(validator(invalidOutput), false);
    });

    it("should allow multiple validations with same validator", () => {
      const validator = createOutputValidator();

      const validOutput: ScanOutput = {
        schemaVersion: "1",
        toolVersion: "0.1.0",
        generatedAt: new Date().toISOString(),
        scanned: 0,
        errors: 0,
        warnings: 0,
        findings: [],
      };

      // Validate multiple times
      strictEqual(validator(validOutput), true);
      strictEqual(validator(validOutput), true);
      strictEqual(validator(validOutput), true);
    });
  });
});
