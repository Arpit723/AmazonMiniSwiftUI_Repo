//
//  ProductListViewModelCategoryTests.swift
//  AmazonMiniSwiftUITests
//
//  Created by Arpit Parekh on 09/10/26.
//

import XCTest
@testable import AmazonMiniSwiftUI

@MainActor
final class ProductListViewModelCategoryTests: XCTestCase {

    private func makeViewModel() -> ProductListViewModel {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return ProductListViewModel(service: ProductService(session: URLSession(configuration: config)))
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<500 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func productsData(ids: [Int]) -> Data {
        let products = ids.map { id in
            #"{"id":\#(id),"title":"P\#(id)","description":"d","category":"c","price":1,"discountPercentage":1,"rating":1,"stock":1,"brand":null,"thumbnail":"t"}"#
        }.joined(separator: ",")
        return Data(#"{"products":[\#(products)],"total":\#(ids.count),"skip":0,"limit":25}"#.utf8)
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testLoadCategories_populatesCategoriesFromService() async {
        var requestURLs: [URL] = []
        MockURLProtocol.handler = { request in
            requestURLs.append(request.url!)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let body = request.url?.path == "/products/categories"
                ? Data(#"[{"slug":"beauty","name":"Beauty","url":"https://dummyjson.com/products/category/beauty"},{"slug":"fragrances","name":"Fragrances","url":"https://dummyjson.com/products/category/fragrances"}]"#.utf8)
                : Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8)
            return (response, body)
        }

        let vm = makeViewModel()
        await vm.loadCategories()

        XCTAssertEqual(vm.categories.map(\.slug), ["beauty", "fragrances"])
        XCTAssertTrue(requestURLs.contains { $0.path == "/products/categories" })
    }

    func testSelectCategory_hitsCategoryEndpointAndSetsSelection() async {
        var requestURLs: [URL] = []
        MockURLProtocol.handler = { request in
            requestURLs.append(request.url!)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8))
        }
        let vm = makeViewModel()

        vm.selectCategory("beauty")
        await waitUntil { requestURLs.contains { $0.path == "/products/category/beauty" } }

        XCTAssertEqual(vm.selectedCategory, "beauty")
        let categoryURL = requestURLs.last { $0.path == "/products/category/beauty" }
        XCTAssertEqual(categoryURL?.query, "limit=25&skip=0")
    }

    func testSelectCategory_clearsSearchText() async {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8))
        }
        let vm = makeViewModel()

        vm.searchText = "phone"
        vm.selectCategory("beauty")

        XCTAssertEqual(vm.searchText, "")
        XCTAssertEqual(vm.selectedCategory, "beauty")
    }

    func testNonEmptySearch_resetsSelectedCategory() async {
        var requestURLs: [URL] = []
        MockURLProtocol.handler = { request in
            requestURLs.append(request.url!)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8))
        }
        let vm = makeViewModel()

        vm.selectedCategory = "beauty"
        vm.searchText = "phone"
        vm.searchTextChanged()
        try? await Task.sleep(for: .milliseconds(700))

        XCTAssertEqual(vm.selectedCategory, nil)
        XCTAssertTrue(requestURLs.contains { $0.path == "/products/search" })
    }

    func testSelectAll_hitsPlainProductsEndpointAfterCategory() async {
        var requestURLs: [URL] = []
        MockURLProtocol.handler = { request in
            requestURLs.append(request.url!)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8))
        }
        let vm = makeViewModel()

        vm.selectCategory("beauty")
        await waitUntil { requestURLs.contains { $0.path == "/products/category/beauty" } }

        vm.selectCategory(nil)
        await waitUntil {
            guard let categoryIndex = requestURLs.firstIndex(where: { $0.path == "/products/category/beauty" }) else { return false }
            return requestURLs[(categoryIndex + 1)...].contains { $0.path == "/products" }
        }

        XCTAssertEqual(vm.selectedCategory, nil)
    }

    func testLoadProducts_failure_setsErrorAndClearsLoading() async {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let vm = makeViewModel()

        await vm.loadProducts()

        XCTAssertNotNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    func testRapidCategorySwitches_lastSelectionWinsWithoutError() async {
        let beautyData = productsData(ids: [1])
        let fragrancesData = productsData(ids: [2])
        let emptyData = Data(#"{"products":[],"total":0,"skip":0,"limit":0}"#.utf8)
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            if request.url?.path == "/products/category/beauty" {
                Thread.sleep(forTimeInterval: 0.08)
                return (response, beautyData)
            }
            if request.url?.path == "/products/category/fragrances" {
                return (response, fragrancesData)
            }
            return (response, emptyData)
        }
        let vm = makeViewModel()

        vm.selectCategory("beauty")
        vm.selectCategory("fragrances")

        await waitUntil { vm.products.map(\.id) == [2] }
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(vm.selectedCategory, "fragrances")
        XCTAssertEqual(vm.products.map(\.id), [2])
        XCTAssertNil(vm.error)
        XCTAssertFalse(vm.isLoading)
    }

    func testSelectAll_duringActiveSearch_clearsSearchAndReloads() async {
        let searchData = productsData(ids: [99])
        let allData = productsData(ids: [7])
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            if request.url?.path == "/products/search" {
                return (response, searchData)
            }
            return (response, allData)
        }
        let vm = makeViewModel()
        vm.searchText = "phone"

        vm.selectCategory(nil)

        XCTAssertEqual(vm.searchText, "")
        await waitUntil { vm.products.map(\.id) == [7] }
        XCTAssertEqual(vm.selectedCategory, nil)
    }
}
