//
//  DiscountPriceView.swift
//  AmazonMiniSwiftUI
//
//  Drop-in replacement for `PriceText` that also surfaces a product's discount. When
//  `discountPercentage > 0` it shows the discounted price, the original price struck
//  through, and (optionally) a "-X%" capsule chip; when there's no discount it renders a
//  single plain `PriceText`, identical to prior behavior. Composes `PriceText` rather than
//  duplicating its currency formatting, so price display stays consistent everywhere.
//
//      DiscountPriceView(price: product.price, discountPercentage: product.discountPercentage)
//      DiscountPriceView(price: total, discountPercentage: product.discountPercentage, showBadge: false)
//
//  Created by Arpit Parekh on 11/08/26.
//

import SwiftUI

struct DiscountPriceView: View {
    var price: Double
    var discountPercentage: Double
    var font: Font = .headline
    var color: Color = .brandText
    var showBadge: Bool = true

    private var hasDiscount: Bool {
        discountPercentage > 0
    }

    // Same formula as CartItem.discountedTotal in Cart.swift — single source of math.
    private var discountedPrice: Double {
        price * (1 - discountPercentage / 100)
    }

    private var badgeText: String {
        "-\(Int(discountPercentage.rounded()))%"
    }

    var body: some View {
        if hasDiscount {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                PriceText(amount: discountedPrice, font: font, color: color)

                // Original price, smaller and struck through. `.strikethrough()` is a
                // Text-only API, so this can't go through `PriceText` (which stays untouched);
                // it's styled to match PriceText's footnote/secondary look instead.
                Text(price, format: .currency(code: "USD"))
                    .font(AppFont.footnote)
                    .foregroundStyle(Color.brandSecondary)
                    .strikethrough()

                if showBadge {
                    Text(badgeText)
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(Color.errorRed)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.errorRed.opacity(0.12), in: Capsule())
                }
            }
        } else {
            PriceText(amount: price, font: font, color: color)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: AppSpacing.lg) {
        DiscountPriceView(price: 9.99, discountPercentage: 10.48)
        DiscountPriceView(price: 12.99, discountPercentage: 0)
    }
    .padding()
}
