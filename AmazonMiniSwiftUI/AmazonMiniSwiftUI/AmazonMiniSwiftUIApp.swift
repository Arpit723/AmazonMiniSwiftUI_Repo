//
//  AmazonMiniSwiftUIApp.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/06/26.
//

import SwiftUI
import SwiftData

@main
struct AmazonMiniSwiftUIApp: App {
    @State private var cartViewModel = CartViewModel()
    @State private var checkoutViewModel: CheckoutViewModel

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
         let cart = CartViewModel()
         _cartViewModel = State(initialValue: cart)
         _checkoutViewModel = State(initialValue: CheckoutViewModel(cartViewModel: cart))
     }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(cartViewModel).environment(checkoutViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
