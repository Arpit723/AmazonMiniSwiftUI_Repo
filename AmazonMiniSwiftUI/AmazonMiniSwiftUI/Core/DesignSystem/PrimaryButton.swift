//
//  PrimaryButton.swift
//  AmazonMiniSwiftUI
//
//  The app-wide primary call-to-action: full-width, brand-orange, with a loading
//  spinner and disabled dimming. Use it for "Login", "Sign Up", "Add to Cart",
//  "Proceed to Checkout", etc.
//
//      PrimaryButton("Add to Cart") { ... }
//      PrimaryButton("Login", isLoading: vm.isLoading, isEnabled: isValid) { ... }
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var isLoading: Bool
    var isEnabled: Bool
    var action: () -> Void

    init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(.white)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color.brandOrange.opacity(isEnabled ? 1 : 0.45))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Enabled") { }
        PrimaryButton(title: "Loading", isLoading: true) { }
        PrimaryButton(title: "Disabled", isEnabled: false) { }
    }
    .padding()
}
