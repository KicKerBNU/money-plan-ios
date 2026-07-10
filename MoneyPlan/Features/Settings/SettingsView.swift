import SwiftUI

/// Dedicated settings page (replaces the old gear dropdown menu).
struct SettingsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(MoneyPreferences.self) private var money
    @Environment(\.dismiss) private var dismiss
    @Environment(\.selectedAppTab) private var selectedAppTab

    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false

    var body: some View {
        let _ = money.activeCurrency
        List {
            Section("settings.section.preferences") {
                NavigationLink {
                    CategoriesView()
                } label: {
                    SettingsRow(icon: "tag", title: "settings.categories")
                }

                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    SettingsRow(icon: "moon", title: "settings.appearance")
                }
            }

            Section("settings.section.planning") {
                NavigationLink {
                    RecurringExpensesView()
                } label: {
                    SettingsRow(icon: "arrow.triangle.2.circlepath", title: "recurring.settingsMenu")
                }

                NavigationLink {
                    RecurringIncomesView()
                } label: {
                    SettingsRow(icon: "arrow.up.circle", title: "recurringIncome.settingsMenu")
                }

                NavigationLink {
                    CurrencySettingsView()
                } label: {
                    SettingsRow(
                        icon: "coloncurrencysign.circle",
                        title: "preferences.currency",
                        value: currencyValueLabel
                    )
                }
            }

            Section {
                Button {
                    try? auth.signOut()
                } label: {
                    SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "appNav.logout")
                        .foregroundStyle(.primary)
                }

                Button(role: .destructive) {
                    showDeleteAccountConfirm = true
                } label: {
                    SettingsRow(icon: "trash", title: "auth.deleteAccount.menu", iconColor: AppColors.danger)
                }
                .disabled(isDeletingAccount)
            }
        }
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.large)
        // Switching tabs pops Settings (and anything pushed above it), so coming
        // back to the tab shows its root screen instead of a stale Settings page.
        .onChange(of: selectedAppTab) {
            dismiss()
        }
        .confirmationDialog(
            "auth.deleteAccount.confirmTitle",
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("auth.deleteAccount.confirmAction", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("auth.deleteAccount.confirmBody")
        }
    }

    /// e.g. "EUR (€)" like the design mockup.
    private var currencyValueLabel: String {
        let code = money.activeCurrency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        let symbol = formatter.currencySymbol ?? code
        return symbol == code ? code : "\(code) (\(symbol))"
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await auth.deleteAccount()
        } catch {
            // Errors surface via ToastCenter from APIClient.
        }
    }
}

// MARK: - Row

private struct SettingsRow: View {
    let icon: String
    let title: LocalizedStringKey
    var value: String? = nil
    var iconColor: Color = AppColors.primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 26)

            Text(title)

            Spacer(minLength: 8)

            if let value {
                Text(verbatim: value)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        List {
            Section {
                themeOption(.system, label: "theme.system", icon: "circle.lefthalf.filled")
                themeOption(.light, label: "theme.light", icon: "sun.max")
                themeOption(.dark, label: "theme.dark", icon: "moon")
            }
        }
        .navigationTitle("settings.appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeOption(_ preference: ThemeManager.Preference, label: LocalizedStringKey, icon: String) -> some View {
        Button {
            theme.preference = preference
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 26)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if theme.preference == preference {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Currency

struct CurrencySettingsView: View {
    @Environment(MoneyPreferences.self) private var money

    var body: some View {
        List {
            Section {
                currencyOption(nil, label: String(localized: "preferences.currencyAuto") + " · " + money.autoCurrency)

                ForEach(MoneyPreferences.supportedCurrencies, id: \.self) { code in
                    currencyOption(code, label: code)
                }
            }
        }
        .navigationTitle("preferences.currency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func currencyOption(_ code: String?, label: String) -> some View {
        Button {
            money.setCurrency(code)
        } label: {
            HStack {
                Text(verbatim: label)
                    .foregroundStyle(.primary)
                Spacer()
                if money.currency == code {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
    }
}
