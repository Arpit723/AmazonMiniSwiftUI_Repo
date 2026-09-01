//
//  PaymentService.swift
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
        // Deterministic mock: a demo checkout always succeeds for a payable
        // amount and only fails for non-positive totals (previously this
        // randomly declined ~15% of the time regardless of cart contents).
        guard amount > 0 else {
            return .failure(reason: "Invalid amount")
        }
        return .success(transactionId: UUID().uuidString)
    }
}
