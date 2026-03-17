import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("App") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appModel.appDisplayName)
                            .font(.title2.weight(.semibold))

                        Text(appModel.bundleIdentifier)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Next step") {
                    Button("Open setup checklist", systemImage: "checklist") {
                        path.append(HomeDestination.checklist)
                    }
                }

                Section("Included in this template") {
                    Label("SwiftUI feature-based folder structure", systemImage: "square.grid.2x2")
                    Label("Layered xcconfig files", systemImage: "slider.horizontal.3")
                    Label("XcodeGen project generation", systemImage: "hammer")
                    Label("Optional SwiftLint build phase", systemImage: "checkmark.seal")
                }
            }
            .navigationTitle("Home")
            .navigationDestination(for: HomeDestination.self, destination: destinationView)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: HomeDestination) -> some View {
        switch destination {
        case .checklist:
            HomeChecklistView()
        }
    }
}

