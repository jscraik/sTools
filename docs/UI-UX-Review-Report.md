# SkillsInspector UI/UX Review Report
## Swift → React/Tauri Migration Analysis

**Date:** January 25, 2026
**Version:** 1.0
**Status:** Documentation Only - No Code Changes

---

## Executive Summary

This report provides a comprehensive analysis of the SkillsInspector Swift/SwiftUI application, documenting its current UI/UX architecture, component structure, workflows, and providing recommendations for transformation to a React/Tauri application with TypeScript, JavaScript, and Tailwind CSS v4.

### Key Findings

| Category | Assessment | Priority |
|----------|------------|----------|
| Design System | Well-established aStudio tokens with bridge extensions | High |
| Component Architecture | Modular, view-based structure with clear separation | High |
| State Management | Centralized ViewModels with Observable pattern | High |
| Navigation | Sidebar-based with clear mode switching | Medium |
| Accessibility | Basic keyboard navigation, needs enhancement | Medium |
| Desktop Integration | Deep macOS-specific features requiring adaptation | High |

---

## Table of Contents

1. [Application Architecture](#1-application-architecture)
2. [Component Inventory](#2-component-inventory)
3. [Design System Analysis](#3-design-system-analysis)
4. [User Workflows](#4-user-workflows)
5. [Migration Recommendations](#5-migration-recommendations)
6. [Standard Operating Procedures](#6-standard-operating-procedures)

---

## 1. Application Architecture

### 1.1 Overall Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    SkillsInspector (macOS)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌─────────────────────────────────────────────┐ │
│  │ Sidebar  │  │              Main Content Area              │ │
│  │          │  │                                             │ │
│  │ Analysis │  │  ┌─────────────┐  ┌──────────────────────┐ │ │
│  │ Validate │  │  │   Toolbar   │  │                      │ │ │
│  │ Statistics│  │  └─────────────┘  │                      │ │ │
│  │          │  │                   │     Detail View      │ │ │
│  │ Management│  │  ┌───────────┐   │                      │ │ │
│  │ Sync     │  │  │ Findings  │   │                      │ │ │
│  │ Index    │  │  │   List    │   │                      │ │ │
│  │ Remote   │  │  │           │   │                      │ │ │
│  │ Changelog│  │  └───────────┘   └──────────────────────┘ │ │
│  │          │  │                                             │ │
│  │ Scan Roots│                                             │ │
│  │ Options  │                                             │ │
│  └──────────┘                                             │ │
│                                                           └─┘
└───────────────────────────────────────────────────────────────┘
```

### 1.2 App Modes

The application operates in six distinct modes, each with its own view:

| Mode | View File | Purpose | Key Interactions |
|------|-----------|---------|------------------|
| **Validate** | `ValidateView.swift` | Scan and display rule violations | Scan, filter findings, apply fixes |
| **Stats** | `StatsView.swift` | Display statistics and charts | View analytics, export data |
| **Sync** | `SyncView.swift` | Synchronize skills across agents | Compare, sync, manage roots |
| **Index** | `IndexView.swift` | Browse skill index | Search, filter, view metadata |
| **Remote** | `RemoteView.swift` | Manage remote skills | Install, update, verify signatures |
| **Changelog** | `ChangelogView.swift` | View skill change history | Timeline view, ledger events |

### 1.3 Window Management

```swift
// Primary Window
WindowGroup("SkillsInspector")
  - minWidth: 1200, minHeight: 800
  - defaultSize: 1400 x 900

// Modal Windows
Window("Settings", id: "settings")
  - style: .hiddenTitleBar
  - resizability: .contentSize
  - position: .center

Window("Keyboard Shortcuts", id: "shortcuts")
  - style: .hiddenTitleBar
  - resizability: .contentSize
  - shortcut: Cmd+?
```

---

## 2. Component Inventory

### 2.1 Core UI Components

#### Navigation Components

```
Sidebar (ContentView.swift)
├── Branding Section
│   ├── App Icon (sparkles)
│   └── App Title ("SkillsInspector")
├── Analysis Section
│   ├── Validate Row (with error count badge)
│   └── Statistics Row
├── Management Section
│   ├── Sync Row
│   ├── Index Row
│   ├── Remote Row
│   └── Changelog Row
├── Scan Roots Section
│   ├── Codex Root Cards (multiple)
│   ├── Claude Root Card
│   ├── Copilot Root Card
│   ├── CodexSkillManager Root Card
│   └── Add Root Button
├── Options Section
│   └── Recursive Scan Toggle
└── Filters Section (when in Validate mode)
    ├── Severity Picker
    └── Agent Picker
```

#### Toolbar Components

```
Main Toolbar (ValidateView.swift)
├── Primary Actions
│   ├── Scan Rules Button (Cmd+R)
│   └── Stop Button (during scan)
├── Configuration
│   ├── Watch Mode Toggle
│   └── Recursive Toggle
├── Status Indicators
│   ├── Scanning Progress
│   ├── Last Run Timestamp
│   └── Cache Hit Rate
└── Export Menu
    └── Format Options (JSON, CSV, Markdown)

Filter Bar (ValidateView.swift)
├── Severity Badges (Error, Warning, Info)
└── Scan Duration Display
```

#### Content Components

```
Findings List (ValidateView.swift)
├── Empty State
├── Skeleton Loading State
├── Finding Row Components
│   ├── Severity Icon
│   ├── Rule ID
│   ├── Message Preview
│   ├── File Path
│   └── Context Menu
└── Auto-Fix Banner (when applicable)

Detail Panel (FindingDetailView.swift)
├── Header Section
│   ├── Severity Badge
│   ├── Rule ID
│   └── File Location
├── Finding Details
│   ├── Full Message
│   ├── Code Context
│   └── Suggested Fix
├── Actions Section
│   ├── Apply Fix Button
│   ├── Open in Editor
│   ├── Show in Finder
│   └── Add to Baseline
└── Metadata Section
    ├── Agent Info
    ├── Timestamp
    └── Related Findings
```

### 2.2 Specialized Views

#### Analytics Dashboard

```
AnalyticsDashboardView.swift
├── Header
│   ├── Title & Description
│   ├── Time Range Picker (segmented)
│   └── Export CSV Button
├── Charts Row
│   ├── ScanFrequencyChart
│   └── ErrorTrendsChart
└── Top Skills List
    ├── Skill Ranking Rows
    │   ├── Rank Badge
    │   ├── Skill Name
    │   ├── Agent Icon
    │   └── Scan Count
    └── Skeleton Loading States
```

#### Settings Modal

```
SettingsView.swift (5 tabs)
├── General Tab
│   ├── Scanning Options
│   ├── Display Options
│   ├── Safety Options
│   └── Telemetry Options
├── Editor Tab
│   ├── Default Editor Picker
│   └── Detected Editors List
├── Appearance Tab
│   ├── Theme Picker (System/Light/Dark)
│   ├── Accent Color Grid
│   └── Density Picker
├── Trust Tab
│   ├── Trusted Keys List
│   └── Add Key Sheet
└── Privacy Tab
    ├── Telemetry Toggle
    ├── Metrics List
    └── Privacy Policy
```

### 2.3 Component Hierarchy Diagram

```
App (SkillsInspectorApp)
├── ContentView (Main Layout)
│   ├── Sidebar
│   │   ├── SidebarSection (reusable)
│   │   ├── SidebarRow (reusable)
│   │   ├── RootCard (reusable)
│   │   └── FilterPicker (reusable)
│   ├── SidebarResizer
│   └── ActiveDetailView
│       ├── ValidateView
│       │   ├── ScanToolbar
│       │   ├── FilterBar
│       │   ├── FindingsList
│       │   │   └── FindingRow (reusable)
│       │   └── FindingDetailView
│       ├── StatsView
│       ├── SyncView
│       ├── IndexView
│       ├── RemoteView
│       └── ChangelogView
│           └── LedgerEventRowView (reusable)
├── SettingsView (Modal)
│   ├── GeneralTabView
│   ├── EditorTabView
│   ├── AppearanceTabView
│   ├── TrustTabView
│   └── PrivacyTabView
└── KeyboardShortcutsView (Modal)
    └── ShortcutCategory (reusable)
```

---

## 3. Design System Analysis

### 3.1 Token Structure

The app uses a comprehensive design token system:

```swift
DesignTokens
├── Colors
│   ├── Background
│   │   ├── primary (#FFFFFF light / #212121 dark)
│   │   ├── secondary (#E8E8E8 light / #303030 dark)
│   │   └── tertiary (#F3F3F3 light / #414141 dark)
│   ├── Text
│   │   ├── primary (#0D0D0D light / #FFFFFF dark)
│   │   ├── secondary (#5D5D5D light / #CDCDCD dark)
│   │   └── tertiary (#8F8F8F light / #D0D0D0 dark)
│   ├── Icon (same as Text)
│   ├── Border
│   │   ├── light (5% opacity)
│   │   └── heavy (15% opacity)
│   ├── Accent (semantic colors)
│   │   ├── gray, red, orange, yellow, green, blue, purple, pink
│   └── Status (aliases to Accent)
│       ├── success = green
│       ├── warning = orange
│       ├── error = red
│       └── info = blue
├── Typography (SF Pro)
│   ├── Heading1: 36pt / -0.1 tracking / semibold
│   ├── Heading2: 24pt / -0.25 tracking / semibold
│   ├── Heading3: 18pt / -0.45 tracking / semibold
│   ├── Body: 16pt / 26 leading / regular
│   ├── BodySmall: 14pt / 18 leading / regular
│   ├── Caption: 11pt / 16 leading / regular
│   └── Subcaption: 10pt / 14 leading / regular
├── Spacing
│   ├── xxxl: 128pt, xxl: 64pt, xl: 48pt
│   ├── lg: 40pt, md: 32pt, sm: 24pt
│   ├── xs: 16pt, xxs: 12pt, xxxs: 8pt
│   ├── hair: 4pt, micro: 2pt, none: 0
├── Radius
│   ├── sm: 6pt, md: 8pt, lg: 12pt, xl: 16pt, pill: 999pt
├── Shadow
│   ├── card, subtle, elevated, pip, pill, close
└── Layout
    ├── sidebarMinWidth: 220pt
    ├── sidebarIdealWidth: 260pt
    ├── sidebarMaxWidth: 340pt
    ├── minRowHeight: 36pt
    ├── sectionSpacing: 20pt
    └── cardSpacing: 12pt
```

### 3.2 aStudio Bridge Extensions

The app includes bridge extensions for gradual migration from local tokens to aStudio tokens:

```swift
// Examples of bridge extensions:
DesignTokens.Colors.Text.fTextPrimary → FColor.textPrimary
DesignTokens.Colors.Accent.fAccentBlue → FColor.accentBlue
DesignTokens.Spacing.fCard → FSpacing.s16
DesignTokens.Typography.fTitle → FType.title()
```

### 3.3 Tailwind v4 Migration Strategy

For React/Tauri migration, map existing tokens to Tailwind v4 CSS variables:

```css
/* tailwind.config.css - Token Mapping */
@theme {
  /* Colors - Background */
  --color-bg-primary: #FFFFFF;
  --color-bg-primary-dark: #212121;
  --color-bg-secondary: #E8E8E8;
  --color-bg-secondary-dark: #303030;

  /* Colors - Text */
  --color-text-primary: #0D0D0D;
  --color-text-primary-dark: #FFFFFF;
  --color-text-secondary: #5D5D5D;
  --color-text-secondary-dark: #CDCDCD;

  /* Colors - Accent (Semantic) */
  --color-accent-blue: #0285FF;
  --color-accent-blue-dark: #48AAFF;
  --color-accent-green: #008635;
  --color-accent-green-dark: #40C977;
  --color-accent-red: #E02E2A;
  --color-accent-red-dark: #FF8583;
  --color-accent-orange: #E25507;
  --color-accent-orange-dark: #FF9E6C;

  /* Spacing */
  --spacing-xxxl: 128px;
  --spacing-xxl: 64px;
  --spacing-xl: 48px;
  --spacing-lg: 40px;
  --spacing-md: 32px;
  --spacing-sm: 24px;
  --spacing-xs: 16px;
  --spacing-xxs: 12px;
  --spacing-xxxs: 8px;
  --spacing-hair: 4px;

  /* Radius */
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;

  /* Typography */
  --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
}
```

### 3.4 Component Styling Patterns

#### Card Style

```swift
// Current SwiftUI Pattern
.cardStyle(tint: DesignTokens.Colors.Accent.blue)

// React/Tailwind v4 Equivalent
className="bg-background-tertiary/50 rounded-lg border border-border-light"
```

#### Button Styles

```swift
// Bordered Prominent
.buttonStyle(.borderedProminent)
→ className="bg-accent-blue text-white border-0 hover:bg-accent-blue/90"

// Plain Button
.buttonStyle(.plain)
→ className="hover:bg-background-secondary rounded transition-colors"
```

---

## 4. User Workflows

### 4.1 Primary Workflows

#### Workflow 1: Validate Skills

```
User Action                    System Response
─────────────────────────────────────────────────────────────
1. Launch App                  → App initializes, shows Validate view
                              → Sidebar displays configured roots
                              → Empty state: "No findings yet"

2. Click "Scan Rules"         → Scan begins (⌘R available)
                              → Progress bar appears at top
                              → Skeleton states shown in findings list
                              → File count updates in real-time

3. Scan Complete              → Findings populate list
                              → Severity badges show counts
                              → Last run timestamp updated
                              → First finding auto-selected

4. Click Finding Row          → Detail panel updates
                              → Shows full message, context, fix
                              → Focus moves to detail panel

5. Click "Apply Fix"          → Fix applied to file
                              → Success toast appears
                              → Finding re-scans automatically
                              → List updates if resolved

6. Export Results             → File export dialog appears
                              → Choose format (JSON/CSV/MD)
                              → File saved, success toast shown
```

#### Workflow 2: Configure Scan Roots

```
User Action                    System Response
─────────────────────────────────────────────────────────────
1. Locate Scan Roots          → Sidebar shows all root sections
                              → Status indicator (green/gray)
                              → Current path displayed (shortened)

2. Click Root Card Ellipsis   → Context menu appears
                              → Options: Change Location, Remove

3. Select "Change Location"   → NSOpenPanel appears
                              → Directory picker shown
                              → Validates selection

4. Choose Directory           → Path updates in card
                              → Status indicator updates
                              → Validates skills directory
                              → Error alert if invalid

5. Click "Add Root"           → New root card created
                              → Directory picker shown
                              → Multiple Codex roots supported
```

#### Workflow 3: View Analytics

```
User Action                    System Response
─────────────────────────────────────────────────────────────
1. Click "Statistics"         → Mode switches to Stats view
                              → Dashboard loads with 30-day default
                              → Charts render with animations

2. Change Time Range          → Picker shows 7d/30d/90d/All
                              → Data refreshes asynchronously
                              → Charts update with new data
                              → Skeleton states during load

3. Click "Export CSV"         → Save panel appears twice
                              → (frequency data + error data)
                              → Files saved to chosen location
                              → Success alert shows filenames

4. Click Top Skill Row        → No explicit action
                              → Shows scan metadata
                              → Agent icon and count displayed
```

#### Workflow 4: Manage Settings

```
User Action                    System Response
─────────────────────────────────────────────────────────────
1. Press Cmd+,                → Settings modal opens
                              → TabView shows 5 tabs
                              → General tab selected by default

2. Navigate Tabs              → Click tab or swipe to switch
                              → Each tab has themed cards
                              → Settings persist to @AppStorage

3. Change Accent Color        → Grid of 6 color circles shown
                              → Click to select
                              → Checkmark shows selection
                              → App updates immediately

4. Toggle Telemetry           → Switch shows current state
                              → Enable shows confirmation alert
                              → Privacy notice displayed
                              → Must confirm to enable
```

### 4.2 Workflow Diagram

```
┌──────────────┐
│   Launch     │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────┐
│         Sidebar Navigation           │
│  ┌────────────────────────────────┐  │
│  │ Analysis Mode                  │  │
│  │  ├─ Validate (default)         │  │
│  │  └─ Statistics                │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ Management Mode                │  │
│  │  ├─ Sync                       │  │
│  │  ├─ Index                      │  │
│  │  ├─ Remote                     │  │
│  │  └─ Changelog                  │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ Configuration                  │  │
│  │  ├─ Scan Roots (expandable)    │  │
│  │  └─ Options (toggles)          │  │
│  └────────────────────────────────┘  │
└───────────────┬──────────────────────┘
                │
                ▼
┌───────────────────────────────────────────┐
│           Content Area                    │
│  ┌─────────────────────────────────────┐ │
│  │ Mode-Specific Toolbar               │ │
│  │ (scan controls, filters, export)    │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────┬───────────────────┐ │
│  │  Findings List  │   Detail Panel    │ │
│  │  (scrollable)   │   (contextual)    │ │
│  │                 │                   │ │
│  │  ┌───────────┐  │ ┌───────────────┐ │ │
│  │  │ Finding 1 │─┼─→│ Full Details  │ │ │
│  │  ├───────────┤  │ │ Code Context  │ │ │
│  │  │ Finding 2 │  │ │ Suggested Fix │ │ │
│  │  ├───────────┤  │ │ Actions       │ │ │
│  │  │ Finding 3 │  │ └───────────────┘ │ │
│  │  └───────────┘  │                   │ │
│  └─────────────────┴───────────────────┘ │
└───────────────────────────────────────────┘
```

### 4.3 Keyboard Shortcuts

| Shortcut | Action | Mode |
|----------|--------|------|
| `Cmd+R` | Run Scan | Validate |
| `Cmd+.` | Cancel Scan | Validate |
| `Cmd+Shift+W` | Toggle Watch Mode | Validate |
| `Cmd+,` | Open Settings | Global |
| `Cmd+?` | Keyboard Shortcuts | Global |
| `↑/↓` | Navigate Findings | Validate |
| `Enter` | Open Selected Finding | Validate |

---

## 5. Migration Recommendations

### 5.1 Architecture Recommendations

#### Component Framework Decisions

```
Decision Point                  Recommendation              Rationale
─────────────────────────────────────────────────────────────────────────────
State Management              → Zustand + React Query      Lightweight, async-friendly
                              (or Jotai for atomics)     TypeScript-first

Routing                       → React Router v7           File-based routing for future
                              (or TanStack Router)        Type-safe navigation

UI Primitives                 → Radix UI + Headless UI    Accessible, unstyled, customizable
                              (shadcn/ui patterns)        Well-maintained

Styling                       → Tailwind CSS v4           Matches Swift token structure
                              + CVA for variants          First-class variant support

Data Fetching                 → TanStack Query            Caching, background updates
                              (React Query)               Optimistic updates

Forms                         → React Hook Form           TypeScript integration
                              + Zod validation           Runtime validation

Animations                   → Framer Motion              Production-ready, accessible
                              (or Auto Animate)           Declarative APIs

Charts                        ├── Recharts (simple)      React-native, well-documented
                              └── Visx (performant)     D3-like, but declarative
```

#### State Management Strategy

```typescript
// Recommended State Architecture
┌─────────────────────────────────────────────────────────────┐
│                       Application State                      │
├─────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────┐ │
│  │   UI State       │  │  Server State    │  │ Local State │ │
│  │   (Zustand)      │  │  (React Query)   │  │  (Zustand)  │ │
│  │                  │  │                  │  │             │ │
│  │ • currentMode    │  │ • findings       │  │ • settings  │ │
│  │ • sidebarWidth   │  │ • scanStatus     │  │ • editorPref │ │
│  │ • selectedID     │  │ • analyticsData  │  │ • theme      │ │
│  │ • filters        │  │ • remoteSkills   │  │ • telemetry  │ │
│  └──────────────────┘  └──────────────────┘  └─────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Tauri Backend (Rust)                        │   │
│  │  • File system access                                    │   │
│  │  • Scan engine bridge                                     │   │
│  │  • Native dialogs (folder picker, save panel)            │   │
│  │  • System integration (editor, notifications)            │   │
│  └─────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 Component Mapping

#### Sidebar Component

```typescript
// src/components/Sidebar/Sidebar.tsx
interface SidebarProps {
  currentMode: AppMode;
  onModeChange: (mode: AppMode) => void;
  scanRoots: ScanRoots;
  onRootChange: (index: number, url: URL) => void;
  filters: ValidateFilters;
  onFilterChange: (filters: ValidateFilters) => void;
}

// Sub-components
// - SidebarSection.tsx
// - SidebarRow.tsx
// - RootCard.tsx
// - FilterPicker.tsx
// - SeverityBadge.tsx
```

#### Findings List Component

```typescript
// src/components/Validate/FindingsList.tsx
interface FindingsListProps {
  findings: Finding[];
  selectedId: string | null;
  onSelectionChange: (id: string) => void;
  filters: ValidateFilters;
  isScanning: boolean;
  scanProgress: number;
}

// Sub-components
// - FindingRow.tsx (with context menu)
// - FindingSkeleton.tsx
// - EmptyState.tsx
// - AutoFixBanner.tsx
```

#### Detail Panel Component

```typescript
// src/components/Validate/FindingDetailPanel.tsx
interface FindingDetailPanelProps {
  finding: Finding | null;
  onApplyFix: (fix: SuggestedFix) => Promise<void>;
  onOpenInEditor: (url: URL, line: number) => void;
  onAddToBaseline: (finding: Finding) => Promise<void>;
}

// Sub-components
// - FindingHeader.tsx
// - CodeContext.tsx (syntax highlighted)
// - SuggestedFixCard.tsx
// - ActionButtons.tsx
// - FindingMetadata.tsx
```

### 5.3 Desktop-Specific Features

#### macOS → Tauri API Mapping

| macOS Feature | Tauri Equivalent | Notes |
|--------------|------------------|-------|
| `NSOpenPanel` | `dialog.open()` | Multiple selection support |
| `NSSavePanel` | `dialog.save()` | File type filtering |
| `NSWorkspace.open` | `shell.open()` | Use system default |
| `NSApplication.setActivationPolicy` | N/A | Tauri always regular |
| `NotificationCenter` | Custom event bus | Implement via Zustand |
| `@AppStorage` | LocalStorage + Tauri Store | Persist to disk |
| `MenuItem` | Tauri menu API | Recreate menus |
| `KeyboardShortcut` | `globalShortcut` | Or hotkeys-js |

#### File System Access

```typescript
// Tauri Commands (Rust backend)
#[tauri::command]
async fn pick_folder() -> Result<String, String> {
    // Use native file dialog
    // Validate skills directory
    // Return path or error
}

#[tauri::command]
async fn read_skill_file(path: String) -> Result<String, String> {
    // Read file contents
    // Handle errors gracefully
}

#[tauri::command]
async fn apply_fix(file_path: String, fix: SuggestedFix) -> Result<(), String> {
    // Apply text replacement
    // Create backup if needed
    // Return success/error
}
```

### 5.4 Accessibility Recommendations

#### Current State Assessment

| Area | Current Implementation | Gap | Recommendation |
|------|----------------------|-----|----------------|
| Keyboard Navigation | Basic arrow key support | Limited tab navigation | Full keyboard traversal |
| Screen Reader | Partial labels | Missing aria labels | Comprehensive labeling |
| Focus Management | Auto-select on scan | No focus restoration | Restore after actions |
| Color Contrast | WCAG AA compliant | Good | Maintain current |
| Reduced Motion | Not implemented | No preference handling | Add `prefers-reduced-motion` |
| High Contrast | Not available | macOS only | Add theme variant |

#### Accessibility Implementation

```typescript
// Recommended a11y patterns
<div
  role="list"
  aria-label="Findings list"
  aria-activedescendant={selectedId}
>
  {findings.map(finding => (
    <div
      role="listitem"
      tabIndex={0}
      aria-selected={finding.id === selectedId}
      onKeyDown={handleKeyDown}
      onClick={handleClick}
    >
      {/* Finding content */}
    </div>
  ))}
</div>
```

### 5.5 Performance Considerations

#### Virtual Scrolling

```typescript
// For large findings lists
import { useVirtualizer } from '@tanstack/react-virtual';

// Use virtual list instead of native scroll
const rowVirtualizer = useVirtualizer({
  count: findings.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 80, // Estimated row height
  overscan: 5,
});
```

#### Code Splitting

```typescript
// Lazy load heavy components
const AnalyticsDashboard = lazy(() =>
  import('./components/Analytics/AnalyticsDashboard')
);

const ChartsPanel = lazy(() =>
  import('./components/Analytics/ChartsPanel')
);

// Use Suspense for loading states
<Suspense fallback={<ChartsSkeleton />}>
  <ChartsPanel data={analyticsData} />
</Suspense>
```

---

## 6. Standard Operating Procedures

### 6.1 Development SOPs

#### SOP-1: Component Development Workflow

```
1. Design Phase
   ├─ Review Swift component behavior
   ├─ Sketch React component structure
   ├─ Define TypeScript interfaces
   └─ Map design tokens to Tailwind classes

2. Implementation Phase
   ├─ Create component file with exports
   ├─ Implement with Radix UI primitives
   ├─ Apply Tailwind v4 utility classes
   ├─ Add CVA variants for states
   └─ Include accessibility attributes

3. Testing Phase
   ├─ Storybook: Create stories for all variants
   ├─ Unit tests: Test state changes and callbacks
   ├─ Keyboard: Verify tab order and shortcuts
   ├─ Screen reader: Test with VoiceOver/NVDA
   └─ Visual: Compare screenshots with Swift version

4. Documentation Phase
   ├─ Add JSDoc comments
   ├─ Document prop interfaces
   ├─ Include usage examples
   └─ Note any deviations from Swift behavior
```

#### SOP-2: Token Migration Workflow

```
1. Extract Swift token value
2. Add to tailwind.config.css
3. Create semantic utility class
4. Map to component usage
5. Verify with design QA
```

### 6.2 Quality Assurance SOPs

#### QA-1: Visual Regression Checklist

```
□ Compare layout proportions (within 2px)
□ Verify color contrast ratios (WCAG AA)
□ Check spacing consistency (4px base unit)
□ Verify font rendering (SF Pro → Inter)
□ Test light/dark mode parity
□ Validate hover/focus states
□ Check empty/loading/error states
□ Verify responsive behavior (min/max constraints)
```

#### QA-2: Keyboard Navigation Checklist

```
□ Tab order follows visual flow
□ All interactive elements reachable
□ Focus indicators visible (2px minimum)
□ Escape key closes modals
□ Arrow keys navigate lists
□ Enter activates selections
□ Shortcuts work as documented
□ Focus restoration after actions
```

#### QA-3: Cross-Platform Checklist

```
□ macOS: Native dialogs work correctly
□ macOS: Menu bar commands functional
□ macOS: Window controls (min/max/close)
□ Windows: File picker returns paths correctly
□ Windows: Shortcuts use Ctrl vs Cmd
□ Linux: Theme integration works
□ All: File system permissions handled
□ All: Editor integration functions
```

### 6.3 Deployment SOPs

#### Build Process

```
1. Development
   └─ pnpm dev (Vite dev server with HMR)

2. Type Checking
   └─ pnpm tsc --noEmit (strict mode)

3. Linting
   └─ pnpm biome check . (or pnpm lint)

4. Testing
   └─ pnpm test (Vitest for unit + integration)

5. Build
   └─ pnpm build (Vite production build)

6. Tauri Build
   ├─ pnpm tauri build (release binaries)
   └─ pnpm tauri dev (development with Rust backend)

7. Code Signing
   ├─ macOS: Sign with developer certificate
   ├─ Windows: Sign with certificate
   └─ Notarization: Submit to Apple (macOS)
```

---

## 7. Component Diagrams

### 7.1 Application State Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐              ┌─────────────────────────┐   │
│  │   Router       │─────────────>│   Layout                │   │
│  │ (React Router) │              │   (Sidebar + Content)   │   │
│  └────────────────┘              └──────────┬──────────────┘   │
│                                             │                    │
│           ┌─────────────────────────────────┼──────────────┐    │
│           │                                 │              │    │
│           ▼                                 ▼              ▼    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Validate    │  │    Stats     │  │    Sync      │       │
│  │    View      │  │    View      │  │    View      │       │
│  │              │  │              │  │              │       │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │       │
│  │  │Toolbar │  │  │  │Toolbar │  │  │  │Toolbar │  │       │
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │       │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │       │
│  │  │  List  │  │  │  │ Charts │  │  │  │  Tree  │  │       │
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │       │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │       │
│  │  │ Detail │  │  │  │TopSkills│  │  │  │ Detail │  │       │
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Global Modals                         │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │   │
│  │  │ Settings │  │ Shortcuts│  │  About   │             │   │
│  │  └──────────┘  └──────────┘  └──────────┘             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### 7.2 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Flow                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User Actions                                                     │
│     │                                                             │
│     ├──> Click "Scan"                                             │
│     │    │                                                        │
│     │    ├──> UI State (setScanning)                             │
│     │    │                                                        │
│     │    └──> Tauri Command (scan_skills)                        │
│     │           │                                                 │
│     │           ├──> Rust: File system scan                      │
│     │           │                                                │
│     │           └──> React Query (invalidate + refetch)          │
│     │                   │                                        │
│     │                   └──> Component re-render                  │
│     │                                                            │
│     ├──> Select Finding                                           │
│     │    │                                                        │
│     │    └──> UI State (setSelectedFinding)                      │
│     │           │                                                │
│     │           └──> Detail Panel updates                         │
│     │                                                            │
│     └──> Apply Fix                                                │
│          │                                                        │
│          ├──> Tauri Command (apply_fix)                          │
│          │           │                                          │
│          │           └──> Rust: Write file                      │
│          │                   │                                  │
│          │                   └──> React Query (invalidate)       │
│          │                            │                          │
│          │                            └──> Optimistic update     │
│          │                            └──> Background refresh    │
│          │                                                            │
└───────────────────────────────────────────────────────────────────┘
```

### 7.3 Component Dependency Graph

```
                    ┌─────────────┐
                    │  App.tsx    │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  Layout.tsx │ │  Router.tsx │ │ Providers.tsx│
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
     ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
     │           │   │           │   │           │
     ▼           ▼   ▼           ▼   ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│ Sidebar │ │ Validate│ │  Stats  │ │  Sync   │
└────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘
     │           │           │           │
     ▼           ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│Sidebar  │ │Finding  │ │Charts   │ │FileTree │
│Section  │ │Row      │ │         │ │         │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
```

---

## 8. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

- [ ] Set up Tauri + React + Vite project
- [ ] Configure Tailwind CSS v4 with design tokens
- [ ] Set up Radix UI + shadcn/ui components
- [ ] Create base layout with sidebar
- [ ] Implement routing structure

### Phase 2: Core Features (Weeks 3-4)

- [ ] Validate view with findings list
- [ ] Detail panel component
- [ ] Scan integration via Tauri commands
- [ ] Settings modal structure
- [ ] Keyboard shortcut system

### Phase 3: Advanced Features (Weeks 5-6)

- [ ] Analytics dashboard with charts
- [ ] Sync/index views
- [ ] Remote skill management
- [ ] Changelog view
- [ ] File export functionality

### Phase 4: Polish & Launch (Weeks 7-8)

- [ ] Accessibility audit and fixes
- [ ] Performance optimization
- [ ] Cross-platform testing
- [ ] Code signing and notarization
- [ ] Documentation completion

---

## Appendix A: File Structure

### Proposed React/Tauri Structure

```
src/
├── components/
│   ├── ui/                    # Base UI components (Radix + shadcn)
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── dialog.tsx
│   │   ├── dropdown-menu.tsx
│   │   ├── label.tsx
│   │   ├── separator.tsx
│   │   ├── switch.tsx
│   │   ├── tabs.tsx
│   │   └── ...
│   ├── layout/
│   │   ├── Sidebar.tsx
│   │   ├── SidebarSection.tsx
│   │   ├── SidebarRow.tsx
│   │   └── RootCard.tsx
│   ├── validate/
│   │   ├── ValidateView.tsx
│   │   ├── ScanToolbar.tsx
│   │   ├── FilterBar.tsx
│   │   ├── FindingsList.tsx
│   │   ├── FindingRow.tsx
│   │   ├── FindingDetailPanel.tsx
│   │   └── EmptyStates.tsx
│   ├── stats/
│   │   ├── StatsView.tsx
│   │   ├── AnalyticsDashboard.tsx
│   │   ├── ScanFrequencyChart.tsx
│   │   ├── ErrorTrendsChart.tsx
│   │   └── TopSkillsList.tsx
│   ├── sync/
│   │   └── SyncView.tsx
│   ├── index/
│   │   └── IndexView.tsx
│   ├── remote/
│   │   └── RemoteView.tsx
│   └── changelog/
│       └── ChangelogView.tsx
├── modals/
│   ├── SettingsModal.tsx
│   ├── ShortcutsModal.tsx
│   └── settings/
│       ├── GeneralTab.tsx
│       ├── EditorTab.tsx
│       ├── AppearanceTab.tsx
│       ├── TrustTab.tsx
│       └── PrivacyTab.tsx
├── hooks/
│   ├── useAppState.ts
│   ├── useScan.ts
│   ├── useFindings.ts
│   ├── useKeyboardShortcuts.ts
│   └── useToast.ts
├── stores/
│   ├── appStore.ts
│   ├── settingsStore.ts
│   └── uiStore.ts
├── services/
│   ├── api.ts                 # Tauri command wrappers
│   ├── analytics.ts
│   ├── scanner.ts
│   └── storage.ts
├── types/
│   ├── app.ts
│   ├── findings.ts
│   ├── settings.ts
│   └── analytics.ts
├── utils/
│   ├── tokens.ts              # Design token utilities
│   ├── keyboard.ts
│   └── formatting.ts
├── App.tsx
└── main.tsx

src-tauri/
├── src/
│   ├── commands.rs            # Tauri commands
│   ├── scanner.rs             # Scan engine
│   ├── file_utils.rs
│   └── main.rs
├── Cargo.toml
├── tauri.conf.json
└── build.rs
```

---

## Appendix B: Tailwind Token Configuration

### Complete Token Mapping

```css
/* tailwind.config.css */
@import "tailwindcss";

@theme {
  /* Color Palette - Background */
  --color-bg-primary: oklabach(from #FFFFFF l a b);
  --color-bg-primary-dark: oklabach(from #212121 l a b);
  --color-bg-secondary: oklabach(from #E8E8E8 l a b);
  --color-bg-secondary-dark: oklabach(from #303030 l a b);
  --color-bg-tertiary: oklabach(from #F3F3F3 l a b);
  --color-bg-tertiary-dark: oklabach(from #414141 l a b);

  /* Color Palette - Text */
  --color-text-primary: oklabach(from #0D0D0D l a b);
  --color-text-primary-dark: oklabach(from #FFFFFF l a b);
  --color-text-secondary: oklabach(from #5D5D5D l a b);
  --color-text-secondary-dark: oklabach(from #CDCDCD l a b);
  --color-text-tertiary: oklabach(from #8F8F8F l a b);
  --color-text-tertiary-dark: oklabach(from #D0D0D0 l a b);

  /* Semantic Colors - Accent */
  --color-accent-blue: #0285FF;
  --color-accent-blue-dark: #48AAFF;
  --color-accent-green: #008635;
  --color-accent-green-dark: #40C977;
  --color-accent-red: #E02E2A;
  --color-accent-red-dark: #FF8583;
  --color-accent-orange: #E25507;
  --color-accent-orange-dark: #FF9E6C;
  --color-accent-yellow: #C08C00;
  --color-accent-yellow-dark: #FFD666;
  --color-accent-purple: #934FF2;
  --color-accent-purple-dark: #BA8FF7;
  --color-accent-pink: #E3008D;
  --color-accent-pink-dark: #FF6BC7;
  --color-accent-gray: #8F8F8F;
  --color-accent-gray-dark: #ABABAB;

  /* Status Colors (aliases) */
  --color-status-success: var(--color-accent-green);
  --color-status-warning: var(--color-accent-orange);
  --color-status-error: var(--color-accent-red);
  --color-status-info: var(--color-accent-blue);

  /* Spacing Scale */
  --spacing-xxxl: 128px;
  --spacing-xxl: 64px;
  --spacing-xl: 48px;
  --spacing-lg: 40px;
  --spacing-md: 32px;
  --spacing-sm: 24px;
  --spacing-xs: 16px;
  --spacing-xxs: 12px;
  --spacing-xxxs: 8px;
  --spacing-hair: 4px;
  --spacing-micro: 2px;

  /* Border Radius */
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-pill: 999px;

  /* Typography */
  --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;

  /* Animation */
  --duration-fast: 150ms;
  --duration-normal: 200ms;
  --duration-slow: 300ms;
  --ease-default: cubic-bezier(0.4, 0, 0.2, 1);
}
```

---

## Appendix C: TypeScript Interface Definitions

### Core Type Definitions

```typescript
// src/types/app.ts
export enum AppMode {
  VALIDATE = 'validate',
  STATS = 'stats',
  SYNC = 'sync',
  INDEX = 'index',
  REMOTE = 'remote',
  CHANGELOG = 'changelog',
}

export enum Severity {
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info',
}

export enum AgentKind {
  CLAUDE = 'claude',
  CODEX = 'codex',
  CODEX_SKILL_MANAGER = 'codexSkillManager',
  COPILOT = 'copilot',
}

// src/types/findings.ts
export interface Finding {
  id: string;
  ruleId: string;
  severity: Severity;
  agent: AgentKind;
  message: string;
  fileURL: URL;
  line: number;
  column?: number;
  codeContext?: string;
  suggestedFix?: SuggestedFix;
  timestamp: Date;
}

export interface SuggestedFix {
  description: string;
  search: string;
  replace: string;
  automated: boolean;
}

export interface ValidateFilters {
  severity?: Severity;
  agent?: AgentKind;
  searchText: string;
}

// src/types/analytics.ts
export interface ScanFrequencyMetrics {
  dailyCounts: Array<{
    date: Date;
    count: number;
  }>;
  totalScans: number;
  averagePerDay: number;
}

export interface ErrorTrendsReport {
  errorsByRule: Record<string, number>;
  totalErrors: number;
  mostCommonRule: string;
}

export interface SkillUsageRanking {
  skillName: string;
  agent: AgentKind;
  scanCount: number;
  lastScanned: Date;
}

// src/types/settings.ts
export interface AppSettings {
  autoScanOnLaunch: boolean;
  useSharedSkillsRoot: boolean;
  showFileCounts: boolean;
  confirmDeletion: boolean;
  telemetryEnabled: boolean;
  accentColor: AccentColor;
  densityMode: DensityMode;
  colorSchemeOverride: ColorScheme;
  defaultEditor: Editor;
}

export enum AccentColor {
  BLUE = 'blue',
  PURPLE = 'purple',
  GREEN = 'green',
  ORANGE = 'orange',
  PINK = 'pink',
  RED = 'red',
}

export enum DensityMode {
  COMPACT = 'compact',
  COMFORTABLE = 'comfortable',
  SPACIOUS = 'spacious',
}

export enum ColorScheme {
  SYSTEM = 'system',
  LIGHT = 'light',
  DARK = 'dark',
}

export enum Editor {
  VS_CODE = 'VS Code',
  CURSOR = 'Cursor',
  ZED = 'Zed',
  FINDER = 'Finder',
}
```

---

## Conclusion

This UI/UX review provides a comprehensive foundation for migrating the SkillsInspector Swift application to React/Tauri. The current SwiftUI implementation demonstrates:

- **Strong architectural patterns** that translate well to React
- **Comprehensive design tokens** ready for Tailwind v4 mapping
- **Clear component boundaries** for modular development
- **Desktop-specific features** requiring careful Tauri integration

### Next Steps

1. **Design System Migration:** Create a Storybook-based design system with mapped tokens
2. **Component Library:** Build reusable UI components with Radix UI
3. **State Architecture:** Implement Zustand + React Query for state management
4. **Tauri Integration:** Develop Rust backend commands for native features
5. **Quality Pipeline:** Set up visual regression, a11y, and E2E testing

---

*Report prepared for SkillsInspector React/Tauri migration project*
*January 25, 2026*
