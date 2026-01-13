import XCTest
@testable import SkillsCore

final class RemoteSkillInstallerTests: XCTestCase {
    func testInstallCopiesSkillAndComputesChecksum() async throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("installer-\(UUID().uuidString)", isDirectory: true)
        let skillDir = temp.appendingPathComponent("skill-one", isDirectory: true)
        let archiveURL = temp.appendingPathComponent("skill-one.zip")
        let targetRoot = temp.appendingPathComponent("target", isDirectory: true)

        try fm.createDirectory(at: skillDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: targetRoot, withIntermediateDirectories: true)
        try """
        ---
        name: demo
        description: Demo skill
        ---

        # Sample skill
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        // zip the skill directory
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = temp
        process.arguments = ["-rq", archiveURL.lastPathComponent, "skill-one"]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let manifest = RemoteArtifactManifest(sha256: try RemoteSkillInstaller.sha256Hex(of: archiveURL))
        let installer = RemoteSkillInstaller()
        let result = try await installer.install(
            archiveURL: archiveURL,
            target: .custom(targetRoot),
            overwrite: false,
            manifest: manifest,
            policy: .permissive
        )

        let expectedDir = targetRoot.appendingPathComponent("skill-one")
        XCTAssertTrue(fm.fileExists(atPath: expectedDir.path))
        XCTAssertEqual(result.skillDirectory, expectedDir)
        XCTAssertNotNil(result.archiveSHA256)
    }

    func testRejectsFileCountLimit() async throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("installer-\(UUID().uuidString)", isDirectory: true)
        let skillDir = temp.appendingPathComponent("skill-many", isDirectory: true)
        let archiveURL = temp.appendingPathComponent("skill-many.zip")
        let targetRoot = temp.appendingPathComponent("target", isDirectory: true)

        try fm.createDirectory(at: skillDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: targetRoot, withIntermediateDirectories: true)
        try """
        ---
        name: bad
        description: bad
        ---
        # bad
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "extra".write(to: skillDir.appendingPathComponent("extra.txt"), atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = temp
        process.arguments = ["-rq", archiveURL.lastPathComponent, skillDir.lastPathComponent]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let installer = RemoteSkillInstaller()
        do {
            _ = try await installer.install(
                archiveURL: archiveURL,
                target: .custom(targetRoot),
                overwrite: false,
                manifest: RemoteArtifactManifest(sha256: try RemoteSkillInstaller.sha256Hex(of: archiveURL)),
                policy: RemoteVerificationPolicy(mode: .permissive, limits: RemoteVerificationLimits(maxArchiveBytes: 50 * 1024 * 1024, maxExtractedBytes: 50 * 1024 * 1024, maxFileCount: 1))
            )
            XCTFail("Expected verification failure for file-count limit")
        } catch {
            guard case RemoteInstallError.verificationFailed(let reason) = error else {
                return XCTFail("Expected verificationFailed, got \(error)")
            }
            XCTAssertTrue(reason.contains("file-count"), "Reason was: \(reason)")
        }
    }

    func testChecksumMismatchFails() async throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("installer-\(UUID().uuidString)", isDirectory: true)
        let skillDir = temp.appendingPathComponent("skill-bad", isDirectory: true)
        let archiveURL = temp.appendingPathComponent("skill-bad.zip")
        let targetRoot = temp.appendingPathComponent("target", isDirectory: true)

        try fm.createDirectory(at: skillDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: targetRoot, withIntermediateDirectories: true)
        try """
        ---
        name: bad
        description: bad
        ---
        # bad
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = temp
        process.arguments = ["-rq", archiveURL.lastPathComponent, "skill-bad"]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let manifest = RemoteArtifactManifest(sha256: String(repeating: "0", count: 64))
        let installer = RemoteSkillInstaller()
        do {
            _ = try await installer.install(
                archiveURL: archiveURL,
                target: .custom(targetRoot),
                overwrite: false,
                manifest: manifest,
                policy: .permissive
            )
            XCTFail("Expected verification failure for checksum mismatch")
        } catch {
            guard case RemoteInstallError.verificationFailed(let reason) = error else {
                return XCTFail("Expected verificationFailed, got \(error)")
            }
            XCTAssertTrue(reason.contains("Checksum mismatch"))
        }
    }

    func testVerifyReturnsIssuesInPermissiveMode() async throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent("installer-\(UUID().uuidString)", isDirectory: true)
        let skillDir = temp.appendingPathComponent("skill-verify", isDirectory: true)
        let archiveURL = temp.appendingPathComponent("skill-verify.zip")

        try fm.createDirectory(at: skillDir, withIntermediateDirectories: true)
        try """
        ---
        name: verify
        description: verify
        ---
        # verify
        """.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = temp
        process.arguments = ["-rq", archiveURL.lastPathComponent, "skill-verify"]
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)

        let manifest = RemoteArtifactManifest(sha256: try RemoteSkillInstaller.sha256Hex(of: archiveURL))
        let installer = RemoteSkillInstaller()
        let outcome = try installer.verify(
            archiveURL: archiveURL,
            manifest: manifest,
            policy: .permissive
        )
        XCTAssertTrue(outcome.checksumValidated)
        XCTAssertTrue(outcome.issues.contains(where: { $0.contains("Signature") }))
    }
}
