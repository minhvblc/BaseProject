import Foundation

struct ScaffoldConfiguration {
    let appDisplayName: String
    let targetName: String
    let bundleIdentifier: String
    let useCocoaPods: Bool
}

enum TargetName {
    static func suggested(from appDisplayName: String) -> String {
        let words = appDisplayName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let joined = words
            .map { word in
                let head = word.prefix(1).uppercased()
                let tail = word.dropFirst()
                return head + tail
            }
            .joined()

        let candidate = joined.isEmpty ? "BaseApp" : joined
        if let first = candidate.first, first.isNumber {
            return "App\(candidate)"
        }

        return candidate
    }

    static func validated(rawValue: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))

        guard !trimmed.isEmpty else {
            throw CLIError.validation("Target name must not be empty.")
        }

        guard trimmed.unicodeScalars.allSatisfy(allowed.contains) else {
            let suggestion = suggested(from: trimmed)
            throw CLIError.validation("Target name must contain only letters, numbers, or underscores. Suggested value: \(suggestion)")
        }

        guard let first = trimmed.first, first.isLetter || first == "_" else {
            throw CLIError.validation("Target name must start with a letter or underscore.")
        }

        return trimmed
    }
}

enum BundleIdentifier {
    static func validated(rawValue: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let segments = trimmed.split(separator: ".")

        guard segments.count >= 2 else {
            throw CLIError.validation("Bundle identifier must have at least two dot-separated segments.")
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let isValid = segments.allSatisfy { segment in
            !segment.isEmpty && segment.unicodeScalars.allSatisfy(allowed.contains)
        }

        guard isValid else {
            throw CLIError.validation("Bundle identifier contains invalid characters.")
        }

        return trimmed
    }
}
