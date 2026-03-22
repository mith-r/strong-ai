import Foundation
import Security
import SwiftData

private enum APIKeychainStore {
    static let service = "com.strong-ai.credentials"
    static let account = "anthropic_api_key"

    static func load() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return ""
        }

        return String(decoding: data, as: UTF8.self)
    }

    static func save(_ apiKey: String) throws {
        let normalizedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        if normalizedKey.isEmpty {
            try delete()
            return
        }

        let updateAttributes: [String: Any] = [
            kSecValueData as String: Data(normalizedKey.utf8)
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw APIKeychainStoreError.unhandledStatus(updateStatus)
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: Data(normalizedKey.utf8)
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw APIKeychainStoreError.unhandledStatus(status)
        }
    }

    static func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeychainStoreError.unhandledStatus(status)
        }
    }
}

private enum APIKeychainStoreError: LocalizedError {
    case unhandledStatus(OSStatus)

    var errorDescription: String? {
        "Couldn't store the Anthropic API key in Keychain."
    }
}

@Model
final class UserProfile {
    var goals: String
    var schedule: String
    var equipment: String
    var injuries: String

    init(
        goals: String = "",
        schedule: String = "",
        equipment: String = "",
        injuries: String = ""
    ) {
        self.goals = goals
        self.schedule = schedule
        self.equipment = equipment
        self.injuries = injuries
    }

    static func loadSavedAPIKey() -> String {
        APIKeychainStore.load()
    }

    static func saveAPIKey(_ apiKey: String) throws {
        try APIKeychainStore.save(apiKey)
    }
}
