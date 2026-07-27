import SwiftUI

enum IncomeIcon {
    private static let map: [String: String] = [
        "salary": "briefcase.fill",
        "payroll": "briefcase.fill",
        "wage": "briefcase.fill",
        "freelance": "laptopcomputer",
        "contract": "doc.text.fill",
        "consulting": "person.2.fill",
        "bonus": "gift.fill",
        "dividend": "chart.line.uptrend.xyaxis",
        "rent": "house.fill",
        "refund": "arrow.uturn.backward.circle.fill",
        "interest": "percent",
        "other": "banknote.fill",
    ]

    static func symbol(for label: String) -> String {
        let normalized = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = map[normalized] { return exact }
        for (keyword, symbol) in map where normalized.contains(keyword) {
            return symbol
        }
        return "banknote.fill"
    }
}

struct IncomeIconView: View {
    let label: String

    var body: some View {
        Image(systemName: IncomeIcon.symbol(for: label))
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColors.primary)
            .frame(width: 36, height: 36)
            .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
