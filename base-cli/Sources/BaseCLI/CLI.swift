import Foundation

struct CLI {
    func run(arguments: [String]) throws {
        guard let command = arguments.first else {
            Terminal.output(Self.helpText)
            return
        }

        switch command {
        case "new":
            var newCommand = try NewCommand.parse(arguments: Array(arguments.dropFirst()))
            try newCommand.run()
        case "help", "--help", "-h":
            Terminal.output(Self.helpText)
        default:
            throw CLIError.usage("Unknown command '\(command)'.\n\n\(Self.helpText)")
        }
    }

    private static let helpText = """
    base

    Usage:
      base new [options]

    Commands:
      new             Create a new app from the bundled base template.

    Global options:
      -h, --help      Show help.
    """
}

