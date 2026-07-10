import SwiftUI

enum AppTab: Hashable {
    case expenses, income, add, chat, accounts
}

/// Currently selected tab, exposed to pushed screens (e.g. Settings) so they can
/// pop themselves when the user switches tabs instead of lingering on the stack.
private struct SelectedAppTabKey: EnvironmentKey {
    static let defaultValue: AppTab? = nil
}

extension EnvironmentValues {
    var selectedAppTab: AppTab? {
        get { self[SelectedAppTabKey.self] }
        set { self[SelectedAppTabKey.self] = newValue }
    }
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
        .environment(\.selectedAppTab, selectedTab)
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

/// Gear button that pushes the dedicated Settings page (replaced the old dropdown menu).
struct SettingsToolbar: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("appNav.settingsMenu")
    }
}
