import Foundation

enum WildcardMatcher {
    static func matches(path: String, pattern: String) -> Bool {
        let pathComponents = split(path)
        let patternComponents = split(pattern)
        return match(pathComponents, patternComponents)
    }

    private static func split(_ string: String) -> [String] {
        string.split(separator: "/").map(String.init)
    }

    private static func match(_ path: [String], _ pattern: [String]) -> Bool {
        if pattern.isEmpty {
            return path.isEmpty
        }

        if pattern[0] == "**" {
            if match(path, Array(pattern.dropFirst())) {
                return true
            }

            guard !path.isEmpty else {
                return false
            }

            return match(Array(path.dropFirst()), pattern)
        }

        guard !path.isEmpty else {
            return false
        }

        guard componentMatches(path[0], pattern: pattern[0]) else {
            return false
        }

        return match(Array(path.dropFirst()), Array(pattern.dropFirst()))
    }

    private static func componentMatches(_ value: String, pattern: String) -> Bool {
        if pattern == "*" {
            return true
        }

        if !pattern.contains("*") {
            return value == pattern
        }

        var regex = "^"
        for character in pattern {
            if character == "*" {
                regex += ".*"
            } else {
                regex += NSRegularExpression.escapedPattern(for: String(character))
            }
        }
        regex += "$"

        return value.range(of: regex, options: .regularExpression) != nil
    }
}

