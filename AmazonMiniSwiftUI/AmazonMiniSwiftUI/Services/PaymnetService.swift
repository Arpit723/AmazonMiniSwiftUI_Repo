//
//  PaymnetService.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 25/07/26.
//

import Foundation

enum PaymentResult: Sendable {
    case success(transactionId: String)
    case failure(reason: String)
}

protocol PaymentServicing: Sendable {
    func processPayment(amount: Double) async throws -> PaymentResult
}

struct PaymentService: PaymentServicing {
    func processPayment(amount: Double) async throws -> PaymentResult {
        try await Task.sleep(for: .seconds(2))
        return Double.random(in: 0...1) < 0.85
            ? .success(transactionId: UUID().uuidString)
            : .failure(reason: "Card declined")
    }
}
