//
//  OrderStore.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 25/07/26.
//

import Foundation

actor OrderStore {
    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("orders.json")
    }

    func save(_ order: Order) throws {
        var orders = try loadAll()
        orders.append(order)
        let data = try JSONEncoder().encode(orders)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadAll() throws -> [Order] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Order].self, from: data)
    }
}
