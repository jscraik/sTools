import { useState, useEffect } from "react"
import { Button } from "./ui/Button"
import { Separator } from "./ui/Separator"

const STORAGE_KEY = "skillsinspector:scan-roots"

interface ScanRoot {
  id: string
  path: string
  name: string
}

interface SidebarProps {
  onScan: () => void
  isScanning: boolean
  filters: {
    severity: ("error" | "warning" | "info")[]
    agent: string[]
  }
  onFiltersChange: (filters: {
    severity: ("error" | "warning" | "info")[]
    agent: string[]
  }) => void
  repoPath: string
  onRepoPathChange: (path: string) => void
}

function getRootName(path: string): string {
  // Extract the last directory component as the name
  const parts = path.replace(/\/$/, "").split("/")
  return parts[parts.length - 1] || path
}

export function Sidebar({
  onScan,
  isScanning,
  filters,
  onFiltersChange,
  repoPath,
  onRepoPathChange,
}: SidebarProps) {
  const [roots, setRoots] = useState<ScanRoot[]>([])
  const [showAddRoot, setShowAddRoot] = useState(false)

  // Load roots from localStorage on mount
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored) {
        const parsed = JSON.parse(stored) as ScanRoot[]
        setRoots(parsed)
      }
    } catch {
      // Ignore parse errors
    }
  }, [])

  // Save roots to localStorage when they change
  useEffect(() => {
    if (roots.length > 0) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(roots))
    } else {
      localStorage.removeItem(STORAGE_KEY)
    }
  }, [roots])

  const toggleSeverity = (severity: "error" | "warning" | "info") => {
    const newSeverity = filters.severity.includes(severity)
      ? filters.severity.filter((s) => s !== severity)
      : [...filters.severity, severity]
    onFiltersChange({ ...filters, severity: newSeverity })
  }

  const agents = ["codex", "claude", "copilot", "codexSkillManager"]

  const toggleAgent = (agent: string) => {
    const newAgent = filters.agent.includes(agent)
      ? filters.agent.filter((a) => a !== agent)
      : [...filters.agent, agent]
    onFiltersChange({ ...filters, agent: newAgent })
  }

  const handleAddRoot = () => {
    if (!repoPath.trim()) return

    // Check if root already exists
    if (roots.some((r) => r.path === repoPath)) {
      setShowAddRoot(false)
      return
    }

    const newRoot: ScanRoot = {
      id: Date.now().toString(),
      path: repoPath,
      name: getRootName(repoPath),
    }

    setRoots([...roots, newRoot])
    setShowAddRoot(false)
  }

  const handleRemoveRoot = (id: string) => {
    setRoots(roots.filter((r) => r.id !== id))
  }

  const handleSelectRoot = (path: string) => {
    onRepoPathChange(path)
  }

  return (
    <aside className="w-60 border-r border-[var(--color-border)] flex flex-col bg-[var(--color-surface)]">
      {/* Branding */}
      <div className="p-4 border-b border-[var(--color-border)]">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded bg-[var(--color-primary)] flex items-center justify-center text-white text-sm font-bold">
            SI
          </div>
          <div>
            <h2 className="font-semibold text-sm">SkillsInspector</h2>
            <p className="text-xs text-[var(--color-text-muted)]">v1.0.0</p>
          </div>
        </div>
      </div>

      {/* Analysis Section */}
      <div className="flex-1 overflow-y-auto">
        {/* Mode Selection */}
        <div className="p-4">
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-3">
            Analysis
          </h3>
          <nav className="space-y-1">
            <button
              className="w-full text-left px-3 py-2 rounded-md text-sm bg-[var(--color-primary)] text-white"
            >
              Validate
            </button>
            <button
              className="w-full text-left px-3 py-2 rounded-md text-sm text-[var(--color-text)] hover:bg-[var(--color-background)]"
              disabled
            >
              Sync-check
              <span className="ml-auto text-xs text-[var(--color-text-muted)]">Soon</span>
            </button>
          </nav>
        </div>

        <Separator />

        {/* Repository Path */}
        <div className="p-4">
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-3">
            Directory
          </h3>
          <input
            type="text"
            value={repoPath}
            onChange={(e) => onRepoPathChange(e.target.value)}
            placeholder="/path/to/scan"
            className="w-full px-3 py-2 rounded text-sm bg-[var(--color-background)] border border-[var(--color-border)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] font-mono text-xs"
          />
        </div>

        <Separator />

        {/* Actions */}
        <div className="p-4">
          <Button
            onClick={onScan}
            disabled={isScanning || !repoPath.trim()}
            variant="primary"
            className="w-full"
          >
            {isScanning ? "Scanning..." : "Run Scan"}
          </Button>
        </div>

        <Separator />

        {/* Filters */}
        <div className="p-4">
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-3">
            Filter by Severity
          </h3>
          <div className="space-y-2">
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input
                type="checkbox"
                checked={filters.severity.includes("error")}
                onChange={() => toggleSeverity("error")}
                className="rounded"
              />
              <span className="text-red-500">Error</span>
            </label>
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input
                type="checkbox"
                checked={filters.severity.includes("warning")}
                onChange={() => toggleSeverity("warning")}
                className="rounded"
              />
              <span className="text-yellow-600">Warning</span>
            </label>
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input
                type="checkbox"
                checked={filters.severity.includes("info")}
                onChange={() => toggleSeverity("info")}
                className="rounded"
              />
              <span className="text-blue-500">Info</span>
            </label>
          </div>
        </div>

        <Separator />

        {/* Agent Filter */}
        <div className="p-4">
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-3">
            Filter by Agent
          </h3>
          <div className="space-y-2">
            {agents.map((agent) => (
              <label key={agent} className="flex items-center gap-2 text-sm cursor-pointer">
                <input
                  type="checkbox"
                  checked={filters.agent.includes(agent)}
                  onChange={() => toggleAgent(agent)}
                  className="rounded"
                />
                <span className="capitalize">{agent}</span>
              </label>
            ))}
          </div>
        </div>

        <Separator />

        {/* Scan Roots */}
        <div className="p-4">
          <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-3">
            Scan Roots
          </h3>

          {roots.length > 0 && (
            <div className="space-y-1 mb-3">
              {roots.map((root) => (
                <div
                  key={root.id}
                  className="group flex items-center gap-1 px-2 py-1.5 rounded text-sm hover:bg-[var(--color-background)] transition-fast"
                >
                  <button
                    onClick={() => handleSelectRoot(root.path)}
                    className="flex-1 text-left truncate text-[var(--color-text)] hover:text-[var(--color-primary)]"
                    title={root.path}
                  >
                    {root.name}
                  </button>
                  <button
                    onClick={() => handleRemoveRoot(root.id)}
                    className="opacity-0 group-hover:opacity-100 text-[var(--color-text-muted)] hover:text-red-500 px-1 transition-fast"
                    title="Remove root"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          )}

          {showAddRoot ? (
            <div className="space-y-2">
              <p className="text-xs text-[var(--color-text-muted)]">
                Add current path to roots?
              </p>
              <div className="flex gap-2">
                <Button
                  onClick={handleAddRoot}
                  variant="primary"
                  className="flex-1 text-xs px-2 py-1"
                  disabled={!repoPath.trim()}
                >
                  Add
                </Button>
                <Button
                  onClick={() => setShowAddRoot(false)}
                  variant="ghost"
                  className="text-xs px-2 py-1"
                >
                  Cancel
                </Button>
              </div>
            </div>
          ) : (
            <button
              onClick={() => setShowAddRoot(true)}
              className="w-full px-3 py-2 rounded-md text-sm border border-dashed border-[var(--color-border)] text-[var(--color-text-muted)] hover:border-[var(--color-primary)] hover:text-[var(--color-primary)] transition-fast"
            >
              + Add Root
            </button>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="p-4 border-t border-[var(--color-border)]">
        <p className="text-xs text-[var(--color-text-muted)]">
          {roots.length} {roots.length === 1 ? "root" : "roots"} saved
        </p>
      </div>
    </aside>
  )
}
