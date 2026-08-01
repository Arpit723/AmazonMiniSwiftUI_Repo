//
//  OrderDetailView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 01/08/26.
//

import Foundation
import SwiftUI

// Read-only breakdown of a single past order. Pushed from OrderHistoryView via
// NavigationLink(value:). No own NavigationStack — OrderHistoryView already has one.
struct OrderDetailView: View {
    let order: Order

    var body: some View {
        List {
            Section {
                LabeledContent("Order ID", value: String(order.transactionId.prefix(8)))
                LabeledContent("Date", value: order.date.formatted(.dateTime.day().month().year().hour().minute()))
            }

            Section("Items") {
                ForEach(order.items) { item in
                    HStack(spacing: AppSpacing.md) {
                        RemoteImage(urlString: item.thumbnail)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(AppFont.subheadline)
                                .foregroundStyle(Color.brandNavy)
                            Text("Qty \(item.quantity)")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.brandSecondary)
                        }
                        Spacer()
                        PriceText(amount: item.total, font: AppFont.subheadline, color: Color.brandText)
                    }
                }
            }

            Section {
                HStack {
                    Text("Total")
                        .font(AppFont.headline)
                        .foregroundStyle(Color.brandNavy)
                    Spacer()
                    PriceText(amount: order.subtotal, font: AppFont.title2, color: Color.brandNavy)
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: Order(id: UUID(), items: [], subtotal: 0, transactionId: "PREVIEW1234", date: .now))
    }
}
