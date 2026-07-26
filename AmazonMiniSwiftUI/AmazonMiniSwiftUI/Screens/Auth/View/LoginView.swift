//
//  LoginView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// Username + password login. DummyJSON authenticates by username (not email),
// so this screen asks for a username and surfaces the seeded demo credentials.
struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var username = ""
    @State private var password = ""

    var onSwitchToSignup: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
            }

            if let error = authViewModel.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            Section {
                Button {
                    Task {
                        await authViewModel.login(username: username, password: password)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(authViewModel.isLoading ? "Signing in…" : "Login").bold()
                        Spacer()
                    }
                }
                .disabled(username.isEmpty || password.isEmpty || authViewModel.isLoading)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New here?")
                    Button("Create an account") { onSwitchToSignup() }
                        .font(.footnote)
                }
                Text("Demo credentials:  emilys / emilyspass")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    LoginView(onSwitchToSignup: {})
        .environment(AuthViewModel())
}
