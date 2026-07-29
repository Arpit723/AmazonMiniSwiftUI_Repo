//
//  QuantityStepper.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 29/07/26.
//

import SwiftUI

// MARK: - QuantityStepper

// A prominent "− [count] +" control for adjusting an item's cart quantity, used on the
// product-detail screen. Owns no state — increments/decrements are reported via closures;
// the caller decides that a decrement at quantity 1 removes the item (detail-screen UX).
struct QuantityStepper: View {
    let quantity: Int
    var onIncrement: () -> Void
    var onDecrement: () -> Void

    private let maxQuantity = 99

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            circleButton(systemName: "minus", action: onDecrement)

            Text("\(quantity)")
                .font(AppFont.headline)
                .foregroundStyle(Color.brandNavy)
                .monospacedDigit()
                .frame(minWidth: 28)

            circleButton(systemName: "plus", isEnabled: quantity < maxQuantity, action: onIncrement)
        }
    }

    private func circleButton(systemName: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Color.brandOrange.opacity(isEnabled ? 1 : 0.4))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        QuantityStepper(quantity: 1, onIncrement: {}, onDecrement: {})
        QuantityStepper(quantity: 3, onIncrement: {}, onDecrement: {})
        QuantityStepper(quantity: 99, onIncrement: {}, onDecrement: {})
    }
    .padding()
}
