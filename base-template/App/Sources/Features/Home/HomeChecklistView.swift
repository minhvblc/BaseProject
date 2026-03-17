import SwiftUI

struct HomeChecklistView: View {
    private let items = [
        "Replace __APP_DISPLAY_NAME__ in template files.",
        "Replace __TARGET_NAME__ for the project, target, and module.",
        "Replace __BUNDLE_ID__ in project and config files.",
        "Run Scripts/generate.sh to create the Xcode project.",
        "Open the generated project and confirm the first simulator build."
    ]

    var body: some View {
        List(items, id: \.self) { item in
            Label(item, systemImage: "checkmark.circle")
        }
        .navigationTitle("Setup Checklist")
    }
}

