import Foundation

public struct SkillChangelogGenerator: Sendable {
    public init() {}

    public func generateAppStoreMarkdown(
        events: [LedgerEvent],
        title: String = "Changelog"
    ) -> String {
        let relevant = events
            .filter { $0.status == .success }
            .sorted { lhs, rhs in
                if lhs.timestamp == rhs.timestamp { return lhs.id > rhs.id }
                return lhs.timestamp > rhs.timestamp
            }
        guard !relevant.isEmpty else {
            return "## \(title)\n(No entries yet.)"
        }

        let grouped = Dictionary(grouping: relevant) { dayKey(for: $0.timestamp) }
        let sortedKeys = grouped.keys.sorted(by: >)
        var lines: [String] = []
        lines.append("## \(title)")
        lines.append("_Generated: \(DateFormatter.shortDateTime.string(from: Date()))_")
        lines.append("")

        for key in sortedKeys {
            guard let events = grouped[key] else { continue }
            lines.append("### \(key)")
            for event in events {
                lines.append("- \(formatEvent(event))")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatEvent(_ event: LedgerEvent) -> String {
        let verb = verbForType(event.eventType)
        var parts: [String] = []
        parts.append("\(verb) \(event.skillName)")
        if let version = event.version {
            parts.append("v\(version)")
        }
        if let agent = event.agent {
            parts.append("(\(agent.displayLabel))")
        }
        if let note = event.note, !note.isEmpty {
            parts.append("— \(note)")
        }
        return parts.joined(separator: " ")
    }

    private func verbForType(_ type: LedgerEventType) -> String {
        switch type {
        case .install: return "Installed"
        case .update: return "Updated"
        case .remove: return "Removed"
        case .verify: return "Verified"
        case .sync: return "Synced"
        }
    }
}
