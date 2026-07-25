//
//  OrderHistoryView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 25/07/26.
//

import Foundation
import SwiftUI

struct OrderHistoryView: View {
    @State private var viewModel = OrderHistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let error = viewModel.error {
                    Text("Error: \(error)").foregroundStyle(.red)
                } else if viewModel.orders.isEmpty {
                    ContentUnavailableView("No Orders Yet", systemImage: "bag")
                } else {
                    List(viewModel.orders) { order in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order #\(order.transactionId.prefix(8))").font(.headline)
                            Text(order.date, format: .dateTime.day().month().year().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(order.subtotal, specifier: "%.2f")  ·  \(order.items.count) item(s)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Order History")
            .task { await viewModel.load() }
        }
    }
}
