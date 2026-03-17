import Foundation
import Testing
@testable import BaseCLI

struct ProjectScaffolderTests {
    @Test("Target names are derived from the app display name")
    func targetNameSuggestion() {
        #expect(TargetName.suggested(from: "Base Demo") == "BaseDemo")
        #expect(TargetName.suggested(from: "123 launch pad") == "App123LaunchPad")
    }

    @Test("Scaffolder copies the template and replaces the expected tokens")
    func scaffoldWithoutGeneratingProject() throws {
        let scaffolder = ProjectScaffolder()
        let outputRoot = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputRoot) }

        let result = try scaffolder.scaffold(
            using: ScaffoldConfiguration(
                appDisplayName: "Base Demo",
                targetName: "BaseDemo",
                bundleIdentifier: "com.example.basedemo"
            ),
            templateRoot: templateRoot(),
            outputRoot: outputRoot,
            skipGenerate: true,
            force: true
        )

        let spec = result.outputDirectory.appendingPathComponent("project.yml")
        let infoPlist = result.outputDirectory.appendingPathComponent("App/Resources/Info.plist")

        let specContents = try String(contentsOf: spec, encoding: .utf8)
        let plistContents = try String(contentsOf: infoPlist, encoding: .utf8)

        #expect(specContents.contains("name: BaseDemo"))
        #expect(!specContents.contains("__TARGET_NAME__"))
        #expect(plistContents.contains("Base Demo"))
        #expect(!plistContents.contains("__APP_DISPLAY_NAME__"))
        #expect(result.generatedProject == nil)
    }

    private func templateRoot() -> URL {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return packageRoot.deletingLastPathComponent().appendingPathComponent("base-template", isDirectory: true)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
