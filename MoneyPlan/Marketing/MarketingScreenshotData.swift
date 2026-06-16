import Foundation

/// Static demo data for App Store marketing screenshots (no API / auth required).
enum MarketingScreenshotData {
    static let accounts: [Account] = [
        Account(id: 1, name: "Main Checking", isDefault: true, initialBalance: 1200, currentBalance: 2450.80),
        Account(id: 2, name: "Savings", isDefault: false, initialBalance: 5000, currentBalance: 8200),
        Account(id: 3, name: "Travel", isDefault: false, initialBalance: 300, currentBalance: 680.50),
    ]

    static let categories: [Category] = [
        Category(id: 1, name: "Food", isDefault: true),
        Category(id: 2, name: "Transport", isDefault: false),
        Category(id: 3, name: "Rent", isDefault: false),
        Category(id: 4, name: "Social Life", isDefault: false),
        Category(id: 5, name: "Health", isDefault: false),
        Category(id: 6, name: "Other", isDefault: false),
    ]

    static let expenses: [Expense] = [
        Expense(id: 1, date: "2026-06-01", amount: 850, categoryId: 3, categoryName: "Rent", accountId: 1, accountName: "Main Checking", note: "June rent"),
        Expense(id: 2, date: "2026-06-03", amount: 68.40, categoryId: 1, categoryName: "Food", accountId: 1, accountName: "Main Checking", note: "Dinner out"),
        Expense(id: 3, date: "2026-06-05", amount: 45.20, categoryId: 1, categoryName: "Food", accountId: 1, accountName: "Main Checking", note: "Groceries"),
        Expense(id: 4, date: "2026-06-06", amount: 32, categoryId: 2, categoryName: "Transport", accountId: 1, accountName: "Main Checking", note: nil),
        Expense(id: 5, date: "2026-06-07", amount: 24.50, categoryId: 4, categoryName: "Social Life", accountId: 3, accountName: "Travel", note: "Coffee with friends"),
    ]

    static let incomeEntries: [IncomeEntry] = [
        IncomeEntry(id: 1, date: "2026-06-01", amount: 3200, accountId: 1, accountName: "Main Checking", note: "Salary"),
        IncomeEntry(id: 2, date: "2026-06-04", amount: 450, accountId: 1, accountName: "Main Checking", note: "Freelance project"),
    ]

    static let chatMessages: [ChatMessage] = [
        ChatMessage(role: .user, content: "How much did I spend on food this month?"),
        ChatMessage(
            role: .assistant,
            content: "You've spent €113.60 on Food in June across 2 entries — groceries (€45.20) and dinner out (€68.40). That's about 9% of your total spending so far."
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

    static var netBalance: Double { totalIncome - totalSpent }
    static var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return max(0, netBalance / totalIncome)
    }
    static var accountsBalance: Double { accounts.reduce(0) { $0 + $1.currentBalance } }

    /// Sample day buckets for the overview bar chart (June 2026).
    static let chartBuckets: [(label: String, income: Double, expenses: Double)] = [
        ("1", 3200, 850),
        ("3", 0, 68),
        ("5", 0, 45),
        ("6", 0, 32),
        ("7", 0, 25),
        ("8", 450, 0),
        ("10", 0, 18),
        ("12", 0, 42),
    ]

    static let monthlyStats = MonthlyExpensesStats(
        period: .init(year: 2026, month: 6),
        total: 1020.10,
        categories: [
            MonthlyCategoryTotal(categoryId: 3, categoryName: "Rent", totalAmount: 850, entryCount: 1),
            MonthlyCategoryTotal(categoryId: 1, categoryName: "Food", totalAmount: 113.60, entryCount: 2),
            MonthlyCategoryTotal(categoryId: 2, categoryName: "Transport", totalAmount: 32, entryCount: 1),
            MonthlyCategoryTotal(categoryId: 4, categoryName: "Social Life", totalAmount: 24.50, entryCount: 1),
        ]
    )

    static var foodExpenses: [Expense] {
        expenses.filter { $0.categoryName == "Food" }
    }
}
