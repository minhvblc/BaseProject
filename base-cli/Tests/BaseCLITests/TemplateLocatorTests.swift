import Foundation
import Testing
@testable import BaseCLI

struct TemplateLocatorTests {
    @Test("Homebrew-style share path is discovered from the real executable path")
    func resolvesHomebrewTemplatePath() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let executableURL = root
            .appendingPathComponent("Cellar/base/0.1.1/bin/base")
        let templateURL = root
            .appendingPathComponent("Cellar/base/0.1.1/share/base-cli/template", isDirectory: true)

        try FileManager.default.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: executableURL)

        try FileManager.default.createDirectory(at: templateURL, withIntermediateDirectories: true)
        try "{}".write(to: templateURL.appendingPathComponent("TemplateManifest.json"), atomically: true, encoding: .utf8)
        try "name: TestApp\n".write(to: templateURL.appendingPathComponent("project.yml"), atomically: true, encoding: .utf8)

        let resolved = try TemplateLocator.resolveTemplateRoot(
            explicitPath: nil,
            executableURL: executableURL
        )

        #expect(resolved.standardizedFileURL == templateURL.standardizedFileURL)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
