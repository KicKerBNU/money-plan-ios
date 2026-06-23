import Foundation

/// Per-account consent before sending expense-assistant data to OpenAI (App Store 5.1.1(i) / 5.1.2(i)).
@MainActor
enum ExpenseChatConsentStore {
    private static let keyPrefix = "money-plan-expense-chat-ai-consent"

    static func hasConsent(for firebaseUid: String) -> Bool {
        UserDefaults.standard.bool(forKey: storageKey(for: firebaseUid))
    }

    static func grantConsent(for firebaseUid: String) {
        UserDefaults.standard.set(true, forKey: storageKey(for: firebaseUid))
    }

    static func revokeConsent(for firebaseUid: String) {
        UserDefaults.standard.removeObject(forKey: storageKey(for: firebaseUid))
    }

    private static func storageKey(for firebaseUid: String) -> String {
        "\(keyPrefix)-\(firebaseUid)"
    }
}
