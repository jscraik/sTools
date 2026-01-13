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
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .editor: return "pencil"
            case .appearance: return "paintbrush"
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
