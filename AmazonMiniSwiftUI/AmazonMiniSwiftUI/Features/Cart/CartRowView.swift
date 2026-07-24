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
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Stepper(value: Binding(
                    get: { item.quantity },
                    set: { onQuantityChange($0) }
                ), in: 1...99) {
                    Text("Qty: \(item.quantity)")
                }

                Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }

    // Same AsyncImage pattern used in ProductListView / ProductDetailView.
    private var thumbnail: some View {
        AsyncImage(url: URL(string: item.thumbnail)) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
