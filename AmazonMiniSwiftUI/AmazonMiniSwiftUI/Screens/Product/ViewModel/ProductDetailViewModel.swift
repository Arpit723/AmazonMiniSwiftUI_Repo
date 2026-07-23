
//
//  Untitled.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/06/26.
//

import Foundation

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var productDetail: ProductDetail?
    @Published var error: String?
    @Published var isLoading = false

    private let service: ProductService

    init(service: ProductService = ProductService()) {
        self.service = service
    }

    func loadProductDetail(productId: Int) async {
        isLoading = true
        error = nil

        do {
            self.productDetail = try await service.fetchProductDetail(productId: productId)
        } catch {
            self.error = error.localizedDescription
        }
        self.isLoading = false
    }

}
