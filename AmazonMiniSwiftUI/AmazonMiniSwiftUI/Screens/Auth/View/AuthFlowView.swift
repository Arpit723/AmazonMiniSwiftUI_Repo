//
//  AuthFlowView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// Container for the unauthenticated experience: swaps between Login and Signup
// within its own NavigationStack. Shown by RootView when not logged in.
struct AuthFlowView: View {
    @State private var mode: AuthMode = .login

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .login:
                    LoginView(onSwitchToSignup: { withAnimation { mode = .signup } })
                case .signup:
                    SignupView(onSwitchToLogin: { withAnimation { mode = .login } })
                }
            }
            .navigationTitle(mode == .login ? "Login" : "Sign Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

enum AuthMode {
    case login
    case signup
}

#Preview {
    AuthFlowView()
        .environment(AuthViewModel())
}
