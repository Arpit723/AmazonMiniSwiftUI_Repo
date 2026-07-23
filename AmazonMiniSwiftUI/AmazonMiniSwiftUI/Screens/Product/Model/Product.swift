struct ProductResponse: Decodable, Sendable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}

struct Product: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let brand: String?
    let thumbnail: String
}

extension Product {
    static let mock = Product(
        id: 1,
        title: "Essence Mascara Lash Princess",
        description: "A popular mascara known for its volumizing and lengthening effects.",
        category: "beauty",
        price: 9.99,
        discountPercentage: 10.48,
        rating: 2.56,
        stock: 99,
        brand: "Essence",
        thumbnail: "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp"
    )
    
    static let mocks: [Product] = [
        Product(id: 1, title: "Essence Mascara Lash Princess", description: "Volumizing and lengthening mascara.",
                category: "beauty", price: 9.99, discountPercentage: 10.48, rating: 2.56, stock: 99,
                brand: "Essence", thumbnail: "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp"),
        
        Product(id: 2, title: "Eyeshadow Palette with Mirror", description: "Versatile eyeshadow palette with built-in mirror.",
                category: "beauty", price: 19.99, discountPercentage: 18.19, rating: 2.86, stock: 34,
                brand: "Glamour Beauty", thumbnail: "https://cdn.dummyjson.com/product-images/beauty/eyeshadow-palette-with-mirror/thumbnail.webp"),
        
        Product(id: 3, title: "Powder Canister", description: "Lightweight translucent setting powder.",
                category: "beauty", price: 14.99, discountPercentage: 9.84, rating: 4.64, stock: 89,
                brand: "Velvet Touch", thumbnail: "https://cdn.dummyjson.com/product-images/beauty/powder-canister/thumbnail.webp"),
        
        Product(id: 4, title: "Red Lipstick", description: "Classic bold red with creamy pigmented formula.",
                category: "beauty", price: 12.99, discountPercentage: 12.16, rating: 4.36, stock: 91,
                brand: "Chic Cosmetics", thumbnail: "https://cdn.dummyjson.com/product-images/beauty/red-lipstick/thumbnail.webp"),
        
        Product(id: 5, title: "Red Nail Polish", description: "Rich glossy red with quick-drying formula.",
                category: "beauty", price: 8.99, discountPercentage: 11.44, rating: 4.32, stock: 79,
                brand: "Nail Couture", thumbnail: "https://cdn.dummyjson.com/product-images/beauty/red-nail-polish/thumbnail.webp"),
        
        Product(id: 6, title: "Calvin Klein CK One", description: "Classic unisex fresh and clean fragrance.",
                category: "fragrances", price: 49.99, discountPercentage: 1.89, rating: 4.37, stock: 29,
                brand: "Calvin Klein", thumbnail: "https://cdn.dummyjson.com/product-images/fragrances/calvin-klein-ck-one/thumbnail.webp"),
        
        Product(id: 7, title: "Chanel Coco Noir", description: "Elegant evening fragrance with rose and sandalwood.",
                category: "fragrances", price: 129.99, discountPercentage: 16.51, rating: 4.26, stock: 58,
                brand: "Chanel", thumbnail: "https://cdn.dummyjson.com/product-images/fragrances/chanel-coco-noir-eau-de/thumbnail.webp"),
    ]
}
