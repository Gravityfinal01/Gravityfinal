import SwiftUI

/// Light / dark / follow-system. Stored in UserDefaults under `AppAppearance.storageKey`.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// nil means "follow the system setting".
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// How items are laid out in the Wardrobe tab.
enum WardrobeLayout: String, CaseIterable, Identifiable {
    case list, compact, detailed

    static let storageKey = "wardrobeLayout"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .list:     return "List"
        case .compact:  return "Grid"
        case .detailed: return "Grid with Details"
        }
    }

    var description: String {
        switch self {
        case .list:     return "Small photo with the item name and type."
        case .compact:  return "Photos only, three per row."
        case .detailed: return "Large photos with name, color and brand."
        }
    }

    var systemImage: String {
        switch self {
        case .list:     return "list.bullet"
        case .compact:  return "square.grid.3x3"
        case .detailed: return "square.grid.2x2"
        }
    }
}
