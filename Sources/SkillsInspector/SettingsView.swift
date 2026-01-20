import SwiftUI
import SkillsCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEditor: Editor = EditorIntegration.defaultEditor
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case editor = "Editor"
        case appearance = "Appearance"
        case trust = "Trust"
        case privacy = "Privacy"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .editor: return "pencil"
            case .appearance: return "paintbrush"
            case .trust: return "hand.raised.fill"
            case .privacy: return "hand.raised.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            TabView(selection: $selectedTab) {
                GeneralTabView()
                    .tabItem {
                        Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                    }
                    .tag(SettingsTab.general)

                EditorTabView(selectedEditor: $selectedEditor)
                    .tabItem {
                        Label(SettingsTab.editor.rawValue, systemImage: SettingsTab.editor.icon)
                    }
                    .tag(SettingsTab.editor)

                AppearanceTabView()
                    .tabItem {
                        Label(SettingsTab.appearance.rawValue, systemImage: SettingsTab.appearance.icon)
                    }
                    .tag(SettingsTab.appearance)

                TrustTabView()
                    .tabItem {
                        Label(SettingsTab.trust.rawValue, systemImage: SettingsTab.trust.icon)
                    }
                    .tag(SettingsTab.trust)

                PrivacyTabView()
                    .tabItem {
                        Label(SettingsTab.privacy.rawValue, systemImage: SettingsTab.privacy.icon)
                    }
                    .tag(SettingsTab.privacy)
            }
            .padding(0)
        }
        .frame(width: 600, height: 500)
        .onChange(of: selectedEditor) { _, newValue in
            EditorIntegration.defaultEditor = newValue
        }
    }
    
    private var header: some View {
        HStack {
            Text("Settings")
                .heading2()
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(.bar)
    }
}

// MARK: - General Tab

struct GeneralTabView: View {
    @AppStorage("autoScanOnLaunch") private var autoScanOnLaunch = false
    @AppStorage("useSharedSkillsRoot") private var useSharedSkillsRoot = false
    @AppStorage("showFileCounts") private var showFileCounts = true
    @AppStorage("confirmDeletion") private var confirmDeletion = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                scanningCard
                displayCard
                safetyCard
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.Background.secondary)
    }
    
    private var scanningCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Scanning", systemImage: "doc.text.magnifyingglass")
                .heading3()
            
            Toggle(isOn: $autoScanOnLaunch) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-scan on launch")
                        .font(.callout)
                    Text("Automatically start scanning when the app launches")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
            .toggleStyle(.switch)
            
            Divider()
            
            Toggle(isOn: $useSharedSkillsRoot) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Single source of truth")
                        .font(.callout)
                    Text("Use the first Codex root as the master for all agents. Sync/Index won't compare agents in this mode.")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.blue)
    }
    
    private var displayCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Display", systemImage: "list.bullet")
                .heading3()
            
            Toggle(isOn: $showFileCounts) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Show file counts")
                        .font(.callout)
                    Text("Display the number of scanned files in the sidebar")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.purple)
    }
    
    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Safety", systemImage: "shield")
                .heading3()
            
            Toggle(isOn: $confirmDeletion) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Confirm deletion")
                        .font(.callout)
                    Text("Show confirmation dialog before deleting items")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.orange)
    }
}

// MARK: - Editor Tab

struct EditorTabView: View {
    @Binding var selectedEditor: Editor
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                editorCard
                detectedEditorsCard
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.Background.secondary)
    }
    
    private var editorCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Default Editor", systemImage: "pencil")
                .heading3()
            Picker("Default Editor", selection: $selectedEditor) {
                ForEach(Editor.allCases, id: \.self) { editor in
                    HStack {
                        Image(systemName: editor.icon)
                        Text(editor.rawValue)
                        Spacer()
                        if !editor.isInstalled() {
                            Text("Not Installed")
                                .captionText()
                                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                        }
                    }
                    .tag(editor)
                }
            }
            .pickerStyle(.menu)
            Text("Choose which editor to use when opening files.")
                .captionText()
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.blue)
    }
    
    private var detectedEditorsCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Detected Editors", systemImage: "checkmark.seal")
                .heading3()
            VStack(alignment: .leading, spacing: 8) {
                ForEach(EditorIntegration.installedEditors, id: \.self) { editor in
                    HStack(spacing: 8) {
                        Image(systemName: editor.icon)
                            .foregroundStyle(DesignTokens.Colors.Status.success)
                            .frame(width: 20)
                        Text(editor.rawValue)
                            .font(.callout)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignTokens.Colors.Status.success)
                            .font(.caption)
                    }
                }
                if EditorIntegration.installedEditors.count == 1 {
                    Text("Only Finder is available")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.green)
    }
}

// MARK: - Appearance Tab

struct AppearanceTabView: View {
    @AppStorage("accentColorName") private var accentColorName = "blue"
    @AppStorage("densityMode") private var densityMode = "comfortable"
    @AppStorage("colorSchemeOverride") private var colorSchemeOverride = "system"
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                colorSchemeCard
                accentColorCard
                densityCard
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.Background.secondary)
    }
    
    private var colorSchemeCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Theme", systemImage: "moon.stars")
                .heading3()
            
            Picker("Appearance", selection: $colorSchemeOverride) {
                Label("System", systemImage: "gear").tag("system")
                Label("Light", systemImage: "sun.max").tag("light")
                Label("Dark", systemImage: "moon").tag("dark")
            }
            .pickerStyle(.segmented)
            
            Text("Choose how the app appears. System matches your macOS settings.")
                .captionText()
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.purple)
    }
    
    private var accentColorCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Accent Color", systemImage: "paintpalette")
                .heading3()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(["blue", "purple", "green", "orange", "pink", "red"], id: \.self) { colorName in
                    Button {
                        accentColorName = colorName
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(colorForName(colorName))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if accentColorName == colorName {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.semibold)
                                    }
                                }
                            Text(colorName.capitalized)
                                .captionText()
                                .foregroundStyle(accentColorName == colorName ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Choose an accent color for highlights and interactive elements.")
                .captionText()
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.blue)
    }
    
    private var densityCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Density", systemImage: "rectangle.3.group")
                .heading3()
            
            Picker("Density", selection: $densityMode) {
                Text("Compact").tag("compact")
                Text("Comfortable").tag("comfortable")
                Text("Spacious").tag("spacious")
            }
            .pickerStyle(.segmented)
            
            Text("Adjust spacing and sizing of UI elements.")
                .captionText()
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.orange)
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return DesignTokens.Colors.Accent.blue
        case "purple": return DesignTokens.Colors.Accent.purple
        case "green": return DesignTokens.Colors.Accent.green
        case "orange": return DesignTokens.Colors.Accent.orange
        case "pink": return .pink
        case "red": return .red
        default: return DesignTokens.Colors.Accent.blue
        }
    }
}

// MARK: - Trust Tab

struct TrustTabView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TrustStoreViewModel()
    @State private var showAddKeySheet = false
    @State private var newKeyId = ""
    @State private var newPublicKey = ""
    @State private var newScopeSlug = ""

    private var activeKeys: [RemoteTrustStore.TrustedKey] {
        viewModel.keys.filter { !viewModel.revokedKeyIds.contains($0.keyId) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                infoCard
                keysCard
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.Background.secondary)
        .sheet(isPresented: $showAddKeySheet) {
            addKeySheet
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Trusted Signers", systemImage: "hand.raised.fill")
                .heading3()

            VStack(alignment: .leading, spacing: 4) {
                Text("Manage trusted public keys for skill signature verification.")
                    .font(.callout)
                Text("Keys added here will be used to verify signatures when installing remote skills.")
                    .captionText()
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.blue)
    }

    private var keysCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            HStack {
                Label("Trusted Keys", systemImage: "key.fill")
                    .heading3()
                Spacer()
                Button("Trust Signer") {
                    newKeyId = ""
                    newPublicKey = ""
                    newScopeSlug = ""
                    showAddKeySheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if activeKeys.isEmpty {
                emptyState
            } else {
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    ForEach(activeKeys, id: \.keyId) { key in
                        keyRow(key)
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.green)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "key.slash")
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
            Text("No trusted keys yet")
                .font(.callout)
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
            Text("Add a trusted signer key to begin verifying skill signatures.")
                .captionText()
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    private func keyRow(_ key: RemoteTrustStore.TrustedKey) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            VStack(alignment: .leading, spacing: 4) {
                Text(key.keyId)
                    .font(.callout)
                    .fontWeight(.medium)
                    .textSelection(.enabled)

                if let allowedSlugs = key.allowedSlugs, !allowedSlugs.isEmpty {
                    Text("Scoped to: \(allowedSlugs.joined(separator: ", "))")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                } else {
                    Text("All skills")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }

            Spacer()

            Button("Remove") {
                viewModel.revokeKey(keyId: key.keyId)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .background(DesignTokens.Colors.Background.tertiary.opacity(0.5))
        .cornerRadius(6)
    }

    private var addKeySheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Key Information")) {
                    TextField("Key ID", text: $newKeyId)
                        .textFieldStyle(.roundedBorder)
                    #if os(macOS)
                    TextEditor(text: $newPublicKey)
                        .frame(minHeight: 80)
                        .border(DesignTokens.Colors.Border.light)
                    #else
                    TextField("Public Key (Base64)", text: $newPublicKey, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                    #endif
                    TextField("Scope Slug (optional)", text: $newScopeSlug)
                        .textFieldStyle(.roundedBorder)
                    Text("Leave scope empty to trust all skills from this signer")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Trust Signer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddKeySheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addTrustedKey(
                            keyId: newKeyId,
                            publicKeyBase64: newPublicKey,
                            allowedSlugs: newScopeSlug.isEmpty ? nil : [newScopeSlug]
                        )
                        showAddKeySheet = false
                    }
                    .disabled(newKeyId.isEmpty || newPublicKey.isEmpty)
                }
            }
        }
    }
}

// MARK: - Privacy Tab

struct PrivacyTabView: View {
    @AppStorage("telemetryOptIn") private var telemetryOptIn = false
    @State private var showingPrivacyDetails = false
    @State private var showingEnableAlert = false

    private var telemetryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SkillsInspector", isDirectory: true)
            .appendingPathComponent("telemetry.jsonl") ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("telemetry.jsonl")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                telemetryCard
                privacyPolicyCard
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.Background.secondary)
        .alert("Enable Telemetry", isPresented: $showingEnableAlert) {
            Button("Cancel", role: .cancel) {
                telemetryOptIn = false
            }
            Button("Enable") {
                telemetryOptIn = true
            }
        } message: {
            Text(PRIVACY_NOTICE)
        }
    }

    private var telemetryCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Telemetry", systemImage: "chart.bar")
                .heading3()

            Toggle(isOn: Binding(
                get: { telemetryOptIn },
                set: { newValue in
                    if newValue {
                        showingEnableAlert = true
                    } else {
                        telemetryOptIn = false
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share anonymous usage data")
                        .font(.callout)
                    Text("Help improve SkillsInspector by sharing anonymous metrics")
                        .captionText()
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xxxs)

            telemetryMetrics
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.blue)
    }

    private var telemetryMetrics: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
            Text("What we collect:")
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.Text.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                    Text("Verified install count")
                        .captionText()
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                    Text("Blocked download count")
                        .captionText()
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                    Text("Publish run count")
                        .captionText()
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                    Text("App version")
                        .captionText()
                }
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.Status.error)
                    Text("No personally identifiable information")
                        .captionText()
                }
            }
        }
    }

    private var privacyPolicyCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Label("Data Retention", systemImage: "clock")
                .heading3()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxxs) {
                Text("Telemetry data is:")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.Accent.blue)
                        Text("Stored locally on your Mac")
                            .captionText()
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.Accent.blue)
                        Text("Automatically deleted after 30 days")
                            .captionText()
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.Accent.blue)
                        Text("Paths and user IDs are redacted")
                            .captionText()
                    }
                }
            }

            Divider()
                .padding(.vertical, DesignTokens.Spacing.xxxs)

            Button("View Full Privacy Notice") {
                showingPrivacyDetails = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .sheet(isPresented: $showingPrivacyDetails) {
                PrivacyNoticeSheet()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxxs)
        .cardStyle(tint: DesignTokens.Colors.Accent.purple)
    }
}

// MARK: - Privacy Notice Sheet

struct PrivacyNoticeSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    privacyNoticeContent
                }
                .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.Background.secondary)
            .navigationTitle("Privacy Notice")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(width: 500, height: 400)
    }

    private var privacyNoticeContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(PRIVACY_NOTICE)
                .font(.body)
                .foregroundStyle(DesignTokens.Colors.Text.primary)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("Data Collected")
                    .font(.headline)
                    .foregroundStyle(DesignTokens.Colors.Accent.blue)

                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("Number of verified skill installs")
                    bulletPoint("Number of blocked downloads (with reason category)")
                    bulletPoint("Number of publish runs (success/failure)")
                    bulletPoint("SkillsInspector app version")
                    bulletPoint("Anonymized installer ID (random 8-character identifier)")
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("What We Don't Collect")
                    .font(.headline)
                    .foregroundStyle(DesignTokens.Colors.Status.success)

                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("No usernames or real names")
                    bulletPoint("No file paths or directory names")
                    bulletPoint("No skill names or content")
                    bulletPoint("No IP addresses or location data")
                    bulletPoint("No device identifiers or serial numbers")
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("Data Retention")
                    .font(.headline)
                    .foregroundStyle(DesignTokens.Colors.Accent.purple)

                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("All telemetry data is stored locally")
                    bulletPoint("Data is automatically deleted after 30 days")
                    bulletPoint("You can clear telemetry at any time from Settings")
                    bulletPoint("Disabling telemetry stops all data collection")
                }
            }

            Text("By enabling telemetry, you help improve SkillsInspector while maintaining your privacy.")
                .font(.callout)
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .padding(.top, DesignTokens.Spacing.xs)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(DesignTokens.Colors.Accent.blue)
            Text(text)
                .font(.body)
                .foregroundStyle(DesignTokens.Colors.Text.primary)
        }
    }
}

// MARK: - Privacy Notice Text

private let PRIVACY_NOTICE = """
SkillsInspector collects anonymous usage data to help improve the app. This data is stored locally on your Mac and automatically deleted after 30 days.

We do not collect any personally identifiable information (PII). File paths, usernames, and skill names are redacted before storage.
"""

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
