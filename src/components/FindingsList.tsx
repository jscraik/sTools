import { useState } from "react"
import type { Finding } from "../types"
import { Button } from "./ui/Button"

interface FindingsListProps {
  findings: Finding[]
  selectedFinding: Finding | null
  onSelectFinding: (finding: Finding | null) => void
  focusedIndex: number
  filters: {
    severity: ("error" | "warning" | "info")[]
    agent: string[]
  }
  onFiltersChange: (filters: {
    severity: ("error" | "warning" | "info")[]
    agent: string[]
  }) => void
  totalCount: number
  onExport?: () => void
}

export function FindingsList({
  findings,
  selectedFinding,
  onSelectFinding,
  focusedIndex,
  filters,
  onFiltersChange,
  totalCount,
  onExport,
}: FindingsListProps) {
  const [sortBy, setSortBy] = useState<"severity" | "agent" | "file">("file")

  const sortedFindings = [...findings].sort((a, b) => {
    if (sortBy === "severity") {
      const order = { error: 0, warning: 1, info: 2 }
      return order[a.severity] - order[b.severity]
    }
    if (sortBy === "agent") {
      return a.agent.localeCompare(b.agent)
    }
    return a.file.localeCompare(b.file)
  })

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

  const clearFilters = () => {
    onFiltersChange({ severity: [], agent: [] })
  }

  const hasActiveFilters = filters.severity.length > 0 || filters.agent.length > 0
  const showingCount = findings.length
  const hiddenCount = totalCount - showingCount

  return (
    <div className="flex-1 flex flex-col border-r border-[var(--color-border)] min-w-0">
      {/* Toolbar */}
      <div className="p-4 border-b border-[var(--color-border)] flex items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as "severity" | "agent" | "file")}
            className="px-2 py-1 rounded text-sm bg-[var(--color-surface)] border border-[var(--color-border)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
          >
            <option value="file">Sort by File</option>
            <option value="severity">Sort by Severity</option>
            <option value="agent">Sort by Agent</option>
          </select>
          <span className="text-sm text-[var(--color-text-muted)]">
            {showingCount} of {totalCount}
          </span>
        </div>
        <div className="flex items-center gap-2">
          {hasActiveFilters && (
            <Button onClick={clearFilters} variant="secondary" className="text-sm px-3 py-1">
              Clear filters
            </Button>
          )}
          {onExport && findings.length > 0 && (
            <Button onClick={onExport} variant="secondary" className="text-sm px-3 py-1" title="Cmd+E">
              Export
            </Button>
          )}
        </div>
      </div>

      {/* Hidden count warning */}
      {hiddenCount > 0 && (
        <div className="px-4 py-2 bg-yellow-500/10 border-b border-yellow-500/20 text-yellow-700 text-sm">
          {hiddenCount} findings hidden by filters
        </div>
      )}

      {/* Empty State */}
      {findings.length === 0 && (
        <div className="flex-1 flex items-center justify-center p-6">
          <div className="text-center max-w-sm">
            {hasActiveFilters ? (
              <>
                <svg
                  className="w-12 h-12 mx-auto mb-4 text-[var(--color-text-muted)] opacity-50"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"
                  />
                </svg>
                <p className="text-[var(--color-text-muted)] mb-3">No findings match your filters</p>
                <button
                  onClick={clearFilters}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-md text-sm bg-[var(--color-primary)] text-white hover:bg-[var(--color-primary-hover)] transition-fast"
                >
                  Clear filters
                </button>
              </>
            ) : totalCount === 0 ? (
              <>
                <svg
                  className="w-12 h-12 mx-auto mb-4 text-[var(--color-success)] opacity-80 animate-checkmark"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <p className="text-[var(--color-text)] font-medium mb-1">No findings found</p>
                <p className="text-sm text-[var(--color-text-muted)]">
                  Scan completed successfully — everything looks good!
                </p>
              </>
            ) : (
              <>
                <svg
                  className="w-12 h-12 mx-auto mb-4 text-[var(--color-text-muted)] opacity-50"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M9.5 3H6.257a1.5 1.5 0 00-1.5 1.5v15a1.5 1.5 0 001.5 1.5h9.75a1.5 1.5 0 001.5-1.5V6.5"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M12 3v4.5m0 0l-2-2m2 2l2-2"
                  />
                </svg>
                <p className="text-[var(--color-text-muted)]">No findings</p>
              </>
            )}
          </div>
        </div>
      )}

      {/* Findings List */}
      <div className="flex-1 overflow-y-auto">
        <div className="divide-y divide-[var(--color-border)] stagger-children">
          {sortedFindings.map((finding, index) => {
            const isSelected = selectedFinding === finding
            const isFocused = focusedIndex === index

            return (
              <button
                key={`${finding.file}-${finding.line}-${index}`}
                onClick={() => onSelectFinding(finding)}
                style={{ animationDelay: `${Math.min(index * 30, 150)}ms` }}
                className={`w-full text-left px-4 py-3 animate-slide-in transition-fast ${
                  isSelected
                    ? "bg-[var(--color-background)] ring-1 ring-inset ring-[var(--color-primary)]"
                    : isFocused
                      ? "bg-[var(--color-border)]"
                      : "hover:bg-[var(--color-background)]"
                }`}
              >
              <div className="flex items-start gap-3">
                {/* Severity Badge */}
                <span
                  className={`shrink-0 px-2 py-0.5 rounded text-xs font-medium capitalize ${getSeverityColor(
                    finding.severity
                  )} bg-opacity-10`}
                >
                  {finding.severity}
                </span>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 text-xs text-[var(--color-text-muted)] mb-1">
                    <span className="font-mono">{finding.ruleID}</span>
                    <span>•</span>
                    <span className="capitalize">{finding.agent}</span>
                  </div>
                  <p className="text-sm truncate">{finding.message}</p>
                  <div className="flex items-center gap-2 text-xs text-[var(--color-text-muted)] mt-1 font-mono">
                    <span>{finding.file}</span>
                    {finding.line && <span>:{finding.line}</span>}
                  </div>
                </div>
              </div>
            </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
