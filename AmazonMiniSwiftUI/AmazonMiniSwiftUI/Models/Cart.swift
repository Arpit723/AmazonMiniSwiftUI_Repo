//
//  Cart.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/07/26.
//

import Foundation

// MARK: - CartItem

// A product line inside a cart. Mirrors the DummyJSON `/carts` "products" entry:
//   id, title, price, quantity, total, discountPercentage, discountedTotal, thumbnail.
//
// Note: DummyJSON is inconsistent across endpoints — GET responses name the discounted
// line value "discountedTotal", while POST/PUT responses name it "discountedPrice".
// We decode from either key so the same model works for fetch, add, and update.
struct CartItem: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let price: Double
    var quantity: Int
    var total: Double
    let discountPercentage: Double
    let discountedTotal: Double
    let thumbnail: String

    enum CodingKeys: String, CodingKey {
        case id, title, price, quantity, total, discountPercentage
        case discountedTotal, discountedPrice
        case thumbnail
    }

    init(
        id: Int,
        title: String,
        price: Double,
        quantity: Int,
        total: Double,
        discountPercentage: Double,
        discountedTotal: Double,
        thumbnail: String
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.quantity = quantity
        self.total = total
        self.discountPercentage = discountPercentage
        self.discountedTotal = discountedTotal
        self.thumbnail = thumbnail
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        price = try c.decode(Double.self, forKey: .price)
        quantity = try c.decode(Int.self, forKey: .quantity)
        total = try c.decode(Double.self, forKey: .total)
        discountPercentage = try c.decode(Double.self, forKey: .discountPercentage)
        thumbnail = try c.decode(String.self, forKey: .thumbnail)
        // GET returns "discountedTotal", POST/PUT return "discountedPrice".
        discountedTotal = (try c.decodeIfPresent(Double.self, forKey: .discountedTotal))
            ?? (try? c.decodeIfPresent(Double.self, forKey: .discountedPrice))
            ?? total
    }

    // Encoding is explicit because the custom init(from:) above disables the
    // automatic Encodable synthesis. We always write under the canonical
    // "discountedTotal" key (the extra discountedPrice case is decode-only).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(price, forKey: .price)
        try c.encode(quantity, forKey: .quantity)
        try c.encode(total, forKey: .total)
        try c.encode(discountPercentage, forKey: .discountPercentage)
        try c.encode(discountedTotal, forKey: .discountedTotal)
        try c.encode(thumbnail, forKey: .thumbnail)
    }

    init(product: Product, quantity: Int) {
        self.id = product.id
        self.title = product.title
        self.price = product.price
        self.quantity = quantity
        self.total = product.price * Double(quantity)
        self.discountPercentage = product.discountPercentage
        self.discountedTotal = product.price * Double(quantity) * (1 - product.discountPercentage / 100)
        self.thumbnail = product.thumbnail
    }

    init(detail: ProductDetail, quantity: Int) {
        self.id = detail.id
        self.title = detail.title
        self.price = detail.price
        self.quantity = quantity
        self.total = detail.price * Double(quantity)
        self.discountPercentage = detail.discountPercentage
        self.discountedTotal = detail.price * Double(quantity) * (1 - detail.discountPercentage / 100)
        self.thumbnail = detail.thumbnail
    }
}

// MARK: - Cart

// A full cart. The JSON "products" array maps to the Swift `items` property.
struct Cart: Codable, Sendable {
    let id: Int
    let userId: Int
    let items: [CartItem]
    let total: Double
    let discountedTotal: Double
    let totalProducts: Int
    let totalQuantity: Int

    enum CodingKeys: String, CodingKey {
        case id, userId, total, discountedTotal, totalProducts, totalQuantity
        case items = "products"
    }

    static func empty(userId: Int) -> Cart {
        Cart(id: 0, userId: userId, items: [], total: 0, discountedTotal: 0,
             totalProducts: 0, totalQuantity: 0)
    }
}

// MARK: - Wrapper for GET /carts/user/{id}

// The "get carts by user" endpoint wraps results: { "carts": [...], "total", "skip", "limit" }.
struct CartCollection: Decodable, Sendable {
    let carts: [Cart]
    let total: Int
    let skip: Int
    let limit: Int
}

// MARK: - Request body

// The shape sent to DummyJSON for add/update operations: { "id": Int, "quantity": Int }.
struct CartProductRequest: Encodable {
    let id: Int
    let quantity: Int
}
