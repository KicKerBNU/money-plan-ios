import SwiftUI

enum AppColors {
    static let primary = Color("Primary")
    static let positive = Color("Positive")
    static let danger = Color("Danger")
    static let surface = Color("Surface")
    static let surfaceSoft = Color("SurfaceSoft")
    static let muted = Color("Muted")
}

@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    enum Preference: String, CaseIterable {
        case system, light, dark
    }

    private let storageKey = "money-plan-theme"

    var preference: Preference {
        didSet { UserDefaults.standard.set(preference.rawValue, forKey: storageKey) }
    }

    var colorScheme: ColorScheme? {
        switch preference {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let value = Preference(rawValue: raw) {
            preference = value
        } else {
            preference = .dark
        }
    }

    func toggle() {
        preference = preference == .dark ? .light : .dark
    }
}
