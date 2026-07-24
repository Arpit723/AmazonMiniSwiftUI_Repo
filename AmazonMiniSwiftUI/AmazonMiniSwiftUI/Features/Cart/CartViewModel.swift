//
//  CartViewModel.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/07/26.
//

import Foundation
import Observation

// MARK: - CartViewModel

// The Cart feature's state holder. Built with the Observation framework (@Observable)
// instead of ObservableObject/@Published, and async/await instead of Combine.
//
// `@Observable` is NOT implicitly main-actor isolated the way @Published code often
// assumes, so `@MainActor` is declared explicitly. All UI state mutations happen on
// the main actor; service calls await off the main actor and resume here.
@MainActor
@Observable
final class CartViewModel {
    // MARK: Observable state

    var items: [CartItem] = []
    var isLoading = false
    var error: String?

    // MARK: Derived state (read-only; recomputed when `items` changes)

    var subtotal: Double { items.reduce(0) { $0 + $1.price * Double($1.quantity) } }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    // MARK: Dependencies / internals

    private let service: CartService
    private let userId: Int
    private var cartId: Int?

    // Cancel-and-replace Task used to debounce quantity syncs (async equivalent of
    // Combine's .debounce). Cancelling the previous pending Task throws away any
    // in-flight sleep, so only the final value reaches the server.
    private var syncTask: Task<Void, Never>?

    init(userId: Int = 1, service: CartService = CartService()) {
        self.userId = userId
        self.service = service
    }

    // MARK: Mutations (optimistic + background sync)

    // Add from the product list screen.
    func addItem(product: Product) {
        applyAdd(item: CartItem(product: product, quantity: 1))
    }

    // Add from the product detail screen.
    func addItem(product: ProductDetail) {
        applyAdd(item: CartItem(detail: product, quantity: 1))
    }

    func removeItem(id: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items.remove(at: index)
        syncCart()
    }

    // Instant UI feedback, then a debounced sync so rapid stepper taps hit the
    // network once.
    func updateQuantity(id: Int, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].quantity = quantity
        items[index].total = items[index].price * Double(quantity)

        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            syncCart()
        }
    }

    // MARK: Loading

    func refresh() async {
        isLoading = true
        error = nil
        do {
            let cart = try await service.fetchCart(userId: userId)
            items = cart.items
            cartId = cart.id
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Private

    private func applyAdd(item: CartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].quantity += 1
            items[index].total = items[index].price * Double(items[index].quantity)
        } else {
            items.append(item)
        }
        syncAdd()
    }

    // Add creates a new cart on DummyJSON (it's a mock, so carts don't persist
    // across calls). We capture the returned id so quantity updates can target it.
    private func syncAdd() {
        let snapshot = items.map { (id: $0.id, quantity: $0.quantity) }
        Task {
            do {
                let cart = try await service.addToCart(userId: userId, products: snapshot)
                cartId = cart.id
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    // Best-effort update of the known cart with the current local quantities.
    // No-op until we hold a cartId (e.g. before any add/refresh has resolved).
    private func syncCart() {
        guard let cartId else { return }
        let snapshot = items.map { (id: $0.id, quantity: $0.quantity) }
        Task {
            // Errors here are non-fatal: local state is the source of truth for the UI.
            _ = try? await service.updateCart(cartId: cartId, products: snapshot)
        }
    }
}
