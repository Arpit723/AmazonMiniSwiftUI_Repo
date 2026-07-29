//
//  AuthValidatorTests.swift
//  AmazonMiniSwiftUITests
//

import XCTest
@testable import AmazonMiniSwiftUI

final class AuthValidatorTests: XCTestCase {

    func testParseBirthDate_validString() {
        XCTAssertNotNil(AuthValidator.parseBirthDate("1996-5-30"))
    }

    func testParseBirthDate_nilAndEmpty() {
        XCTAssertNil(AuthValidator.parseBirthDate(nil))
        XCTAssertNil(AuthValidator.parseBirthDate(""))
    }

    func testParseBirthDate_invalid() {
        XCTAssertNil(AuthValidator.parseBirthDate("not-a-date"))
    }

    func testParseBirthDate_roundTripsWithFormatDate() throws {
        let original = try XCTUnwrap(AuthValidator.parseBirthDate("2000-1-15"))
        XCTAssertEqual(AuthValidator.formatDate(original), "2000-1-15")
    }
}
