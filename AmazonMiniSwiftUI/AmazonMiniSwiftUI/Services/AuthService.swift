//
//  AuthService.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import Foundation

// MARK: - AuthService

// Networking layer for authentication. async/await + URLSession, no Combine.
// No mutable stored state → safely `Sendable` as a plain class (same pattern as
// CartService). Would only need to become an actor if it grew shared mutable state.
final class AuthService: Sendable {
    private let baseURL = URL(string: "https://dummyjson.com")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // POST /user/login — username + password (DummyJSON does NOT accept email).
    func login(username: String, password: String) async throws -> User {
        let body = LoginRequest(username: username, password: password, expiresInMins: 60)
        return try await send("user/login", method: "POST", body: body)
    }

    // POST /users/add — registers a user. NOTE: DummyJSON does not persist this,
    // so the returned user cannot log in via /user/login afterwards; callers persist
    // it locally to make the account usable.
    func register(_ request: SignupRequest) async throws -> User {
        try await send("users/add", method: "POST", body: request)
    }

    // GET /user/me — fetches the current user for an access token. Included for an
    // optional future validation pass; not used by the default routing in v1.
    func currentUser(token: String) async throws -> User {
        var request = URLRequest(url: baseURL.appending(path: "user/me"))
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try Self.validate(response, data: data)
        return try JSONDecoder().decode(User.self, from: data)
    }

    // DELETE /users/{id} — best-effort account removal. DummyJSON returns the deleted
    // user (or 404 for ids it never persisted). Response body is intentionally ignored.
    func deleteUser(id: Int) async throws {
        var request = URLRequest(url: baseURL.appending(path: "users/\(id)"))
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        try Self.validate(response, data: data)
    }

    // MARK: - Private helpers

    private func send(_ path: String, method: String, body: some Encodable) async throws -> User {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response, data: data)
        return try JSONDecoder().decode(User.self, from: data)
    }

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let apiMessage = (try? JSONDecoder().decode(DummyJSONError.self, from: data))?.message
            switch apiMessage {
            case "Invalid credentials", "Username and password required":
                throw AuthError.invalidCredentials
            default:
                throw AuthError.message(apiMessage ?? "Server error (\(http.statusCode))")
            }
        }
    }
}

// MARK: - Error types

struct DummyJSONError: Decodable {
    let message: String
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case usernameTaken
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid username or password."
        case .usernameTaken: return "This username is already taken."
        case .message(let text): return text
        }
    }
}
