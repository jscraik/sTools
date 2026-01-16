import SwiftUI
import SkillsCore

/// Security settings UI for configuring ACIP scanner and quarantine settings
public struct SecuritySettingsView: View {
    @State private var securityConfig = SecurityConfig()
    @State private var quarantineStore = QuarantineStore()
    @State private var quarantinedCount = 0
    @State private var isLoading = false

    public init() {}

    public var body: some View {
        Form {
            // Preset Section
            Section {
                Picker("Security Level", selection: $securityPreset) {
                    Text("Default").tag(Preset.default)
                    Text("Permissive").tag(Preset.permissive)
                    Text("Strict").tag(Preset.strict)
                }
                .pickerStyle(.segmented)

                Text(presetDescription)
                    .font(.system(size: DesignTokens.Typography.BodySmall.size))
                    .foregroundStyle(DesignTokens.Colors.Text.secondary)
            } header: {
                Text("Security Preset")
            } footer: {
                Text("Presets configure the ACIP scanner sensitivity and allowed patterns.")
            }

            // Scan Configuration
            Section {
                Toggle("Scan Code Blocks", isOn: $securityConfig.scanCodeBlocks)
                Toggle("Scan References", isOn: $securityConfig.scanReferences)

                HStack {
                    Text("Max File Size")
                    Spacer()
                    Text("\(formatFileSize(securityConfig.maxFileSize))")
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }

                Stepper("Max File Size: \(formatFileSize(securityConfig.maxFileSize))",
                        value: $securityConfig.maxFileSize,
                        in: 1024...10*1024*1024,
                        step: 1024*1024)
                .font(.system(size: DesignTokens.Typography.Body.size))
            } header: {
                Text("Scan Configuration")
            } footer: {
                Text("Configure which content types to scan and file size limits.")
            }

            // Pattern Configuration
            Section {
                List {
                    ForEach(ACIPScanner.InjectionPattern.builtInPatterns, id: \.id) { pattern in
                        HStack {
                            Toggle(isOn: bindingForPattern(pattern.id)) {
                                HStack {
                                    severityIcon(pattern.severity)
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
                                        Text(pattern.name)
                                            .font(.system(size: DesignTokens.Typography.Body.size, weight: DesignTokens.Typography.Body.emphasis))
                                        Text(pattern.description)
                                            .font(.system(size: DesignTokens.Typography.BodySmall.size))
                                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Detection Patterns")
            } footer: {
                Text("Select which ACIP v1.3 injection patterns to enable during scanning.")
            }

            // Allowlist Configuration
            Section {
                if securityConfig.allowlist.isEmpty {
                    Text("No allowlist patterns configured")
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                } else {
                    ForEach(Array(securityConfig.allowlist.enumerated()), id: \.offset) { _, pattern in
                        Text(pattern)
                            .font(.system(size: DesignTokens.Typography.Body.size))
                            .monospaced()
                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    }
                }

                Button("Add Allowlist Pattern") {
                    // TODO: Implement add pattern sheet
                }
                .disabled(true)
            } header: {
                Text("Allowlist")
            } footer: {
                Text("Patterns that bypass security checks. Use with caution.")
            }

            // Blocklist Configuration
            Section {
                if securityConfig.blocklist.isEmpty {
                    Text("No blocklist patterns configured")
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                } else {
                    ForEach(Array(securityConfig.blocklist.enumerated()), id: \.offset) { _, pattern in
                        Text(pattern)
                            .font(.system(size: DesignTokens.Typography.Body.size))
                            .monospaced()
                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    }
                }

                Button("Add Blocklist Pattern") {
                    // TODO: Implement add pattern sheet
                }
                .disabled(true)
            } header: {
                Text("Blocklist")
            } footer: {
                Text("Patterns that immediately block content.")
            }

            // Quarantine Stats
            Section {
                HStack {
                    Text("Quarantined Skills")
                    Spacer()
                    Text("\(quarantinedCount)")
                        .foregroundStyle(DesignTokens.Colors.Text.secondary)
                }

                NavigationLink {
                    QuarantineReviewView()
                } label: {
                    Label("Review Quarantine", systemImage: "shield.checkered")
                }
            } header: {
                Text("Quarantine")
            } footer: {
                Text("Review and manage skills that have been quarantined due to security issues.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Security Settings")
        .task {
            await loadSettings()
        }
    }

    // MARK: - Computed Properties

    private enum Preset: String {
        case `default`
        case permissive
        case strict
    }

    @State private var securityPreset: Preset = .default

    private var presetDescription: String {
        switch securityPreset {
        case .default:
            return "Balanced security with standard ACIP v1.3 patterns enabled."
        case .permissive:
            return "Reduced security checks, allows more content through."
        case .strict:
            return "Maximum security with all patterns enabled and strict validation."
        }
    }

    // MARK: - Helper Methods

    private func bindingForPattern(_ patternId: String) -> Binding<Bool> {
        Binding(
            get: {
                self.securityConfig.enabledPatterns.contains(patternId) || self.securityConfig.enabledPatterns.isEmpty
            },
            set: { newValue in
                if newValue {
                    if !self.securityConfig.enabledPatterns.contains(patternId) {
                        self.securityConfig.enabledPatterns.append(patternId)
                    }
                } else {
                    self.securityConfig.enabledPatterns.removeAll { $0 == patternId }
                }
            }
        )
    }

    private func severityIcon(_ severity: ACIPScanner.InjectionPattern.Severity) -> some View {
        let (iconName, color): (String, Color) = {
            switch severity {
            case .critical:
                return ("xmark.circle.fill", DesignTokens.Colors.Accent.red)
            case .high:
                return ("exclamationmark.triangle.fill", DesignTokens.Colors.Accent.orange)
            case .medium:
                return ("exclamationmark.triangle", DesignTokens.Colors.Accent.yellow)
            case .low:
                return ("info.circle.fill", DesignTokens.Colors.Accent.blue)
            }
        }()

        return Image(systemName: iconName)
            .font(.system(size: 12))
            .foregroundStyle(color)
            .frame(width: 16)
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        // Load default config
        securityConfig = SecurityConfig()

        // Load quarantine count
        let items = await quarantineStore.list()
        quarantinedCount = items.filter { $0.status == .pending }.count
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SecuritySettingsView()
    }
}
