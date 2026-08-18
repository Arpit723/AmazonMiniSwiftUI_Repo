import Foundation

enum SortOption: String, CaseIterable, Identifiable, Hashable, Sendable {
    case relevance
    case priceLowToHigh
    case priceHighToLow
    case ratingHighToLow
    case titleAZ

    var id: String { rawValue }

    var label: String {
        switch self {
        case .relevance: return "Featured"
        case .priceLowToHigh: return "Price: Low to High"
        case .priceHighToLow: return "Price: High to Low"
        case .ratingHighToLow: return "Rating"
        case .titleAZ: return "Title: A to Z"
        }
    }

    var sortBy: String? {
        switch self {
        case .relevance: return nil
        case .priceLowToHigh, .priceHighToLow: return "price"
        case .ratingHighToLow: return "rating"
        case .titleAZ: return "title"
        }
    }

    var order: String? {
        switch self {
        case .relevance: return nil
        case .priceLowToHigh, .titleAZ: return "asc"
        case .priceHighToLow, .ratingHighToLow: return "desc"
        }
    }
}
