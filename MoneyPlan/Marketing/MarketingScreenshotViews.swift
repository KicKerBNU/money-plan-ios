import SwiftUI

// MARK: - Public entry points (used by screenshot generator)

struct MarketingExpensesScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .expenses) {
            MarketingExpensesContent()
        }
    }
}

struct MarketingIncomeScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .income) {
            MarketingIncomeContent()
        }
    }
}

struct MarketingChatbotScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .chat) {
            MarketingChatbotContent()
        }
    }
}

struct MarketingAccountsScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .accounts) {
            MarketingAccountsContent()
        }
    }
}

// MARK: - Shell (nav + tab bar)

enum MarketingTab: Hashable {
    case expenses, income, add, chat, accounts
}

struct MarketingScreenshotShell<Content: View>: View {
    let tab: MarketingTab
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            MarketingTabBar(selected: tab)
        }
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
        .tint(AppColors.primary)
    }
}

private struct MarketingTabBar: View {
    let selected: MarketingTab

    var body: some View {
        HStack {
            tabItem(.expenses, label: "appNav.expenses", icon: "list.bullet.rectangle.fill")
            tabItem(.income, label: "appNav.income", icon: "arrow.up.right")
            tabItem(.add, label: "appNav.add", icon: "plus.circle.fill", prominent: true)
            tabItem(.chat, label: "appNav.chatbot", icon: "bubble.left.and.bubble.right.fill")
            tabItem(.accounts, label: "appNav.accounts", icon: "building.columns.fill")
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func tabItem(_ tab: MarketingTab, label: LocalizedStringKey, icon: String, prominent: Bool = false) -> some View {
        let isSelected = selected == tab
        return VStack(spacing: 4) {
            Image(systemName: icon)
                .font(prominent ? .title2 : .body)
                .symbolVariant(isSelected ? .fill : .none)
            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(isSelected ? AppColors.primary : AppColors.muted)
        .frame(maxWidth: .infinity)
    }
}

struct MarketingToolbarGear: View {
    var body: some View {
        Image(systemName: "gearshape")
            .foregroundStyle(AppColors.primary)
    }
}

/// `NavigationStack` crashes under `ImageRenderer` (no interface idiom); mimic the nav bar instead.
struct MarketingNavBar: View {
    let title: LocalizedStringKey
    var leading: AnyView?
    var trailing: AnyView?

    init(
        title: LocalizedStringKey,
        @ViewBuilder leading: () -> some View = { EmptyView() },
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.leading = AnyView(leading())
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.headline)
            HStack {
                leading
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Expenses

struct MarketingExpensesContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "expenses.title") {
                EmptyView()
            } trailing: {
                HStack {
                    Image(systemName: "plus")
                    MarketingToolbarGear()
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("\(data.expenses.count) \(String(localized: "expenses.entriesThisMonth"))")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        KPIView(title: "expenses.summary.totalSpent", value: CurrencyFormatter.format(data.totalSpent))
                        KPIView(
                            title: "expenses.summary.cashFlow",
                            value: CurrencyFormatter.formatSigned(data.cashFlow),
                            valueColor: data.cashFlow >= 0 ? AppColors.positive : AppColors.danger
                        )
                    }
                }

                HStack(spacing: 8) {
                    marketingChip("expenses.filters.last3Days", selected: false)
                    marketingChip("expenses.filters.last7Days", selected: true)
                    marketingChip("expenses.filters.tripWeek", selected: false)
                }

                HStack(spacing: 8) {
                    marketingChip("expenses.filters.all", selected: true)
                    ForEach(data.categories.prefix(4)) { cat in
                        marketingChipLiteral(cat.name, selected: false)
                    }
                }

                FinanceCard {
                    ForEach(data.expenses.prefix(3)) { expense in
                        MarketingExpenseRow(expense: expense)
                        if expense.id != data.expenses.prefix(3).last?.id { Divider() }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func marketingChip(_ key: LocalizedStringKey, selected: Bool) -> some View {
        Text(key)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: Capsule())
    }

    private func marketingChipLiteral(_ title: String, selected: Bool) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: Capsule())
    }
}

struct MarketingExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(name: expense.categoryName)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.categoryName)
                    .font(.subheadline.weight(.semibold))
                Text("\(DateUtils.formatShortDate(expense.date)) · \(expense.accountName)")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(CurrencyFormatter.format(expense.amount))
                .font(.subheadline.weight(.bold))
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(AppColors.muted)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Income

private struct MarketingIncomeContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "income.title") {
                EmptyView()
            } trailing: {
                MarketingToolbarGear()
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("income.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    KPIView(title: "income.summary.totalIncome", value: CurrencyFormatter.format(data.totalIncome))
                    if let last = data.incomeEntries.map(\.date).sorted().last {
                        Text(String(format: String(localized: "income.summary.lastEntry"), data.incomeEntries.count, DateUtils.formatShortDate(last)))
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                    }
                }

                FinanceCard {
                    Text("income.recent.title")
                        .font(.headline)
                    ForEach(data.incomeEntries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(CurrencyFormatter.format(entry.amount))
                                    .font(.subheadline.weight(.semibold))
                                Text("\(DateUtils.formatShortDate(entry.date)) · \(entry.accountName ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.muted)
                                if let note = entry.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.muted)
                                }
                            }
                            Spacer()
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(AppColors.muted)
                        }
                        .padding(.vertical, 6)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Chatbot

private struct MarketingChatbotContent: View {
    private let messages = MarketingScreenshotData.chatMessages

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "chatbot.title") {
                Text("chatbot.clear")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)
            } trailing: {
                MarketingToolbarGear()
            }

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("chatbot.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.muted)
                        .padding(.bottom, 8)

                    ForEach(messages) { message in
                        MarketingChatBubble(message: message)
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                MarketingChatComposer()
            }
        }
    }
}

private struct MarketingChatBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "chatbot.you" : "chatbot.assistant")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColors.muted)
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: RoundedRectangle(cornerRadius: 16))
            }
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Accounts

private struct MarketingAccountsContent: View {
    private let accounts = MarketingScreenshotData.accounts

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "accountsPage.title") {
                EmptyView()
            } trailing: {
                MarketingToolbarGear()
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("accountsPage.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    Text("accountsPage.listTitle")
                        .font(.headline)
                    Text("accountsPage.dragHint")
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)

                    ForEach(accounts) { account in
                        MarketingAccountRow(account: account)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct MarketingAccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(AppColors.muted)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name)
                        .font(.subheadline.weight(.semibold))
                    if account.isDefault {
                        Text("accountsPage.defaultBadge")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.primary.opacity(0.15), in: Capsule())
                    }
                }
                Text("accountsPage.balanceCaption")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                Text(CurrencyFormatter.format(account.currentBalance))
                    .font(.title3.weight(.bold))
            }
            Spacer()
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(AppColors.muted)
        }
        .padding(.vertical, 6)
    }
}
