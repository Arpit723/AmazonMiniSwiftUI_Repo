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
        Group {
            if let error = viewModel.error {
                Text("Error: \(error)").foregroundStyle(Color.errorRed)
            } else if viewModel.orders.isEmpty {
                ContentUnavailableView("No Orders Yet", systemImage: "bag")
            } else {
                List(viewModel.orders) { order in
                    NavigationLink {
                        OrderDetailView(order: order)
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Order #\(order.transactionId.prefix(8))")
                                .font(AppFont.headline)
                                .foregroundStyle(Color.brandNavy)
                            Text(order.date, format: .dateTime.day().month().year().hour().minute())
                                .font(AppFont.caption)
                                .foregroundStyle(Color.brandSecondary)
                            HStack(spacing: AppSpacing.xs) {
                                PriceText(amount: order.subtotal, font: AppFont.subheadline, color: Color.brandText)
                                Text("·").foregroundStyle(Color.brandSecondary)
                                Text("\(order.items.count) item(s)")
                                    .font(AppFont.subheadline)
                                    .foregroundStyle(Color.brandSecondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Order History")
        .task { await viewModel.load() }
    }
}
