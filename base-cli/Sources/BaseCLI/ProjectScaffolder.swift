import Foundation

struct ScaffoldResult {
    let outputDirectory: URL
    let generatedProject: URL?
}

struct ProjectScaffolder {
    func scaffold(
        using configuration: ScaffoldConfiguration,
        templateRoot: URL,
        outputRoot: URL,
        skipGenerate: Bool,
        force: Bool
    ) throws -> ScaffoldResult {
        let manifest = try loadManifest(from: templateRoot)
        try prepareOutputDirectory(outputRoot, force: force)
        try copyTemplate(from: templateRoot, to: outputRoot)
        try replaceTokens(in: outputRoot, manifest: manifest, configuration: configuration)
        try validateResolvedPlaceholders(in: outputRoot, pattern: manifest.validation.placeholderPattern)

        let generatedProject: URL?
        if skipGenerate {
            generatedProject = nil
        } else {
            try runXcodeGen(in: outputRoot)
            generatedProject = outputRoot.appendingPathComponent("\(configuration.targetName).xcodeproj")
        }

        return ScaffoldResult(outputDirectory: outputRoot, generatedProject: generatedProject)
    }

    private func loadManifest(from templateRoot: URL) throws -> TemplateManifest {
        let manifestURL = templateRoot.appendingPathComponent("TemplateManifest.json")

        do {
            let data = try Data(contentsOf: manifestURL)
            return try JSONDecoder().decode(TemplateManifest.self, from: data)
        } catch {
            throw CLIError.runtime("Failed to load TemplateManifest.json from \(templateRoot.path): \(error.localizedDescription)")
        }
    }

    private func prepareOutputDirectory(_ outputRoot: URL, force: Bool) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: outputRoot.path, isDirectory: &isDirectory)

        if exists {
            if force {
                try fileManager.removeItem(at: outputRoot)
            } else {
                throw CLIError.validation("Output directory already exists at \(outputRoot.path). Use `--force` to replace it.")
            }
        }

        do {
            try fileManager.createDirectory(at: outputRoot, withIntermediateDirectories: true)
        } catch {
            throw CLIError.runtime("Failed to create output directory: \(error.localizedDescription)")
        }
    }

    private func copyTemplate(from templateRoot: URL, to outputRoot: URL) throws {
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey]

        guard let enumerator = fileManager.enumerator(
            at: templateRoot,
            includingPropertiesForKeys: Array(resourceKeys)
        ) else {
            throw CLIError.runtime("Failed to enumerate template files at \(templateRoot.path)")
        }

        for case let sourceURL as URL in enumerator {
            let relativePath = relativePath(of: sourceURL, from: templateRoot)
            if shouldSkip(relativePath: relativePath) {
                if isDirectory(sourceURL) {
                    enumerator.skipDescendants()
                }
                continue
            }

            let destinationURL = outputRoot.appendingPathComponent(relativePath)
            if isDirectory(sourceURL) {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            } else {
                try fileManager.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
        }
    }

    private func replaceTokens(
        in outputRoot: URL,
        manifest: TemplateManifest,
        configuration: ScaffoldConfiguration
    ) throws {
        let replacements = replacementMap(from: manifest, configuration: configuration)
        let files = try regularFiles(in: outputRoot)

        for fileURL in files {
            let relativePath = relativePath(of: fileURL, from: outputRoot)
            let shouldReplace = manifest.textReplaceGlobs.contains { pattern in
                WildcardMatcher.matches(path: relativePath, pattern: pattern)
            }

            guard shouldReplace else {
                continue
            }

            guard var contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            let original = contents
            for (token, replacement) in replacements {
                contents = contents.replacingOccurrences(of: token, with: replacement)
            }

            if contents != original {
                try contents.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    private func validateResolvedPlaceholders(in outputRoot: URL, pattern: String) throws {
        let files = try regularFiles(in: outputRoot)
        let regex = try NSRegularExpression(pattern: pattern)
        var matches: [String] = []

        for fileURL in files {
            guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            let range = NSRange(contents.startIndex..<contents.endIndex, in: contents)
            if regex.firstMatch(in: contents, range: range) != nil {
                let relativePath = relativePath(of: fileURL, from: outputRoot)
                matches.append(relativePath)
            }
        }

        if !matches.isEmpty {
            let message = matches.prefix(10).joined(separator: ", ")
            throw CLIError.runtime("Unresolved placeholders remain after scaffolding. Files: \(message)")
        }
    }

    private func runXcodeGen(in outputRoot: URL) throws {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["xcodegen", "generate", "--spec", "project.yml"]
        process.currentDirectoryURL = outputRoot
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw CLIError.runtime("Failed to launch xcodegen. Install it with `brew install xcodegen`.")
        }

        process.waitUntilExit()

        let output = (
            String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        ) + (
            String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )

        if process.terminationStatus != 0 {
            throw CLIError.runtime("xcodegen generate failed.\n\(output.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
    }

    private func regularFiles(in root: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else {
            throw CLIError.runtime("Failed to enumerate files in \(root.path)")
        }

        var files: [URL] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            if values.isRegularFile == true {
                files.append(url)
            }
        }

        return files
    }

    private func replacementMap(
        from manifest: TemplateManifest,
        configuration: ScaffoldConfiguration
    ) -> [String: String] {
        manifest.placeholders.reduce(into: [String: String]()) { partialResult, placeholder in
            switch placeholder.key {
            case "appDisplayName":
                partialResult[placeholder.token] = configuration.appDisplayName
            case "targetName":
                partialResult[placeholder.token] = configuration.targetName
            case "bundleIdentifier":
                partialResult[placeholder.token] = configuration.bundleIdentifier
            default:
                break
            }
        }
    }

    private func shouldSkip(relativePath: String) -> Bool {
        let lastComponent = URL(fileURLWithPath: relativePath).lastPathComponent
        if lastComponent == ".DS_Store" || lastComponent == ".git" || lastComponent == ".build" || lastComponent == ".swiftpm" {
            return true
        }

        return relativePath.hasSuffix(".xcodeproj") || relativePath.hasSuffix(".xcworkspace")
    }

    private func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    private func relativePath(of fileURL: URL, from root: URL) -> String {
        let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
        let resolvedFile = fileURL.resolvingSymlinksInPath().standardizedFileURL
        let rootComponents = resolvedRoot.pathComponents
        let fileComponents = resolvedFile.pathComponents

        guard fileComponents.starts(with: rootComponents) else {
            return resolvedFile.lastPathComponent
        }

        return fileComponents.dropFirst(rootComponents.count).joined(separator: "/")
    }
}
