//
//  AuthViewModelProfileTests.swift
//  AmazonMiniSwiftUITests
//

import XCTest
@testable import AmazonMiniSwiftUI

final class AuthViewModelProfileTests: XCTestCase {

    private func makeUser(username: String, password: String? = "Secret1") -> User {
        User(id: 1, firstName: "Old", lastName: "Name", username: username, email: nil,
             gender: "male", birthDate: "1990-1-1", image: nil, password: password,
             accessToken: nil, refreshToken: nil)
    }

    override func tearDown() {
        KeychainStore.delete(for: KeychainStore.Key.currentUser)
        KeychainStore.delete(for: KeychainStore.Key.registeredUsers)
        // Reset the mock so a handler set in one test can't leak into another.
        MockURLProtocol.handler = nil
    }

    @MainActor
    func testUpdateProfile_mutatesCurrentUserAndPersists() throws {
        let vm = AuthViewModel(service: AuthService())
        vm.currentUser = makeUser(username: "tester")

        vm.updateProfile(firstName: "Jane", lastName: "Doe", gender: "Female", birthDate: "1995-6-15")

        XCTAssertEqual(vm.currentUser?.firstName, "Jane")
        XCTAssertEqual(vm.currentUser?.lastName, "Doe")
        XCTAssertEqual(vm.currentUser?.gender, "female")
        XCTAssertEqual(vm.currentUser?.birthDate, "1995-6-15")

        let persisted = try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser)
        XCTAssertEqual(persisted?.firstName, "Jane")
        XCTAssertEqual(persisted?.birthDate, "1995-6-15")
    }

    @MainActor
    func testUpdateProfile_refreshesLocalRegisteredEntry() throws {
        let local = makeUser(username: "localuser")
        try KeychainStore.save([local], for: KeychainStore.Key.registeredUsers)

        let vm = AuthViewModel(service: AuthService())
        vm.currentUser = local

        vm.updateProfile(firstName: "New", lastName: "Name", gender: "male", birthDate: "1990-1-1")

        let registered = try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers) ?? []
        XCTAssertEqual(registered.count, 1)
        XCTAssertEqual(registered.first?.firstName, "New")
    }

    @MainActor
    func testUpdateProfile_doesNotAddSeededAccountToRegistered() throws {
        let seeded = User(id: 1, firstName: "Emily", lastName: "Blunt", username: "emilys",
                          email: nil, gender: "female", birthDate: "1996-5-30", image: nil,
                          password: nil, accessToken: "tok", refreshToken: nil)

        let vm = AuthViewModel(service: AuthService())
        vm.currentUser = seeded

        vm.updateProfile(firstName: "Em", lastName: "B", gender: "female", birthDate: "1996-5-30")

        let registered = try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers)
        XCTAssertNil(registered)
    }

    @MainActor
    func testDeleteAccount_clearsSession() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{}".utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let vm = AuthViewModel(service: AuthService(session: URLSession(configuration: config)))

        let local = makeUser(username: "deleteme")
        try KeychainStore.save([local], for: KeychainStore.Key.registeredUsers)
        vm.currentUser = local

        await vm.deleteAccount()

        XCTAssertNil(vm.currentUser)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser))
        XCTAssertEqual((try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers))?.count ?? 0, 0)
    }

    @MainActor
    func testDeleteAccount_clearsLocalEvenWhenServer404() async throws {
        MockURLProtocol.handler = { request in
            let body = Data(#"{"message":"User not found"}"#.utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let vm = AuthViewModel(service: AuthService(session: URLSession(configuration: config)))

        let local = makeUser(username: "deleteme")
        try KeychainStore.save([local], for: KeychainStore.Key.registeredUsers)
        vm.currentUser = local

        await vm.deleteAccount()

        XCTAssertNil(vm.currentUser)
        XCTAssertNil(try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser))
        XCTAssertEqual((try KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers))?.count ?? 0, 0)
    }
}
