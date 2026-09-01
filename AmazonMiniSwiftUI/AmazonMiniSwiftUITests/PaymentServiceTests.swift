//
//  PaymentServiceTests.swift
//  AmazonMiniSwiftUITests
//
//  Created by Arpit Parekh on 31/08/26.
//

import XCTest
@testable import AmazonMiniSwiftUI

final class PaymentServiceTests: XCTestCase {

    func testProcessPayment_succeedsForPositiveAmount() async throws {
        let service = PaymentService()
        let result = try await service.processPayment(amount: 44.99)
        guard case .success = result else {
            return XCTFail("Expected success for a positive amount, got \(result)")
        }
    }

    func testProcessPayment_succeedsForSingleAndMultipleItemTotals() async throws {
        let service = PaymentService()
        let singleItemTotal = 44.99
        let multipleItemsTotal = 44.99 + 179.96 + 12.5
        for amount in [singleItemTotal, multipleItemsTotal] {
            let result = try await service.processPayment(amount: amount)
            guard case .success = result else {
                return XCTFail("Expected success for amount \(amount), got \(result)")
            }
        }
    }

    func testProcessPayment_failsForNonPositiveAmount() async throws {
        let service = PaymentService()
        for amount in [0.0, -10.0] {
            let result = try await service.processPayment(amount: amount)
            guard case .failure = result else {
                return XCTFail("Expected failure for amount \(amount), got \(result)")
            }
        }
    }
}
