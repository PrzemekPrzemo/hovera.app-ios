import Foundation
import Security

/// Stores the API token + active tenant id. Token is in Keychain (after
/// first unlock); active tenant id is in UserDefaults (it isn't a secret
/// and we want it readable from background tasks).
public actor KeychainStore {
    public static let shared = KeychainStore()

    private let service = "app.hovera.ios"
    private let tokenAccount = "api.token"

    public func token() async -> String? { read(account: tokenAccount) }
    public func setToken(_ token: String?) async { write(account: tokenAccount, value: token) }

    public func activeTenantId() async -> String? {
        UserDefaults.standard.string(forKey: "hovera.active_tenant_id")
    }
    public func setActiveTenantId(_ id: String?) async {
        if let id { UserDefaults.standard.set(id, forKey: "hovera.active_tenant_id") }
        else { UserDefaults.standard.removeObject(forKey: "hovera.active_tenant_id") }
    }

    public func wipe() async {
        write(account: tokenAccount, value: nil)
        await setActiveTenantId(nil)
    }

    // MARK: - Plumbing

    private func read(account: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(account: String, value: String?) {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(baseQuery as CFDictionary)
        guard let value, let data = value.data(using: .utf8) else { return }
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
