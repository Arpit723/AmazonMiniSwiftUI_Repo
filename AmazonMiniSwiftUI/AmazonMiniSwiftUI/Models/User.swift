//
//  User.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import Foundation

// MARK: - User

// The authenticated user. Optional fields cover all DummyJSON response shapes:
//   - /user/login returns: id, username, email, firstName, lastName, gender, image,
//     accessToken, refreshToken (NO password/birthDate).
//   - /users/add returns: a full user incl. password + birthDate (NO tokens).
// All value-type members → Sendable by inference; declared explicitly to match
// Product/Cart conventions.
struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var firstName: String
    var lastName: String
    var username: String
    var email: String?
    var gender: String?
    var birthDate: String?
    var image: String?
    var password: String?
    var accessToken: String?
    var refreshToken: String?
}

// MARK: - Request bodies

// POST /user/login
struct LoginRequest: Encodable {
    let username: String
    let password: String
    let expiresInMins: Int?
}

// POST /users/add
struct SignupRequest: Encodable {
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let password: String
    let gender: String      // lowercase "male" / "female"
    let birthDate: String   // "yyyy-M-d"
}
