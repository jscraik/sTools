import type { Meta, StoryObj } from "@storybook/react-vite"
import { StatusBanner } from "./StatusBanner"
import type { ScanResult, ScanOutput } from "../types"

const meta: Meta<typeof StatusBanner> = {
  title: "Components/StatusBanner",
  component: StatusBanner,
  parameters: {
    layout: "padded",
  },
  tags: ["autodocs"],
}

export default meta
type Story = StoryObj<typeof StatusBanner>

const mockScanOutput = (overrides?: Partial<ScanOutput>): ScanOutput => ({
  schemaVersion: "1",
  toolVersion: "0.1.0",
  generatedAt: new Date().toISOString(),
  scanned: 42,
  errors: 0,
  warnings: 0,
  findings: [],
  ...overrides,
})

const mockScanResult = (overrides?: Partial<ScanResult>): ScanResult => ({
  success: true,
  output: JSON.stringify(mockScanOutput()),
  exit_code: 0,
  error: null,
  ...overrides,
})

export const Idle: Story = {
  args: {
    state: "idle",
    scanResult: null,
    parsedOutput: null,
  },
}

export const Scanning: Story = {
  args: {
    state: "scanning",
    scanResult: null,
    parsedOutput: null,
  },
}

export const SuccessNoFindings: Story = {
  args: {
    state: "success",
    scanResult: mockScanResult(),
    parsedOutput: mockScanOutput(),
  },
}

export const SuccessWithWarnings: Story = {
  args: {
    state: "success",
    scanResult: mockScanResult({ exit_code: 1 }),
    parsedOutput: mockScanOutput({
      warnings: 3,
      findings: [
        {
          ruleID: "CLAUDE-001",
          severity: "warning",
          agent: "claude",
          file: "src/utils.ts",
          message: "Possible API key exposure",
          line: 15,
        },
        {
          ruleID: "CODEX-003",
          severity: "warning",
          agent: "codex",
          file: "src/config.ts",
          message: "Codex config directory reference",
          line: 8,
        },
        {
          ruleID: "COPILOT-001",
          severity: "warning",
          agent: "copilot",
          file: "src/ai.ts",
          message: "GitHub Copilot API usage detected",
          line: 22,
        },
      ],
    }),
  },
}

export const SuccessWithErrors: Story = {
  args: {
    state: "success",
    scanResult: mockScanResult({ exit_code: 1 }),
    parsedOutput: mockScanOutput({
      errors: 2,
      warnings: 1,
      findings: [
        {
          ruleID: "CLAUDE-001",
          severity: "error",
          agent: "claude",
          file: "src/secrets.ts",
          message: "Anthropic API key exposed",
          line: 5,
        },
        {
          ruleID: "CODEX-001",
          severity: "error",
          agent: "codex",
          file: "src/logs.ts",
          message: "Codex session log detected",
          line: 12,
        },
        {
          ruleID: "CSM-002",
          severity: "warning",
          agent: "codexSkillManager",
          file: "src/skills.ts",
          message: "Skill file reference detected",
          line: 30,
        },
      ],
    }),
  },
}

export const ErrorState: Story = {
  args: {
    state: "error",
    scanResult: mockScanResult({
      success: false,
      exit_code: 2,
      error: "Repository path does not exist: /path/to/nonexistent",
    }),
    parsedOutput: null,
  },
}

export const ErrorWithAction: Story = {
  args: {
    state: "error",
    scanResult: mockScanResult({
      success: false,
      exit_code: 2,
      error: "Failed to run scan: Node.js not found",
    }),
    parsedOutput: null,
  },
}

export const StateMatrix: Story = {
  render: () => (
    <div className="space-y-6">
      <div>
        <p className="text-sm font-medium mb-2 text-[var(--color-text-muted)]">Scanning</p>
        <StatusBanner state="scanning" scanResult={null} parsedOutput={null} />
      </div>
      <div>
        <p className="text-sm font-medium mb-2 text-[var(--color-text-muted)]">Success (No findings)</p>
        <StatusBanner
          state="success"
          scanResult={mockScanResult()}
          parsedOutput={mockScanOutput()}
        />
      </div>
      <div>
        <p className="text-sm font-medium mb-2 text-[var(--color-text-muted)]">Warnings</p>
        <StatusBanner
          state="success"
          scanResult={mockScanResult({ exit_code: 1 })}
          parsedOutput={mockScanOutput({
            warnings: 2,
            findings: [
              { ruleID: "W-001", severity: "warning", agent: "codex", file: "test.ts", message: "Warning 1" },
              { ruleID: "W-002", severity: "warning", agent: "claude", file: "test2.ts", message: "Warning 2" },
            ],
          })}
        />
      </div>
      <div>
        <p className="text-sm font-medium mb-2 text-[var(--color-text-muted)]">Errors</p>
        <StatusBanner
          state="success"
          scanResult={mockScanResult({ exit_code: 1 })}
          parsedOutput={mockScanOutput({
            errors: 1,
            warnings: 1,
            findings: [
              { ruleID: "E-001", severity: "error", agent: "codex", file: "test.ts", message: "Error 1" },
              { ruleID: "W-001", severity: "warning", agent: "claude", file: "test2.ts", message: "Warning 1" },
            ],
          })}
        />
      </div>
      <div>
        <p className="text-sm font-medium mb-2 text-[var(--color-text-muted)]">Error State</p>
        <StatusBanner
          state="error"
          scanResult={mockScanResult({ success: false, exit_code: 2, error: "Path not found" })}
          parsedOutput={null}
        />
      </div>
    </div>
  ),
}
