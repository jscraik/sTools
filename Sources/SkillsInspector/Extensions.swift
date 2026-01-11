import SwiftUI
import SkillsCore

// MARK: - Severity Color Extension

extension Severity {
    var color: Color {
        switch self {
        case .error: return DesignTokens.Colors.Status.error
        case .warning: return DesignTokens.Colors.Status.warning
        case .info: return DesignTokens.Colors.Icon.secondary
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - AgentKind Styling Extension

extension AgentKind {
    var color: Color {
        switch self {
        case .codex: return DesignTokens.Colors.Accent.blue
        case .claude: return DesignTokens.Colors.Accent.purple
        }
    }
    
    var icon: String {
        switch self {
        case .codex: return "cpu"
        case .claude: return "brain"
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Try Again"
    
    @State private var iconScale: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.Colors.Icon.tertiary)
                .scaleEffect(iconScale)
                .onAppear {
                    if !reduceMotion {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            iconScale = 1.0
                        }
                    } else {
                        iconScale = 1.0
                    }
                }
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .font(.body)
                .foregroundStyle(DesignTokens.Colors.Text.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            if let action {
                Button(actionLabel) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.Background.primary)
    }
}

// MARK: - Status Bar View

struct StatusBarView: View {
    let errorCount: Int
    let warningCount: Int
    let infoCount: Int
    let lastScan: Date?
    let duration: TimeInterval?
    let cacheHits: Int
    let scannedFiles: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Severity badges
            HStack(spacing: 8) {
                severityBadge(count: errorCount, severity: .error)
                severityBadge(count: warningCount, severity: .warning)
                severityBadge(count: infoCount, severity: .info)
            }
            
            Divider()
                .frame(height: 16)
            
            // Cache stats
            if scannedFiles > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(DesignTokens.Colors.Status.success)
                    Text("\(scannedFiles) files")
                    if cacheHits > 0 {
                        Text("(\(cacheHits) cached)")
                            .foregroundStyle(DesignTokens.Colors.Text.secondary)
                    }
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Timing info
            if let duration {
                Text(String(format: "%.2fs", duration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            
            if let lastScan {
                Text(lastScan.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
    
    private func severityBadge(count: Int, severity: Severity) -> some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
                .foregroundStyle(count > 0 ? AnyShapeStyle(severity.color) : AnyShapeStyle(.tertiary))
            Text("\(count)")
                .fontWeight(count > 0 ? .medium : .regular)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(count > 0 ? severity.color.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Shimmer Loading Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Loading Skeleton Views

struct SkeletonFindingRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Severity indicator
            Circle()
                .fill(DesignTokens.Colors.Background.secondary)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.Background.secondary)
                        .frame(width: 100, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.Background.secondary)
                        .frame(width: 50, height: 12)
                }
                
                // Message
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.secondary)
                    .frame(height: 14)
                
                // File path
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.secondary)
                    .frame(width: 150, height: 10)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .shimmer()
    }
}

struct SkeletonSyncRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundStyle(DesignTokens.Colors.Background.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.secondary)
                    .frame(width: 180, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.secondary)
                    .frame(width: 120, height: 10)
            }
        }
        .padding(12)
        .shimmer()
    }
}

struct SkeletonIndexRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(DesignTokens.Colors.Background.secondary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.secondary)
                    .frame(width: 200, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.Background.secondary)
                    .frame(width: 150, height: 12)
            }
        }
        .padding(12)
        .shimmer()
    }
}

// MARK: - Keyboard Shortcut Helpers

extension KeyboardShortcut {
    static let scan = KeyboardShortcut("r", modifiers: .command)
    static let refresh = KeyboardShortcut("r", modifiers: [.command, .shift])
    static let filter = KeyboardShortcut("f", modifiers: .command)
    static let clearFilter = KeyboardShortcut(.escape, modifiers: [])
    static let openInEditor = KeyboardShortcut(.return, modifiers: .command)
    static let showInFinder = KeyboardShortcut("o", modifiers: [.command, .shift])
    static let baseline = KeyboardShortcut("b", modifiers: [.command, .shift])
}

// MARK: - Animated Transition Helpers

extension AnyTransition {
    static var fadeAndSlide: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity.combined(with: .move(edge: .bottom))
        )
    }
}

// MARK: - Card Styling

extension View {
    /// Standard card styling used across list rows for visual parity.
    func cardStyle(selected: Bool = false, tint: Color = .accentColor) -> some View {
        self
            .padding(DesignTokens.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DesignTokens.Colors.Background.primary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? tint.opacity(0.55) : .clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(selected ? 0.14 : 0.06), radius: selected ? 8 : 4, y: selected ? 4 : 2)
    }
}

// MARK: - Toast Notification System

enum ToastStyle {
    case success
    case warning
    case error
    case info
    
    var color: Color {
        switch self {
        case .success: return DesignTokens.Colors.Status.success
        case .warning: return DesignTokens.Colors.Status.warning
        case .error: return DesignTokens.Colors.Status.error
        case .info: return DesignTokens.Colors.Status.info
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let style: ToastStyle
    let message: String
    let duration: TimeInterval
    
    init(style: ToastStyle, message: String, duration: TimeInterval = 3.0) {
        self.style = style
        self.message = message
        self.duration = duration
    }
}

struct ToastView: View {
    let toast: ToastMessage
    @Binding var isShowing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Image(systemName: toast.style.icon)
                .foregroundStyle(toast.style.color)
            
            Text(toast.message)
                .bodySmall()
                .foregroundStyle(DesignTokens.Colors.Text.primary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .fill(DesignTokens.Colors.Background.primary)
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .stroke(toast.style.color.opacity(0.3), lineWidth: 1)
        )
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                withAnimation(reduceMotion ? .easeOut : .spring(response: 0.3, dampingFraction: 0.7)) {
                    isShowing = false
                }
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toast {
                    ToastView(toast: toast, isShowing: Binding(
                        get: { self.toast != nil },
                        set: { if !$0 { self.toast = nil } }
                    ))
                    .padding(.top, DesignTokens.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: toast != nil)
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "checkmark.circle",
        title: "No Issues Found",
        message: "All skill files pass validation.",
        action: { print("Scan") },
        actionLabel: "Scan Again"
    )
}

#Preview("Status Bar") {
    StatusBarView(
        errorCount: 3,
        warningCount: 7,
        infoCount: 2,
        lastScan: Date(),
        duration: 1.234,
        cacheHits: 15,
        scannedFiles: 20
    )
}
