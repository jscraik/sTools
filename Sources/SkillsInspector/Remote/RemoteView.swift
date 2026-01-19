import SwiftUI
import SkillsCore

struct RemoteView: View {
    @ObservedObject var viewModel: RemoteViewModel
    @ObservedObject var trustStoreVM: TrustStoreViewModel
    @State private var selectedSkill: RemoteSkill?
    @State private var trustPrompt: TrustPrompt?

    var body: some View {
        // Use GeometryReader for proper sizing within parent NavigationSplitView
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar
                VStack(spacing: 0) {
                    // Header
                    headerView

                    Divider()

                    // Content
                    sidebarContent
                }
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)

                Divider()

                // Detail panel
                detailPanel
            }
        }
        .task {
            if viewModel.skills.isEmpty && !viewModel.isLoading {
                await viewModel.loadLatest()
            }
        }
        .onChange(of: selectedSkill?.id) { _, _ in
            if let skill = selectedSkill {
                Task { await viewModel.fetchPreview(for: skill) }
                Task { await viewModel.fetchChangelog(for: skill.slug) }
                Task { await viewModel.fetchOwner(for: skill.slug) }
            }
        }
    }
}

// MARK: - Subviews
private extension RemoteView {
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Label("Marketplace", systemImage: "square.grid.3x3.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(DesignTokens.Colors.Text.primary)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Button {
                    Task { await viewModel.loadLatest() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.customGlass)
                .help("Refresh library")
            }

            if viewModel.isBulkActionsEnabled() {
                Menu {
                    Button("Verify All") { Task { await viewModel.verifyAll() } }
                    Button("Update All Verified") { Task { await viewModel.updateAllVerified() } }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.customGlass)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.Background.primary.opacity(0.5))
    }

    @ViewBuilder
    private var sidebarContent: some View {
        ZStack {
            DesignTokens.Colors.Background.secondary.opacity(0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                if let progress = viewModel.bulkOperationProgress {
                    bulkOperationProgressView(progress)
                }

                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                        Text(error)
                            .lineLimit(2)
                    }
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.Status.error)
                    .padding(DesignTokens.Spacing.xs)
                    .background(DesignTokens.Colors.Status.error.opacity(0.1))
                }

                if viewModel.isLoading && viewModel.skills.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(0..<8, id: \.self) { _ in
                            SkeletonSkillRow()
                        }
                    }
                    .padding(DesignTokens.Spacing.sm)
                } else if viewModel.skills.isEmpty {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Spacer()
                        Image(systemName: "cloud.rain.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(DesignTokens.Colors.Icon.tertiary)
                        Text("No remote skills found")
                            .font(.headline)
                        Text("Check your connection or enable Mock Remote in settings.")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    List(selection: $selectedSkill) {
                        ForEach(viewModel.skills, id: \.id) { skill in
                            skillRow(skill)
                                .tag(skill)
                                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        ZStack {
            DesignTokens.Colors.Background.primary.ignoresSafeArea()

            if let skill = selectedSkill {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        // Title and status
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Text(skill.displayName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(DesignTokens.Colors.Text.primary)

                                Spacer()

                                if viewModel.installedVersions[skill.slug] != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(DesignTokens.Colors.Status.success)
                                            .font(.system(size: 12))
                                        Text("Installed")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(DesignTokens.Colors.Status.success)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DesignTokens.Colors.Status.success.opacity(0.1))
                                    .cornerRadius(DesignTokens.Radius.sm)
                                }
                            }

                            if let summary = skill.summary {
                                Text(summary)
                                    .font(.system(size: 13))
                                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                            }
                        }

                        Divider()

                        // Metadata
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            metadataRow(label: "Slug", value: skill.slug)
                            metadataRow(label: "Latest Version", value: skill.latestVersion)
                            if let installed = viewModel.installedVersions[skill.slug] {
                                metadataRow(label: "Installed Version", value: installed)
                            }
                            if let owner = viewModel.skillOwners[skill.slug] {
                                metadataRow(label: "Author", value: owner.displayName)
                                if let description = owner.description {
                                    Text(description)
                                        .font(.system(size: 11))
                                        .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                                        .padding(.leading, DesignTokens.Spacing.md)
                                }
                            }
                        }

                        Divider()

                        // Trust and Verification
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Trust & Verification")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DesignTokens.Colors.Text.secondary)

                            HStack(spacing: DesignTokens.Spacing.xs) {
                                if trustStoreVM.trustStore.isTrusted(skill.slug) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundStyle(DesignTokens.Colors.Status.success)
                                        Text("Trusted")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DesignTokens.Colors.Status.success.opacity(0.1))
                                    .cornerRadius(DesignTokens.Radius.sm)
                                }

                                if viewModel.isVerified(skill.slug) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(DesignTokens.Colors.Accent.blue)
                                        Text("Verified")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DesignTokens.Colors.Accent.blue.opacity(0.1))
                                    .cornerRadius(DesignTokens.Radius.sm)
                                }

                                if viewModel.isUpdateAvailable(for: skill.slug) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(DesignTokens.Colors.Status.warning)
                                        Text("Update Available")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(DesignTokens.Colors.Status.warning.opacity(0.1))
                                    .cornerRadius(DesignTokens.Radius.sm)
                                }
                            }
                        }

                        Divider()

                        // Actions
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Actions")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DesignTokens.Colors.Text.secondary)

                            HStack(spacing: DesignTokens.Spacing.xs) {
                                // Verify/Unverify
                                if viewModel.isVerified(skill.slug) {
                                    Button {
                                        Task { await viewModel.unverify(skill.slug) }
                                    } label: {
                                        Label("Unverify", systemImage: "xmark.seal")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.customGlass)
                                } else {
                                    Button {
                                        Task { await viewModel.verify(skill.slug) }
                                    } label: {
                                        Label("Verify", systemImage: "checkmark.seal")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.customGlassProminent)
                                }

                                // Trust/Untrust
                                if trustStoreVM.trustStore.isTrusted(skill.slug) {
                                    Button {
                                        trustStoreVM.trustStore.removeTrusted(skill.slug)
                                    } label: {
                                        Label("Untrust", systemImage: "xmark.shield")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.customGlass)
                                } else {
                                    Button {
                                        trustStoreVM.trustStore.addTrusted(skill.slug)
                                    } label: {
                                        Label("Trust", systemImage: "checkmark.shield")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.customGlass)
                                }

                                // Install
                                if viewModel.installedVersions[skill.slug] == nil {
                                    Button {
                                        Task { await viewModel.install(skill) }
                                    } label: {
                                        Label("Install", systemImage: "arrow.down.circle")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.customGlassProminent)
                                } else if viewModel.isUpdateAvailable(for: skill.slug) {
                                    Button {
                                        Task { await viewModel.update(skill) }
                                    } label: {
                                        Label("Update", systemImage: "arrow.up.circle")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .buttonStyle(.customGlassProminent)
                                }
                            }
                        }

                        Divider()

                        // Changelog
                        if let changelog = viewModel.skillChangelogs[skill.slug], !changelog.isEmpty {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("Changelog")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(DesignTokens.Colors.Text.secondary)

                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    ForEach(changelog.prefix(5), id: \.version) { entry in
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: DesignTokens.Spacing.xxxs) {
                                                Text(entry.version)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundStyle(DesignTokens.Colors.Text.primary)

                                                if let date = entry.date {
                                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                                                }
                                            }

                                            if !entry.changes.isEmpty {
                                                Text(entry.changes.joined(separator: "\n"))
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }

                            Divider()
                        }

                        // Preview
                        if let preview = viewModel.skillPreviews[skill.slug] {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("Preview")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(DesignTokens.Colors.Text.secondary)

                                Text(preview)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                                    .padding(DesignTokens.Spacing.sm)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(DesignTokens.Colors.Background.tertiary.opacity(0.5))
                                    .cornerRadius(DesignTokens.Radius.sm)
                            }

                            Divider()
                        }

                        Spacer()
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            } else {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignTokens.Colors.Icon.tertiary)
                    Text("Select a skill to view details")
                        .font(.headline)
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
        }
    }

    private func skillRow(_ skill: RemoteSkill) -> some View {
        let isSelected = selectedSkill?.id == skill.id
        let isUpdateAvailable = viewModel.isUpdateAvailable(for: skill)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.Text.primary)

                    Text(skill.slug)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                }

                Spacer()

                if isUpdateAvailable {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.Status.warning)
                        .font(.system(size: 14))
                } else if viewModel.installedVersions[skill.slug] != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                        .font(.system(size: 14))
                }
            }

            if let summary = skill.summary {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: DesignTokens.Spacing.xxxs) {
                if viewModel.isVerified(skill.slug) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.Colors.Accent.blue)
                }

                if trustStoreVM.trustStore.isTrusted(skill.slug) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                }

                Spacer()

                Text(skill.latestVersion)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
            }
        }
        .padding(DesignTokens.Spacing.xs)
        .background(
            Group {
                if isSelected {
                    DesignTokens.Colors.Accent.blue.opacity(0.1)
                } else {
                    DesignTokens.Colors.Background.secondary.opacity(0.3)
                }
            }
        )
        .cornerRadius(DesignTokens.Radius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .stroke(isSelected ? DesignTokens.Colors.Accent.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Colors.Text.primary)

            Spacer()
        }
    }

    private func bulkOperationProgressView(_ progress: BulkOperationProgress) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ProgressView()
                .scaleEffect(0.6)

            Text("\(progress.current)/\(progress.total)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)

            Text(progress.operation.displayName)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                .lineLimit(1)
        }
        .padding(DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.Accent.blue.opacity(0.1))
        .cornerRadius(DesignTokens.Radius.sm)
    }
}
