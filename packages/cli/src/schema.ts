/**
 * JSON Schema for scan output v1
 * Matches sTools findings-schema.json
 */
export const FINDINGS_SCHEMA_V1 = {
  title: "skillsctl scan output",
  type: "object",
  required: ["schemaVersion", "toolVersion", "generatedAt", "scanned", "errors", "warnings", "findings"],
  properties: {
    schemaVersion: { type: "string", enum: ["1"] },
    toolVersion: { type: "string" },
    generatedAt: { type: "string", format: "date-time" },
    scanned: { type: "integer", minimum: 0 },
    errors: { type: "integer", minimum: 0 },
    warnings: { type: "integer", minimum: 0 },
    findings: {
      type: "array",
      items: {
        type: "object",
        required: ["ruleID", "severity", "agent", "file", "message"],
        properties: {
          ruleID: { type: "string" },
          severity: { type: "string", enum: ["error", "warning", "info"] },
          agent: { type: "string", enum: ["codex", "claude", "copilot", "codexSkillManager"] },
          file: { type: "string" },
          message: { type: "string" },
          line: { type: "integer", minimum: 1 },
          column: { type: "integer", minimum: 1 },
        },
        additionalProperties: false,
      },
    },
  },
  additionalProperties: false,
} as const;

/**
 * Current tool version
 */
export const TOOL_VERSION = "0.1.0";

/**
 * Current schema version
 */
export const SCHEMA_VERSION = "1";
