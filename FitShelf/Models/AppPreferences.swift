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

/// App-wide accent color. Pastel-leaning but dark enough to carry white text.
enum ThemeColor: String, CaseIterable, Identifiable {
    // Order is the order of the swatches in Settings.
    case blue, sky, lavender, pink, red, yellow, green, brown

    static let storageKey = "themeColor"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blue:     return "Blue"
        case .sky:      return "Sky"
        case .lavender: return "Lavender"
        case .pink:     return "Pink"
        case .red:      return "Red"
        case .yellow:   return "Yellow"
        case .green:    return "Green"
        case .brown:    return "Brown"
        }
    }

    var color: Color {
        switch self {
        case .blue:     return Color(red: 0.36, green: 0.56, blue: 0.93)
        case .sky:      return Color(red: 0.47, green: 0.72, blue: 0.92)
        case .lavender: return Color(red: 0.63, green: 0.56, blue: 0.90)
        case .pink:     return Color(red: 0.93, green: 0.55, blue: 0.72)
        case .red:      return Color(red: 0.90, green: 0.42, blue: 0.42)
        case .yellow:   return Color(red: 0.95, green: 0.76, blue: 0.31)
        case .green:    return Color(red: 0.42, green: 0.72, blue: 0.55)
        case .brown:    return Color(red: 0.67, green: 0.51, blue: 0.38)
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
