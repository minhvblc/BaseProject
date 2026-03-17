import Foundation

do {
    try CLI().run(arguments: Array(CommandLine.arguments.dropFirst()))
} catch let error as CLIError {
    Terminal.error(error.message)
    Foundation.exit(error.exitCode)
} catch {
    Terminal.error("Unexpected error: \(error.localizedDescription)")
    Foundation.exit(1)
}

