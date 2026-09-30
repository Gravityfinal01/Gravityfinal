import Foundation

// MARK: - Top-level category

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case tops
    case bottoms
    case jackets
    case sweaters
    case shoes
    case dresses
    case accessories
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tops:        return "Tops"
        case .bottoms:     return "Bottoms"
        case .jackets:     return "Jackets"
        case .sweaters:    return "Sweaters"
        case .shoes:       return "Shoes"
        case .dresses:     return "Dresses"
        case .accessories: return "Accessories"
        case .other:       return "Other"
        }
    }

    var singularName: String {
        switch self {
        case .tops:        return "Top"
        case .bottoms:     return "Bottom"
        case .jackets:     return "Jacket"
        case .sweaters:    return "Sweater"
        case .shoes:       return "Shoes"
        case .dresses:     return "Dress"
        case .accessories: return "Accessory"
        case .other:       return "Item"
        }
    }

    var systemImage: String {
        switch self {
        case .tops:        return "tshirt"
        case .bottoms:     return "figure.walk"
        case .jackets:     return "cloud.fill"
        case .sweaters:    return "person.fill"
        case .shoes:       return "shoeprints.fill"
        case .dresses:     return "figure.stand"
        case .accessories: return "sparkles"
        case .other:       return "questionmark.circle"
        }
    }

    var subcategories: [ClothingSubcategory] {
        ClothingSubcategory.allCases.filter { $0.parent == self }
    }

    var hasSubcategories: Bool { !subcategories.isEmpty }

    var immichAlbumName: String { "Wardrobe - \(displayName)" }

    /// Maps raw values from the previous flat category scheme
    /// ("shirt", "pants", "hoodie", …) onto the new hierarchy.
    static func fromLegacy(_ raw: String) -> (category: ClothingCategory, subcategory: ClothingSubcategory?) {
        if let cat = ClothingCategory(rawValue: raw) { return (cat, nil) }
        switch raw {
        case "shirt":  return (.tops, .tshirt)
        case "pants":  return (.bottoms, nil)
        case "hoodie": return (.sweaters, .hoodie)
        case "jacket": return (.jackets, nil)
        case "dress":  return (.dresses, nil)
        case "shorts": return (.bottoms, .shorts)
        default:       return (.other, nil)
        }
    }
}

// MARK: - Subcategory

enum ClothingSubcategory: String, Codable, CaseIterable, Identifiable {
    // Tops
    case tshirt, longSleeve, buttonUp, polo, tankTop
    // Bottoms
    case shorts, jeans, sweatpants, dressPants, skirt
    // Jackets
    case coat, puffer, vest
    // Sweaters
    case zipUp, crewneck, hoodie, sweater, turtleneck, cardigan
    // Shoes
    case boots, athletic, casualShoes, heels, dressShoes, flats, sandals
    // Accessories
    case bag, earrings, ring, bracelet, necklace, watch, belt

    var id: String { rawValue }

    var parent: ClothingCategory {
        switch self {
        case .tshirt, .longSleeve, .buttonUp, .polo, .tankTop:
            return .tops
        case .shorts, .jeans, .sweatpants, .dressPants, .skirt:
            return .bottoms
        case .coat, .puffer, .vest:
            return .jackets
        case .zipUp, .crewneck, .hoodie, .sweater, .turtleneck, .cardigan:
            return .sweaters
        case .boots, .athletic, .casualShoes, .heels, .dressShoes, .flats, .sandals:
            return .shoes
        case .bag, .earrings, .ring, .bracelet, .necklace, .watch, .belt:
            return .accessories
        }
    }

    var displayName: String {
        switch self {
        case .tshirt:      return "T-Shirts"
        case .longSleeve:  return "Long-Sleeves"
        case .buttonUp:    return "Button-Ups"
        case .polo:        return "Polo Shirts"
        case .tankTop:     return "Tank Tops"
        case .shorts:      return "Shorts"
        case .jeans:       return "Jeans"
        case .sweatpants:  return "Sweatpants"
        case .dressPants:  return "Dress Pants"
        case .skirt:       return "Skirts"
        case .coat:        return "Coats"
        case .puffer:      return "Puffers"
        case .vest:        return "Vests"
        case .zipUp:       return "Zip-Ups"
        case .crewneck:    return "Crewnecks"
        case .hoodie:      return "Hoodies"
        case .sweater:     return "Sweaters"
        case .turtleneck:  return "Turtle Necks"
        case .cardigan:    return "Cardigans"
        case .boots:       return "Boots"
        case .athletic:    return "Athletic"
        case .casualShoes: return "Shoes"
        case .heels:       return "Heels"
        case .dressShoes:  return "Dress Shoes"
        case .flats:       return "Flats"
        case .sandals:     return "Sandals"
        case .bag:         return "Bags"
        case .earrings:    return "Earrings"
        case .ring:        return "Rings"
        case .bracelet:    return "Bracelets"
        case .necklace:    return "Necklaces"
        case .watch:       return "Watches"
        case .belt:        return "Belts"
        }
    }

    var singularName: String {
        switch self {
        case .tshirt:      return "T-Shirt"
        case .longSleeve:  return "Long-Sleeve"
        case .buttonUp:    return "Button-Up"
        case .polo:        return "Polo"
        case .tankTop:     return "Tank Top"
        case .shorts:      return "Shorts"
        case .jeans:       return "Jeans"
        case .sweatpants:  return "Sweatpants"
        case .dressPants:  return "Dress Pants"
        case .skirt:       return "Skirt"
        case .coat:        return "Coat"
        case .puffer:      return "Puffer"
        case .vest:        return "Vest"
        case .zipUp:       return "Zip-Up"
        case .crewneck:    return "Crewneck"
        case .hoodie:      return "Hoodie"
        case .sweater:     return "Sweater"
        case .turtleneck:  return "Turtle Neck"
        case .cardigan:    return "Cardigan"
        case .boots:       return "Boots"
        case .athletic:    return "Athletic Shoes"
        case .casualShoes: return "Shoes"
        case .heels:       return "Heels"
        case .dressShoes:  return "Dress Shoes"
        case .flats:       return "Flats"
        case .sandals:     return "Sandals"
        case .bag:         return "Bag"
        case .earrings:    return "Earrings"
        case .ring:        return "Ring"
        case .bracelet:    return "Bracelet"
        case .necklace:    return "Necklace"
        case .watch:       return "Watch"
        case .belt:        return "Belt"
        }
    }

    /// Case-insensitive lookup, tolerant of Ollama returning e.g. "longsleeve" or "Long Sleeve".
    static func lenient(_ raw: String?) -> ClothingSubcategory? {
        guard let raw else { return nil }
        let key = raw.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        return allCases.first { $0.rawValue.lowercased() == key }
    }
}
