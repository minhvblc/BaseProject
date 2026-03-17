import Foundation
import Darwin

enum Terminal {
    static func output(_ message: String) {
        write(message + "\n", to: FileHandle.standardOutput)
    }

    static func error(_ message: String) {
        write("error: " + message + "\n", to: FileHandle.standardError)
    }

    static func prompt(_ label: String, defaultValue: String? = nil) -> String? {
        if !isInputInteractive {
            return defaultValue
        }

        let promptText: String
        if let defaultValue, !defaultValue.isEmpty {
            promptText = "\(label) [\(defaultValue)]: "
        } else {
            promptText = "\(label): "
        }

        write(promptText, to: FileHandle.standardOutput)
        fflush(stdout)

        guard let line = readLine() else {
            return defaultValue
        }

        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return defaultValue
        }

        return trimmed
    }

    static func confirm(_ label: String, defaultValue: Bool = false) -> Bool {
        if !isInputInteractive {
            return defaultValue
        }

        let suffix = defaultValue ? " [Y/n]: " : " [y/N]: "
        write(label + suffix, to: FileHandle.standardOutput)
        fflush(stdout)

        guard let line = readLine() else {
            return defaultValue
        }

        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return defaultValue
        }

        switch trimmed {
        case "y", "yes":
            return true
        case "n", "no":
            return false
        default:
            return defaultValue
        }
    }

    private static func write(_ message: String, to handle: FileHandle) {
        guard let data = message.data(using: .utf8) else {
            return
        }
        try? handle.write(contentsOf: data)
    }

    private static var isInputInteractive: Bool {
        isatty(STDIN_FILENO) == 1
    }
}
