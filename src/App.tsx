import { useState, useEffect, useCallback } from "react"
import { invoke } from "@tauri-apps/api/core"
import type { ScanResult, ScanOptions, ScanOutput, Finding } from "./types"
import { Sidebar } from "./components/Sidebar"
import { FindingsList } from "./components/FindingsList"
import { DetailPanel } from "./components/DetailPanel"
import { StatusBanner } from "./components/StatusBanner"

type ScanState = "idle" | "scanning" | "success" | "error"

function App() {
  const [repoPath, setRepoPath] = useState("")
  const [scanState, setScanState] = useState<ScanState>("idle")
  const [scanResult, setScanResult] = useState<ScanResult | null>(null)
  const [parsedOutput, setParsedOutput] = useState<ScanOutput | null>(null)
  const [selectedFinding, setSelectedFinding] = useState<Finding | null>(null)
  const [focusedIndex, setFocusedIndex] = useState<number>(-1)
  const [filters, setFilters] = useState<{
    severity: ("error" | "warning" | "info")[]
    agent: string[]
  }>({ severity: [], agent: [] })

  const handleScan = async () => {
    if (!repoPath.trim()) {
      setScanState("error")
      setScanResult({
        success: false,
        output: "",
        exit_code: 1,
        error: "Please enter a repository path",
      })
      return
    }

    setScanState("scanning")
    setSelectedFinding(null)
    setParsedOutput(null)

    try {
      const options: ScanOptions = {
        repo: repoPath,
        format: "json",
      }

      const result = await invoke<ScanResult>("run_scan", { options })
      setScanResult(result)

      // Try to parse JSON output
      if (result.success && result.output) {
        try {
          const parsed = JSON.parse(result.output) as ScanOutput
          setParsedOutput(parsed)
          setScanState("success")
        } catch (parseErr) {
          // Output isn't JSON or parsing failed
          setScanState("error")
          setScanResult({
            ...result,
            error: `Failed to parse scan output as JSON: ${parseErr}`,
          })
        }
      } else {
        setScanState(result.success ? "success" : "error")
      }
    } catch (err) {
      setScanState("error")
      setScanResult({
        success: false,
        output: "",
        exit_code: 1,
        error: err instanceof Error ? err.message : String(err),
      })
    }
  }

  const filteredFindings = parsedOutput?.findings?.filter((finding) => {
    if (filters.severity.length > 0 && !filters.severity.includes(finding.severity)) {
      return false
    }
    if (filters.agent.length > 0 && !filters.agent.includes(finding.agent)) {
      return false
    }
    return true
  }) ?? []

  // Export findings as JSON
  const handleExport = useCallback(() => {
    if (!parsedOutput) return

    const exportData = {
      scanOutput: parsedOutput,
      filteredFindings,
      exportedAt: new Date().toISOString(),
    }

    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: "application/json",
    })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `skillsinspector-scan-${new Date().toISOString().split("T")[0]}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }, [parsedOutput, filteredFindings])

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore if typing in an input
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        return
      }

      // Cmd+R / Ctrl+R - Run scan
      if ((e.metaKey || e.ctrlKey) && e.key === "r") {
        e.preventDefault()
        if (scanState !== "scanning" && repoPath.trim()) {
          handleScan()
        }
        return
      }

      // Cmd+E / Ctrl+E - Export findings
      if ((e.metaKey || e.ctrlKey) && e.key === "e") {
        e.preventDefault()
        handleExport()
        return
      }

      // Arrow keys - Navigate findings
      if (filteredFindings.length > 0) {
        if (e.key === "ArrowDown" || e.key === "j") {
          e.preventDefault()
          setFocusedIndex((prev) => {
            const next = Math.min(prev + 1, filteredFindings.length - 1)
            setSelectedFinding(filteredFindings[next])
            return next
          })
        } else if (e.key === "ArrowUp" || e.key === "k") {
          e.preventDefault()
          setFocusedIndex((prev) => {
            const next = Math.max(prev - 1, 0)
            setSelectedFinding(filteredFindings[next])
            return next
          })
        } else if (e.key === "Enter" && focusedIndex >= 0) {
          e.preventDefault()
          setSelectedFinding(filteredFindings[focusedIndex])
        }
      }

      // Esc - Clear selection
      if (e.key === "Escape") {
        e.preventDefault()
        setSelectedFinding(null)
        setFocusedIndex(-1)
      }
    }

    window.addEventListener("keydown", handleKeyDown)
    return () => window.removeEventListener("keydown", handleKeyDown)
  }, [scanState, repoPath, filteredFindings, focusedIndex, handleScan, handleExport])

  // Update focused index when selected finding changes externally
  useEffect(() => {
    if (selectedFinding) {
      const index = filteredFindings.findIndex((f) => f === selectedFinding)
      if (index >= 0) {
        setFocusedIndex(index)
      }
    } else {
      setFocusedIndex(-1)
    }
  }, [selectedFinding, filteredFindings])

  return (
    <div className="flex h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      {/* Sidebar */}
      <Sidebar
        onScan={handleScan}
        isScanning={scanState === "scanning"}
        filters={filters}
        onFiltersChange={setFilters}
        repoPath={repoPath}
        onRepoPathChange={setRepoPath}
      />

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Header */}
        <header className="border-b border-[var(--color-border)] px-6 py-4">
          <h1 className="text-xl font-semibold">SkillsInspector</h1>
          <p className="text-sm text-[var(--color-text-muted)]">
            Scan repositories for AI agent usage patterns
          </p>
        </header>

        {/* Status Banner */}
        <StatusBanner
          state={scanState}
          scanResult={scanResult}
          parsedOutput={parsedOutput}
        />

        {/* Empty State (when no results) */}
        {scanState === "idle" && (
          <div className="flex-1 flex items-center justify-center p-6">
            <div className="text-center">
              <p className="text-[var(--color-text-muted)] mb-4">
                Enter a directory path in the sidebar and click "Run Scan" to begin
              </p>
              <div className="text-xs text-[var(--color-text-muted)] space-y-1">
                <p className="font-medium mb-2">Keyboard shortcuts:</p>
                <p><kbd className="px-1.5 py-0.5 rounded bg-[var(--color-surface)] border border-[var(--color-border)] font-mono">Cmd+R</kbd> Run scan</p>
                <p><kbd className="px-1.5 py-0.5 rounded bg-[var(--color-surface)] border border-[var(--color-border)] font-mono">↑↓</kbd> Navigate findings</p>
                <p><kbd className="px-1.5 py-0.5 rounded bg-[var(--color-surface)] border border-[var(--color-border)] font-mono">Enter</kbd> Select finding</p>
                <p><kbd className="px-1.5 py-0.5 rounded bg-[var(--color-surface)] border border-[var(--color-border)] font-mono">Esc</kbd> Clear selection</p>
                <p><kbd className="px-1.5 py-0.5 rounded bg-[var(--color-surface)] border border-[var(--color-border)] font-mono">Cmd+E</kbd> Export findings</p>
              </div>
            </div>
          </div>
        )}

        {/* Results Area */}
        {(scanState === "success" || scanState === "error") && (
          <div className="flex-1 flex overflow-hidden">
            {/* Findings List */}
            <FindingsList
              findings={filteredFindings}
              selectedFinding={selectedFinding}
              onSelectFinding={setSelectedFinding}
              focusedIndex={focusedIndex}
              filters={filters}
              onFiltersChange={setFilters}
              totalCount={parsedOutput?.findings?.length ?? 0}
              onExport={handleExport}
            />

            {/* Detail Panel */}
            <DetailPanel finding={selectedFinding} />
          </div>
        )}
      </div>
    </div>
  )
}

export default App
