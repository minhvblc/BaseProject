import Foundation

enum TemplateLocator {
    static func resolveTemplateRoot(explicitPath: String?) throws -> URL {
        let fileManager = FileManager.default

        var candidates: [URL] = []
        if let explicitPath, !explicitPath.isEmpty {
            candidates.append(URL(fileURLWithPath: explicitPath, isDirectory: true))
        }

        if let environmentPath = ProcessInfo.processInfo.environment["BASE_TEMPLATE_PATH"], !environmentPath.isEmpty {
            candidates.append(URL(fileURLWithPath: environmentPath, isDirectory: true))
        }

        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let executableDirectory = executableURL.deletingLastPathComponent()
        candidates.append(executableDirectory.appendingPathComponent("../share/base-cli/template", isDirectory: true))
        candidates.append(executableDirectory.appendingPathComponent("../../share/base-cli/template", isDirectory: true))

        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        candidates.append(contentsOf: ancestorCandidates(from: currentDirectory))
        candidates.append(contentsOf: ancestorCandidates(from: executableDirectory))

        for candidate in candidates.map(\.standardizedFileURL) {
            if isTemplateRoot(candidate) {
                return candidate
            }
        }

        throw CLIError.runtime("Unable to locate a template directory. Pass `--template <path>` or set `BASE_TEMPLATE_PATH`.")
    }

    private static func ancestorCandidates(from start: URL) -> [URL] {
        var results: [URL] = []
        var current = start.standardizedFileURL

        for _ in 0..<6 {
            results.append(current.appendingPathComponent("base-template", isDirectory: true))
            results.append(current.appendingPathComponent("template", isDirectory: true))
            let parent = current.deletingLastPathComponent()
            if parent == current {
                break
            }
            current = parent
        }

        return results
    }

    private static func isTemplateRoot(_ url: URL) -> Bool {
        let fileManager = FileManager.default
        let manifest = url.appendingPathComponent("TemplateManifest.json")
        let spec = url.appendingPathComponent("project.yml")
        return fileManager.fileExists(atPath: manifest.path) && fileManager.fileExists(atPath: spec.path)
    }
}

