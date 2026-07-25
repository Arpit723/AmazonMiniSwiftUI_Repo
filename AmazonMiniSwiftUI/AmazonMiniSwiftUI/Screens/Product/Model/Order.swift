//
//  Order.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 25/07/26.
//

import Foundation

struct Order: Codable, Identifiable, Sendable {
    let id: UUID
    let items: [CartItem]
    let subtotal: Double
    let transactionId: String
    let date: Date
}
