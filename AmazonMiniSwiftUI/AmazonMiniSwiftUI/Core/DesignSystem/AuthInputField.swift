//
//  AuthInputField.swift
//  AmazonMiniSwiftUI
//
//  A labeled, rounded, icon-led text field shared across forms (Login, Signup,
//  Profile). Supports secure (password) fields with a show/hide toggle and an
//  optional inline error caption (red) shown under the field. Lives in the design
//  system because it is reused beyond the Auth feature.
//
//  Created by Arpit Parekh on 27/07/26.
//

import SwiftUI
import UIKit

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
    var placeholder: String = ""

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
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
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
