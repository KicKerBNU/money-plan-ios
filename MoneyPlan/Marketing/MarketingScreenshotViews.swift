import SwiftUI

// MARK: - Public entry points (used by screenshot generator)

struct MarketingExpensesScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.expenses) {
            MarketingScreenshotShell(tab: .expenses) {
                MarketingExpensesContent()
            }
        }
    }
}

struct MarketingIncomeScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.income) {
            MarketingScreenshotShell(tab: .income) {
                MarketingIncomeContent()
            }
        }
    }
}

struct MarketingChatbotScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.chatbot) {
            MarketingScreenshotShell(tab: .chat) {
                MarketingChatbotContent()
            }
        }
    }
}

struct MarketingAccountsScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.accounts) {
            MarketingScreenshotShell(tab: .accounts) {
                MarketingAccountsContent()
            }
        }
    }
}

struct MarketingCategoriesScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.categories) {
            MarketingScreenshotShell(tab: .accounts) {
                MarketingCategoriesContent()
            }
        }
    }
}

/// Phone-frame expenses slide (optional slot 2+ in Connect).
struct MarketingExpensesPhoneScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.expenses) {
            MarketingScreenshotShell(tab: .expenses) {
                MarketingExpensesContent()
            }
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
        .padding(.top, MarketingPhoneMetrics.topSafeArea)
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
        .padding(.bottom, 22)
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

struct MarketingAddAndSettingsToolbar: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "plus")
            Image(systemName: "gearshape")
        }
        .foregroundStyle(AppColors.primary)
    }
}

/// Large-title header — fixed height so every marketing screen aligns.
struct MarketingLargeTitleBar: View {
    let title: LocalizedStringKey
    var trailing: AnyView

    init(title: LocalizedStringKey, @ViewBuilder trailing: () -> some View = { EmptyView() }) {
        self.title = title
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 8)
            trailing
        }
        .frame(height: 44, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
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

// MARK: - Chart palette (matches ExpensesView)

private enum MarketingChartPalette {
    static let colors: [Color] = [
        AppColors.primary,
        Color(.systemRed),
        Color(.systemYellow),
        Color(.systemGray),
        Color(.systemPurple),
        Color(.systemOrange),
    ]

    static func color(at index: Int) -> Color {
        index < colors.count ? colors[index] : Color(.systemGray3)
    }
}

// MARK: - Expenses

struct MarketingExpensesContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingLargeTitleBar(title: "expenses.title") {
                MarketingAddAndSettingsToolbar()
            }

            // ImageRenderer does not rasterize ScrollView content — use a static VStack.
            VStack(alignment: .leading, spacing: 16) {
                periodPicker
                summaryCard
                groupedList
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var periodPicker: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
            Spacer()
            Text("July 2026")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
        }
        .padding(.top, 4)
    }

    private var summaryCard: some View {
        FinanceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("expenses.summary.totalSpent")
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                        Text(CurrencyFormatter.format(data.totalSpent))
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("expenses.summary.cashFlow")
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                        Text(CurrencyFormatter.formatSigned(data.cashFlow))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(data.cashFlow >= 0 ? AppColors.positive : AppColors.danger)
                    }
                }

                categoryBar

                LazyVGrid(
                    columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(Array(data.categoryBreakdown.enumerated()), id: \.element.name) { index, row in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(MarketingChartPalette.color(at: index))
                                .frame(width: 8, height: 8)
                            Text(row.name)
                                .font(.caption)
                                .foregroundStyle(AppColors.muted)
                                .lineLimit(1)
                            Text(CurrencyFormatter.formatSigned(-row.amount))
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    private var categoryBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(data.categoryBreakdown.enumerated()), id: \.element.name) { index, row in
                    Rectangle()
                        .fill(MarketingChartPalette.color(at: index))
                        .frame(width: geo.size.width * row.amount / data.totalSpent)
                }
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }

    private var groupedList: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(data.dateGroups, id: \.date) { group in
                VStack(spacing: 8) {
                    HStack {
                        Text(data.dayHeader(group.date))
                            .font(.caption.weight(.semibold))
                            .tracking(0.6)
                            .foregroundStyle(AppColors.muted)
                        Spacer()
                        Text(CurrencyFormatter.formatSigned(-group.total))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.muted)
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(group.items) { expense in
                            MarketingExpenseRow(expense: expense)
                            if expense.id != group.items.last?.id {
                                Divider().padding(.leading, 58)
                            }
                        }
                    }
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.primary.opacity(0.08))
                    )
                }
            }
        }
    }
}

struct MarketingExpenseRow: View {
    let expense: Expense
    var icon: String? = nil

    private var subtitle: String {
        var parts = [DateUtils.formatShortDate(expense.date), expense.accountName]
        if let note = expense.note, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(name: expense.categoryName, icon: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.categoryName)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.formatSigned(-expense.amount))
                .font(.subheadline.weight(.bold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Income

struct MarketingIncomeContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingLargeTitleBar(title: "income.title") {
                MarketingAddAndSettingsToolbar()
            }

            VStack(spacing: 24) {
                periodPicker
                totalHero
                recentSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var periodPicker: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
            Spacer()
            Text("July 2026")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
        }
        .padding(.top, 4)
    }

    private var totalHero: some View {
        VStack(spacing: 8) {
            Text("income.summary.totalIncome")
                .font(.subheadline)
                .foregroundStyle(AppColors.muted)
            Text(CurrencyFormatter.format(data.totalIncome))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("income.recent.title")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.leading, 4)

            FinanceCard {
                VStack(spacing: 0) {
                    ForEach(Array(data.incomeEntries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider().padding(.leading, 52)
                        }
                        MarketingIncomeEntryRow(entry: entry)
                    }
                }
            }
        }
    }
}

private struct MarketingIncomeEntryRow: View {
    let entry: IncomeEntry

    private var title: String {
        if let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            return note
        }
        return entry.accountName ?? String(localized: "income.title")
    }

    var body: some View {
        HStack(spacing: 12) {
            IncomeIconView(label: title)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(DateUtils.formatShortDate(entry.date)) · \(entry.accountName ?? "")")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.format(entry.amount))
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Chatbot

struct MarketingChatbotContent: View {
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

struct MarketingAccountsContent: View {
    private let accounts = MarketingScreenshotData.accounts

    var body: some View {
        VStack(spacing: 0) {
            MarketingLargeTitleBar(title: "accountsPage.title") {
                MarketingAddAndSettingsToolbar()
            }

            VStack(alignment: .leading, spacing: 24) {
                totalBalanceHero
                cardsCarousel
                allAccountsSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    private var totalBalanceHero: some View {
        FinanceCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "Total balance")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                Text(CurrencyFormatter.format(MarketingScreenshotData.accountsBalance))
                    .font(.title2.weight(.bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cardsCarousel: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = 178
            let spacing: CGFloat = 10
            let naturalWidth = cardWidth * CGFloat(accounts.count) + spacing * CGFloat(max(accounts.count - 1, 0))
            let scale = min(1, geo.size.width / naturalWidth)

            HStack(spacing: spacing) {
                ForEach(accounts) { account in
                    MarketingAccountCard(account: account, width: cardWidth)
                }
            }
            .scaleEffect(scale, anchor: .leading)
            .frame(width: geo.size.width, height: 148 * scale, alignment: .topLeading)
        }
        .frame(height: 148)
    }

    private var allAccountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("accountsPage.allAccounts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.leading, 4)

            FinanceCard {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        if index > 0 {
                            Divider().padding(.leading, 52)
                        }
                        MarketingAccountRow(account: account)
                    }
                }
            }
        }
    }
}

private struct MarketingAccountCard: View {
    let account: Account
    var width: CGFloat = 190

    private var metallicGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(white: 0.97), location: 0.0),
                .init(color: Color(white: 0.84), location: 0.38),
                .init(color: Color(white: 0.72), location: 0.62),
                .init(color: Color(white: 0.88), location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: AccountIcon.symbol(for: account.name))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Spacer(minLength: 8)
                if account.isDefault {
                    Text("accountsPage.defaultBadge")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.82), in: Capsule())
                }
            }
            Spacer(minLength: 20)
            Text(account.name)
                .font(.footnote)
                .foregroundStyle(Color.black.opacity(0.55))
                .lineLimit(1)
            Text(CurrencyFormatter.format(account.currentBalance))
                .font(.title3.weight(.bold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(width: width, height: 148, alignment: .topLeading)
        .background(metallicGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.black.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }
}

private struct MarketingAccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            AccountIconView(name: account.name)
            HStack(spacing: 6) {
                Text(account.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if account.isDefault {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColors.primary)
                }
            }
            Spacer(minLength: 8)
            Text(CurrencyFormatter.format(account.currentBalance))
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Categories grid

struct MarketingCategoriesContent: View {
    private let categories = MarketingScreenshotData.categories
    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            MarketingLargeTitleBar(title: "settings.categories") {
                Image(systemName: "plus")
                    .foregroundStyle(AppColors.primary)
            }

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(categories) { category in
                    MarketingCategoryTile(category: category)
                }
                MarketingNewCategoryTile()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct MarketingCategoryTile: View {
    let category: Category

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: CategoryIcon.symbol(for: category))
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.primary)
                .frame(width: 58, height: 58)
                .background(AppColors.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(category.name)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MarketingNewCategoryTile: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.muted)
                .frame(width: 58, height: 58)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppColors.muted.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            Text("categories.new")
                .font(.caption)
                .foregroundStyle(AppColors.muted)
        }
        .frame(maxWidth: .infinity)
    }
}
