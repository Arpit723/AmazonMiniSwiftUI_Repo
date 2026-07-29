//
//  AuthServiceTests.swift
//  AmazonMiniSwiftUITests
//

import XCTest
@testable import AmazonMiniSwiftUI

final class AuthServiceTests: XCTestCase {

    private func makeService() -> AuthService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return AuthService(session: URLSession(configuration: config))
    }

    func testDeleteUser_success_sendsDELETE() async throws {
        var captured: URLRequest?
        MockURLProtocol.handler = { request in
            captured = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        try await makeService().deleteUser(id: 42)
        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertEqual(request.url?.absoluteString, "https://dummyjson.com/users/42")
    }

    func testDeleteUser_throwsOn404() async {
        MockURLProtocol.handler = { request in
            let body = Data(#"{"message":"User not found"}"#.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        do {
            try await makeService().deleteUser(id: 99)
            XCTFail("Expected deleteUser to throw")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
}
