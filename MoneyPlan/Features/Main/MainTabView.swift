import SwiftUI

enum AppTab: Hashable {
    case expenses, income, chat, accounts
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

    var body: some View {
        TabView(selection: $selectedTab) {
            ExpensesView()
                .tabItem { Label("appNav.expenses", systemImage: "list.bullet.rectangle.fill") }
                .tag(AppTab.expenses)
                .accessibilityIdentifier("tab-expenses")

            IncomeView()
                .tabItem { Label("appNav.income", systemImage: "arrow.up.right") }
                .tag(AppTab.income)
                .accessibilityIdentifier("tab-income")

            ChatbotView()
                .tabItem { Label("appNav.chatbot", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.chat)
                .accessibilityIdentifier("tab-chatbot")

            AccountsView()
                .tabItem { Label("appNav.accounts", systemImage: "building.columns.fill") }
                .tag(AppTab.accounts)
                .accessibilityIdentifier("tab-accounts")
        }
        .environment(\.selectedAppTab, selectedTab)
        .accessibilityIdentifier("main-tabs")
        .onAppear {
            logScreen(for: selectedTab)
        }
        .onChange(of: selectedTab) { _, tab in
            logScreen(for: tab)
        }
    }

    private func logScreen(for tab: AppTab) {
        AnalyticsService.logScreen(screenName(for: tab))
    }

    private func screenName(for tab: AppTab) -> String {
        switch tab {
        case .expenses: "expenses"
        case .income: "income"
        case .chat: "chatbot"
        case .accounts: "accounts"
        }
    }
}

/// Gear button that pushes the dedicated Settings page (replaced the old dropdown menu).
/// Must be its own toolbar item. Nested in another control, the link has no hit frame.
struct SettingsToolbar: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .frame(width: 24, height: 24)
        }
        .accessibilityLabel("appNav.settingsMenu")
        .accessibilityIdentifier("settings-menu-trigger")
    }
}
