/**
 * Severity color utilities for consistent styling across components
 */

export type Severity = "error" | "warning" | "info";

/**
 * Get the text color class for a severity level
 * Uses CSS variables for theme consistency
 */
export function getSeverityColor(severity: string): string {
  switch (severity) {
    case "error":
      return "text-[var(--color-critical)]";
    case "warning":
      return "text-[var(--color-warn)]";
    case "info":
      return "text-blue-500";
    default:
      return "text-[var(--color-text-muted)]";
  }
}

/**
 * Get the background color class for a severity level
 */
export function getSeverityBg(severity: string): string {
  switch (severity) {
    case "error":
      return "bg-[var(--color-critical-bg)]";
    case "warning":
      return "bg-[var(--color-warn-bg)]";
    case "info":
      return "bg-blue-500/10";
    default:
      return "bg-[var(--color-surface)]";
  }
}

/**
 * Get both text and background classes for a severity level
 */
export function getSeverityStyles(severity: string): {
  text: string;
  bg: string;
} {
  return {
    text: getSeverityColor(severity),
    bg: getSeverityBg(severity),
  };
}
