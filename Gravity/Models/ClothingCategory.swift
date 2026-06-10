import Foundation

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case shirt
    case pants
    case hoodie
    case jacket
    case shoes
    case dress
    case shorts
    case accessories
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shirt: return "Shirts"
        case .pants: return "Pants"
        case .hoodie: return "Hoodies"
        case .jacket: return "Jackets"
        case .shoes: return "Shoes"
        case .dress: return "Dresses"
        case .shorts: return "Shorts"
        case .accessories: return "Accessories"
        case .other: return "Other"
        }
    }

    var singularName: String {
        switch self {
        case .shirt: return "Shirt"
        case .pants: return "Pants"
        case .hoodie: return "Hoodie"
        case .jacket: return "Jacket"
        case .shoes: return "Shoes"
        case .dress: return "Dress"
        case .shorts: return "Shorts"
        case .accessories: return "Accessory"
        case .other: return "Item"
        }
    }

    var systemImage: String {
        switch self {
        case .shirt: return "tshirt"
        case .pants: return "figure.walk"
        case .hoodie: return "person.fill"
        case .jacket: return "cloud.fill"
        case .shoes: return "shoeprints.fill"
        case .dress: return "figure.stand"
        case .shorts: return "figure.run"
        case .accessories: return "sparkles"
        case .other: return "questionmark.circle"
        }
    }

    var immichAlbumName: String { "Wardrobe - \(displayName)" }
}
