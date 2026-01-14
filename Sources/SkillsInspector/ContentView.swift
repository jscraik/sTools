import SwiftUI
import SkillsCore

struct LegacyContentView: View {
    @StateObject private var viewModel = InspectorViewModel()
    @StateObject private var syncVM = SyncViewModel()
    @StateObject private var indexVM = IndexViewModel()
    @StateObject private var changelogVM: ChangelogViewModel
    @StateObject private var trustStoreVM = TrustStoreViewModel()
    @StateObject private var remoteVM: RemoteViewModel
    @State private var mode: AppMode = .validate
    @State private var severityFilter: Severity? = nil
    @State private var agentFilter: AgentKind? = nil
    @State private var searchText: String = ""
    @State private var showingRootError = false
    @State private var rootErrorMessage = ""

    init() {
        let trustStoreVM = TrustStoreViewModel()
        let ledger = try? SkillLedger()
        let features = FeatureFlags.fromEnvironment()
        let telemetryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SkillsInspector", isDirectory: true)
            .appendingPathComponent("telemetry.jsonl")
        let telemetry = features.telemetryOptIn
            ? TelemetryClient.file(url: telemetryURL ?? FileManager.default.temporaryDirectory.appendingPathComponent("telemetry.jsonl"))
            : .noop
        _trustStoreVM = StateObject(wrappedValue: trustStoreVM)
        _changelogVM = StateObject(wrappedValue: ChangelogViewModel(ledger: ledger))
        _remoteVM = StateObject(
            wrappedValue: RemoteViewModel(
                client: RemoteSkillClient.live(),
                ledger: ledger,
                telemetry: telemetry,
                features: features,
                trustStoreProvider: { trustStoreVM.trustStore }
            )
        )
    }

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
                    copilotRoot: $viewModel.copilotRoot,
                    codexSkillManagerRoot: $viewModel.codexSkillManagerRoot,
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
                    codexSkillManagerRoot: viewModel.codexSkillManagerRoot,
                    copilotRoot: viewModel.copilotRoot,
                    recursive: $viewModel.recursive,
                    excludes: viewModel.effectiveExcludes,
                    excludeGlobs: viewModel.effectiveGlobExcludes
                )
            case .remote:
                RemoteView(viewModel: remoteVM, trustStoreVM: trustStoreVM)
            case .changelog:
                ChangelogView(viewModel: changelogVM)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .background(DesignTokens.Colors.Background.primary)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Spacer()
            }
            ToolbarItemGroup(placement: .principal) {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DesignTokens.Colors.Accent.blue)
                    Text("sTools")
                        .heading3()
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.vertical, DesignTokens.Spacing.xxxs)
                .background(cleanToolbarStyle())
            }
            ToolbarItemGroup(placement: .automatic) {
                HStack(spacing: DesignTokens.Spacing.xxxs) {
                    Image(systemName: "bell")
                        .accessibilityLabel("Notifications")
                    Divider()
                        .frame(height: 18)
                    Image(systemName: "magnifyingglass")
                        .accessibilityLabel("Search")
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.vertical, DesignTokens.Spacing.xxxs)
                .background(cleanToolbarStyle())
            }
        }
        .alert("Invalid Root Directory", isPresented: $showingRootError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(rootErrorMessage)
        }
    }

}

// MARK: - Subviews
private extension LegacyContentView {

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sidebar Header / Branding
            HStack(spacing: DesignTokens.Spacing.xxs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [DesignTokens.Colors.Accent.blue, DesignTokens.Colors.Accent.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("sTools")
                    .font(.system(size: 18, weight: .black))
                    .tracking(-0.5)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xs)
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    // Analysis Section
                    sidebarSection(title: "Analysis") {
                        VStack(spacing: DesignTokens.Spacing.micro) {
                            sidebarRow(title: "Validate", icon: "checkmark.seal.fill", value: .validate, tint: DesignTokens.Colors.Accent.blue) {
                                if !viewModel.findings.isEmpty {
                                    let errorCount = viewModel.findings.filter { $0.severity == .error }.count
                                    if errorCount > 0 {
                                        badge(text: "\(errorCount)", color: DesignTokens.Colors.Status.error)
                                    }
                                }
                            }
                            
                            sidebarRow(title: "Statistics", icon: "chart.bar.xaxis", value: .stats, tint: DesignTokens.Colors.Accent.pink)
                        }
                    }
                    
                    // Management Section
                    sidebarSection(title: "Management") {
                        VStack(spacing: DesignTokens.Spacing.micro) {
                            sidebarRow(title: "Sync", icon: "arrow.triangle.2.circlepath", value: .sync, tint: DesignTokens.Colors.Accent.green)
                            sidebarRow(title: "Index", icon: "text.book.closed.fill", value: .index, tint: DesignTokens.Colors.Accent.blue)
                            sidebarRow(title: "Remote", icon: "network", value: .remote, tint: DesignTokens.Colors.Accent.purple)
                            sidebarRow(title: "Changelog", icon: "clock.badge.checkmark.fill", value: .changelog, tint: DesignTokens.Colors.Accent.orange)
                        }
                    }
                    
                    // Scan Roots Section
                    sidebarSection(title: "Scan Roots") {
                        VStack(spacing: DesignTokens.Spacing.xxs) {
                            // Codex Roots
                            ForEach(Array(viewModel.codexRoots.enumerated()), id: \.offset) { index, url in
                                rootCard(
                                    title: viewModel.codexRoots.count > 1 ? "Codex \(index + 1)" : "Codex",
                                    url: url,
                                    tint: DesignTokens.Colors.Accent.blue,
                                    menu: {
                                        Button("Change Location...") {
                                            if let picked = pickFolder() {
                                                applyRootChange(index: index, newURL: picked, isClaude: false)
                                            }
                                        }
                                        if viewModel.codexRoots.count > 1 {
                                            Divider()
                                            Button("Remove", role: .destructive) {
                                                viewModel.codexRoots.remove(at: index)
                                            }
                                        }
                                    }
                                )
                            }
                            
                            addRootButton {
                                if let picked = pickFolder() {
                                    applyRootChange(index: viewModel.codexRoots.count, newURL: picked, isClaude: false, allowAppend: true)
                                }
                            }
                            .padding(.top, DesignTokens.Spacing.hair)
                            
                            // Claude Root
                            rootCard(
                                title: "Claude",
                                url: viewModel.claudeRoot,
                                tint: DesignTokens.Colors.Accent.purple,
                                menu: {
                                    Button("Change Location...") {
                                        if let picked = pickFolder() {
                                            applyRootChange(index: 0, newURL: picked, isClaude: true)
                                        }
                                    }
                                }
                            )
                            
                            // Copilot Root
                            rootCard(
                                title: "Copilot",
                                url: viewModel.copilotRoot,
                                tint: DesignTokens.Colors.Accent.orange,
                                menu: {
                                    Button(viewModel.copilotRoot == nil ? "Set Location..." : "Change Location...") {
                                        if let picked = pickFolder() {
                                            applyCopilotRoot(picked)
                                        }
                                    }
                                    if viewModel.copilotRoot != nil {
                                        Divider()
                                        Button("Clear", role: .destructive) {
                                            viewModel.copilotRoot = nil
                                        }
                                    }
                                }
                            )
                            
                            // CodexSkillManager Root
                            rootCard(
                                title: "CodexSkillManager",
                                url: viewModel.codexSkillManagerRoot,
                                tint: DesignTokens.Colors.Accent.green,
                                menu: {
                                    Button(viewModel.codexSkillManagerRoot == nil ? "Set Location..." : "Change Location...") {
                                        if let picked = pickFolder() {
                                            applyCSMRoot(picked)
                                        }
                                    }
                                    if viewModel.codexSkillManagerRoot != nil {
                                        Divider()
                                        Button("Clear", role: .destructive) {
                                            viewModel.codexSkillManagerRoot = nil
                                        }
                                    }
                                }
                            )
                        }
                    }
                    
                    // Options Section
                    sidebarSection(title: "Options") {
                        HStack {
                            Label("Recursive Scan", systemImage: "arrow.down.right.and.arrow.up.left")
                                .font(.caption)
                                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                            Spacer()
                            Toggle("", isOn: $viewModel.recursive)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .scaleEffect(0.7)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, DesignTokens.Spacing.hair)
                        .background(DesignTokens.Colors.Background.primary)
                        .cornerRadius(DesignTokens.Radius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .stroke(DesignTokens.Colors.Border.light, lineWidth: 1)
                        )
                    }
                    
                    // Filters Section
                    if mode == .validate {
                        sidebarSection(title: "Filters") {
                            VStack(spacing: DesignTokens.Spacing.xxs) {
                                filterPicker(title: "Severity", icon: "exclamationmark.triangle", selection: $severityFilter) {
                                    Text("All Severities").tag(Severity?.none)
                                    Divider()
                                    Text("Errors Only").tag(Severity?.some(.error))
                                    Text("Warnings").tag(Severity?.some(.warning))
                                    Text("Info").tag(Severity?.some(.info))
                                }
                                
                                filterPicker(title: "Agent", icon: "person.2", selection: $agentFilter) {
                                    Text("All Agents").tag(AgentKind?.none)
                                    Divider()
                                    ForEach(AgentKind.allCases, id: \.self) { agent in
                                        Text(agent.displayName).tag(AgentKind?.some(agent))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
        }
        .background(DesignTokens.Colors.Background.secondary.ignoresSafeArea())
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
    }

    // MARK: - Private Sidebar Components

    private func sidebarSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.hair)
                .padding(.bottom, 2)
            
            content()
        }
        .padding(.top, DesignTokens.Spacing.xs)
    }

    private func sidebarRow<V: View>(title: String, icon: String, value: AppMode, tint: Color, @ViewBuilder trailing: () -> V = { EmptyView() }) -> some View {
        Button {
            mode = value
        } label: {
            HStack(spacing: DesignTokens.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(mode == value ? .white : tint)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: mode == value ? .bold : .medium))
                
                Spacer()
                
                trailing()
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .foregroundStyle(mode == value ? .white : DesignTokens.Colors.Text.primary)
            .background {
                if mode == value {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(tint.gradient)
                        .shadow(color: tint.opacity(0.4), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(Color.clear)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }

    private func rootCard<M: View>(title: String, url: URL?, tint: Color, @ViewBuilder menu: () -> M) -> some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            // Precise Status Indicator
            ZStack {
                Circle()
                    .fill(statusColor(for: url).opacity(0.12))
                    .frame(width: 24, height: 24)
                
                Image(systemName: statusIcon(for: url))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(statusColor(for: url))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.Text.primary)
                
                Group {
                    if let url = url {
                        Text(shortenPath(url.path))
                    } else {
                        Text("Not configured")
                    }
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                menu()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.Icon.tertiary)
                    .padding(6)
                    .background(DesignTokens.Colors.Background.tertiary.opacity(0.4))
                    .clipShape(Circle())
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxs)
        .padding(.vertical, DesignTokens.Spacing.xxxs)
        .background(DesignTokens.Colors.Background.primary)
        .cornerRadius(DesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Colors.Border.light, lineWidth: 1)
        )
    }

    private func addRootButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xxs) {
                ZStack {
                    Circle()
                        .stroke(DesignTokens.Colors.Accent.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2]))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.Accent.blue)
                }
                
                Text("Add Codex Root")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.Accent.blue)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.xxs)
            .padding(.vertical, DesignTokens.Spacing.xxxs)
            .background(DesignTokens.Colors.Accent.blue.opacity(0.06))
            .cornerRadius(DesignTokens.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(DesignTokens.Colors.Accent.blue.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }

    private func statusColor(for url: URL?) -> Color {
        guard let url = url else { return DesignTokens.Colors.Accent.gray }
        return FileManager.default.fileExists(atPath: url.path) ? DesignTokens.Colors.Status.success : DesignTokens.Colors.Status.error
    }

    private func statusIcon(for url: URL?) -> String {
        guard let url = url else { return "questionmark" }
        return FileManager.default.fileExists(atPath: url.path) ? "checkmark" : "exclamationmark"
    }

    private func filterPicker<S: View>(title: String, icon: String, selection: Binding<Severity?>, @ViewBuilder content: () -> S) -> some View {
        Menu {
            content()
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, DesignTokens.Spacing.hair)
            .background(DesignTokens.Colors.Background.primary)
            .cornerRadius(DesignTokens.Spacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .stroke(DesignTokens.Colors.Border.light, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func filterPicker<S: View>(title: String, icon: String, selection: Binding<AgentKind?>, @ViewBuilder content: () -> S) -> some View {
        Menu {
            content()
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, DesignTokens.Spacing.hair)
            .background(DesignTokens.Colors.Background.primary)
            .cornerRadius(DesignTokens.Radius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .stroke(DesignTokens.Colors.Border.light, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Actions
private extension LegacyContentView {

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

    private func applyCSMRoot(_ newURL: URL) {
        guard viewModel.validateRoot(newURL) else {
            rootErrorMessage = "The selected CodexSkillManager path is not a valid directory:\n\(newURL.path)"
            showingRootError = true
            return
        }
        viewModel.codexSkillManagerRoot = newURL
    }

    private func applyCopilotRoot(_ newURL: URL) {
        guard viewModel.validateRoot(newURL) else {
            rootErrorMessage = "The selected Copilot path is not a valid directory:\n\(newURL.path)"
            showingRootError = true
            return
        }
        viewModel.copilotRoot = newURL
    }

}

// MARK: - Helpers
private extension LegacyContentView {
    private func shortenPath(_ path: String) -> String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let shortened = path.replacingOccurrences(of: homePath, with: "~")
        
        // If path is still too long, show just the last few components
        let components = shortened.components(separatedBy: "/")
        if components.count > 3 && shortened.count > 40 {
            let lastComponents = components.suffix(2).joined(separator: "/")
            return ".../" + lastComponents
        }
        
        return shortened
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

    private var cleanBackground: some View {
        DesignTokens.Colors.Background.primary
    }

    private var cleanSidebarBackground: some View {
        DesignTokens.Colors.Background.secondary
    }
}



// Alias for backward compatibility
typealias ContentView = LegacyContentView
