import type { Meta, StoryObj } from "@storybook/react-vite"
import { useState } from "react"
import { FindingsList } from "./FindingsList"
import type { Finding } from "../types"

const meta: Meta<typeof FindingsList> = {
  title: "Components/FindingsList",
  component: FindingsList,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
}

export default meta
type Story = StoryObj<typeof FindingsList>

const mockFindings: Finding[] = [
  {
    ruleID: "CLAUDE-001",
    severity: "error",
    agent: "claude",
    file: "src/utils/api.ts",
    message: "Possible Anthropic API key exposure",
    line: 15,
    column: 12,
  },
  {
    ruleID: "CODEX-003",
    severity: "warning",
    agent: "codex",
    file: "src/config/settings.ts",
    message: "Codex configuration directory reference",
    line: 8,
  },
  {
    ruleID: "COPILOT-001",
    severity: "info",
    agent: "copilot",
    file: "src/ai/integration.ts",
    message: "GitHub Copilot API usage detected",
    line: 22,
  },
  {
    ruleID: "CSM-002",
    severity: "error",
    agent: "codexSkillManager",
    file: "src/skills/manager.ts",
    message: "Skill file reference detected",
    line: 45,
  },
  {
    ruleID: "CLAUDE-002",
    severity: "warning",
    agent: "claude",
    file: "src/auth/claude.ts",
    message: "Claude API key in environment variable",
    line: 5,
  },
]

const defaultFilters = {
  severity: [] as ("error" | "warning" | "info")[],
  agent: [] as string[],
}

export const Empty: Story = {
  args: {
    findings: [],
    selectedFinding: null,
    onSelectFinding: () => {},
    focusedIndex: -1,
    filters: defaultFilters,
    onFiltersChange: () => {},
    totalCount: 0,
  },
}

export const WithFindings: Story = {
  render: () => {
    const [selected, setSelected] = useState<Finding | null>(null)
    return (
      <div className="h-96 w-96 border border-[var(--color-border)] rounded-lg overflow-hidden">
        <FindingsList
          findings={mockFindings}
          selectedFinding={selected}
          onSelectFinding={setSelected}
          focusedIndex={-1}
          filters={defaultFilters}
          onFiltersChange={() => {}}
          totalCount={mockFindings.length}
        />
      </div>
    )
  },
}

export const WithSelection: Story = {
  render: () => {
    const [selected, setSelected] = useState<Finding | null>(mockFindings[0])
    return (
      <div className="h-96 w-96 border border-[var(--color-border)] rounded-lg overflow-hidden">
        <FindingsList
          findings={mockFindings}
          selectedFinding={selected}
          onSelectFinding={setSelected}
          focusedIndex={0}
          filters={defaultFilters}
          onFiltersChange={() => {}}
          totalCount={mockFindings.length}
        />
      </div>
    )
  },
}

export const WithActiveFilters: Story = {
  render: () => {
    const [filters, setFilters] = useState({
      severity: ["error"] as ("error" | "warning" | "info")[],
      agent: [] as string[],
    })
    const filtered = mockFindings.filter((f) => filters.severity.includes(f.severity))
    return (
      <div className="h-96 w-96 border border-[var(--color-border)] rounded-lg overflow-hidden">
        <FindingsList
          findings={filtered}
          selectedFinding={null}
          onSelectFinding={() => {}}
          focusedIndex={-1}
          filters={filters}
          onFiltersChange={setFilters}
          totalCount={mockFindings.length}
        />
      </div>
    )
  },
}

export const EmptyWithFilters: Story = {
  args: {
    findings: [],
    selectedFinding: null,
    onSelectFinding: () => {},
    focusedIndex: -1,
    filters: { severity: ["error"], agent: [] },
    onFiltersChange: () => {},
    totalCount: 5,
  },
}

export const WithExport: Story = {
  render: () => {
    const [selected, setSelected] = useState<Finding | null>(null)
    return (
      <div className="h-96 w-96 border border-[var(--color-border)] rounded-lg overflow-hidden">
        <FindingsList
          findings={mockFindings}
          selectedFinding={selected}
          onSelectFinding={setSelected}
          focusedIndex={-1}
          filters={defaultFilters}
          onFiltersChange={() => {}}
          totalCount={mockFindings.length}
          onExport={() => alert("Export clicked!")}
        />
      </div>
    )
  },
}

export const ManyFindings: Story = {
  render: () => {
    const manyFindings: Finding[] = Array.from({ length: 20 }, (_, i) => ({
      ruleID: `RULE-${String(i + 1).padStart(3, "0")}`,
      severity: i % 3 === 0 ? "error" : i % 3 === 1 ? "warning" : "info",
      agent: ["claude", "codex", "copilot", "codexSkillManager"][i % 4],
      file: `src/components/${["Button", "Input", "Card", "Modal"][i % 4]}.tsx`,
      message: `Sample finding message ${i + 1} with some additional context`,
      line: (i + 1) * 10,
    }))
    return (
      <div className="h-96 w-96 border border-[var(--color-border)] rounded-lg overflow-hidden">
        <FindingsList
          findings={manyFindings}
          selectedFinding={null}
          onSelectFinding={() => {}}
          focusedIndex={-1}
          filters={defaultFilters}
          onFiltersChange={() => {}}
          totalCount={manyFindings.length}
        />
      </div>
    )
  },
}

export const SeverityColors: Story = {
  render: () => {
    const findings: Finding[] = [
      { ruleID: "E-001", severity: "error", agent: "claude", file: "error.ts", message: "Error severity", line: 1 },
      { ruleID: "W-001", severity: "warning", agent: "codex", file: "warning.ts", message: "Warning severity", line: 2 },
      { ruleID: "I-001", severity: "info", agent: "copilot", file: "info.ts", message: "Info severity", line: 3 },
    ]
    return (
      <div className="h-64 w-96 border border-[var(--color-border)] rounded-lg overflow-hidden">
        <FindingsList
          findings={findings}
          selectedFinding={null}
          onSelectFinding={() => {}}
          focusedIndex={-1}
          filters={defaultFilters}
          onFiltersChange={() => {}}
          totalCount={findings.length}
        />
      </div>
    )
  },
}
