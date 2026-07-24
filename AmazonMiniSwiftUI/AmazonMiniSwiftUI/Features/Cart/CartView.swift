//
//  CartView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/07/26.
//

import SwiftUI

// The Cart screen. Reads its view model from the environment (injected with
// .environment(cartViewModel) higher up), matching the @Observable + .environment
// pattern rather than ObservableObject + .environmentObject.
//
// Note: this view is presented as a navigation push (see ProductListView's
// navigationDestination), so it does NOT wrap itself in a NavigationStack —
// pushing a NavigationStack into an existing one would double-nest the bars.
// It just sets navigationTitle("Cart").
struct CartView: View {
    @Environment(CartViewModel.self) private var cartViewModel
    @State private var showCheckoutAlert = false

    var body: some View {
        Group {
            if cartViewModel.isLoading && cartViewModel.items.isEmpty {
                ProgressView()
            } else if let error = cartViewModel.error, cartViewModel.items.isEmpty {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
            } else if cartViewModel.items.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    listContent
                    checkoutFooter
                }
            }
        }
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Checkout", isPresented: $showCheckoutAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Checkout is not implemented in this demo.")
        }
    }

    // MARK: - States

    private var emptyState: some View {
        ContentUnavailableView(
            "Your cart is empty",
            systemImage: "cart",
            description: Text("Browse products and add items to your cart.")
        )
    }

    // MARK: - Content

    private var listContent: some View {
        List {
            ForEach(cartViewModel.items) { item in
                CartRowView(
                    item: item,
                    onQuantityChange: { quantity in
                        cartViewModel.updateQuantity(id: item.id, quantity: quantity)
                    },
                    onDelete: {
                        cartViewModel.removeItem(id: item.id)
                    }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        cartViewModel.removeItem(id: item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await cartViewModel.refresh()
        }
    }

    // Pinned below the List (it's outside the List, so it never scrolls away).
    private var checkoutFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Subtotal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("$\(cartViewModel.subtotal, specifier: "%.2f")")
                    .font(.title3)
                    .bold()
            }
            Spacer()
            Button("Proceed to Checkout") {
                showCheckoutAlert = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
    }
}
