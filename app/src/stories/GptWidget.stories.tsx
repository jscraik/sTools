import type { Meta, StoryObj } from "@storybook/react-vite";

import { Badge } from "@openai/apps-sdk-ui/components/Badge";
import { Button } from "@openai/apps-sdk-ui/components/Button";
import { ShimmerText } from "@openai/apps-sdk-ui/components/ShimmerText";
import {
  ArrowRightSm,
  Bolt,
  ChatTemporary,
  ClipboardCopy,
  SparkleDouble,
} from "@openai/apps-sdk-ui/components/Icon";

const GptWidgetStory = () => {
  return (
    <main className="min-h-screen bg-subtle text-primary">
      <div className="mx-auto flex max-w-5xl flex-col gap-6 px-6 py-10">
        <header className="flex flex-wrap items-center gap-3">
          <Badge color="info" pill>
            GPT widget
          </Badge>
          <ShimmerText as="h1" className="heading-lg">
            Trip Planner Assistant
          </ShimmerText>
          <span className="text-sm text-secondary">
            GPT surfaces combine prompt context, quick actions, and output
            controls inside the design system.
          </span>
        </header>

        <section className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
          <div className="rounded-2xl border border-default bg-surface p-6 shadow-lg">
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-center gap-2 text-sm text-secondary">
                <ChatTemporary className="size-4" />
                Assistant summary
              </div>
              <Badge color="success">Ready</Badge>
            </div>

            <div className="mt-4 rounded-xl border border-subtle bg-canvas p-4 text-sm text-secondary">
              You asked for a three-day itinerary with food, museums, and a
              relaxed pace. I used your saved preferences and added two GPT
              widget suggestions to refine the schedule.
            </div>

            <div className="mt-5 grid gap-3">
              <div className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                <div className="flex items-center gap-2 text-sm text-secondary">
                  <SparkleDouble className="size-4" />
                  Add a sunrise photo spot
                </div>
                <Button size="sm" color="secondary" variant="soft">
                  <ArrowRightSm />
                  Add
                </Button>
              </div>
              <div className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                <div className="flex items-center gap-2 text-sm text-secondary">
                  <Bolt className="size-4" />
                  Shorten day two travel time
                </div>
                <Button size="sm" color="secondary" variant="soft">
                  <ArrowRightSm />
                  Apply
                </Button>
              </div>
            </div>

            <div className="mt-6 flex flex-wrap items-center gap-3">
              <Button color="primary">
                <Bolt />
                Generate itinerary
              </Button>
              <Button color="secondary" variant="soft">
                <ClipboardCopy />
                Copy summary
              </Button>
            </div>
          </div>

          <aside className="rounded-2xl border border-default bg-surface p-5 shadow-lg">
            <p className="text-xs uppercase tracking-[0.3em] text-secondary">
              GPT widget controls
            </p>
            <h2 className="heading-md mt-2">Context panel</h2>
            <p className="mt-2 text-sm text-secondary">
              Use the widget to swap prompt context, reveal sources, or adjust
              the output style before publishing.
            </p>
            <div className="mt-4 grid gap-3 text-sm">
              <div className="rounded-xl border border-subtle bg-canvas px-4 py-3 text-secondary">
                Tone: Relaxed / Visual
              </div>
              <div className="rounded-xl border border-subtle bg-canvas px-4 py-3 text-secondary">
                Sources: 4 saved places
              </div>
              <div className="rounded-xl border border-subtle bg-canvas px-4 py-3 text-secondary">
                Output: 3-day plan + map pins
              </div>
            </div>
            <Button className="mt-4" color="secondary" variant="outline" block>
              Review prompt context
            </Button>
          </aside>
        </section>
      </div>
    </main>
  );
};

const meta = {
  title: "Design System/GPT Widgets",
  component: GptWidgetStory,
  parameters: {
    layout: "fullscreen",
  },
  tags: ["autodocs"],
} satisfies Meta<typeof GptWidgetStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const WidgetSurface: Story = {
  render: () => <GptWidgetStory />,
};
