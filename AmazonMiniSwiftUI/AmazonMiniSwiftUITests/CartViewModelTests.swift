//
//  CartViewModelTests.swift
//  AmazonMiniSwiftUITests
//
//  Created by Arpit Parekh on 29/07/26.
//

import XCTest
@testable import AmazonMiniSwiftUI

@MainActor
final class CartViewModelTests: XCTestCase {

    func testQuantityFor_zeroWhenItemAbsent() {
        let vm = CartViewModel()
        XCTAssertEqual(vm.quantity(for: 999), 0)
    }

    func testQuantityFor_returnsLineQuantity() {
        let vm = CartViewModel()
        vm.items = [CartItem(product: Product.mock, quantity: 3)]
        XCTAssertEqual(vm.quantity(for: Product.mock.id), 3)
    }

    func testQuantityFor_updatesWhenQuantityChanges() {
        let vm = CartViewModel()
        vm.items = [CartItem(product: Product.mock, quantity: 2)]
        XCTAssertEqual(vm.quantity(for: Product.mock.id), 2)

        vm.items[0].quantity = 5
        XCTAssertEqual(vm.quantity(for: Product.mock.id), 5)

        vm.items = []
        XCTAssertEqual(vm.quantity(for: Product.mock.id), 0)
    }
}
