import SwiftUI
import SkillsCore

struct RemoteView: View {
    @ObservedObject var viewModel: RemoteViewModel
    @ObservedObject var trustStoreVM: TrustStoreViewModel
    @State private var selectedSkill: RemoteSkill?
    @State private var trustPrompt: TrustPrompt?

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("Remote Library")
        } detail: {
            detailPanel
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
    private var sidebar: some View {
        ZStack {
            DesignTokens.Colors.Background.secondary.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Toolbar
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
                
                Divider()
                
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
                if let version = skill.latestVersion {
                    Text("v\(version)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(DesignTokens.Colors.Background.tertiary)
                        .cornerRadius(4)
                }
                
                provenanceBadge(for: skill)
                
                Spacer()
                
                if let _ = viewModel.installedVersions[skill.slug] {
                    Text("INSTALLED")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                }
            }
        }
        .padding(10)
        .background(
            ZStack {
                if isSelected {
                    DesignTokens.Colors.Accent.blue.opacity(0.12)
                } else {
                    DesignTokens.Colors.Background.primary.opacity(0.4)
                }
            }
        )
        .cornerRadius(DesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(isSelected ? DesignTokens.Colors.Accent.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func provenanceBadge(for skill: RemoteSkill) -> some View {
        let status = viewModel.provenanceStatus(for: skill.slug)
        let (icon, color): (String, Color) = {
            switch status {
            case .verified: return ("checkmark.seal.fill", DesignTokens.Colors.Status.success)
            case .failed: return ("exclamationmark.shield.fill", DesignTokens.Colors.Status.error)
            case .unknown: return ("questionmark.shield", DesignTokens.Colors.Icon.tertiary)
            }
        }()
        
        return HStack(spacing: 2) {
            Image(systemName: icon)
            Text(status.rawValue.uppercased())
        }
        .font(.system(size: 8, weight: .black))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let skill = selectedSkill {
            let previewState = viewModel.previewStateBySlug[skill.slug] ?? RemotePreviewState(status: .idle, preview: nil, manifest: nil, error: nil)
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    // Header Card
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                                Text(skill.displayName)
                                    .font(.system(.title2, weight: .black))
                                Text(skill.slug)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxxs) {
                                if let version = skill.latestVersion {
                                    Text("v\(version)")
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.bold)
                                }
                                provenanceBadge(for: skill)
                            }
                        }
                        
                        if let owner = viewModel.ownerBySlug[skill.slug] ?? nil {
                            HStack(spacing: DesignTokens.Spacing.xxxs) {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(DesignTokens.Colors.Accent.purple)
                                Text("by \(owner.displayName ?? owner.handle ?? "Unknown")")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                        }
                        
                        Divider()
                        
                        if let summary = skill.summary {
                            Text(summary)
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundStyle(DesignTokens.Colors.Text.primary)
                                .lineSpacing(4)
                        }
                    }
                    .padding(DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.Background.secondary.opacity(0.4))
                    .cornerRadius(DesignTokens.Radius.md)
                    
                    // Action Bar
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Button {
                            Task { await viewModel.install(skill: skill) }
                        } label: {
                            HStack {
                                if viewModel.installingSlug == skill.slug {
                                    ProgressView().scaleEffect(0.6).tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.down.fill")
                                }
                                Text(viewModel.installedVersions[skill.slug] != nil ? "Update Skill" : "Download & Install")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.customGlassProminent)
                        .tint(DesignTokens.Colors.Accent.blue)
                        .disabled(previewState.manifest == nil || viewModel.installingSlug != nil)
                        
                        if viewModel.isCrossIDEEnabled() {
                            Button {
                                Task { await viewModel.installToAllTargets(skill: skill) }
                            } label: {
                                Image(systemName: "square.grid.2x2.fill")
                                    .help("Install to all agent roots")
                            }
                            .buttonStyle(.customGlass)
                            .disabled(previewState.manifest == nil || viewModel.installingSlug != nil)
                        }
                        
                        Button {
                            Task { await viewModel.fetchPreview(for: skill) }
                        } label: {
                            Image(systemName: "checkmark.seal.fill")
                                .help("Re-verify provenance")
                        }
                        .buttonStyle(.customGlass)
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                    }
                    
                    // Security / Signer Card
                    signerCard(previewState: previewState)
                    
                    // Content Preview Card
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack {
                            Label("Skill Preview", systemImage: "doc.richtext")
                                .font(.system(size: 11, weight: .black))
                                .textCase(.uppercase)
                                .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                            
                            Spacer()
                            
                            if previewState.status == .loading {
                                ProgressView().scaleEffect(0.5)
                            }
                        }
                        
                        if let preview = previewState.preview, let markdown = preview.skillMarkdown {
                            MarkdownPreviewView(content: markdown)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 300)
                                .background(DesignTokens.Colors.Background.primary)
                                .cornerRadius(DesignTokens.Radius.sm)
                        } else if previewState.status == .loading {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Fetching secure preview...")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.title)
                                    .foregroundStyle(DesignTokens.Colors.Icon.tertiary)
                                Text(previewState.status == .unavailable ? "Preview unavailable" : "Select Verify to load content")
                                    .font(.subheadline)
                                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 150)
                            .background(DesignTokens.Colors.Background.tertiary.opacity(0.2))
                            .cornerRadius(DesignTokens.Radius.sm)
                        }
                    }
                    .padding(DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.Background.secondary.opacity(0.3))
                    .cornerRadius(DesignTokens.Radius.md)
                    
                    // Changelog Section
                    if let change = viewModel.changelogBySlug[skill.slug] ?? nil {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("RECENT CHANGES")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                            
                            Text(change)
                                .font(.system(.callout))
                                .padding(DesignTokens.Spacing.xs)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignTokens.Colors.Background.tertiary.opacity(0.3))
                                .cornerRadius(DesignTokens.Radius.sm)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.sm)
            }
            .background(DesignTokens.Colors.Background.primary)
            .sheet(item: $trustPrompt) { prompt in
                TrustSignerSheet(prompt: prompt, trustStoreVM: trustStoreVM)
            }
        } else {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignTokens.Colors.Icon.tertiary)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("Select a skill to explore")
                    .font(.title2.weight(.bold))
                
                Text("Browse the remote marketplace for secure, verified skills from the community.")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Colors.Background.primary)
        }
    }

    @ViewBuilder
    private func signerCard(previewState: RemotePreviewState) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("SECURITY & TRUST")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(DesignTokens.Colors.Text.tertiary)
            
            if let signerKeyId = previewState.manifest?.signerKeyId {
                let trusted = trustStoreVM.isTrusted(keyId: signerKeyId, slug: selectedSkill?.slug)
                
                HStack(spacing: DesignTokens.Spacing.xs) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signer Identification")
                            .font(.caption.weight(.bold))
                        Text(signerKeyId)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    }
                    
                    Spacer()
                    
                    if trusted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("TRUSTED")
                        }
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Colors.Status.success.opacity(0.1))
                        .cornerRadius(6)
                        
                        Button("Revoke") {
                            trustStoreVM.revokeKey(keyId: signerKeyId)
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    } else {
                        Button {
                            trustPrompt = TrustPrompt(keyId: signerKeyId, slug: selectedSkill?.slug)
                        } label: {
                            Label("Trust Signer", systemImage: "hand.raised.fill")
                        }
                        .buttonStyle(.customGlassProminent)
                        .tint(DesignTokens.Colors.Accent.orange)
                        .controlSize(.small)
                    }
                }
                .padding(DesignTokens.Spacing.xs)
                .background(DesignTokens.Colors.Background.tertiary.opacity(0.4))
                .cornerRadius(DesignTokens.Radius.sm)
            } else if previewState.status == .loading {
                Text("Verifying artifact integrity...")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                    .shimmer()
            } else {
                HStack {
                    Image(systemName: "questionmark.diamond.fill")
                        .foregroundStyle(DesignTokens.Colors.Status.warning)
                    Text("Unknown Signer: Artifact is not cryptographicly signed.")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
                .padding(DesignTokens.Spacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Colors.Status.warning.opacity(0.05))
                .cornerRadius(DesignTokens.Radius.sm)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.Background.secondary.opacity(0.3))
        .cornerRadius(DesignTokens.Radius.md)
    }
}

// MARK: - Skeleton Views
struct SkeletonSkillRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.tertiary)
                    .frame(width: 140, height: 16)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.tertiary)
                    .frame(width: 40, height: 16)
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignTokens.Colors.Background.tertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 12)
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.tertiary)
                    .frame(width: 80, height: 10)
                Spacer()
            }
        }
        .padding(10)
        .background(DesignTokens.Colors.Background.secondary.opacity(0.2))
        .cornerRadius(DesignTokens.Radius.md)
        .shimmer()
    }
}

private struct TrustPrompt: Identifiable {
    let id = UUID()
    let keyId: String
    let slug: String?
}

private struct TrustSignerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var publicKey = ""
    @State private var trustAllSkills = false
    let prompt: TrustPrompt
    let trustStoreVM: TrustStoreViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(DesignTokens.Colors.Accent.orange)
                Text("Trust New Signer")
                    .font(.title3.weight(.black))
            }
            
            Text("To install skills from this source, you must verify their public key. This ensures the content hasn't been tampered with.")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("KEY ID")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                Text(prompt.keyId)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.Background.tertiary.opacity(0.5))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("PUBLIC KEY (BASE64)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                TextEditor(text: $publicKey)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 100)
                    .padding(4)
                    .background(DesignTokens.Colors.Background.primary)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(DesignTokens.Colors.Border.light, lineWidth: 1))
            }

            Toggle(isOn: $trustAllSkills) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Global Trust")
                        .font(.subheadline.weight(.bold))
                    Text("Trust this signer for all skills they publish.")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.Colors.Text.tertiary)
                }
            }
            .toggleStyle(.switch)
            .padding(.vertical, 4)

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .buttonStyle(.customGlass)
                
                Spacer()
                
                Button {
                    let trimmed = publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    let allowed = trustAllSkills ? nil : prompt.slug.map { [$0] }
                    trustStoreVM.addTrustedKey(keyId: prompt.keyId, publicKeyBase64: trimmed, allowedSlugs: allowed)
                    dismiss()
                } label: {
                    Text("Authorize Trust")
                        .fontWeight(.bold)
                        .frame(width: 120)
                }
                .buttonStyle(.customGlassProminent)
                .tint(DesignTokens.Colors.Accent.orange)
                .disabled(publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(width: 440)
        .background(DesignTokens.Colors.Background.primary)
    }
}
