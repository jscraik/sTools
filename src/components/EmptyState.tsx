interface EmptyStateProps {
  onStartScan?: () => void
  hasRepoPath?: boolean
}

export function EmptyState({ onStartScan, hasRepoPath }: EmptyStateProps) {
  return (
    <div className="w-full h-full flex items-center justify-center p-6 overflow-auto">
      <div className="text-center max-w-sm w-full animate-fade-in">
        {/* Visual illustration */}
        <div className="relative w-24 h-24 mx-auto mb-6">
          {/* Background glow */}
          <div className="absolute inset-0 bg-[var(--color-primary)] opacity-10 blur-2xl rounded-full" />
          
          {/* Search icon with animated elements */}
          <svg
            className="relative w-full h-full text-[var(--color-primary)]"
            viewBox="0 0 96 96"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            {/* Folder base */}
            <rect
              x="20"
              y="32"
              width="56"
              height="40"
              rx="6"
              stroke="currentColor"
              strokeWidth="2"
              fill="var(--color-surface)"
              className="animate-slide-in"
              style={{ animationDelay: "100ms" }}
            />
            {/* Folder tab */}
            <path
              d="M20 38V34C20 30.6863 22.6863 28 26 28H38L44 32H70C73.3137 32 76 34.6863 76 38V38"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              fill="var(--color-surface)"
              className="animate-slide-in"
              style={{ animationDelay: "50ms" }}
            />
            {/* Magnifying glass */}
            <g className="animate-slide-in" style={{ animationDelay: "200ms" }}>
              <circle
                cx="44"
                cy="52"
                r="12"
                stroke="currentColor"
                strokeWidth="2.5"
              />
              <line
                x1="52.5"
                y1="60.5"
                x2="62"
                y2="70"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
              />
            </g>
            {/* Code brackets decoration */}
            <g 
              className="text-[var(--color-text-muted)] opacity-50"
              style={{ animationDelay: "300ms" }}
            >
              <text x="28" y="54" fontSize="10" fontFamily="monospace">{'{'}</text>
              <text x="54" y="54" fontSize="10" fontFamily="monospace">{'}'}</text>
            </g>
          </svg>
        </div>

        {/* Title */}
        <h2 className="text-lg font-semibold text-[var(--color-text)] mb-2">
          Ready to scan
        </h2>

        {/* Description */}
        <p className="text-[var(--color-text-muted)] mb-6 text-sm leading-relaxed">
          Enter a repository path in the sidebar and click "Run Scan" to analyze for AI agent usage patterns.
        </p>

        {/* Primary CTA - only show if repo path is set */}
        {hasRepoPath && onStartScan && (
          <button
            onClick={onStartScan}
            className="mb-8 px-6 py-2.5 bg-[var(--color-primary)] text-white rounded-md text-sm font-medium
              hover:bg-[var(--color-primary-hover)] active:scale-[0.98] transition-fast shadow-sm
              hover:shadow-md"
          >
            Run Scan Now
          </button>
        )}

        {/* Keyboard shortcuts grid */}
        <div className="inline-flex flex-col items-start gap-2 text-xs text-[var(--color-text-muted)] bg-[var(--color-surface)] px-4 py-3 rounded-lg border border-[var(--color-border)]">
          <p className="font-medium text-[var(--color-text)] mb-1">Keyboard shortcuts</p>
          <div className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 items-center">
            <kbd className="px-1.5 py-0.5 rounded bg-[var(--color-background)] border border-[var(--color-border)] font-mono text-[10px]">
              Cmd+R
            </kbd>
            <span>Run scan</span>
            <kbd className="px-1.5 py-0.5 rounded bg-[var(--color-background)] border border-[var(--color-border)] font-mono text-[10px]">
              ↑↓
            </kbd>
            <span>Navigate findings</span>
            <kbd className="px-1.5 py-0.5 rounded bg-[var(--color-background)] border border-[var(--color-border)] font-mono text-[10px]">
              Enter
            </kbd>
            <span>Select finding</span>
            <kbd className="px-1.5 py-0.5 rounded bg-[var(--color-background)] border border-[var(--color-border)] font-mono text-[10px]">
              Esc
            </kbd>
            <span>Clear selection</span>
          </div>
        </div>
      </div>
    </div>
  )
}
