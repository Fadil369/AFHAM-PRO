//
// SecureAPIKeyManager.swift
// AFHAM
//
// Secure API key management using Keychain
// PDPL Compliant - No hardcoded secrets
//

import Foundation
import Security

/// Secure manager for API keys using iOS Keychain
/// Prevents hardcoded secrets and provides secure storage
@MainActor
class SecureAPIKeyManager {
    static let shared = SecureAPIKeyManager()

    private let keychainService = "com.brainsait.afham"
    private let geminiKeyIdentifier = "geminiAPIKey"

    private init() {}

    // MARK: - API Key Management

    /// Retrieves the Gemini API key from secure storage
    /// - Returns: API key if found, nil otherwise
    func getGeminiAPIKey() -> String? {
        return getKey(identifier: geminiKeyIdentifier)
    }

    /// Stores the Gemini API key securely in Keychain
    /// - Parameter key: The API key to store
    /// - Throws: AFHAMError if storage fails
    func setGeminiAPIKey(_ key: String) throws {
        try setKey(key, identifier: geminiKeyIdentifier)
        AppLogger.shared.log("Gemini API key stored securely", level: .info)
    }

    /// Removes the Gemini API key from secure storage
    func removeGeminiAPIKey() {
        removeKey(identifier: geminiKeyIdentifier)
        AppLogger.shared.log("Gemini API key removed", level: .info)
    }

    /// Checks if Gemini API key is configured
    var isGeminiKeyConfigured: Bool {
        return getGeminiAPIKey() != nil && !(getGeminiAPIKey()?.isEmpty ?? true)
    }

    // MARK: - Generic API Key Management

    /// Retrieves an API key for any service from secure storage
    /// - Parameter service: The service identifier (e.g., "deepseek", "openai", "gemini")
    /// - Returns: API key if found, nil otherwise
    func getAPIKey(for service: String) -> String? {
        return getKey(identifier: "\(service)APIKey")
    }

    /// Stores an API key for any service securely in Keychain
    /// - Parameters:
    ///   - key: The API key to store
    ///   - service: The service identifier (e.g., "deepseek", "openai", "gemini")
    func setAPIKey(_ key: String, for service: String) {
        do {
            try setKey(key, identifier: "\(service)APIKey")
            AppLogger.shared.log("\(service) API key stored securely", level: .info)
        } catch {
            AppLogger.shared.log("Failed to store \(service) API key: \(error)", level: .error)
        }
    }

    /// Removes an API key for any service from secure storage
    /// - Parameter service: The service identifier (e.g., "deepseek", "openai", "gemini")
    func removeAPIKey(for service: String) {
        removeKey(identifier: "\(service)APIKey")
        AppLogger.shared.log("\(service) API key removed", level: .info)
    }

    /// Rotates the API key (useful for security compliance)
    /// - Parameter newKey: The new API key
    /// - Throws: AFHAMError if rotation fails
    func rotateGeminiAPIKey(newKey: String) throws {
        let oldKey = getGeminiAPIKey()
        try setGeminiAPIKey(newKey)

        AppLogger.shared.log(
            "API key rotated successfully. Old key archived.",
            level: .success
        )

        // Archive old key with timestamp for audit purposes
        if let oldKey = oldKey {
            try archiveOldKey(oldKey, identifier: "\(geminiKeyIdentifier)_archived_\(Date().timeIntervalSince1970)")
        }
    }

    // MARK: - Generic Keychain Operations

    /// Generic method to retrieve a key from Keychain
    private func getKey(identifier: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                AppLogger.shared.log(
                    "Keychain read error: \(status)",
                    level: .error
                )
            }
            return nil
        }

        return key
    }

    /// Generic method to store a key in Keychain
    private func setKey(_ key: String, identifier: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw AFHAMError.keychainError("Invalid key format")
        }

        // Delete existing item if present
        removeKey(identifier: identifier)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: false // Don't sync to iCloud
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            AppLogger.shared.log(
                "Keychain write error: \(status)",
                level: .error
            )
            throw AFHAMError.keychainError("Failed to store key: \(status)")
        }
    }

    /// Generic method to remove a key from Keychain
    private func removeKey(identifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: identifier
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// Archives an old key for audit purposes
    private func archiveOldKey(_ key: String, identifier: String) throws {
        try setKey(key, identifier: identifier)
    }

    // MARK: - Development Helper Methods

    #if DEBUG
    /// Debug helper to set API key from environment variable
    /// Only available in DEBUG builds
    func setKeyFromEnvironment() throws {
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !envKey.isEmpty {
            try setGeminiAPIKey(envKey)
            AppLogger.shared.log("API key loaded from environment", level: .debug)
        } else {
            AppLogger.shared.log("No GEMINI_API_KEY in environment", level: .warning)
        }
    }

    /// Debug helper to print key status (NOT the actual key)
    func printKeyStatus() {
        let status = isGeminiKeyConfigured ? "Configured" : "Not configured"
        AppLogger.shared.log("Gemini API Key: \(status)", level: .debug)
    }
    #endif

    // MARK: - Migration Helper

    /// Migrates from hardcoded key to secure storage
    /// This should be called once during app initialization
    func migrateFromHardcodedKey(_ hardcodedKey: String?) throws {
        // Only migrate if we don't have a key already
        guard !isGeminiKeyConfigured else {
            AppLogger.shared.log("Key already in secure storage, skipping migration", level: .info)
            return
        }

        if let key = hardcodedKey, !key.isEmpty {
            try setGeminiAPIKey(key)
            AppLogger.shared.log("Migrated API key to secure storage", level: .success)
        } else {
            AppLogger.shared.log("No hardcoded key to migrate", level: .warning)
        }
    }
}

// MARK: - Error Extensions
extension AFHAMError {
    static func keychainError(_ message: String) -> AFHAMError {
        return .networkError("Keychain error: \(message)")
    }
}
