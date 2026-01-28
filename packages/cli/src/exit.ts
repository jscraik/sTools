/**
 * Exit codes matching sTools behavior
 */
export const EXIT_CODES = {
  Success: 0,
  ErrorsFound: 1,
  FatalError: 2,
} as const;

export type ExitCode = (typeof EXIT_CODES)[keyof typeof EXIT_CODES];
