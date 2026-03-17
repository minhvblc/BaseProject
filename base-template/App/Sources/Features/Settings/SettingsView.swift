import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Identifiers") {
                    LabeledContent("Display name", value: appModel.appDisplayName)
                    LabeledContent("Target", value: "__TARGET_NAME__")
                    LabeledContent("Bundle ID", value: appModel.bundleIdentifier)
                }

                Section("Build setup") {
                    Label("Config/Base.xcconfig, Debug.xcconfig, Release.xcconfig", systemImage: "gearshape.2")
                    Label("Scripts/check-placeholders.sh pre-build validation", systemImage: "exclamationmark.shield")
                    Label("Scripts/swiftlint.sh post-compile lint hook", systemImage: "checkmark.seal")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

