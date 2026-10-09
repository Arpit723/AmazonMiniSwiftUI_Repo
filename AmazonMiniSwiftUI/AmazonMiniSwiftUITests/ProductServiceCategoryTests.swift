//
//  ProductServiceCategoryTests.swift
//  AmazonMiniSwiftUITests
//
//  Created by Arpit Parekh on 09/10/26.
//

import XCTest
@testable import AmazonMiniSwiftUI

final class ProductServiceCategoryTests: XCTestCase {

    private func makeService() -> ProductService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return ProductService(session: URLSession(configuration: config))
    }

    private func okResponse(_ request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private var emptyProductsData: Data {
        Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8)
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testFetchCategories_returnsDecodedCategories() async throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            let body = Data(#"[{"slug":"beauty","name":"Beauty","url":"https://dummyjson.com/products/category/beauty"},{"slug":"home-decoration","name":"Home Decoration","url":"https://dummyjson.com/products/category/home-decoration"}]"#.utf8)
            return (self.okResponse(request), body)
        }

        let categories = try await makeService().fetchCategories()

        XCTAssertEqual(categories.map(\.slug), ["beauty", "home-decoration"])
        XCTAssertEqual(categories.map(\.name), ["Beauty", "Home Decoration"])
        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.url?.absoluteString, "https://dummyjson.com/products/categories")
    }

    func testFetchProducts_category_buildsURLWithPaginationAndSortParams() async throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            return (self.okResponse(request), self.emptyProductsData)
        }

        let products = try await makeService().fetchProducts(
            category: "beauty",
            limit: 25,
            skip: 50,
            sortBy: "price",
            order: "asc"
        )

        XCTAssertTrue(products.isEmpty)
        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.url?.path, "/products/category/beauty")
        XCTAssertEqual(request.url?.query, "limit=25&skip=50&sortBy=price&order=asc")
    }

    func testFetchProducts_category_omitsSortParamsWhenNil() async throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            return (self.okResponse(request), self.emptyProductsData)
        }

        _ = try await makeService().fetchProducts(category: "fragrances", limit: 10, skip: 0)

        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.url?.absoluteString, "https://dummyjson.com/products/category/fragrances?limit=10&skip=0")
    }
}
