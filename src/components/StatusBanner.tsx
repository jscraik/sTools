import type { ScanResult, ScanOutput } from "../types"

interface StatusBannerProps {
  state: "idle" | "scanning" | "success" | "error"
  scanResult: ScanResult | null
  parsedOutput: ScanOutput | null
}

function getErrorAction(error: string): { message: string; action?: string } {
  if (error.includes("Repository path cannot be empty")) {
    return { message: "Please enter a repository path to scan." }
  }
  if (error.includes("does not exist")) {
    return {
      message: "The repository path doesn't exist.",
      action: "Check the path and try again.",
    }
  }
  if (error.includes("Failed to run scan") || error.includes("Failed to run sync-check")) {
    return {
      message: "Scan command failed.",
      action: "Make sure Node.js is installed and try again.",
    }
  }
  if (error.includes("Node.js")) {
    return {
      message: "Node.js not found.",
      action: "Install Node.js to use SkillsInspector.",
    }
  }
  if (error.includes("Failed to parse")) {
    return {
      message: "Failed to parse scan results.",
      action: "Try running the scan again.",
    }
  }
  return { message: error }
}

export function StatusBanner({ state, scanResult, parsedOutput }: StatusBannerProps) {
  if (state === "idle" || state === "scanning") {
    return (
      <div className="mx-6 mt-4">
        {state === "scanning" && (
          <div className="animate-fade-in px-4 py-3 rounded-md bg-[var(--color-surface)] border border-[var(--color-border)] flex items-center gap-3 shadow-sm">
            <div className="w-4 h-4 rounded-full border-2 border-[var(--color-primary)] border-t-transparent animate-spin" />
            <span className="text-sm">Scanning repository...</span>
          </div>
        )}
      </div>
    )
  }

  if (state === "error") {
    // Show detailed error if available, otherwise show scanResult.error
    const errorMessage = scanResult?.error || "An unknown error occurred"
    const errorInfo = getErrorAction(errorMessage)

    return (
      <div className="mx-6 mt-4">
        <div className="animate-fade-in px-4 py-3 rounded-md bg-[var(--color-critical-bg)] border border-[var(--color-critical)] text-[var(--color-critical)] shadow-sm">
          <div className="flex items-start gap-3">
            {/* Error icon */}
            <svg
              className="w-5 h-5 shrink-0 mt-0.5"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fillRule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                clipRule="evenodd"
              />
            </svg>
            <div className="flex-1 min-w-0">
              <p className="font-medium text-sm">Scan Error</p>
              <p className="text-sm mt-1">{errorInfo.message}</p>
              {errorInfo.action && (
                <p className="text-sm mt-2 opacity-80">{errorInfo.action}</p>
              )}
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (state === "success" && parsedOutput) {
    const { errors, warnings, findings, scanned } = parsedOutput

    return (
      <div className="mx-6 mt-4">
        <div
          className={`animate-fade-in px-4 py-3 rounded-md border shadow-sm ${
            errors > 0
              ? "bg-[var(--color-critical-bg)] border-[var(--color-critical)] text-[var(--color-critical)]"
              : warnings > 0
                ? "bg-[var(--color-warn-bg)] border-[var(--color-warn)] text-[var(--color-warn)]"
                : "bg-[var(--color-success-bg)] border-[var(--color-success)] text-[var(--color-success)]"
          }`}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4 text-sm">
              {errors === 0 && warnings === 0 && (
                <svg
                  className="w-5 h-5 animate-checkmark"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fillRule="evenodd"
                    d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                    clipRule="evenodd"
                  />
                </svg>
              )}
              <span className="font-medium">
                {errors > 0 ? "Issues Found" : warnings > 0 ? "Warnings Found" : "All Clear"}
              </span>
              <span className="text-[var(--color-text-muted)]">•</span>
              <span>{scanned} files scanned</span>
              <span className="text-[var(--color-text-muted)]">•</span>
              <span>{findings.length} findings</span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              {errors > 0 && <span className="font-medium">{errors} errors</span>}
              {warnings > 0 && <span className="font-medium">{warnings} warnings</span>}
            </div>
          </div>
        </div>
      </div>
    )
  }

  return null
}
