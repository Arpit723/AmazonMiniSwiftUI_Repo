//
//  ContentView.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        ProductListView()
        
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
