//
//  AuthValidator.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import Foundation

// MARK: - AuthValidator

// Pure, side-effect-free validation + formatting helpers for the auth forms.
// Kept free of actor/UI concerns so they can be unit-tested in isolation.
enum AuthValidator {
    // ≥8 chars, at least 1 lowercase, 1 uppercase, and 1 digit.
    static func isValidPassword(_ password: String) -> Bool {
        let pattern = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"
        return password.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidUsername(_ username: String) -> Bool {
        username.trimmingCharacters(in: .whitespaces).count >= 3
    }

    static func isValidFullName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func isValidBirthDate(_ date: Date) -> Bool {
        date < Date()
    }

    // Single "Full Name" field → (firstName, lastName). First token becomes the
    // first name; everything after the first space becomes the last name.
    static func splitName(_ fullName: String) -> (firstName: String, lastName: String) {
        let parts = fullName.split(separator: " ", omittingEmptySubsequences: true)
        let firstName = parts.first.map(String.init) ?? ""
        let lastName = parts.dropFirst().joined(separator: " ")
        return (firstName, lastName)
    }

    // DummyJSON expects birthDate as "1996-5-30" (M-D-YYYY, no leading zeros).
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        return formatter.string(from: date)
    }
}
