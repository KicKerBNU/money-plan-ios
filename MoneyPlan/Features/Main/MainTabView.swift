import SwiftUI

enum AppTab: Hashable {
    case expenses, income, add, chat, accounts
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .expenses
    @State private var previousTab: AppTab = .expenses
    @State private var showAddExpense = false

    /// "Add" is rendered as a tab item so iOS keeps the bar at a natural 5 slots.
    /// Selecting it jumps to the Expenses tab (where the sheet lives) and presents
    /// the new-expense form — a common iOS pattern for primary-action tabs.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == .add {
                    showAddExpense = true
                    // Land on Expenses so the placeholder view never appears and
                    // the user sees the new expense in context after saving.
                    DispatchQueue.main.async {
                        previousTab = .expenses
                        selectedTab = .expenses
                    }
                } else {
                    previousTab = newValue
                    selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            ExpensesView(showAddSheet: $showAddExpense)
                .tabItem { Label("appNav.expenses", systemImage: "list.bullet.rectangle.fill") }
                .tag(AppTab.expenses)

            IncomeView()
                .tabItem { Label("appNav.income", systemImage: "arrow.up.right") }
                .tag(AppTab.income)

            // Placeholder view — never actually shown thanks to the binding above.
            Color.clear
                .tabItem { Label("appNav.add", systemImage: "plus.circle.fill") }
                .tag(AppTab.add)

            ChatbotView()
                .tabItem { Label("appNav.chatbot", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.chat)

            AccountsView()
                .tabItem { Label("appNav.accounts", systemImage: "building.columns.fill") }
                .tag(AppTab.accounts)
        }
        .onAppear {
            logScreen(for: selectedTab)
        }
        .onChange(of: selectedTab) { _, tab in
            logScreen(for: tab)
        }
    }

    private func logScreen(for tab: AppTab) {
        guard tab != .add else { return }
        AnalyticsService.logScreen(screenName(for: tab))
    }

    private func screenName(for tab: AppTab) -> String {
        switch tab {
        case .expenses: "expenses"
        case .income: "income"
        case .add: "add"
        case .chat: "chatbot"
        case .accounts: "accounts"
        }
    }
}

struct SettingsToolbar: View {
    @Environment(AuthService.self) private var auth
    @Environment(ThemeManager.self) private var theme
    @Environment(MoneyPreferences.self) private var money

    @State private var showDeleteAccountConfirm = false
    @State private var showRecurringExpenses = false
    @State private var showRecurringIncomes = false
    @State private var isDeletingAccount = false

    var body: some View {
        Menu {
            // Theme submenu (System / Light / Dark)
            Menu {
                Picker("theme.label", selection: themePreferenceBinding) {
                    Label("theme.system", systemImage: "circle.lefthalf.filled")
                        .tag(ThemeManager.Preference.system)
                    Label("theme.light", systemImage: "sun.max")
                        .tag(ThemeManager.Preference.light)
                    Label("theme.dark", systemImage: "moon")
                        .tag(ThemeManager.Preference.dark)
                }
            } label: {
                Label("theme.label", systemImage: themeIcon)
            }

            // Currency submenu
            Menu {
                Picker("preferences.currency", selection: currencyBinding) {
                    Text(verbatim: String(localized: "preferences.currencyAuto") + " · " + money.autoCurrency)
                        .tag(String?.none)
                    ForEach(MoneyPreferences.supportedCurrencies, id: \.self) { code in
                        Text(verbatim: code).tag(String?.some(code))
                    }
                }
            } label: {
                Label {
                    HStack {
                        Text("preferences.currency")
                        Spacer()
                        Text(verbatim: money.activeCurrency)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "dollarsign.circle")
                }
            }

            Divider()

            Button {
                showRecurringExpenses = true
            } label: {
                Label("recurring.settingsMenu", systemImage: "arrow.triangle.2.circlepath")
            }

            Button {
                showRecurringIncomes = true
            } label: {
                Label("recurringIncome.settingsMenu", systemImage: "arrow.up.circle")
            }

            Divider()

            Button(role: .destructive) {
                showDeleteAccountConfirm = true
            } label: {
                Label("auth.deleteAccount.menu", systemImage: "person.crop.circle.badge.minus")
            }
            .disabled(isDeletingAccount)

            Button(role: .destructive) {
                try? auth.signOut()
            } label: {
                Label("appNav.logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("appNav.settingsMenu")
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
        .sheet(isPresented: $showRecurringExpenses) {
            RecurringExpensesView()
        }
        .sheet(isPresented: $showRecurringIncomes) {
            RecurringIncomesView()
        }
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

    private var themeIcon: String {
        switch theme.preference {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    private var themePreferenceBinding: Binding<ThemeManager.Preference> {
        Binding(get: { theme.preference }, set: { theme.preference = $0 })
    }

    private var currencyBinding: Binding<String?> {
        Binding(
            get: { money.currency },
            set: { money.setCurrency($0) }
        )
    }
}
