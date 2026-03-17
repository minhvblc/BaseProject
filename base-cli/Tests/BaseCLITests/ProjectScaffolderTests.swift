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
                bundleIdentifier: "com.example.basedemo",
                useCocoaPods: false
            ),
            templateRoot: templateRoot(),
            outputRoot: outputRoot,
            skipGenerate: true,
            skipPodInstall: true,
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
        #expect(result.generatedWorkspace == nil)
    }

    @Test("Scaffolder can emit a Podfile when CocoaPods is enabled")
    func scaffoldWithCocoaPods() throws {
        let scaffolder = ProjectScaffolder()
        let outputRoot = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: outputRoot) }

        let result = try scaffolder.scaffold(
            using: ScaffoldConfiguration(
                appDisplayName: "Pods Demo",
                targetName: "PodsDemo",
                bundleIdentifier: "com.example.podsdemo",
                useCocoaPods: true
            ),
            templateRoot: templateRoot(),
            outputRoot: outputRoot,
            skipGenerate: true,
            skipPodInstall: true,
            force: true
        )

        let podfileContents = try String(contentsOf: result.podfile, encoding: .utf8)
        let baseXCConfigContents = try String(
            contentsOf: result.outputDirectory.appendingPathComponent("Config/Base.xcconfig"),
            encoding: .utf8
        )
        let debugXCConfigContents = try String(
            contentsOf: result.outputDirectory.appendingPathComponent("Config/Debug.xcconfig"),
            encoding: .utf8
        )
        #expect(podfileContents.contains("project 'PodsDemo.xcodeproj'"))
        #expect(podfileContents.contains("target 'PodsDemo' do"))
        #expect(baseXCConfigContents.contains("ENABLE_USER_SCRIPT_SANDBOXING = NO"))
        #expect(debugXCConfigContents.contains(#"#include? "../Pods/Target Support Files/Pods-PodsDemo/Pods-PodsDemo.debug.xcconfig""#))
        #expect(result.generatedWorkspace == nil)
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
