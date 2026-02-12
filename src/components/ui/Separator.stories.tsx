import type { Meta, StoryObj } from "@storybook/react-vite"
import { Separator } from "./Separator"

const meta: Meta<typeof Separator> = {
  title: "UI/Separator",
  component: Separator,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
  argTypes: {
    orientation: {
      control: "select",
      options: ["horizontal", "vertical"],
    },
  },
}

export default meta
type Story = StoryObj<typeof Separator>

export const Horizontal: Story = {
  args: {
    orientation: "horizontal",
  },
  render: (args: { orientation?: "horizontal" | "vertical" }) => (
    <div className="w-64 space-y-4">
      <p className="text-sm">Content above</p>
      <Separator {...args} />
      <p className="text-sm">Content below</p>
    </div>
  ),
}

export const Vertical: Story = {
  args: {
    orientation: "vertical",
  },
  render: (args: { orientation?: "horizontal" | "vertical" }) => (
    <div className="flex h-16 items-center gap-4">
      <span className="text-sm">Left</span>
      <Separator {...args} />
      <span className="text-sm">Right</span>
    </div>
  ),
}

export const InSidebarContext: Story = {
  render: () => (
    <div className="w-60 p-4 bg-[var(--color-surface)] border border-[var(--color-border)] rounded-lg space-y-4">
      <div>
        <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-2">
          Section A
        </h3>
        <p className="text-sm">Content for section A</p>
      </div>
      <Separator />
      <div>
        <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-2">
          Section B
        </h3>
        <p className="text-sm">Content for section B</p>
      </div>
      <Separator />
      <div>
        <h3 className="text-xs font-semibold text-[var(--color-text-muted)] uppercase tracking-wide mb-2">
          Section C
        </h3>
        <p className="text-sm">Content for section C</p>
      </div>
    </div>
  ),
}
