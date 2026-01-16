import SwiftUI
import SkillsCore

/// SwiftUI search interface with real-time search, results display, and skill preview
public struct SearchView: View {
    @State private var searchEngine: SkillSearchEngine?
    @State private var searchQuery = ""
    @State private var searchResults: [SkillSearchEngine.SearchResult] = []
    @State private var isSearching = false
    @State private var selectedAgent: AgentKind?
    @State private var selectedIndex: Int?
    @State private var searchTask: Task<Void, Never>?

    // Search configuration
    @State private var resultLimit = 20
    @State private var showStats = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailPanel
        }
        .task {
            try? await initializeSearchEngine()
        }
        .navigationTitle("Search Skills")
        .sheet(isPresented: $showStats) {
            SearchStatsSheet(searchEngine: searchEngine)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            Divider()

            // Filters
            filters

            Divider()

            // Results
            if searchQuery.isEmpty {
                emptyState
            } else if isSearching {
                loadingView
            } else if searchResults.isEmpty {
                noResultsState
            } else {
                resultsList
            }
        }
        .navigationSplitViewColumnWidth(min: 300, ideal: 400)
    }

    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.Colors.Icon.secondary)

            TextField("Search skills...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: DesignTokens.Typography.Body.size))
                .autocorrectionDisabled()
                .onChange(of: searchQuery) { _, newValue in
                    debouncedSearch(newValue)
                }
                .onSubmit {
                    if !searchResults.isEmpty {
                        selectedIndex = 0
                    }
                }

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    searchResults = []
                    selectedIndex = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.Icon.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.Background.secondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Agent filter
                Picker("Agent", selection: $selectedAgent) {
                    Text("All Agents").tag(nil as AgentKind?)
                    Text("Codex").tag(.codex as AgentKind?)
                    Text("Claude").tag(.claude as AgentKind?)
                    Text("Copilot").tag(.copilot as AgentKind?)
                }
                .pickerStyle(.menu)
                .frame(height: 28)

                Divider()
                    .frame(height: 20)

                // Limit stepper
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("Limit:")
                        .font(.system(size: DesignTokens.Typography.BodySmall.size))
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)

                    Picker("", selection: $resultLimit) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                        Text("100").tag(100)
                    }
                    .pickerStyle(.menu)
                    .frame(height: 28)
                }

                Divider()
                    .frame(height: 20)

                // Stats button
                Button {
                    showStats = true
                } label: {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 14))
                }
                .buttonStyle(.clean)
                .help("Index Statistics")
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.Background.tertiary.opacity(0.5))
    }

    private var resultsList: some View {
        List(searchResults.indices, id: \.self, selection: $selectedIndex) { index in
            SearchResultRow(result: searchResults[index]) {
                selectedIndex = index
            }
            .tag(index)
            .contentShape(Rectangle())
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.Icon.tertiary)

            Text("Search Skills")
                .font(.system(size: DesignTokens.Typography.Heading3.size, weight: DesignTokens.Typography.Heading3.weight))

            Text("Enter a search query to find skills by name, description, or content.")
                .font(.system(size: DesignTokens.Typography.Body.size))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Searching...")
                .font(.system(size: DesignTokens.Typography.Body.size))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.Icon.tertiary)

            Text("No Results")
                .font(.system(size: DesignTokens.Typography.Heading3.size, weight: DesignTokens.Typography.Heading3.weight))

            Text("No skills match your search query. Try different keywords.")
                .font(.system(size: DesignTokens.Typography.Body.size))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Detail Panel

    private var detailPanel: some View {
        Group {
            if let index = selectedIndex, index < searchResults.count {
                SearchResultDetailView(result: searchResults[index])
            } else {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.Icon.tertiary)

                    Text("Select a Result")
                        .font(.system(size: DesignTokens.Typography.Heading3.size, weight: DesignTokens.Typography.Heading3.weight))

                    Text("Choose a search result to view details and open the skill.")
                        .font(.system(size: DesignTokens.Typography.Body.size))
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Helper Methods

    private func initializeSearchEngine() async throws {
        searchEngine = try SkillSearchEngine.default()
    }

    private func debouncedSearch(_ query: String) {
        // Cancel previous search task
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        // Debounce by 300ms
        searchTask = Task {
            isSearching = true
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            await performSearch(query)
            isSearching = false
        }
    }

    private func performSearch(_ query: String) async {
        guard let engine = searchEngine else { return }

        var filter = SkillSearchEngine.SearchFilter()

        if let agent = selectedAgent {
            filter.agent = agent
        }

        do {
            let results = try await engine.search(query: query, filters: filter, limit: resultLimit)
            searchResults = results
        } catch {
            // Handle search error
            searchResults = []
        }
    }
}

// MARK: - SearchResultDetailView

private struct SearchResultDetailView: View {
    let result: SkillSearchEngine.SearchResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text(result.skillName)
                            .font(.system(size: DesignTokens.Typography.Heading2.size, weight: DesignTokens.Typography.Heading2.weight))

                        Text(result.skillSlug)
                            .font(.system(size: DesignTokens.Typography.Body.size))
                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    }

                    Spacer()

                    agentBadge
                }

                Divider()

                // Snippet
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Matched Content")
                        .font(.system(size: DesignTokens.Typography.Heading3.size, weight: DesignTokens.Typography.Heading3.weight))

                    Text(attributedSnippet)
                        .font(.system(size: DesignTokens.Typography.Body.size))
                        .padding(DesignTokens.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignTokens.Colors.Background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                }

                Divider()

                // Metadata
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Details")
                        .font(.system(size: DesignTokens.Typography.Heading3.size, weight: DesignTokens.Typography.Heading3.weight))

                    detailRow("BM25 Score", String(format: "%.4f", result.rank))
                    detailRow("Agent", result.agent.rawValue.capitalized)
                    detailRow("File Path", result.filePath)
                }

                Spacer()

                // Actions
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Button {
                        NSWorkspace.shared.open(URL(fileURLWithPath: result.filePath))
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result.filePath, forType: .string)
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .navigationTitle("Skill Details")
    }

    private var agentBadge: some View {
        let (iconName, color) = agentIconAndColor

        return HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundStyle(color)

            Text(result.agent.rawValue.capitalized)
                .font(.system(size: DesignTokens.Typography.Body.size, weight: DesignTokens.Typography.Body.emphasis))
                .foregroundStyle(color)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var attributedSnippet: AttributedString {
        let snippet = result.snippet
            .replacingOccurrences(of: "<mark>", with: "||")
            .replacingOccurrences(of: "</mark>", with: "||")

        let parts = snippet.split(separator: "||", maxSplits: 2, omittingEmptySubsequences: false)

        var result = AttributedString(String(parts[0]))

        if parts.count > 1 {
            var highlighted = AttributedString(String(parts[1]))
            highlighted.font = .system(size: DesignTokens.Typography.Body.size, weight: .bold)
            highlighted.backgroundColor = DesignTokens.Colors.Accent.yellow.opacity(0.3)
            result.append(highlighted)
        }

        if parts.count > 2 {
            result.append(AttributedString(String(parts[2])))
        }

        return result
    }

    private var agentIconAndColor: (String, Color) {
        switch result.agent {
        case .codex:
            return ("cube.fill", DesignTokens.Colors.Accent.blue)
        case .claude:
            return ("sparkles", DesignTokens.Colors.Accent.purple)
        case .copilot:
            return ("brain", DesignTokens.Colors.Accent.green)
        default:
            return ("square.fill", DesignTokens.Colors.Accent.gray)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Body.size, weight: DesignTokens.Typography.Body.emphasis))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.system(size: DesignTokens.Typography.Body.size))
                .foregroundStyle(DesignTokens.Colors.Text.primary)

            Spacer()
        }
    }
}

// MARK: - SearchStatsSheet

private struct SearchStatsSheet: View {
    let searchEngine: SkillSearchEngine?
    @State private var stats: SkillSearchEngine.Stats?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Index Statistics")
                .font(.system(size: DesignTokens.Typography.Heading2.size, weight: DesignTokens.Typography.Heading2.weight))

            if isLoading {
                ProgressView("Loading...")
            } else if let stats = stats {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    statRow("Total Skills", "\(stats.totalSkills)")
                    statRow("Index Size", formatBytes(stats.indexSize))
                    statRow("Last Indexed", formatDate(stats.lastIndexed))
                }
            }

            Divider()

            Button("Done") {
                // Sheet will dismiss automatically
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(width: 400)
        .task {
            await loadStats()
        }
    }

    private func loadStats() async {
        isLoading = true
        defer { isLoading = false }

        guard let engine = searchEngine else { return }
        stats = try? await engine.getStats()
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Body.size, weight: DesignTokens.Typography.Body.emphasis))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)

            Spacer()

            Text(value)
                .font(.system(size: DesignTokens.Typography.Body.size))
                .foregroundStyle(DesignTokens.Colors.Text.primary)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}
