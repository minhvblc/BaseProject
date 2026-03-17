import Foundation

struct TemplateManifest: Decodable {
    struct Placeholder: Decodable {
        let key: String
        let token: String
        let description: String
    }

    struct Validation: Decodable {
        let placeholderPattern: String
        let buildPhaseScript: String
    }

    let name: String
    let templateVersion: String
    let placeholders: [Placeholder]
    let textReplaceGlobs: [String]
    let validation: Validation
    let postScaffoldCommands: [String]
}

