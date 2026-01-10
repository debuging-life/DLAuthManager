import Foundation
import Security

// MARK: - Keychain Storage
final class KeychainStorage: @unchecked Sendable {
    private let service: String
    private let accessGroup: String?
    private let lock = NSLock()

    init(service: String = "com.dlauth.manager", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    func save(key: String, data: Data) throws {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw DLAuthError.custom("Failed to save to keychain: \(status)")
        }
    }

    func load(key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw DLAuthError.custom("Failed to load from keychain: \(status)")
        }

        return result as? Data
    }

    func delete(key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw DLAuthError.custom("Failed to delete from keychain: \(status)")
        }
    }

    func saveSession(_ session: DLSession) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try save(key: "current_session", data: data)
    }

    func loadSession() throws -> DLSession? {
        guard let data = try load(key: "current_session") else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DLSession.self, from: data)
    }

    func deleteSession() throws {
        try delete(key: "current_session")
    }
}
