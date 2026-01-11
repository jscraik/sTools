import SwiftUI
import SkillsCore

struct SyncDetailView: View {
    let selection: SyncViewModel.SyncSelection
    let codexRoot: URL
    let claudeRoot: URL
    @State private var codexContent: String = ""
    @State private var claudeContent: String = ""
    @State private var loadError: String?
    @State private var statusMessage: String?
    @State private var diffText: String = ""
    @State private var isLoading = false
    @State private var showingCopyConfirmation = false
    @State private var pendingCopyOperation: CopyOperation?
    @State private var showLineNumbers = true
    @State private var diffViewMode: DiffViewMode = .unified
    
    enum DiffViewMode: String, CaseIterable {
        case unified = "Unified"
        case sideBySide = "Side by Side"
    }

    private var skillName: String {
        switch selection {
        case .onlyCodex(let n), .onlyClaude(let n), .different(let n):
            return n
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: headerIcon)
                            .foregroundStyle(headerColor)
                            .font(.title2)
                        Text(headerLabel)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(headerColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(headerColor.opacity(0.15))
                            .cornerRadius(4)
                    }
                    
                    Text(skillName)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text(headerDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                if let statusMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text(statusMessage)
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading files...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                } else if let loadError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(loadError)
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.1))
                    .cornerRadius(8)
                } else if codexContent.isEmpty && claudeContent.isEmpty {
                    EmptyStateView(
                        icon: "sidebar.right",
                        title: "No Content",
                        message: "Unable to load skill files."
                    )
                } else {
                    // Diff view for different content
                    if isDifferent {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Diff")
                                    .font(.headline)
                                Spacer()
                                
                                // Statistics
                                if !diffText.isEmpty {
                                    HStack(spacing: 12) {
                                        Label("\(diffStats.additions)", systemImage: "plus.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(DesignTokens.Colors.Status.success)
                                        Label("\(diffStats.deletions)", systemImage: "minus.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(DesignTokens.Colors.Status.error)
                                        Label("\(diffStats.totalLines)", systemImage: "doc.text")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.quaternary.opacity(0.5))
                                    .cornerRadius(6)
                                }
                                
                                // View mode toggle
                                Picker("View Mode", selection: $diffViewMode) {
                                    ForEach(DiffViewMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                                
                                Toggle(isOn: $showLineNumbers) {
                                    Label("Line Numbers", systemImage: "number")
                                        .font(.caption)
                                }
                                .toggleStyle(.checkbox)
                                .controlSize(.small)
                                
                                Button {
                                    #if os(macOS)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(diffText, forType: .string)
                                    #endif
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(diffText.isEmpty)
                            }
                            
                            if diffViewMode == .unified {
                                ScrollView([.horizontal, .vertical]) {
                                    enhancedDiffView
                                        .padding(12)
                                }
                                .frame(height: 300)
                                .background(.tertiary.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                sideBySideDiffView
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Side-by-side content comparison
                    HStack(alignment: .top, spacing: 16) {
                        // Codex column
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundStyle(.blue)
                                Text("Codex")
                                    .font(.headline)
                                Spacer()
                                Text("\(codexContent.split(separator: "\n").count) lines")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ScrollView {
                                Text(codexContent.isEmpty ? "Not available" : codexContent)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                            }
                            .frame(maxHeight: 300)
                            .background(.tertiary.opacity(0.05))
                            .cornerRadius(8)
                            
                            if isDifferent && !codexContent.isEmpty {
                                Button {
                                    pendingCopyOperation = CopyOperation(
                                        from: codexFile,
                                        to: claudeFile,
                                        direction: "Codex → Claude"
                                    )
                                    showingCopyConfirmation = true
                                } label: {
                                    Label("Copy to Claude", systemImage: "arrow.right")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(isLoading)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Claude column
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "brain")
                                    .foregroundStyle(.purple)
                                Text("Claude")
                                    .font(.headline)
                                Spacer()
                                Text("\(claudeContent.split(separator: "\n").count) lines")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ScrollView {
                                Text(claudeContent.isEmpty ? "Not available" : claudeContent)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                            }
                            .frame(maxHeight: 300)
                            .background(.tertiary.opacity(0.05))
                            .cornerRadius(8)
                            
                            if isDifferent && !claudeContent.isEmpty {
                                Button {
                                    pendingCopyOperation = CopyOperation(
                                        from: claudeFile,
                                        to: codexFile,
                                        direction: "Claude → Codex"
                                    )
                                    showingCopyConfirmation = true
                                } label: {
                                    Label("Copy to Codex", systemImage: "arrow.left")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(isLoading)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(20)
        }
        .task(id: selection) { await loadFiles() }
        .alert("Confirm Copy Operation", isPresented: $showingCopyConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingCopyOperation = nil
            }
            Button("Copy with Backup", role: .destructive) {
                if let op = pendingCopyOperation {
                    Task(priority: .userInitiated) {
                        await performCopy(from: op.from, to: op.to)
                    }
                }
                pendingCopyOperation = nil
            }
        } message: {
            if let op = pendingCopyOperation {
                Text("This will copy \(op.direction). A backup of the destination file will be created with a .bak extension.\n\nDestination: \(op.to.lastPathComponent)")
            }
        }
    }
    
    private var headerIcon: String {
        switch selection {
        case .onlyCodex: return "doc.badge.plus"
        case .onlyClaude: return "doc.badge.plus"
        case .different: return "doc.badge.gearshape"
        }
    }
    
    private var headerColor: Color {
        switch selection {
        case .onlyCodex: return .blue
        case .onlyClaude: return .purple
        case .different: return .orange
        }
    }
    
    private var headerLabel: String {
        switch selection {
        case .onlyCodex: return "ONLY IN CODEX"
        case .onlyClaude: return "ONLY IN CLAUDE"
        case .different: return "DIFFERENT CONTENT"
        }
    }
    
    private var headerDescription: String {
        switch selection {
        case .onlyCodex:
            return "This skill exists only in Codex and is missing from Claude."
        case .onlyClaude:
            return "This skill exists only in Claude and is missing from Codex."
        case .different:
            return "This skill exists in both locations but has different content."
        }
    }

    private var isDifferent: Bool {
        if case .different = selection { return true }
        return false
    }
    
    private var diffStats: DiffStats {
        let lines = diffText.split(separator: "\n")
        var additions = 0
        var deletions = 0
        
        for line in lines {
            if line.hasPrefix("+") && !line.hasPrefix("+++") {
                additions += 1
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                deletions += 1
            }
        }
        
        return DiffStats(additions: additions, deletions: deletions, totalLines: lines.count)
    }
    
    private var enhancedDiffView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if diffText.isEmpty {
                Text("Diff unavailable")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                let lines = diffText.split(separator: "\n", omittingEmptySubsequences: false)
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(spacing: 8) {
                        if showLineNumbers {
                            Text("\(index + 1)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        
                        let (text, color, bgColor) = formatDiffLine(String(line))
                        Text(text)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(bgColor)
                    }
                    .textSelection(.enabled)
                }
            }
        }
    }
    
    private var sideBySideDiffView: some View {
        HStack(alignment: .top, spacing: 1) {
            // Left side (codex/deletions)
            VStack(alignment: .leading, spacing: 0) {
                Text("Codex (Original)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.tertiary.opacity(0.2))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(codexContent.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { index, line in
                            HStack(spacing: 8) {
                                if showLineNumbers {
                                    Text("\(index + 1)")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                                Text(String(line))
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                            }
                            .textSelection(.enabled)
                        }
                    }
                    .padding(8)
                }
                .background(.tertiary.opacity(0.05))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Right side (claude/additions)
            VStack(alignment: .leading, spacing: 0) {
                Text("Claude (Modified)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.tertiary.opacity(0.2))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(claudeContent.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { index, line in
                            HStack(spacing: 8) {
                                if showLineNumbers {
                                    Text("\(index + 1)")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                                Text(String(line))
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                            }
                            .textSelection(.enabled)
                        }
                    }
                    .padding(8)
                }
                .background(.tertiary.opacity(0.05))
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 300)
        .background(.tertiary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatDiffLine(_ line: String) -> (String, Color, Color) {
        if line.hasPrefix("+++") || line.hasPrefix("---") {
            return (line, .secondary, .clear)
        } else if line.hasPrefix("@@") {
            return (line, .blue, .blue.opacity(0.1))
        } else if line.hasPrefix("+") {
            return (line, DesignTokens.Colors.Status.success, DesignTokens.Colors.Status.success.opacity(0.15))
        } else if line.hasPrefix("-") {
            return (line, DesignTokens.Colors.Status.error, DesignTokens.Colors.Status.error.opacity(0.15))
        } else {
            return (line, .primary, .clear)
        }
    }

    private var codexFile: URL {
        codexRoot.appendingPathComponent(skillName).appendingPathComponent("SKILL.md")
    }
    private var claudeFile: URL {
        claudeRoot.appendingPathComponent(skillName).appendingPathComponent("SKILL.md")
    }

    private func loadFiles() async {
        isLoading = true
        loadError = nil
        statusMessage = nil

        let codexURL = codexFile
        let claudeURL = claudeFile

        let (codex, claude, codexErr, claudeErr) = await Task(priority: .userInitiated) { () -> (String, String, String?, String?) in
            if Task.isCancelled { return ("", "", nil, nil) }
            let codexResult: (String, String?) = {
                guard FileManager.default.fileExists(atPath: codexURL.path) else {
                    return ("", nil)
                }
                do {
                    return (try String(contentsOf: codexURL, encoding: .utf8), nil)
                } catch {
                    return ("", error.localizedDescription)
                }
            }()

            let claudeResult: (String, String?) = {
                guard FileManager.default.fileExists(atPath: claudeURL.path) else {
                    return ("", nil)
                }
                do {
                    return (try String(contentsOf: claudeURL, encoding: .utf8), nil)
                } catch {
                    return ("", error.localizedDescription)
                }
            }()

            return (codexResult.0, claudeResult.0, codexResult.1, claudeResult.1)
        }.value
        if Task.isCancelled { return }

        await MainActor.run {
            isLoading = false
            codexContent = codex
            claudeContent = claude

            var errors: [String] = []
            if let err = codexErr { errors.append("Codex: \(err)") }
            if let err = claudeErr { errors.append("Claude: \(err)") }

            if !errors.isEmpty {
                loadError = errors.joined(separator: "\n")
            }

            if isDifferent {
                diffText = unifiedDiff(left: codexContent, right: claudeContent, leftName: "Codex", rightName: "Claude")
            }
        }
    }

    private func performCopy(from: URL, to: URL) async {
        await MainActor.run {
            statusMessage = "Copying..."
            isLoading = true
        }

        let result = await Task(priority: .userInitiated) { () -> CopyResult in
            if Task.isCancelled { return CopyResult(success: false, message: "Copy cancelled") }
            guard FileManager.default.fileExists(atPath: from.path) else {
                return CopyResult(success: false, message: "Source missing: \(from.lastPathComponent)")
            }

            do {
                if Task.isCancelled { return CopyResult(success: false, message: "Copy cancelled") }
                let data = try Data(contentsOf: from)
                let dir = to.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

                if FileManager.default.fileExists(atPath: to.path) {
                    if Task.isCancelled { return CopyResult(success: false, message: "Copy cancelled") }
                    let backup = to.appendingPathExtension("bak")
                    try? FileManager.default.removeItem(at: backup)
                    try FileManager.default.copyItem(at: to, to: backup)
                }

                if Task.isCancelled { return CopyResult(success: false, message: "Copy cancelled") }
                try data.write(to: to, options: .atomic)
                return CopyResult(success: true, message: "Copied \(from.lastPathComponent) → \(to.lastPathComponent)")
            } catch {
                return CopyResult(success: false, message: "Copy failed: \(error.localizedDescription)")
            }
        }.value
        if Task.isCancelled { return }

        await MainActor.run {
            isLoading = false
            statusMessage = result.message

            if result.success {
                // Reload files to show updated content
                Task { await loadFiles() }
            }
        }
    }

    private func unifiedDiff(left: String, right: String, leftName: String, rightName: String) -> String {
        let leftLines = left.split(separator: "\n", omittingEmptySubsequences: false)
        let rightLines = right.split(separator: "\n", omittingEmptySubsequences: false)

        var output: [String] = []
        output.reserveCapacity(leftLines.count + rightLines.count + 2)
        output.append("--- \(leftName)")
        output.append("+++ \(rightName)")

        let maxCount = max(leftLines.count, rightLines.count)
        for i in 0..<maxCount {
            let l = i < leftLines.count ? String(leftLines[i]) : nil
            let r = i < rightLines.count ? String(rightLines[i]) : nil
            if l == r {
                output.append(" \(l ?? "")")
            } else {
                if let l { output.append("-\(l)") }
                if let r { output.append("+\(r)") }
            }
        }
        return output.joined(separator: "\n")
    }
}

// MARK: - Helper Types

private struct CopyOperation: Sendable {
    let from: URL
    let to: URL
    let direction: String
}

private struct CopyResult: Sendable {
    let success: Bool
    let message: String
}

private struct DiffStats {
    let additions: Int
    let deletions: Int
    let totalLines: Int
}
