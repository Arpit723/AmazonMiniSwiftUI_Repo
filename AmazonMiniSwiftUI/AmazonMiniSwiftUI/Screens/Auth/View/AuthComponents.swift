//
//  AuthComponents.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI
import UIKit

// MARK: - AuthHeaderView

// Branded logo block reused at the top of Login and Signup: an orange rounded square
// holding a bag icon, plus the "Amazon Mini" wordmark and a one-line subtitle.
struct AuthHeaderView: View {
    var subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.brandOrange)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.brandOrange.opacity(0.35), radius: 8, y: 4)
                Image(systemName: "bag.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Amazon Mini")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.brandNavy)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}

// MARK: - AuthInputField

// A labeled, rounded, icon-led text field. Supports secure (password) fields with a
// show/hide toggle and an optional inline error caption (red) shown under the field.
struct AuthInputField: View {
    var title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization? = nil
    var autocorrection: Bool = true
    var leadingIcon: String? = nil
    var errorMessage: String? = nil

    @State private var showText = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.brandNavy)

            HStack(spacing: 10) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(Color.brandSecondary)
                        .frame(width: 20)
                }

                Group {
                    if isSecure && !showText {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(!autocorrection)

                if isSecure {
                    Button {
                        showText.toggle()
                    } label: {
                        Image(systemName: showText ? "eye.slash" : "eye")
                            .foregroundStyle(Color.brandSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showText ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.fieldBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(errorMessage != nil ? Color.errorRed : Color.fieldBorder, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.errorRed)
            }
        }
    }
}
