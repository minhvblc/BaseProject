import Foundation

struct CLIError: Error {
    let message: String
    let exitCode: Int32

    static func usage(_ message: String) -> CLIError {
        CLIError(message: message, exitCode: 64)
    }

    static func validation(_ message: String) -> CLIError {
        CLIError(message: message, exitCode: 65)
    }

    static func runtime(_ message: String) -> CLIError {
        CLIError(message: message, exitCode: 1)
    }
}

