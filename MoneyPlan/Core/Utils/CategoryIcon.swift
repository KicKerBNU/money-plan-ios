import SwiftUI

enum CategoryIcon {
    private static let map: [String: String] = [
        "rent": "house.fill",
        "pension": "banknote.fill",
        "food": "fork.knife",
        "social life": "person.3.fill",
        "pets": "pawprint.fill",
        "transport": "bus.fill",
        "culture": "paintpalette.fill",
        "household": "paintbrush.fill",
        "apparel": "tshirt.fill",
        "beauty": "sparkles",
        "health": "heart.fill",
        "education": "graduationcap.fill",
        "gift": "gift.fill",
        "other": "ellipsis",
    ]

    static func symbol(for name: String) -> String {
        map[name.trimmingCharacters(in: .whitespaces).lowercased()] ?? "tag.fill"
    }

    /// User-picked icon wins; otherwise derive from the name.
    static func symbol(for category: Category) -> String {
        if let icon = category.icon, !icon.isEmpty { return icon }
        return symbol(for: category.name)
    }

    /// Options offered in the category form's icon grid (order matches the design).
    static let pickerSymbols: [String] = [
        "house.fill",
        "fork.knife",
        "person.3.fill",
        "pawprint.fill",
        "bus.fill",
        "paintpalette.fill",
        "paintbrush.fill",
        "tshirt.fill",
        "sparkles",
        "heart.fill",
        "graduationcap.fill",
        "gift.fill",
        "banknote.fill",
        "briefcase.fill",
        "laptopcomputer",
        "car.fill",
        "airplane",
        "cart.fill",
        "cup.and.saucer.fill",
        "dumbbell.fill",
        "book.fill",
        "wifi",
        "tv.fill",
        "wallet.pass.fill",
        "creditcard.fill",
        "building.columns.fill",
        "doc.text.fill",
        "dollarsign.circle.fill",
        "percent",
        "ellipsis",
    ]
}

struct CategoryIconView: View {
    let name: String
    /// Explicit SF Symbol override (user-picked icon); nil = derive from name.
    var icon: String? = nil

    var body: some View {
        Image(systemName: resolvedSymbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColors.primary)
            .frame(width: 32, height: 32)
            .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private var resolvedSymbol: String {
        if let icon, !icon.isEmpty { return icon }
        return CategoryIcon.symbol(for: name)
    }
}
