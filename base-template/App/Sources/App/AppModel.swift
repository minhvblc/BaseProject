import Observation

@MainActor
@Observable
final class AppModel {
    var selectedTab: AppTab = .home
    let appDisplayName = "__APP_DISPLAY_NAME__"
    let bundleIdentifier = "__BUNDLE_ID__"
}

