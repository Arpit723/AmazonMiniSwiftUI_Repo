//
//  LoginView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// Branded username + password login. DummyJSON authenticates by username (not email),
// so this screen asks for a username and surfaces the seeded demo credentials.
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var username = ""
    @State private var password = ""

    var onSwitchToSignup: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthHeaderView(subtitle: "Sign in to continue shopping")

                VStack(spacing: 16) {
                    AuthInputField(
                        title: "Username",
                        text: $username,
                        textContentType: .username,
                        autocapitalization: .never,
                        autocorrection: false,
                        leadingIcon: "person"
                    )

                    AuthInputField(
                        title: "Password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password,
                        autocapitalization: .never,
                        autocorrection: false,
                        leadingIcon: "lock"
                    )

                    if let error = authViewModel.error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.errorRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: authViewModel.isLoading ? "Signing in…" : "Login",
                        isLoading: authViewModel.isLoading,
                        isEnabled: !username.isEmpty && !password.isEmpty
                    ) {
                        Task {
                            await authViewModel.login(username: username, password: password)
                        }
                    }
                }

                VStack(spacing: 6) {
                    Text("New here?")
                        .font(.subheadline)
                        .foregroundStyle(Color.brandSecondary)
                    Button("Create an account") { onSwitchToSignup() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandNavy)
                }

                Text("Demo credentials:  emilys / emilyspass")
                    .font(.footnote)
                    .foregroundStyle(Color.brandSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
    }
}

#Preview {
    LoginView(onSwitchToSignup: {})
        .environment(AuthViewModel())
}
