//
//  KeychainStore.swift
//  AmazonMiniSwiftUI
//
//  Created by Arpit Parekh on 26/07/26.
//

import Foundation
import Security

// MARK: - KeychainStore

// A thin, stateless wrapper around the iOS Keychain for persisting Codable values.
// Implemented as an enum with static methods (no instances) → inherently Sendable.
// Used to store the active session (currentUser) and the locally-registered users
// (so self-registered accounts can log in despite DummyJSON not persisting signups).
enum KeychainStore {
    private static let service = "com.brahmakumaris.amazonmini.AmazonMiniSwiftUI"

    static func save<T: Encodable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data

        // Upsert: delete any existing item, then add.
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, for key: String) throws -> T? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return try JSONDecoder().decode(type, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandledStatus(status)
        }
    }

    static func delete(for key: String) {
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
    }

    private static func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}

// MARK: - Keys

extension KeychainStore {
    enum Key {
        static let currentUser = "auth.currentUser"
        static let registeredUsers = "auth.registeredUsers"
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case unhandledStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unhandledStatus(let status):
            return "Keychain operation failed (status \(status))."
        }
    }
}
