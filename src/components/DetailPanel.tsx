import type { Finding } from "../types"
import { Button } from "./ui/Button"

interface DetailPanelProps {
  finding: Finding | null
}

export function DetailPanel({ finding }: DetailPanelProps) {
  if (!finding) {
    return (
      <div className="w-80 border-l border-[var(--color-border)] bg-[var(--color-surface)] p-6">
        <div className="h-full flex items-center justify-center text-center">
          <div>
            <p className="text-[var(--color-text-muted)] mb-2">Select a finding to view details</p>
            <p className="text-xs text-[var(--color-text-muted)]">
              Click on any finding in the list to see more information
            </p>
          </div>
        </div>
      </div>
    )
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case "error":
        return "text-red-500"
      case "warning":
        return "text-yellow-600"
      case "info":
        return "text-blue-500"
      default:
        return "text-[var(--color-text-muted)]"
    }
  }

  const getSeverityBg = (severity: string) => {
    switch (severity) {
      case "error":
        return "bg-red-500/10"
      case "warning":
        return "bg-yellow-500/10"
      case "info":
        return "bg-blue-500/10"
      default:
        return "bg-[var(--color-surface)]"
    }
  }

  return (
    <div className="w-80 border-l border-[var(--color-border)] bg-[var(--color-surface)] overflow-y-auto">
      {/* Header */}
      <div className="p-4 border-b border-[var(--color-border)]">
        <div className="flex items-center gap-2 mb-3">
          <span
            className={`px-2 py-1 rounded text-xs font-medium capitalize ${getSeverityColor(
              finding.severity
            )} ${getSeverityBg(finding.severity)}`}
          >
            {finding.severity}
          </span>
          <span className="text-xs text-[var(--color-text-muted)] font-mono">
            {finding.ruleID}
          </span>
        </div>
        <p className="text-sm">{finding.message}</p>
      </div>

      {/* Details */}
      <div className="p-4 space-y-4">
        {/* Agent */}
        <div>
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-1">
            Agent
          </h3>
          <p className="text-sm capitalize">{finding.agent}</p>
        </div>

        {/* Location */}
        <div>
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-1">
            Location
          </h3>
          <div className="text-sm font-mono bg-[var(--color-background)] px-2 py-1 rounded">
            {finding.file}
            {finding.line && `:${finding.line}`}
          </div>
        </div>

        {/* Rule ID */}
        <div>
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-1">
            Rule
          </h3>
          <code className="text-sm font-mono text-[var(--color-primary)]">
            {finding.ruleID}
          </code>
        </div>

        {/* Actions */}
        <div className="pt-4 border-t border-[var(--color-border)]">
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-3">
            Actions
          </h3>
          <div className="space-y-2">
            <Button variant="secondary" className="w-full text-sm" disabled>
              Copy Fix Command
            </Button>
            <p className="text-xs text-[var(--color-text-muted)] text-center">
              Fix commands are CLI-only in v1
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
