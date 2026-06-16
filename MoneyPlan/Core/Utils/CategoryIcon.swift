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
}

struct CategoryIconView: View {
    let name: String

    var body: some View {
        Image(systemName: CategoryIcon.symbol(for: name))
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColors.primary)
            .frame(width: 32, height: 32)
            .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
