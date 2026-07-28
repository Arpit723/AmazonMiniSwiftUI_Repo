//
//  RootView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import SwiftUI

// The app's true root. Gates the experience on authentication:
//   - logged in  → ProductListView (the main shopping flow)
//   - logged out → AuthFlowView (Login / Signup)
//
// Session restore happens synchronously in AuthViewModel.init(), so by the time
// this view first renders there is no login-screen flash when a session exists.
struct RootView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                ProductListView()
            } else {
                AuthFlowView()
            }
        }.tint(Color.brandOrange)
    }
}
