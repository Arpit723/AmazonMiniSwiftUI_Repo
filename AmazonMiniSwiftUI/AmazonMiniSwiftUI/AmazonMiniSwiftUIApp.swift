//
//  AmazonMiniSwiftUIApp.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/06/26.
//

import SwiftUI

@main
struct AmazonMiniSwiftUIApp: App {
    @State private var cartViewModel = CartViewModel()
    @State private var checkoutViewModel: CheckoutViewModel
    @State private var authViewModel = AuthViewModel()

    init() {
         let cart = CartViewModel()
         _cartViewModel = State(initialValue: cart)
         _checkoutViewModel = State(initialValue: CheckoutViewModel(cartViewModel: cart))
     }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environment(authViewModel)
                .environment(cartViewModel)
                .environment(checkoutViewModel)
        }
    }
}
