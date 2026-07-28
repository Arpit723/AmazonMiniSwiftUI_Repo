//
//  CartRowView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/07/26.
//

import SwiftUI

// A single cart line. Extracted from CartView so each row is small, testable,
// and reusable. It owns no state — quantity changes and deletion are reported
// back to CartViewModel through closures.
struct CartRowView: View {
    let item: CartItem
    var onQuantityChange: (Int) -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            thumbnail

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(item.title)
                    .font(AppFont.headline)
                    .foregroundStyle(Color.brandNavy)
                    .lineLimit(2)

                PriceText(amount: item.price, font: AppFont.subheadline, color: Color.brandSecondary)

                Stepper(value: Binding(
                    get: { item.quantity },
                    set: { onQuantityChange($0) }
                ), in: 1...99) {
                    Text("Qty: \(item.quantity)")
                }

                PriceText(amount: item.price * Double(item.quantity), font: AppFont.headline, color: Color.brandNavy)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var thumbnail: some View {
        RemoteImage(urlString: item.thumbnail)
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}

#Preview {
    CartRowView(
        item: CartItem(
            id: 144,
            title: "Cricket Helmet",
            price: 44.99,
            quantity: 4,
            total: 179.96,
            discountPercentage: 11.47,
            discountedTotal: 159.32,
            thumbnail: "https://cdn.dummyjson.com/product-images/sports-accessories/cricket-helmet/thumbnail.webp"
        ),
        onQuantityChange: { _ in },
        onDelete: { }
    )
    .padding()
}
