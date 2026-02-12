import type { Meta, StoryObj } from "@storybook/react-vite"
import { DetailPanel } from "./DetailPanel"
import type { Finding } from "../types"

const meta: Meta<typeof DetailPanel> = {
  title: "Components/DetailPanel",
  component: DetailPanel,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
}

export default meta
type Story = StoryObj<typeof DetailPanel>

const mockFinding = (overrides?: Partial<Finding>): Finding => ({
  ruleID: "CLAUDE-001",
  severity: "error",
  agent: "claude",
  file: "src/utils/api.ts",
  message: "Possible Anthropic API key exposure detected in source code",
  line: 15,
  column: 12,
  ...overrides,
})

export const Empty: Story = {
  args: {
    finding: null,
  },
}

export const WithError: Story = {
  args: {
    finding: mockFinding({
      severity: "error",
      ruleID: "CLAUDE-001",
      message: "Possible Anthropic API key exposure detected in source code",
      file: "src/utils/api.ts",
      line: 15,
    }),
  },
}

export const WithWarning: Story = {
  args: {
    finding: mockFinding({
      severity: "warning",
      ruleID: "CODEX-003",
      message: "Codex configuration directory reference found",
      file: "src/config/settings.ts",
      line: 8,
      agent: "codex",
    }),
  },
}

export const WithInfo: Story = {
  args: {
    finding: mockFinding({
      severity: "info",
      ruleID: "COPILOT-001",
      message: "GitHub Copilot API usage detected",
      file: "src/ai/integration.ts",
      line: 22,
      agent: "copilot",
    }),
  },
}

export const WithoutLineNumber: Story = {
  args: {
    finding: mockFinding({
      severity: "warning",
      ruleID: "SYNC-001",
      message: "Claude patterns found but no Codex patterns detected (possible drift)",
      file: ".",
      agent: "codex",
    }),
  },
}

export const LongMessage: Story = {
  args: {
    finding: mockFinding({
      message:
        "This is a very long message that demonstrates how the detail panel handles lengthy finding descriptions. " +
        "It might include context about why this is an issue, what the implications are, and potentially how to resolve it. " +
        "The panel should gracefully handle text of any reasonable length without breaking the layout.",
    }),
  },
}

export const LongFilePath: Story = {
  args: {
    finding: mockFinding({
      file: "src/features/authentication/services/external/providers/anthropic/client/configuration.ts",
      line: 128,
    }),
  },
}

export const SeverityMatrix: Story = {
  render: () => (
    <div className="flex gap-4">
      <div className="space-y-2">
        <p className="text-xs font-medium text-[var(--color-text-muted)] text-center">Error</p>
        <div className="h-80 w-80 border border-[var(--color-border)] rounded-lg overflow-hidden">
          <DetailPanel
            finding={mockFinding({
              severity: "error",
              ruleID: "CLAUDE-001",
              message: "Anthropic API key exposed",
              agent: "claude",
            })}
          />
        </div>
      </div>
      <div className="space-y-2">
        <p className="text-xs font-medium text-[var(--color-text-muted)] text-center">Warning</p>
        <div className="h-80 w-80 border border-[var(--color-border)] rounded-lg overflow-hidden">
          <DetailPanel
            finding={mockFinding({
              severity: "warning",
              ruleID: "CODEX-003",
              message: "Codex config directory reference",
              agent: "codex",
            })}
          />
        </div>
      </div>
      <div className="space-y-2">
        <p className="text-xs font-medium text-[var(--color-text-muted)] text-center">Info</p>
        <div className="h-80 w-80 border border-[var(--color-border)] rounded-lg overflow-hidden">
          <DetailPanel
            finding={mockFinding({
              severity: "info",
              ruleID: "COPILOT-001",
              message: "Copilot API usage detected",
              agent: "copilot",
            })}
          />
        </div>
      </div>
    </div>
  ),
}

export const AllAgents: Story = {
  render: () => (
    <div className="flex gap-4 flex-wrap">
      {[
        { agent: "claude", ruleID: "CLAUDE-001", message: "Claude finding example" },
        { agent: "codex", ruleID: "CODEX-002", message: "Codex finding example" },
        { agent: "copilot", ruleID: "COPILOT-001", message: "Copilot finding example" },
        { agent: "codexSkillManager", ruleID: "CSM-001", message: "CSM finding example" },
      ].map((item) => (
        <div key={item.agent} className="space-y-2">
          <p className="text-xs font-medium text-[var(--color-text-muted)] text-center capitalize">
            {item.agent}
          </p>
          <div className="h-72 w-72 border border-[var(--color-border)] rounded-lg overflow-hidden">
            <DetailPanel
              finding={mockFinding({
                agent: item.agent,
                ruleID: item.ruleID,
                message: item.message,
              })}
            />
          </div>
        </div>
      ))}
    </div>
  ),
}
