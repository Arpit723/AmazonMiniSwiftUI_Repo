//
//  BackButton.swift
//  AmazonMiniSwiftUI
//
//  A reusable view modifier that hides the default navigation back button (and its
//  inherited title) and replaces it with a chevron-only button. Apply it on any pushed
//  screen to show a clean "<" with no back-title:
//
//      ProductDetailView(productId: id)
//          .chevronOnlyBackButton()
//
//  Created by Arpit Parekh on 30/07/26.
//

import SwiftUI

// MARK: - ChevronOnlyBackButton

struct ChevronOnlyBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.brandNavy)
                    }
                    .accessibilityLabel("Back")
                }
            }
    }
}

extension View {
    /// Hides the default back button (and its title) and shows a chevron-only back button.
    func chevronOnlyBackButton() -> some View {
        modifier(ChevronOnlyBackButton())
    }
}
