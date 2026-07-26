//
//  AuthViewModel.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import Foundation
import Observation

// MARK: - AuthViewModel

// Session + auth state for the app. @Observable (not ObservableObject) and @MainActor
// (required: @Observable is not implicitly main-actor isolated). Mirrors the Cart
// feature's async/await + Observation pattern; no Combine.
//
// Strategy: "Username + local persistence".
//   - Login checks locally-registered users first, then falls back to POST /user/login
//     for DummyJSON's seeded accounts (e.g. emilys / emilyspass).
//   - Signup calls POST /users/add AND persists the new user locally so the account
//     can actually log in (DummyJSON does not persist signups).
@MainActor
@Observable
final class AuthViewModel {
    // MARK: Observable state

    var currentUser: User?
    var isLoading = false
    var error: String?

    var isLoggedIn: Bool { currentUser != nil }

    var displayName: String {
        [currentUser?.firstName, currentUser?.lastName]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " ")
    }

    // MARK: Dependencies

    private let service: AuthService

    init(service: AuthService = AuthService()) {
        self.service = service
        // Restore immediately (synchronous Keychain read) so there is no login-screen
        // flash on launch when a valid session already exists.
        restoreSessionIfNeeded()
    }

    // MARK: Session restore

    func restoreSessionIfNeeded() {
        do {
            currentUser = try KeychainStore.load(User.self, for: KeychainStore.Key.currentUser)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: Login

    func login(username: String, password: String) async {
        let username = username.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty, !password.isEmpty else {
            error = "Please enter your username and password."
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        // 1. Locally-registered users (self-registered accounts).
        if let local = locallyRegisteredUser(username: username, password: password) {
            currentUser = local
            persistCurrentUser()
            return
        }

        // 2. API for seeded DummyJSON accounts.
        do {
            let user = try await service.login(username: username, password: password)
            currentUser = user
            persistCurrentUser()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: Signup

    func signup(
        fullName: String,
        username: String,
        email: String,
        password: String,
        confirmPassword: String,
        gender: String,
        birthDate: Date
    ) async {
        guard password == confirmPassword else {
            error = "Passwords do not match."
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        let parts = AuthValidator.splitName(fullName)
        let request = SignupRequest(
            firstName: parts.firstName,
            lastName: parts.lastName,
            username: username.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            password: password,
            gender: gender.lowercased(),
            birthDate: AuthValidator.formatDate(birthDate)
        )

        do {
            var user = try await service.register(request)
            // Keep the password so this account can be matched on future local logins.
            user.password = password
            appendRegisteredUser(user)
            currentUser = user
            persistCurrentUser()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: Logout

    func logout() {
        KeychainStore.delete(for: KeychainStore.Key.currentUser)
        currentUser = nil
    }

    // MARK: - Local credential store (Keychain)

    private func locallyRegisteredUser(username: String, password: String) -> User? {
        let registered = (try? KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers)) ?? []
        return registered.first { $0.username.caseInsensitiveCompare(username) == .orderedSame && $0.password == password }
    }

    private func appendRegisteredUser(_ user: User) {
        var registered = (try? KeychainStore.load([User].self, for: KeychainStore.Key.registeredUsers)) ?? []
        registered.removeAll { $0.username.caseInsensitiveCompare(user.username) == .orderedSame }
        registered.append(user)
        try? KeychainStore.save(registered, for: KeychainStore.Key.registeredUsers)
    }

    private func persistCurrentUser() {
        try? KeychainStore.save(currentUser, for: KeychainStore.Key.currentUser)
    }
}
