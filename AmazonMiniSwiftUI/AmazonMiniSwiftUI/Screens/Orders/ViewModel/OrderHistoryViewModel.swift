//
//  OrderHistoryViewModel.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 25/07/26.
//

import Foundation

@MainActor
@Observable
final class OrderHistoryViewModel {
    var orders: [Order] = []
    var error: String?

    private let store = OrderStore()

    func load() async {
        do {
            orders = try await store.loadAll().sorted { $0.date > $1.date }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
