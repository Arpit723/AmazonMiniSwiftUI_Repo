//
//  ProductDetail.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/06/26.
//

import Foundation

// MARK: - Product Detail Model

struct ProductDetail: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let tags: [String]
    let brand: String?
    let sku: String
    let weight: Int
    let dimensions: Dimensions
    let warrantyInformation: String
    let shippingInformation: String
    let availabilityStatus: String
    let reviews: [Review]
    let returnPolicy: String
    let minimumOrderQuantity: Int
    let meta: Meta
    let images: [String]
    let thumbnail: String
}

// MARK: - Dimensions

struct Dimensions: Decodable, Hashable, Sendable {
    let width: Double
    let height: Double
    let depth: Double
}

// MARK: - Review

struct Review: Decodable, Hashable, Sendable {
    let rating: Int
    let comment: String
    let date: String
    let reviewerName: String
    let reviewerEmail: String
    
    // Computed helper to convert date string → Date
    var parsedDate: Date? {
        ISO8601DateFormatter().date(from: date)
    }
}

// MARK: - Meta

struct Meta: Decodable, Hashable, Sendable {
    let createdAt: String
    let updatedAt: String
    let barcode: String
    let qrCode: String
}

// MARK: - Mock

extension ProductDetail {
    static let mock = ProductDetail(
        id: 1,
        title: "Essence Mascara Lash Princess",
        description: "A popular mascara known for its volumizing and lengthening effects.",
        category: "beauty",
        price: 9.99,
        discountPercentage: 10.48,
        rating: 2.56,
        stock: 99,
        tags: ["beauty", "mascara"],
        brand: "Essence",
        sku: "BEA-ESS-ESS-001",
        weight: 4,
        dimensions: Dimensions(width: 15.14, height: 13.08, depth: 22.99),
        warrantyInformation: "1 week warranty",
        shippingInformation: "Ships in 3-5 business days",
        availabilityStatus: "In Stock",
        reviews: [
            Review(rating: 3, comment: "Would not recommend!", date: "2025-04-30T09:41:02.053Z",
                   reviewerName: "Eleanor Collins", reviewerEmail: "eleanor.collins@x.dummyjson.com"),
            Review(rating: 4, comment: "Very satisfied!", date: "2025-04-30T09:41:02.053Z",
                   reviewerName: "Lucas Gordon", reviewerEmail: "lucas.gordon@x.dummyjson.com")
        ],
        returnPolicy: "No return policy",
        minimumOrderQuantity: 48,
        meta: Meta(createdAt: "2025-04-30T09:41:02.053Z", updatedAt: "2025-04-30T09:41:02.053Z",
                   barcode: "5784719087687", qrCode: "https://cdn.dummyjson.com/public/qr-code.png"),
        images: ["https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/1.webp"],
        thumbnail: "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp"
    )
}
