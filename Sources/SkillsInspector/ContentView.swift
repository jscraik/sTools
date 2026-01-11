import SwiftUI
import SkillsCore

struct ContentView: View {
    @StateObject private var viewModel = InspectorViewModel()
    @StateObject private var syncVM = SyncViewModel()
    @StateObject private var indexVM = IndexViewModel()
    @State private var mode: AppMode = .validate
    @State private var severityFilter: Severity? = nil
    @State private var agentFilter: AgentKind? = nil
    @State private var searchText: String = ""
    @State private var showingRootError = false
    @State private var rootErrorMessage = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            switch mode {
            case .validate:
                ValidateView(
                    viewModel: viewModel,
                    severityFilter: $severityFilter,
                    agentFilter: $agentFilter,
                    searchText: $searchText
                )
            case .stats:
                StatsView(
                    viewModel: viewModel,
                    mode: $mode,
                    severityFilter: $severityFilter,
                    agentFilter: $agentFilter
                )
            case .sync:
                SyncView(
                    viewModel: syncVM,
                    codexRoots: $viewModel.codexRoots,
                    claudeRoot: $viewModel.claudeRoot,
                    recursive: $viewModel.recursive,
                    maxDepth: $viewModel.maxDepth,
                    excludeInput: $viewModel.excludeInput,
                    excludeGlobInput: $viewModel.excludeGlobInput
                )
            case .index:
                IndexView(
                    viewModel: indexVM,
                    codexRoots: viewModel.codexRoots,
                    claudeRoot: viewModel.claudeRoot,
                    recursive: $viewModel.recursive,
                    excludes: viewModel.effectiveExcludes,
                    excludeGlobs: viewModel.effectiveGlobExcludes
                )
            }
        }
        .navigationSplitViewColumnWidth(ideal: 240)
        .alert("Invalid Root Directory", isPresented: $showingRootError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(rootErrorMessage)
        }
    }

    private var sidebar: some View {
        List(selection: $mode) {
            Section {
                NavigationLink(value: AppMode.validate) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .frame(width: 20)
                            .foregroundStyle(mode == .validate ? .accentColor : DesignTokens.Colors.Icon.secondary)
                        Text("Validate")
                            .fontWeight(mode == .validate ? .medium : .regular)
                        Spacer()
                        if !viewModel.findings.isEmpty {
                            let errorCount = viewModel.findings.filter { $0.severity == .error }.count
                            if errorCount > 0 {
                                Text("\(errorCount)")
                                    .captionText(emphasis: true)
                                    .foregroundStyle(DesignTokens.Colors.Status.error)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignTokens.Colors.Status.error.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                NavigationLink(value: AppMode.stats) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .frame(width: 20)
                            .foregroundStyle(mode == .stats ? .accentColor : DesignTokens.Colors.Icon.secondary)
                        Text("Statistics")
                            .fontWeight(mode == .stats ? .medium : .regular)
                        Spacer()
                    }
                }
                NavigationLink(value: AppMode.sync) {
                    HStack {
                        Image(systemName: "arrow.2.squarepath")
                            .frame(width: 20)
                            .foregroundStyle(mode == .sync ? .accentColor : DesignTokens.Colors.Icon.secondary)
                        Text("Sync")
                            .fontWeight(mode == .sync ? .medium : .regular)
                        Spacer()
                    }
                }
                NavigationLink(value: AppMode.index) {
                    HStack {
                        Image(systemName: "doc.text")
                            .frame(width: 20)
                            .foregroundStyle(mode == .index ? .accentColor : DesignTokens.Colors.Icon.secondary)
                        Text("Index")
                            .fontWeight(mode == .index ? .medium : .regular)
                        Spacer()
                    }
                }
            } header: {
                Text("Mode")
            }

            Section {
                ForEach(Array(viewModel.codexRoots.enumerated()), id: \.offset) { index, url in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.hair) {
                        RootRow(title: "Codex \(index + 1)", url: url) { newURL in
                            applyRootChange(index: index, newURL: newURL, isClaude: false)
                        }
                        HStack(spacing: DesignTokens.Spacing.xxxs) {
                            statusDot(for: url)
                            Text(url.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            if viewModel.codexRoots.count > 1 {
                                Button(role: .destructive) {
                                    viewModel.codexRoots.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.borderless)
                                .help("Remove Codex root")
                            }
                        }
                    }
                }

                Button {
                    if let picked = pickFolder() {
                        applyRootChange(index: viewModel.codexRoots.count, newURL: picked, isClaude: false, allowAppend: true)
                    }
                } label: {
                    Label("Add Codex Root", systemImage: "plus.circle")
                }
                .buttonStyle(.borderless)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.hair) {
                    RootRow(title: "Claude", url: viewModel.claudeRoot) { newURL in
                        applyRootChange(index: 0, newURL: newURL, isClaude: true)
                    }
                    HStack(spacing: DesignTokens.Spacing.xxxs) {
                        statusDot(for: viewModel.claudeRoot, tint: DesignTokens.Colors.Accent.purple)
                        Text(viewModel.claudeRoot.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                }
            } header: {
                Text("Scan Roots")
            }
            
            Section {
                Toggle("Recursive", isOn: $viewModel.recursive)
                    .toggleStyle(.switch)
            } header: {
                Text("Options")
            }

            if mode == .validate {
                Section {
                    Picker(selection: $severityFilter) {
                        Text("All").tag(Severity?.none)
                        Text("Error").tag(Severity?.some(.error))
                        Text("Warning").tag(Severity?.some(.warning))
                        Text("Info").tag(Severity?.some(.info))
                    } label: {
                        Label("Severity", systemImage: "exclamationmark.triangle")
                    }
                    .pickerStyle(.menu)

                    Picker(selection: $agentFilter) {
                        Text("All").tag(AgentKind?.none)
                        Text("Codex").tag(AgentKind?.some(.codex))
                        Text("Claude").tag(AgentKind?.some(.claude))
                    } label: {
                        Label("Agent", systemImage: "person.2")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Filters")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 350)
    }

    private func applyRootChange(index: Int, newURL: URL, isClaude: Bool, allowAppend: Bool = false) {
        guard viewModel.validateRoot(newURL) else {
            rootErrorMessage = "The selected path is not a valid skills directory:\n\(newURL.path)"
            showingRootError = true
            return
        }
        if isClaude {
            viewModel.claudeRoot = newURL
            return
        }
        if allowAppend && index >= viewModel.codexRoots.count {
            viewModel.codexRoots.append(newURL)
        } else if index < viewModel.codexRoots.count {
            viewModel.codexRoots[index] = newURL
        }
    }
    
    private func statusDot(for url: URL, tint: Color = DesignTokens.Colors.Accent.orange) -> some View {
        let exists = FileManager.default.fileExists(atPath: url.path)
        return Image(systemName: exists ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(exists ? DesignTokens.Colors.Status.success : DesignTokens.Colors.Status.error)
            .help(exists ? "Directory exists" : "Directory missing")
            .font(.caption2)
    }

    private func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.canCreateDirectories = false
        panel.title = "Select Skills Root Directory"
        panel.prompt = "Select"
        panel.message = "Choose the root directory containing skill folders (SKILL.md files)"

        return panel.runModal() == .OK ? panel.url : nil
    }
}

struct RootRow: View {
    let title: String
    let url: URL
    let onPick: (URL) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("Select") {
                if let picked = pickFolder() {
                    onPick(picked)
                }
            }
            .accessibilityLabel("Select \(title) folder")
            .buttonStyle(.bordered)
            .controlSize(.small)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(url.path)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.primary)
            Spacer()
        }
    }

    private func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.canCreateDirectories = false
        panel.title = "Select Skills Root Directory"
        panel.prompt = "Select"
        panel.message = "Choose the root directory containing skill folders (SKILL.md files)"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
