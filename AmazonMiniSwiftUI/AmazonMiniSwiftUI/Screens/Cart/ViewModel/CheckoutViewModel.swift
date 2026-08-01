//
//  PaymentViewModel.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 25/07/26.
//

import Foundation


@MainActor
@Observable
final class CheckoutViewModel {
    var state: CheckoutState = .idle
    private let paymentService: PaymentService
    private let cartViewModel: CartViewModel   // ← held as a dependency

    
    
    var currentTransactionStatus: String {
        switch state {
        case .success(transactionId: let id): return id
        case .failed(reason: let reason): return reason
        default: return ""
        }
    }
    
    private let orderStore = OrderStore()


    init(paymentService: PaymentService = PaymentService(), cartViewModel: CartViewModel) {
        self.paymentService = paymentService
        self.cartViewModel = cartViewModel
    }

    func pay() async {
        state = .processing
        do {
            let result = try await paymentService.processPayment(amount: cartViewModel.subtotal)
            switch result {
            case .success(let id):
                state = .success(transactionId: id)
                    let order = Order(
                        id: UUID(),
                        items: cartViewModel.items,
                        subtotal: cartViewModel.subtotal,
                        transactionId: id,
                        date: .now
                    )
                    try? await orderStore.save(order)
                    cartViewModel.items.removeAll()
            case .failure(let reason): state = .failed(reason: reason)
            }
            print("Result is: \(result)")
        } catch {
            state = .failed(reason: error.localizedDescription)
        }
    }
}

enum CheckoutState: Equatable {
    case idle, processing
    case success(transactionId: String)
    case failed(reason: String)
}
