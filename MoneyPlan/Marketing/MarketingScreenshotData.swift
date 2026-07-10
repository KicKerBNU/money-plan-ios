import Foundation

/// Static demo data for App Store marketing screenshots (no API / auth required).
enum MarketingScreenshotData {
    static let accounts: [Account] = [
        Account(id: 1, name: "Bank Accounts", isDefault: true, initialBalance: 1200, currentBalance: 2450.80),
        Account(id: 2, name: "Cash", isDefault: false, initialBalance: 500, currentBalance: 680.50),
        Account(id: 3, name: "Savings", isDefault: false, initialBalance: 5000, currentBalance: 8200),
    ]

    static let categories: [Category] = [
        Category(id: 1, name: "Food", isDefault: true, icon: "fork.knife"),
        Category(id: 2, name: "Transport", isDefault: false, icon: "bus.fill"),
        Category(id: 3, name: "Rent", isDefault: false, icon: "house.fill"),
        Category(id: 4, name: "Social Life", isDefault: false, icon: "person.3.fill"),
        Category(id: 5, name: "Pension", isDefault: false, icon: "banknote.fill"),
        Category(id: 6, name: "Health", isDefault: false, icon: "heart.fill"),
        Category(id: 7, name: "Other", isDefault: false, icon: "ellipsis"),
    ]

    static let expenses: [Expense] = [
        Expense(id: 1, date: "2026-07-01", amount: 650, categoryId: 3, categoryName: "Rent", accountId: 1, accountName: "Bank Accounts", note: nil),
        Expense(id: 2, date: "2026-07-01", amount: 120, categoryId: 5, categoryName: "Pension", accountId: 1, accountName: "Bank Accounts", note: nil),
        Expense(id: 3, date: "2026-07-05", amount: 47.31, categoryId: 2, categoryName: "Transport", accountId: 2, accountName: "Cash", note: nil),
        Expense(id: 4, date: "2026-07-05", amount: 24, categoryId: 4, categoryName: "Social Life", accountId: 2, accountName: "Cash", note: "Cinema with friends"),
        Expense(id: 5, date: "2026-07-08", amount: 22, categoryId: 1, categoryName: "Food", accountId: 1, accountName: "Bank Accounts", note: nil),
    ]

    static let incomeEntries: [IncomeEntry] = [
        IncomeEntry(id: 1, date: "2026-07-01", amount: 1200, accountId: 1, accountName: "Bank Accounts", note: "Salary"),
        IncomeEntry(id: 2, date: "2026-07-05", amount: 142.31, accountId: 1, accountName: "Bank Accounts", note: "Freelance"),
        IncomeEntry(id: 3, date: "2026-07-12", amount: 85, accountId: 1, accountName: "Bank Accounts", note: "Consulting"),
        IncomeEntry(id: 4, date: "2026-07-18", amount: 250, accountId: 2, accountName: "Cash", note: "Side project"),
    ]

    static let chatMessages: [ChatMessage] = [
        ChatMessage(role: .user, content: "How much did I spend on food this month?"),
        ChatMessage(
            role: .assistant,
            content: "You've spent €22 on Food in July — one entry on Jul 8 from Bank Accounts."
        ),
        ChatMessage(role: .user, content: "What's my biggest expense category?"),
        ChatMessage(
            role: .assistant,
            content: "Rent is your largest category at €650 — about 75% of July spending."
        ),
    ]

    static var totalSpent: Double { expenses.reduce(0) { $0 + $1.amount } }
    static var totalIncome: Double { incomeEntries.reduce(0) { $0 + $1.amount } }
    static var cashFlow: Double { totalIncome - totalSpent }

    static var categoryBreakdown: [(name: String, amount: Double)] {
        Dictionary(grouping: expenses, by: \.categoryName)
            .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }

    /// Expenses grouped by day, most recent first.
    static var dateGroups: [(date: String, total: Double, items: [Expense])] {
        let groups = Dictionary(grouping: expenses, by: \.date)
        return groups.keys.sorted(by: >).map { date in
            let items = groups[date] ?? []
            return (date, items.reduce(0) { $0 + $1.amount }, items)
        }
    }

    static var netBalance: Double { totalIncome - totalSpent }
    static var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return max(0, netBalance / totalIncome)
    }
    static var accountsBalance: Double { accounts.reduce(0) { $0 + $1.currentBalance } }

    static let chartBuckets: [(label: String, income: Double, expenses: Double)] = [
        ("1", 1200, 770),
        ("5", 142, 71),
        ("8", 0, 22),
    ]

    static let monthlyStats = MonthlyExpensesStats(
        period: .init(year: 2026, month: 7),
        total: totalSpent,
        categories: [
            MonthlyCategoryTotal(categoryId: 3, categoryName: "Rent", totalAmount: 650, entryCount: 1),
            MonthlyCategoryTotal(categoryId: 5, categoryName: "Pension", totalAmount: 120, entryCount: 1),
            MonthlyCategoryTotal(categoryId: 2, categoryName: "Transport", totalAmount: 47.31, entryCount: 1),
            MonthlyCategoryTotal(categoryId: 4, categoryName: "Social Life", totalAmount: 24, entryCount: 1),
            MonthlyCategoryTotal(categoryId: 1, categoryName: "Food", totalAmount: 22, entryCount: 1),
        ]
    )

    static var foodExpenses: [Expense] {
        expenses.filter { $0.categoryName == "Food" }
    }

    static func dayHeader(_ iso: String) -> String {
        guard let date = DateUtils.parseLocalISODate(iso) else { return iso }
        return date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }
}
