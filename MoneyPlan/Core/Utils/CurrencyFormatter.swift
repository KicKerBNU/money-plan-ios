import Foundation

/// Single source of truth for formatting monetary amounts.
///
/// Currency comes from `MoneyPreferences.shared` (user override → `Locale.current`).
/// SwiftUI views that show money should also declare
/// `@Environment(MoneyPreferences.self) private var money` and reference
/// `money.activeCurrency` somewhere in their body so the view re-renders
/// when the user changes their currency from Settings.
enum CurrencyFormatter {
    @MainActor
    static func format(_ value: Double) -> String {
        let code = MoneyPreferences.shared.activeCurrency
        let formatter = makeFormatter(currencyCode: code, hasCents: !value.truncatingRemainder(dividingBy: 1).isZero)
        return formatter.string(from: NSNumber(value: value)) ?? fallback(code: code, value: value)
    }

    @MainActor
    static func formatSigned(_ value: Double) -> String {
        let absolute = abs(value)
        let formatted = format(absolute)
        if value == 0 { return formatted }
        return value >= 0 ? "+\(formatted)" : "−\(formatted)"
    }

    // MARK: - Internals

    private static func makeFormatter(currencyCode: String, hasCents: Bool) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.locale = Locale.current
        f.minimumFractionDigits = hasCents ? 2 : 0
        f.maximumFractionDigits = 2
        return f
    }

    private static func fallback(code: String, value: Double) -> String {
        "\(code) \(value)"
    }
}

enum DefaultAccountPicker {
    static func pick(from accounts: [Account]) -> Account? {
        if let d = accounts.first(where: \.isDefault) { return d }
        if let bank = accounts.first(where: {
            let n = $0.name.lowercased()
            return n == "bank accounts" || n == "bank account"
        }) { return bank }
        return accounts.first
    }
}
