import Foundation
import Observation

/// User-controlled money preferences (currency override).
///
/// `currency == nil` means "auto" — fall back to `Locale.current.currency` so the
/// app shows EUR for a Portuguese user, BRL for a Brazilian user, etc., without
/// any setup. The Settings menu lets the user pin a specific currency instead.
@MainActor
@Observable
final class MoneyPreferences {
    static let shared = MoneyPreferences()

    /// Stable list of currencies surfaced in the picker. Add as new markets onboard.
    static let supportedCurrencies: [String] = [
        "USD", "EUR", "BRL", "GBP", "CAD", "AUD", "JPY", "CHF", "CNY", "INR", "MXN",
    ]

    private let storageKey = "money-plan-currency"

    /// `nil` → auto-detect from `Locale.current`.
    var currency: String? {
        didSet {
            if let currency {
                UserDefaults.standard.set(currency, forKey: storageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: storageKey)
            }
        }
    }

    /// The currency that would be used right now if no override was set.
    var autoCurrency: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    /// The currency the formatter should use today.
    var activeCurrency: String {
        currency ?? autoCurrency
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           !raw.isEmpty {
            currency = raw.uppercased()
        } else {
            currency = nil
        }
    }

    /// Pass `nil` to reset to the auto-detected currency.
    func setCurrency(_ code: String?) {
        guard let code, !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            currency = nil
            return
        }
        currency = code.uppercased()
    }
}
