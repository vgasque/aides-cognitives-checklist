import Foundation
import Security
import AidesCore

/// Jetons de connexion dans le TROUSSEAU (et non dans un fichier) : un élément global, comme
/// la clé `ac-auth` de la PWA, jamais synchronisé via iCloud (`ThisDeviceOnly`).
final class KeychainStore: SecureStore, @unchecked Sendable {
    private let service = "fr.aidescognitives.auth"
    private let account = "ac-auth"
    private let lock = NSLock()

    func load() -> Data? {
        lock.lock(); defer { lock.unlock() }
        var q = base()
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess else { return nil }
        return out as? Data
    }

    func save(_ data: Data?) {
        lock.lock(); defer { lock.unlock() }
        SecItemDelete(base() as CFDictionary)
        guard let data else { return }
        var q = base()
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }

    private func base() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }
}
