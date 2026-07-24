//
//  CartService.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/07/26.
//

import Foundation

// MARK: - CartService

// Stateless networking layer for the Cart feature. Uses async/await + URLSession —
// no Combine. No mutable stored state, so it is safely `Sendable` as a plain class;
// it would only need to become an `actor` if it grew shared mutable state (e.g. a cache).
final class CartService: Sendable {
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // POST /carts/add — returns a freshly-created cart with a new id.
    func addToCart(userId: Int, products: [(id: Int, quantity: Int)]) async throws -> Cart {
        let body = AddCartBody(userId: userId, products: products.map(CartProductRequest.init))
        return try await send("carts/add", method: "POST", body: body)
    }

    // GET /carts/user/{userId} — fetch the user's existing cart.
    // If the user has no cart yet, returns an empty cart rather than throwing.
    func fetchCart(userId: Int) async throws -> Cart {
        let url = baseURL.appending(path: "carts/user/\(userId)")
        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        let collection = try JSONDecoder().decode(CartCollection.self, from: data)
        return collection.carts.first ?? Cart.empty(userId: userId)
    }

    // PUT /carts/{id} — update quantities for an existing cart.
    func updateCart(cartId: Int, products: [(id: Int, quantity: Int)]) async throws -> Cart {
        let body = UpdateCartBody(merge: true, products: products.map(CartProductRequest.init))
        return try await send("carts/\(cartId)", method: "PUT", body: body)
    }

    // MARK: - Private helpers

    private func send(_ path: String, method: String, body: some Encodable) async throws -> Cart {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response)
        return try JSONDecoder().decode(Cart.self, from: data)
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - Request bodies (service-internal)

private struct AddCartBody: Encodable {
    let userId: Int
    let products: [CartProductRequest]
}

private struct UpdateCartBody: Encodable {
    let merge: Bool
    let products: [CartProductRequest]
}
