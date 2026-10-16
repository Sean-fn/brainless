import Foundation
import Security

/// Ollama Cloud 的 API key：存在登入鑰匙圈，不寫進設定檔
enum CloudKey {
    private static let item: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: AppInfo.name,
        kSecAttrAccount as String: "ollama.com API key",
    ]

    /// 沒設定或讀不到時回傳空字串
    static func read() -> String {
        var query = item
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else {
            if status != errSecItemNotFound { Log.w("CloudKey: read failed \(status)") }
            return ""
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// 成功回傳 nil，失敗回傳給人看的原因
    static func save(_ key: String) -> String? {
        let data = Data(key.utf8)
        var status = SecItemUpdate(item as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var add = item
            add[kSecValueData as String] = data
            status = SecItemAdd(add as CFDictionary, nil)
        }
        guard status != errSecSuccess else { return nil }
        Log.w("CloudKey: save failed \(status)")
        return (SecCopyErrorMessageString(status, nil) as String?) ?? "代碼 \(status)"
    }
}
