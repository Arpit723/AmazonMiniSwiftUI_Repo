import Foundation

final class ProductService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProducts(limit: Int, skip: Int) async throws -> [Product] {
        print("\(#function) \(Thread.current.isMainThread)")
        guard let url = URL(string: "https://dummyjson.com/products?limit=\(limit)&skip=\(skip)") else {
            throw URLError(.badURL)
        }

        print("URL \(url.absoluteString)")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
        return decoded.products
    }
    
    
    func searchProducts(searchText: String)  async throws -> [Product] {
        print("\(#function)")
        
        guard let url =  URL(string: "https://dummyjson.com/products/search?q=\(searchText)") else {
            throw URLError(.badURL)
        }
        print("URL \(url.absoluteString)")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
        return decoded.products
    }
    
    func fetchProductDetail(productId: Int) async throws -> ProductDetail {
        print("\(#function)")

        guard let url = URL(string: "https://dummyjson.com/products/\(productId)") else {
            throw URLError(.badURL)
        }
        print("URL \(url.absoluteString)")
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ProductDetail.self, from: data)
    }
}
