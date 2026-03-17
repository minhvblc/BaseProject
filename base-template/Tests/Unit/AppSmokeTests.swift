import Testing
@testable import __TARGET_NAME__

struct AppSmokeTests {
    @Test("App model starts with the configured template values")
    @MainActor
    func appModelDefaults() {
        let model = AppModel()

        #expect(model.selectedTab == .home)
        #expect(model.appDisplayName == "__APP_DISPLAY_NAME__")
        #expect(model.bundleIdentifier == "__BUNDLE_ID__")
    }
}
