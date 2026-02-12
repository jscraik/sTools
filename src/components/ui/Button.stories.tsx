import type { Meta, StoryObj } from "@storybook/react-vite"
import { Button } from "./Button"

const meta: Meta<typeof Button> = {
  title: "UI/Button",
  component: Button,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
  argTypes: {
    variant: {
      control: "select",
      options: ["default", "primary", "secondary", "ghost"],
    },
    disabled: {
      control: "boolean",
    },
  },
}

export default meta
type Story = StoryObj<typeof Button>

export const Default: Story = {
  args: {
    children: "Button",
    variant: "default",
  },
}

export const Primary: Story = {
  args: {
    children: "Run Scan",
    variant: "primary",
  },
}

export const Secondary: Story = {
  args: {
    children: "Export",
    variant: "secondary",
  },
}

export const Ghost: Story = {
  args: {
    children: "Cancel",
    variant: "ghost",
  },
}

export const Disabled: Story = {
  args: {
    children: "Scanning...",
    variant: "primary",
    disabled: true,
  },
}

export const AllVariants: Story = {
  render: () => (
    <div className="flex flex-col gap-4 items-start">
      <Button variant="default">Default</Button>
      <Button variant="primary">Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="ghost">Ghost</Button>
    </div>
  ),
}

export const AllStates: Story = {
  render: () => (
    <div className="flex flex-col gap-4 items-start">
      <div className="flex gap-2">
        <Button variant="primary">Enabled</Button>
        <Button variant="primary" disabled>
          Disabled
        </Button>
      </div>
      <div className="flex gap-2">
        <Button variant="secondary">Enabled</Button>
        <Button variant="secondary" disabled>
          Disabled
        </Button>
      </div>
    </div>
  ),
}
