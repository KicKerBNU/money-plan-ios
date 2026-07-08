import SwiftUI

/// Maps an account name to an SF Symbol (keyword-based, en + pt), like `IncomeIcon`.
enum AccountIcon {
    private static let map: [String: String] = [
        "bank": "building.columns.fill",
        "banco": "building.columns.fill",
        "checking": "building.columns.fill",
        "corrente": "building.columns.fill",
        "cash": "banknote.fill",
        "dinheiro": "banknote.fill",
        "wallet": "banknote.fill",
        "carteira": "banknote.fill",
        "saving": "dollarsign.circle.fill",
        "poupança": "dollarsign.circle.fill",
        "poupanca": "dollarsign.circle.fill",
        "invest": "chart.line.uptrend.xyaxis",
        "credit": "creditcard.fill",
        "card": "creditcard.fill",
        "cartão": "creditcard.fill",
        "cartao": "creditcard.fill",
        "débito": "creditcard.fill",
        "debit": "creditcard.fill",
    ]

    static func symbol(for name: String) -> String {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = map[normalized] { return exact }
        for (keyword, symbol) in map where normalized.contains(keyword) {
            return symbol
        }
        return "building.columns.fill"
    }
}

/// Tinted icon tile used in the All Accounts list rows.
struct AccountIconView: View {
    let name: String

    var body: some View {
        Image(systemName: AccountIcon.symbol(for: name))
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColors.primary)
            .frame(width: 36, height: 36)
            .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
