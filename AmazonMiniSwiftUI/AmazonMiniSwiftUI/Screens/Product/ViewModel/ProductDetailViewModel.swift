
//
//  Untitled.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 24/06/26.
//

import Combine
import Foundation

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var productDetail: ProductDetail?
    @Published var error: String?
    @Published var isLoading = false

    private let service: ProductService
    private var cancellables = Set<AnyCancellable>()

    init(service: ProductService = ProductService()) {
        self.service = service
    }

    func loadProductDetail(productId: Int) async {
        isLoading = true
        error = nil

        await service.fetchProductDetail(productId: productId, )
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                }
            } receiveValue: { [weak self] productDetail in
                self?.productDetail = productDetail
            }
            .store(in: &cancellables)
    }

}
