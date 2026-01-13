import XCTest
@testable import SkillsCore

final class MultiTargetSkillInstallerTests: XCTestCase {
    func testRollbackOnFailure() async throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("multi-\(UUID().uuidString)", isDirectory: true)
        let skillDir = temp.appendingPathComponent("skill-one", isDirectory: true)
        let archiveURL = temp.appendingPathComponent("skill-one.zip")
        let goodRoot = temp.appendingPathComponent("good-root", isDirectory: true)
        let badRootFile = temp.appendingPathComponent("bad-root-file")

        try fm.createDirectory(at: skillDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: goodRoot, withIntermediateDirectories: true)
        try "not a dir".write(to: badRootFile, atomically: true, encoding: .utf8)
        try """
        ---
        name: demo
        description: Demo skill
        ---
        # Sample
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = temp
        process.arguments = ["-rq", archiveURL.lastPathComponent, skillDir.lastPathComponent]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let manifest = RemoteArtifactManifest(sha256: try RemoteSkillInstaller.sha256Hex(of: archiveURL))
        let installer = MultiTargetSkillInstaller()
        let outcome = try await installer.install(
            archiveURL: archiveURL,
            targets: [
                .codex(goodRoot),
                .copilot(badRootFile)
            ],
            overwrite: false,
            manifest: manifest,
            policy: .permissive
        )

        XCTAssertTrue(outcome.didRollback)
        XCTAssertFalse(outcome.failures.isEmpty)
        let installedPath = goodRoot.appendingPathComponent("skill-one")
        XCTAssertFalse(fm.fileExists(atPath: installedPath.path))
    }
}
