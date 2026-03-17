import Testing
@testable import BaseCLI

struct NewCommandTests {
    @Test("Positional app name is accepted")
    func positionalAppName() throws {
        let command = try NewCommand.parse(arguments: [
            "TestApp",
            "--bundle-id", "com.example.testapp"
        ])

        #expect(command.appName == "TestApp")
        #expect(command.bundleID == "com.example.testapp")
    }

    @Test("Unknown double-dash app name suggests the right syntax")
    func malformedAppNameSuggestion() {
        do {
            _ = try NewCommand.parse(arguments: ["--TestApp"])
            Issue.record("Expected parsing to fail for malformed app name syntax.")
        } catch let error as CLIError {
            #expect(error.exitCode == 64)
            #expect(error.message.contains("base new TestApp"))
            #expect(error.message.contains("base new --name TestApp"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
