import { useState, useMemo } from "react"
import type { Finding } from "../types"
import { Button } from "./ui/Button"
import { ContextMenu } from "./ui/ContextMenu"
import { getSeverityColor } from "../lib/severity"

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

  // Check for reduced motion preference
  const prefersReducedMotion = useMemo(() => {
    if (typeof window === "undefined") return false
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }, [])

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
              <ContextMenu
                key={`${finding.ruleID}-${finding.file}-${finding.line ?? 0}-${finding.message.slice(0, 20)}`}
                items={[
                  {
                    label: "Copy message",
                    shortcut: "⌘C",
                    onClick: () => navigator.clipboard.writeText(finding.message),
                  },
                  {
                    label: "Copy file path",
                    onClick: () => navigator.clipboard.writeText(`${finding.file}:${finding.line ?? 0}`),
                  },
                  {
                    label: "Copy rule ID",
                    onClick: () => navigator.clipboard.writeText(finding.ruleID),
                  },
                  { separator: true, onClick: () => {} },
                  {
                    label: finding.line 
                      ? `Open ${finding.file}:${finding.line}` 
                      : `Open ${finding.file}`,
                    onClick: () => {
                      // In a real app, this would open the file in the default editor
                      console.log("Open file:", finding.file, finding.line)
                    },
                  },
                ]}
              >
                <button
                  onClick={() => onSelectFinding(finding)}
                  style={{ 
                    animationDelay: prefersReducedMotion ? undefined : `${Math.min(index * 30, 150)}ms` 
                  }}
                  className={`group w-full text-left px-4 py-3 animate-slide-in transition-all duration-200 relative
                    ${isSelected
                      ? "bg-[var(--color-surface)] shadow-sm"
                      : isFocused
                        ? "bg-[var(--color-surface)]/50"
                        : "hover:bg-[var(--color-surface)] hover:shadow-sm hover:-translate-y-px"
                    }`}
                >
                  {/* Left indicator line */}
                  <div 
                    className={`absolute left-0 top-0 bottom-0 w-0.5 transition-all duration-200 ${
                      isSelected 
                        ? "bg-[var(--color-primary)]" 
                        : "bg-transparent group-hover:bg-[var(--color-primary)]/30"
                    }`} 
                  />
                  
                  <div className="flex items-start gap-3">
                    {/* Severity Badge */}
                    <span
                      className={`shrink-0 px-2 py-0.5 rounded text-xs font-medium capitalize ${getSeverityColor(
                        finding.severity
                      )} bg-opacity-10 transition-transform duration-200 ${
                        isSelected ? "scale-105" : "group-hover:scale-105"
                      }`}
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
                      <p className={`text-sm truncate transition-colors duration-200 ${
                        isSelected ? "text-[var(--color-text)]" : "text-[var(--color-text-muted)] group-hover:text-[var(--color-text)]"
                      }`}>
                        {finding.message}
                      </p>
                      <div className="flex items-center gap-2 text-xs text-[var(--color-text-muted)] mt-1 font-mono">
                        <span>{finding.file}</span>
                        {finding.line && <span>:{finding.line}</span>}
                      </div>
                    </div>
                  </div>
                </button>
              </ContextMenu>
            )
          })}
        </div>
      </div>
    </div>
  )
}
