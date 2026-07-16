import Foundation

/// Localized labels for server-seeded default account and category names (stored in English in the DB).
enum SeedLocalization {
    private static let accountKeys: [String: String.LocalizationValue] = [
        "bank accounts": "seed.account.bankAccounts",
        "bank account": "seed.account.bankAccounts",
        "cash": "seed.account.cash",
        "card": "seed.account.card",
    ]

    private static let categoryKeys: [String: String.LocalizationValue] = [
        "rent": "seed.category.rent",
        "pension": "seed.category.pension",
        "food": "seed.category.food",
        "social life": "seed.category.socialLife",
        "pets": "seed.category.pets",
        "transport": "seed.category.transport",
        "culture": "seed.category.culture",
        "household": "seed.category.household",
        "apparel": "seed.category.apparel",
        "beauty": "seed.category.beauty",
        "health": "seed.category.health",
        "education": "seed.category.education",
        "gift": "seed.category.gift",
        "other": "seed.category.other",
    ]

    static func localizedAccountName(_ name: String) -> String {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let key = accountKeys[normalized] {
            return String(localized: key)
        }
        return name
    }

    static func localizedCategoryName(_ name: String) -> String {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let key = categoryKeys[normalized] {
            return String(localized: key)
        }
        return name
    }
}

extension Account {
    var localizedDisplayName: String {
        SeedLocalization.localizedAccountName(name)
    }
}

extension Category {
    var localizedDisplayName: String {
        SeedLocalization.localizedCategoryName(name)
    }
}
