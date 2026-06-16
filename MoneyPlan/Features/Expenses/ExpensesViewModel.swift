import Foundation

@MainActor
@Observable
final class ExpensesViewModel {
    var expenses: [Expense] = []
    var incomes: [IncomeEntry] = []
    var accounts: [Account] = []
    var categories: [Category] = []
    var isLoading = true
    var errorMessage: String?
    var searchText = ""
    var selectedCategoryIds: Set<Int> = []
    var dateRangeStart: String?
    var dateRangeEnd: String?

    private let yearMonth = DateUtils.currentYearMonth()

    var year: Int { yearMonth.year }
    var month: Int { yearMonth.month }

    var totalSpent: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }
    var totalIncome: Double { incomes.reduce(0) { $0 + $1.amount } }
    var cashFlow: Double { totalIncome - totalSpent }

    var canReorder: Bool {
        searchText.isEmpty && selectedCategoryIds.isEmpty && dateRangeStart == nil
    }

    var filteredExpenses: [Expense] {
        var list = expenses
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                ($0.note?.lowercased().contains(q) ?? false)
                    || $0.categoryName.lowercased().contains(q)
                    || $0.accountName.lowercased().contains(q)
                    || $0.date.contains(q)
            }
        }
        if !selectedCategoryIds.isEmpty {
            list = list.filter { selectedCategoryIds.contains($0.categoryId) }
        }
        if let start = dateRangeStart, let end = dateRangeEnd {
            list = list.filter { $0.date >= start && $0.date <= end }
        }
        return list
    }

    var categoryBreakdown: [(name: String, amount: Double)] {
        var map: [String: Double] = [:]
        for e in expenses {
            map[e.categoryName, default: 0] += e.amount
        }
        return map.map { ($0.key, $0.value) }
            .sorted { lhs, rhs in
                if lhs.0.lowercased() == "other" { return false }
                if rhs.0.lowercased() == "other" { return true }
                return lhs.1 > rhs.1
            }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let exp = FinanceAPI.fetchExpenses(year: year, month: month)
            async let inc = FinanceAPI.fetchIncomes(year: year, month: month)
            async let acc = FinanceAPI.fetchAccounts()
            async let cat = FinanceAPI.fetchCategories()

            expenses = try await exp
            incomes = try await inc
            accounts = try await acc
            categories = try await cat
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteExpense(_ expense: Expense) async {
        let snapshot = expenses
        expenses.removeAll { $0.id == expense.id }
        do {
            try await FinanceAPI.deleteExpense(id: expense.id)
        } catch {
            expenses = snapshot
            await load()
        }
    }

    func updateExpenseOptimistic(_ updated: Expense) async {
        guard let index = expenses.firstIndex(where: { $0.id == updated.id }) else { return }
        let snapshot = expenses[index]
        expenses[index] = updated
        do {
            let saved = try await FinanceAPI.updateExpense(
                id: updated.id,
                date: updated.date,
                amount: updated.amount,
                categoryId: updated.categoryId,
                accountId: updated.accountId,
                note: updated.note
            )
            expenses[index] = saved
        } catch {
            expenses[index] = snapshot
        }
    }

    func createExpense(date: String, amount: Double, categoryId: Int, accountId: Int, note: String?) async throws {
        _ = try await FinanceAPI.createExpense(
            date: date,
            amount: amount,
            categoryId: categoryId,
            accountId: accountId,
            note: note
        )
        await load()
    }

    func reorder(from source: IndexSet, to destination: Int) async {
        guard canReorder else { return }
        var ordered = expenses
        ordered.move(fromOffsets: source, toOffset: destination)
        let snapshot = expenses
        expenses = ordered
        do {
            expenses = try await FinanceAPI.reorderExpenses(
                year: year,
                month: month,
                orderedIds: ordered.map(\.id)
            )
        } catch {
            expenses = snapshot
            await load()
        }
    }

    func applyQuickRange(days: Int) {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -(days - 1), to: end) ?? end
        dateRangeStart = DateUtils.localISODate(from: start)
        dateRangeEnd = DateUtils.localISODate(from: end)
    }

    func clearDateRange() {
        dateRangeStart = nil
        dateRangeEnd = nil
    }
}
