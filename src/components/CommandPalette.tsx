import { useState, useEffect, useRef, useCallback, useMemo } from "react"
import type { Finding } from "../types"

interface CommandPaletteProps {
  isOpen: boolean
  onClose: () => void
  findings: Finding[]
  onSelectFinding: (finding: Finding) => void
  onRunScan: () => void
  onRunSyncCheck: () => void
  onExport: () => void
  mode: "validate" | "sync-check"
  onChangeMode: (mode: "validate" | "sync-check") => void
}

interface Command {
  id: string
  title: string
  subtitle?: string
  shortcut?: string
  icon: React.ReactNode
  action: () => void
  keywords?: string[]
}

export function CommandPalette({
  isOpen,
  onClose,
  findings,
  onSelectFinding,
  onRunScan,
  onRunSyncCheck,
  onExport,
  mode,
  onChangeMode,
}: CommandPaletteProps) {
  const [search, setSearch] = useState("")
  const [selectedIndex, setSelectedIndex] = useState(0)
  const inputRef = useRef<HTMLInputElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  // Build command list
  const commands = useMemo<Command[]>(() => {
    const cmds: Command[] = [
      {
        id: "scan",
        title: "Run Scan",
        subtitle: mode === "validate" ? "Current mode" : "Switch to scan mode",
        shortcut: "⌘R",
        icon: (
          <svg className="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clipRule="evenodd" />
          </svg>
        ),
        action: () => {
          onRunScan()
          onClose()
        },
        keywords: ["scan", "run", "start", "analyze"],
      },
      {
        id: "sync-check",
        title: "Run Sync Check",
        subtitle: mode === "sync-check" ? "Current mode" : "Switch to sync-check mode",
        shortcut: "⌘R",
        icon: (
          <svg className="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clipRule="evenodd" />
          </svg>
        ),
        action: () => {
          onRunSyncCheck()
          onClose()
        },
        keywords: ["sync", "check", "compare", "validate"],
      },
      {
        id: "export",
        title: "Export Findings",
        subtitle: findings.length > 0 ? `${findings.length} findings` : "No findings to export",
        shortcut: "⌘E",
        icon: (
          <svg className="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        ),
        action: () => {
          onExport()
          onClose()
        },
        keywords: ["export", "save", "download", "json"],
      },
      {
        id: "switch-mode",
        title: mode === "validate" ? "Switch to Sync-check Mode" : "Switch to Validate Mode",
        subtitle: `Currently in ${mode} mode`,
        icon: (
          <svg className="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
            <path d="M5 4a2 2 0 012-2h6a2 2 0 012 2v14l-5-2.5L5 18V4z" />
          </svg>
        ),
        action: () => {
          onChangeMode(mode === "validate" ? "sync-check" : "validate")
          onClose()
        },
        keywords: ["mode", "switch", "validate", "sync"],
      },
    ]

    // Add findings as commands
    findings.slice(0, 10).forEach((finding, index) => {
      cmds.push({
        id: `finding-${index}`,
        title: finding.message.slice(0, 50) + (finding.message.length > 50 ? "..." : ""),
        subtitle: `${finding.file}:${finding.line ?? 0} • ${finding.ruleID}`,
        icon: (
          <span className={`w-2 h-2 rounded-full ${
            finding.severity === "error" ? "bg-red-500" :
            finding.severity === "warning" ? "bg-yellow-500" : "bg-blue-500"
          }`} />
        ),
        action: () => {
          onSelectFinding(finding)
          onClose()
        },
        keywords: [finding.ruleID, finding.file, finding.agent, finding.severity],
      })
    })

    return cmds
  }, [findings, mode, onChangeMode, onClose, onExport, onRunScan, onRunSyncCheck, onSelectFinding])

  // Filter commands by search
  const filteredCommands = useMemo(() => {
    if (!search.trim()) return commands
    const query = search.toLowerCase()
    return commands.filter(cmd => 
      cmd.title.toLowerCase().includes(query) ||
      cmd.subtitle?.toLowerCase().includes(query) ||
      cmd.keywords?.some(k => k.toLowerCase().includes(query))
    )
  }, [commands, search])

  // Reset selection when search changes
  useEffect(() => {
    setSelectedIndex(0)
  }, [search])

  // Focus input when opened
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50)
    } else {
      setSearch("")
      setSelectedIndex(0)
    }
  }, [isOpen])

  // Handle keyboard navigation
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!isOpen) return

    switch (e.key) {
      case "ArrowDown":
        e.preventDefault()
        setSelectedIndex(i => Math.min(i + 1, filteredCommands.length - 1))
        break
      case "ArrowUp":
        e.preventDefault()
        setSelectedIndex(i => Math.max(i - 1, 0))
        break
      case "Enter":
        e.preventDefault()
        if (filteredCommands[selectedIndex]) {
          filteredCommands[selectedIndex].action()
        }
        break
      case "Escape":
        e.preventDefault()
        onClose()
        break
    }
  }, [isOpen, filteredCommands, selectedIndex, onClose])

  // Scroll selected into view
  useEffect(() => {
    const element = listRef.current?.children[selectedIndex] as HTMLElement
    if (element) {
      element.scrollIntoView({ block: "nearest" })
    }
  }, [selectedIndex])

  if (!isOpen) return null

  return (
    <div 
      className="fixed inset-0 z-50 flex items-start justify-center pt-[20vh] animate-fade-in"
      onClick={onClose}
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" />
      
      {/* Modal */}
      <div 
        className="relative w-full max-w-2xl mx-4 bg-[var(--color-surface)] rounded-xl shadow-2xl border border-[var(--color-border)] overflow-hidden animate-slide-in-up"
        onClick={e => e.stopPropagation()}
      >
        {/* Search input */}
        <div className="flex items-center gap-3 px-4 py-4 border-b border-[var(--color-border)]">
          <svg className="w-5 h-5 text-[var(--color-text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            ref={inputRef}
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search commands or findings..."
            className="flex-1 bg-transparent text-lg outline-none placeholder:text-[var(--color-text-muted)]"
          />
          <kbd className="hidden sm:inline-block px-2 py-1 text-xs bg-[var(--color-background)] border border-[var(--color-border)] rounded">
            ESC
          </kbd>
        </div>

        {/* Command list */}
        <div ref={listRef} className="max-h-[50vh] overflow-y-auto py-2">
          {filteredCommands.length === 0 ? (
            <div className="px-4 py-8 text-center text-[var(--color-text-muted)]">
              <p>No commands found</p>
              <p className="text-sm mt-1">Try a different search term</p>
            </div>
          ) : (
            filteredCommands.map((cmd, index) => (
              <button
                key={cmd.id}
                onClick={cmd.action}
                onMouseEnter={() => setSelectedIndex(index)}
                className={`w-full px-4 py-3 flex items-center gap-3 text-left transition-colors duration-100
                  ${index === selectedIndex 
                    ? "bg-[var(--color-primary)] text-white" 
                    : "hover:bg-[var(--color-background)]"
                  }`}
              >
                <span className={index === selectedIndex ? "text-white" : "text-[var(--color-text-muted)]"}>
                  {cmd.icon}
                </span>
                <div className="flex-1 min-w-0">
                  <p className="font-medium truncate">{cmd.title}</p>
                  {cmd.subtitle && (
                    <p className={`text-sm truncate ${
                      index === selectedIndex ? "text-white/80" : "text-[var(--color-text-muted)]"
                    }`}>
                      {cmd.subtitle}
                    </p>
                  )}
                </div>
                {cmd.shortcut && (
                  <kbd className={`hidden sm:inline-block px-2 py-0.5 text-xs rounded ${
                    index === selectedIndex 
                      ? "bg-white/20 text-white" 
                      : "bg-[var(--color-background)] border border-[var(--color-border)]"
                  }`}>
                    {cmd.shortcut}
                  </kbd>
                )}
              </button>
            ))
          )}
        </div>

        {/* Footer */}
        <div className="px-4 py-2 border-t border-[var(--color-border)] bg-[var(--color-background)] text-xs text-[var(--color-text-muted)] flex items-center justify-between">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-1">
              <kbd className="px-1.5 py-0.5 bg-[var(--color-surface)] border border-[var(--color-border)] rounded">↑↓</kbd>
              <span>Navigate</span>
            </span>
            <span className="flex items-center gap-1">
              <kbd className="px-1.5 py-0.5 bg-[var(--color-surface)] border border-[var(--color-border)] rounded">↵</kbd>
              <span>Select</span>
            </span>
          </div>
          <span>{filteredCommands.length} commands</span>
        </div>
      </div>
    </div>
  )
}
