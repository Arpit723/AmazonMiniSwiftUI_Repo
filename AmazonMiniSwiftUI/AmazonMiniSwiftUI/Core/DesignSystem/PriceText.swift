//
//  PriceText.swift
//  AmazonMiniSwiftUI
//
//  Consistent currency display everywhere (localized USD, monospaced digits) so prices
//  never drift in format. Replaces inline `Text("$\(value, specifier: "%.2f")")`.
//
//      PriceText(amount: product.price)
//      PriceText(amount: total, font: .title3.weight(.semibold), color: .brandNavy)
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

struct PriceText: View {
    var amount: Double
    var font: Font = .headline
    var color: Color = .brandText

    var body: some View {
        Text(amount, format: .currency(code: "USD"))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
    }
}
