import Foundation

struct NewCommand {
    var appName: String?
    var targetName: String?
    var bundleID: String?
    var outputPath: String?
    var templatePath: String?
    var skipGenerate = false
    var force = false
    var noInput = false
    var showHelp = false

    static func parse(arguments: [String]) throws -> NewCommand {
        var command = NewCommand()
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--app-name", "--name":
                index += 1
                command.appName = try value(for: argument, at: index, in: arguments)
            case "--target-name":
                index += 1
                command.targetName = try value(for: argument, at: index, in: arguments)
            case "--bundle-id":
                index += 1
                command.bundleID = try value(for: argument, at: index, in: arguments)
            case "--output":
                index += 1
                command.outputPath = try value(for: argument, at: index, in: arguments)
            case "--template":
                index += 1
                command.templatePath = try value(for: argument, at: index, in: arguments)
            case "--skip-generate":
                command.skipGenerate = true
            case "--force":
                command.force = true
            case "--no-input":
                command.noInput = true
            case "--help", "-h":
                command.showHelp = true
            default:
                if argument.hasPrefix("--") {
                    throw CLIError.usage("\(unknownOptionMessage(for: argument))\n\n\(helpText)")
                }

                if argument.hasPrefix("-") {
                    throw CLIError.usage("Unknown option '\(argument)'.\n\n\(helpText)")
                }

                if command.appName == nil {
                    command.appName = argument
                    break
                }

                throw CLIError.usage("Unexpected argument '\(argument)'.\n\n\(helpText)")
            }

            index += 1
        }

        return command
    }

    mutating func run() throws {
        if showHelp {
            Terminal.output(Self.helpText)
            return
        }

        let templateRoot = try TemplateLocator.resolveTemplateRoot(explicitPath: templatePath)
        let config = try resolvedConfiguration()

        let outputURL = try resolvedOutputURL(for: config.targetName)
        let scaffolder = ProjectScaffolder()

        let result = try scaffolder.scaffold(
            using: config,
            templateRoot: templateRoot,
            outputRoot: outputURL,
            skipGenerate: skipGenerate,
            force: force
        )

        Terminal.output("Created \(config.targetName) at \(result.outputDirectory.path)")
        if let generatedProject = result.generatedProject {
            Terminal.output("Generated Xcode project: \(generatedProject.path)")
        } else {
            Terminal.output("Skipped project generation. Run `xcodegen generate` inside the project directory when ready.")
        }
    }

    private func resolvedConfiguration() throws -> ScaffoldConfiguration {
        let resolvedAppName = try resolvedAppName()
        let suggestedTargetName = TargetName.suggested(from: resolvedAppName)
        let resolvedTargetName = try TargetName.validated(
            rawValue: targetName ?? promptValue(
                label: "Target name",
                defaultValue: suggestedTargetName,
                required: true
            )
        )
        let suggestedBundleID = "com.example.\(resolvedTargetName.lowercased())"
        let resolvedBundleID = try BundleIdentifier.validated(
            rawValue: bundleID ?? promptValue(
                label: "Bundle identifier",
                defaultValue: suggestedBundleID,
                required: true
            )
        )

        return ScaffoldConfiguration(
            appDisplayName: resolvedAppName,
            targetName: resolvedTargetName,
            bundleIdentifier: resolvedBundleID
        )
    }

    private func resolvedAppName() throws -> String {
        let value = appName ?? promptValue(label: "App display name", defaultValue: nil, required: true)
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw CLIError.validation("App display name must not be empty.")
        }

        return trimmed
    }

    private func resolvedOutputURL(for targetName: String) throws -> URL {
        let basePath = outputPath ?? FileManager.default.currentDirectoryPath + "/\(targetName)"
        let url = URL(fileURLWithPath: basePath, isDirectory: true)

        if url.path.hasPrefix("/") {
            return url.standardizedFileURL
        }

        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        return currentDirectory.appendingPathComponent(basePath, isDirectory: true).standardizedFileURL
    }

    private func promptValue(label: String, defaultValue: String?, required: Bool) -> String {
        if noInput {
            return defaultValue ?? ""
        }

        return Terminal.prompt(label, defaultValue: defaultValue) ?? ""
    }

    private static func value(for option: String, at index: Int, in arguments: [String]) throws -> String {
        guard index < arguments.count else {
            throw CLIError.usage("Missing value for '\(option)'.\n\n\(helpText)")
        }

        return arguments[index]
    }

    private static func unknownOptionMessage(for argument: String) -> String {
        guard argument.count > 2 else {
            return "Unknown option '\(argument)'."
        }

        let candidate = String(argument.dropFirst(2))
        return "Unknown option '\(argument)'. If this is the app name, use `base new \(candidate)` or `base new --name \(candidate)`."
    }

    private static let helpText = """
    Usage:
      base new [<app-name>] [options]

    Options:
      <app-name>                      Optional positional app display name.
      --app-name, --name <value>     App display name shown on the Home Screen.
      --target-name <value>          Xcode target, scheme, and module name.
      --bundle-id <value>            Bundle identifier, for example com.example.myapp.
      --output <path>                Output directory. Defaults to ./<TargetName>.
      --template <path>              Override template path.
      --skip-generate                Copy and replace tokens, but skip `xcodegen generate`.
      --force                        Replace the output directory if it already exists.
      --no-input                     Disable interactive prompts. Missing values become validation errors.
      -h, --help                     Show help.
    """
}
