# DesignSystem (SkillsInspector)

This repository is in **active migration** from a SwiftPM/SwiftUI toolset to a **React + Tauri design system**. The Swift implementation has been archived to prevent confusion for product engineers building React/Tauri apps.

## Migration status

- ✅ Swift history archived: `swift-archive-2026-01-30` tag and `legacy/swift-archive-2026-01-30` branch.
- ✅ Swift sources removed from main branch.
- ✅ React/Tauri scaffold created in `app/` (Vite + React + Tailwind v4).
- ✅ Apps SDK UI wired from `vendor/apps-sdk-ui` (GitHub source build).
- ✅ Storybook + Argos baseline created (addon-vitest manual setup applied).
- 🟡 GPT widgets integration tracked (design targets defined; component coverage pending).

## Target stack (non‑negotiable)

- React + Vite
- Tauri (Rust)
- OpenAI Apps SDK + Apps SDK UI
- GPT widgets (ChatGPT display modes/components)
- Tailwind CSS v4
- Storybook
- Argos visual regression

## Local development (scaffold)

The React/Tauri scaffold lives in `app/`.

```bash
git submodule update --init --recursive
cd vendor/apps-sdk-ui
pnpm install
pnpm build
cd ../../app
pnpm install
pnpm dev          # Vite web preview
pnpm tauri dev    # Desktop shell
pnpm storybook    # Component catalog
```

Apps SDK UI is vendored as a git submodule so we can build the package locally when the npm registry tarball is missing prebuilt assets.

## Source docs

- `docs/UI-UX-Review-Report.md` — migration analysis + Tailwind token mapping plan
- `docs/UI-UX-Improvements-Recommendations.md` — UX recommendations
- `COMPREHENSIVE_UI_IMPROVEMENTS.md` — legacy SwiftUI improvements (historical reference)

## Legacy Swift implementation

The SwiftPM/SwiftUI implementation is archived and **not** part of the active codebase. If you need to inspect it, use:

- Tag: `swift-archive-2026-01-30`
- Branch: `legacy/swift-archive-2026-01-30`

## Current state disclaimer

Apps SDK integration is now wired via the vendored UI library. Follow the ExecPlan at `.spec/exexpln` for remaining polish and acceptance steps.
