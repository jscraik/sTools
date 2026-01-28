import Ajv from "ajv";
import type { ValidateFunction } from "ajv";
import type { ScanOutput } from "./types.js";
import { FINDINGS_SCHEMA_V1 } from "./schema.js";

/**
 * Schema validation result
 */
export interface ValidationResult {
  valid: boolean;
  errors?: string[];
}

/**
 * Validate scan output against JSON schema
 *
 * @param output - Scan output to validate
 * @returns Validation result with any errors
 */
export function validateOutput(output: ScanOutput): ValidationResult {
  const ajv = new Ajv({
    allErrors: true,
    strict: false,
    validateFormats: true,
  });

  // Add date-time format validator
  ajv.addFormat("date-time", {
    type: "string",
    validate: (dateTimeString: string) => {
      return !isNaN(Date.parse(dateTimeString));
    },
  });

  const validate = ajv.compile(FINDINGS_SCHEMA_V1);
  const valid = validate(output);

  if (valid) {
    return { valid: true };
  }

  const errors: string[] = [];
  if (validate.errors) {
    for (const error of validate.errors) {
      errors.push(`${error.instancePath}: ${error.message}`);
    }
  }

  return { valid: false, errors };
}

/**
 * Create a validator function for scan outputs
 */
export function createOutputValidator(): ValidateFunction {
  const ajv = new Ajv({
    allErrors: true,
    strict: false,
    validateFormats: true,
  });

  // Add date-time format validator
  ajv.addFormat("date-time", {
    type: "string",
    validate: (dateTimeString: string) => {
      return !isNaN(Date.parse(dateTimeString));
    },
  });

  return ajv.compile(FINDINGS_SCHEMA_V1);
}
