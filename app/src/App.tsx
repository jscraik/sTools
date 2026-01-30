import { Badge } from "@openai/apps-sdk-ui/components/Badge";
import { Button } from "@openai/apps-sdk-ui/components/Button";
import {
  Calendar,
  Invoice,
  Maps,
  Members,
  Phone,
} from "@openai/apps-sdk-ui/components/Icon";

export default function App() {
  return (
    <main className="min-h-screen bg-subtle text-primary">
      <div className="mx-auto flex max-w-4xl flex-col gap-10 px-6 py-12">
        <header className="flex flex-col gap-3">
          <p className="text-xs uppercase tracking-[0.35em] text-secondary">
            DesignSystem Migration
          </p>
          <h1 className="heading-xl">React + Tauri scaffold</h1>
          <p className="text-sm text-secondary">
            Apps SDK UI is now wired from the GitHub source package. This screen
            uses the design system tokens, Tailwind foundations, and core
            components to prove the integration path.
          </p>
          <div className="flex flex-wrap gap-2">
            <Badge color="success">Tailwind v4</Badge>
            <Badge color="secondary">Storybook</Badge>
            <Badge color="secondary">Argos</Badge>
            <Badge color="info">Apps SDK UI</Badge>
            <Badge color="info">GPT widgets</Badge>
          </div>
        </header>

        <section className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
          <div className="rounded-2xl border border-default bg-surface p-6 shadow-lg">
            <h2 className="heading-lg">Migration checklist</h2>
            <ul className="mt-4 grid gap-3 text-sm text-secondary">
              <li className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                Swift stack removed
                <Badge color="success">Done</Badge>
              </li>
              <li className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                React/Tauri scaffold
                <Badge color="success">Done</Badge>
              </li>
              <li className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                Apps SDK UI wired
                <Badge color="success">Done</Badge>
              </li>
              <li className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                Storybook baseline
                <Badge color="secondary">Ready</Badge>
              </li>
              <li className="flex items-center justify-between rounded-xl border border-subtle bg-canvas px-4 py-3">
                GPT widget surfaces
                <Badge color="secondary">Planned</Badge>
              </li>
            </ul>
          </div>

          <div className="rounded-2xl border border-default bg-surface p-5 shadow-lg">
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="text-sm text-secondary">Reservation</p>
                <h3 className="heading-md mt-1">La Luna Bistro</h3>
              </div>
              <Badge color="success">Confirmed</Badge>
            </div>
            <dl className="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-2 text-sm">
              <dt className="flex items-center gap-1.5 text-secondary">
                <Calendar className="size-4" />
                Date
              </dt>
              <dd className="text-right">Apr 12 · 7:30 PM</dd>
              <dt className="flex items-center gap-1.5 text-secondary">
                <Members className="size-4" />
                Guests
              </dt>
              <dd className="text-right">Party of 2</dd>
              <dt className="flex items-center gap-1.5 text-secondary">
                <Invoice className="size-4" />
                Reference
              </dt>
              <dd className="text-right uppercase">4F9Q2K</dd>
            </dl>
            <div className="mt-4 grid gap-3 border-t border-subtle pt-4 sm:grid-cols-2">
              <Button variant="soft" color="secondary" block>
                <Phone />
                Call
              </Button>
              <Button color="primary" block>
                <Maps />
                Directions
              </Button>
            </div>
          </div>
        </section>
      </div>
    </main>
  );
}
