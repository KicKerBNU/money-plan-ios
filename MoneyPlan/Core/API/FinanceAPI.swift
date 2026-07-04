import Foundation

enum FinanceAPI {
    private static let client = APIClient.shared

    // MARK: - Expenses

    static func fetchExpenses(year: Int, month: Int) async throws -> [Expense] {
        let response: DataResponse<[Expense]> = try await client.fetch("/v1/expenses?year=\(year)&month=\(month)")
        return response.data
    }

    static func fetchExpenses(startDate: String, endDate: String) async throws -> [Expense] {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "startDate", value: startDate),
            URLQueryItem(name: "endDate", value: endDate),
        ]
        let response: DataResponse<[Expense]> = try await client.fetch("/v1/expenses?\(components.query ?? "")")
        return response.data
    }

    static func createExpense(
        date: String,
        amount: Double,
        categoryId: Int,
        accountId: Int,
        note: String?,
        recurrenceFrequency: RecurrenceFrequency? = nil
    ) async throws -> Expense {
        struct Body: Encodable {
            var date: String
            var amount: Double
            var categoryId: Int
            var accountId: Int
            var note: String?
            var recurrenceFrequency: RecurrenceFrequency?
        }
        let response: DataResponse<Expense> = try await client.fetch(
            "/v1/expenses",
            method: "POST",
            body: Body(
                date: date,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                recurrenceFrequency: recurrenceFrequency
            )
        )
        return response.data
    }

    static func updateExpense(
        id: Int,
        date: String,
        amount: Double,
        categoryId: Int,
        accountId: Int,
        note: String?,
        recurrenceEnabled: Bool? = nil,
        recurrenceFrequency: RecurrenceFrequency? = nil
    ) async throws -> Expense {
        struct Body: Encodable {
            var date: String
            var amount: Double
            var categoryId: Int
            var accountId: Int
            var note: String?
            var recurrenceEnabled: Bool?
            var recurrenceFrequency: RecurrenceFrequency?
        }
        let response: DataResponse<Expense> = try await client.fetch(
            "/v1/expenses/\(id)",
            method: "PUT",
            body: Body(
                date: date,
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                recurrenceEnabled: recurrenceEnabled,
                recurrenceFrequency: recurrenceFrequency
            )
        )
        return response.data
    }

    static func deleteExpense(id: Int) async throws {
        let _: EmptyResponse = try await client.fetch("/v1/expenses/\(id)", method: "DELETE")
    }

    static func reorderExpenses(year: Int, month: Int, orderedIds: [Int]) async throws -> [Expense] {
        struct Body: Encodable {
            var year: Int
            var month: Int
            var orderedIds: [Int]
        }
        let response: DataResponse<[Expense]> = try await client.fetch(
            "/v1/expenses/order",
            method: "PATCH",
            body: Body(year: year, month: month, orderedIds: orderedIds)
        )
        return response.data
    }

    // MARK: - Recurring expenses

    static func fetchRecurringExpenses() async throws -> [RecurringExpense] {
        let response: DataResponse<[RecurringExpense]> = try await client.fetch("/v1/recurring-expenses")
        return response.data
    }

    static func fetchRecurringExpense(id: Int) async throws -> RecurringExpense {
        let response: DataResponse<RecurringExpense> = try await client.fetch("/v1/recurring-expenses/\(id)")
        return response.data
    }

    static func setRecurringExpenseActive(id: Int, active: Bool) async throws -> RecurringExpense {
        struct Body: Encodable { var active: Bool }
        let response: DataResponse<RecurringExpense> = try await client.fetch(
            "/v1/recurring-expenses/\(id)",
            method: "PATCH",
            body: Body(active: active)
        )
        return response.data
    }

    static func updateRecurringExpense(
        id: Int,
        amount: Double,
        categoryId: Int,
        accountId: Int,
        note: String?,
        frequency: RecurrenceFrequency,
        startDate: String
    ) async throws -> RecurringExpense {
        struct Body: Encodable {
            var amount: Double
            var categoryId: Int
            var accountId: Int
            var note: String?
            var frequency: RecurrenceFrequency
            var startDate: String
        }
        let response: DataResponse<RecurringExpense> = try await client.fetch(
            "/v1/recurring-expenses/\(id)",
            method: "PUT",
            body: Body(
                amount: amount,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                frequency: frequency,
                startDate: startDate
            )
        )
        return response.data
    }

    static func deleteRecurringExpense(id: Int) async throws {
        let _: EmptyResponse = try await client.fetch("/v1/recurring-expenses/\(id)", method: "DELETE")
    }

    // MARK: - Accounts

    static func fetchAccounts() async throws -> [Account] {
        let response: DataResponse<[Account]> = try await client.fetch("/v1/accounts")
        return response.data
    }

    static func createAccount(name: String) async throws -> Account {
        struct Body: Encodable { var name: String }
        let response: DataResponse<Account> = try await client.fetch("/v1/accounts", method: "POST", body: Body(name: name))
        return response.data
    }

    static func updateAccount(id: Int, name: String, initialBalance: Double? = nil) async throws -> Account {
        struct Body: Encodable {
            var name: String
            var initialBalance: Double?
        }
        let response: DataResponse<Account> = try await client.fetch(
            "/v1/accounts/\(id)",
            method: "PUT",
            body: Body(name: name, initialBalance: initialBalance)
        )
        return response.data
    }

    static func setAccountDefault(id: Int) async throws -> Account {
        struct Body: Encodable {}
        let response: DataResponse<Account> = try await client.fetch(
            "/v1/accounts/\(id)/default",
            method: "PATCH",
            body: Body()
        )
        return response.data
    }

    static func deleteAccount(id: Int) async throws {
        let _: EmptyResponse = try await client.fetch("/v1/accounts/\(id)", method: "DELETE")
    }

    // MARK: - Categories

    static func fetchCategories() async throws -> [Category] {
        let response: DataResponse<[Category]> = try await client.fetch("/v1/categories")
        return response.data
    }

    static func createCategory(name: String) async throws -> Category {
        struct Body: Encodable { var name: String }
        let response: DataResponse<Category> = try await client.fetch("/v1/categories", method: "POST", body: Body(name: name))
        return response.data
    }

    static func updateCategory(id: Int, name: String) async throws -> Category {
        struct Body: Encodable { var name: String }
        let response: DataResponse<Category> = try await client.fetch(
            "/v1/categories/\(id)",
            method: "PUT",
            body: Body(name: name)
        )
        return response.data
    }

    static func deleteCategory(id: Int) async throws {
        let _: EmptyResponse = try await client.fetch("/v1/categories/\(id)", method: "DELETE")
    }

    // MARK: - Income

    static func fetchIncomes(year: Int, month: Int) async throws -> [IncomeEntry] {
        let response: DataResponse<[IncomeEntry]> = try await client.fetch("/v1/incomes?year=\(year)&month=\(month)")
        return response.data
    }

    static func fetchIncomes(startDate: String, endDate: String) async throws -> [IncomeEntry] {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "startDate", value: startDate),
            URLQueryItem(name: "endDate", value: endDate),
        ]
        let response: DataResponse<[IncomeEntry]> = try await client.fetch("/v1/incomes?\(components.query ?? "")")
        return response.data
    }

    static func createIncome(date: String, amount: Double, accountId: Int, note: String?) async throws -> IncomeEntry {
        struct Body: Encodable {
            var date: String
            var amount: Double
            var accountId: Int
            var note: String?
        }
        let response: DataResponse<IncomeEntry> = try await client.fetch(
            "/v1/incomes",
            method: "POST",
            body: Body(date: date, amount: amount, accountId: accountId, note: note)
        )
        return response.data
    }

    static func updateIncome(id: Int, date: String, amount: Double, accountId: Int, note: String?) async throws -> IncomeEntry {
        struct Body: Encodable {
            var date: String
            var amount: Double
            var accountId: Int
            var note: String?
        }
        let response: DataResponse<IncomeEntry> = try await client.fetch(
            "/v1/incomes/\(id)",
            method: "PUT",
            body: Body(date: date, amount: amount, accountId: accountId, note: note)
        )
        return response.data
    }

    static func deleteIncome(id: Int) async throws {
        let _: EmptyResponse = try await client.fetch("/v1/incomes/\(id)", method: "DELETE")
    }

    // MARK: - Stats

    static func fetchMonthlyStats(year: Int, month: Int) async throws -> MonthlyExpensesStats {
        let response: DataResponse<MonthlyExpensesStats> = try await client.fetch(
            "/v1/stats/monthly-expenses?year=\(year)&month=\(month)"
        )
        return response.data
    }

    // MARK: - Chat

    static func sendChat(messages: [ChatMessage], clientToday: String) async throws -> String {
        struct Body: Encodable {
            var messages: [ExpenseChatRequestMessage]
            var clientToday: String
        }
        let payload = Body(
            messages: messages.map { ExpenseChatRequestMessage(role: $0.role.rawValue, content: $0.content) },
            clientToday: clientToday
        )
        let response: DataResponse<ExpenseChatReply> = try await client.fetch(
            "/v1/ai/expense-chat",
            method: "POST",
            body: payload,
            options: APIFetchOptions(silentError: true, silentSuccess: true)
        )
        return response.data.reply
    }
}
