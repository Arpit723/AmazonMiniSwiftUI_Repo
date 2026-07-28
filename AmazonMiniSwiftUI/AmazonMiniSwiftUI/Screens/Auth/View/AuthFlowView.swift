//
//  AuthFlowView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// Container for the unauthenticated experience: swaps between Login and Signup within
// its own NavigationStack, with the nav bar hidden (the logo is the header) and a
// subtle cross-fade between the two screens. Shown by RootView when not logged in.
struct AuthFlowView: View {
    @State private var mode: AuthMode = .login

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .login:
                    LoginView(onSwitchToSignup: { withAnimation(.easeInOut) { mode = .signup } })
                        .transition(.opacity)
                case .signup:
                    SignupView(onSwitchToLogin: { withAnimation(.easeInOut) { mode = .login } })
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            .animation(.easeInOut, value: mode)
            .toolbar(.hidden, for: .navigationBar)
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
