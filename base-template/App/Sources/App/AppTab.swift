import SwiftUI

enum AppTab: String, CaseIterable, Hashable {
    case home
    case settings

    var title: LocalizedStringKey {
        switch self {
        case .home:
            return "Home"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .settings:
            return "gearshape"
        }
    }
}

