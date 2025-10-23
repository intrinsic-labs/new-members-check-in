import Foundation
import Security

/// Manages secure storage of authentication tokens in Keychain
class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.christcovenant.newmembers"
    private let account = "supabase_session"

    private init() {}

    /// Save session token to Keychain
    func save(token: String) throws {
        let data = token.data(using: .utf8)!
        var query = baseQuery()
        query[kSecValueData as String] = data

        // Try to delete first (if exists)
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    /// Retrieve session token from Keychain
    func retrieve() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.retrieveFailed(status)
        }

        return token
    }

    /// Delete session token from Keychain
    func delete() throws {
        let query = baseQuery()
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Clear all tokens (for logout)
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    // MARK: - Private

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save token to Keychain (error: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve token from Keychain (error: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete token from Keychain (error: \(status))"
        }
    }
}
