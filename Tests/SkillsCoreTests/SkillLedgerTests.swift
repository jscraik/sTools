import XCTest
import SkillsCore

final class SkillLedgerTests: XCTestCase {
    func testLedgerRecordsAndFetchesEvents() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let ledgerURL = tempDir.appendingPathComponent("ledger.sqlite3")
        let ledger = try SkillLedger(url: ledgerURL)

        let input = LedgerEventInput(
            eventType: .install,
            skillName: "Prompt Booster",
            skillSlug: "prompt-booster",
            version: "1.2.0",
            agent: .codex,
            status: .success,
            note: "Installed via test",
            verification: .strict,
            manifestSHA256: "abc123",
            targetPath: "/tmp/skills/prompt-booster"
        )

        let saved = try await ledger.record(input)
        let fetched = try await ledger.fetchEvents(limit: 10)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, saved.id)
        XCTAssertEqual(fetched.first?.skillName, "Prompt Booster")
        XCTAssertEqual(fetched.first?.eventType, .install)
    }

    func testChangelogGeneratorFormatsEvents() {
        let generator = SkillChangelogGenerator()
        let events = [
            LedgerEvent(
                id: 1,
                timestamp: Date(),
                eventType: .update,
                skillName: "Lint Wizard",
                skillSlug: "lint-wizard",
                version: "2.0.0",
                agent: .claude,
                status: .success,
                note: "Updated for release",
                verification: .strict,
                manifestSHA256: nil,
                targetPath: nil
            )
        ]
        let markdown = generator.generateAppStoreMarkdown(events: events)
        XCTAssertTrue(markdown.contains("## Changelog"))
        XCTAssertTrue(markdown.contains("Updated Lint Wizard v2.0.0"))
    }
}
