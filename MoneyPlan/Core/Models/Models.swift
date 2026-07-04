import Foundation

// MARK: - Expenses domain

struct Account: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var isDefault: Bool
    var initialBalance: Double
    var currentBalance: Double
}

struct Category: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
    var isDefault: Bool
}

struct Expense: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var date: String
    var amount: Double
    var categoryId: Int
    var categoryName: String
    var accountId: Int
    var accountName: String
    var note: String?
    var manualSort: Int?
    var recurringExpenseId: Int?
}

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case weekly
    case monthly
    case quarterly
    case semiannual
    case yearly

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .weekly: "recurring.frequency.weekly"
        case .monthly: "recurring.frequency.monthly"
        case .quarterly: "recurring.frequency.quarterly"
        case .semiannual: "recurring.frequency.semiannual"
        case .yearly: "recurring.frequency.yearly"
        }
    }
}

struct RecurringExpense: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var amount: Double
    var categoryId: Int
    var categoryName: String
    var accountId: Int
    var accountName: String
    var note: String?
    var frequency: RecurrenceFrequency
    var startDate: String
    var nextDate: String
    var active: Bool
}

struct RecurringExpenseSave: Sendable {
    enum Mode: Sendable {
        case create(RecurrenceFrequency)
        case update(id: Int, enabled: Bool, frequency: RecurrenceFrequency)
    }

    let mode: Mode
}

// MARK: - Income domain

struct IncomeEntry: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var date: String
    var amount: Double
    var accountId: Int?
    var accountName: String?
    var note: String?
}

// MARK: - Stats domain

struct MonthlyCategoryTotal: Codable, Identifiable, Hashable, Sendable {
    var categoryId: Int
    var categoryName: String
    var totalAmount: Double
    var entryCount: Int

    var id: Int { categoryId }
}

struct MonthlyExpensesStats: Codable, Sendable {
    struct Period: Codable, Hashable, Sendable {
        var year: Int
        var month: Int
    }

    var period: Period
    var total: Double
    var categories: [MonthlyCategoryTotal]
}

// MARK: - Chat

struct ChatMessage: Identifiable, Hashable, Sendable {
    let id: UUID
    var role: ChatRole
    var content: String

    init(id: UUID = UUID(), role: ChatRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
}

struct ExpenseChatRequestMessage: Codable, Sendable {
    var role: String
    var content: String
}

struct ExpenseChatReply: Codable, Sendable {
    var reply: String
}

// MARK: - API envelope

struct DataResponse<T: Decodable>: Decodable {
    var data: T
}

struct APIErrorBody: Decodable {
    var message: String?
}
