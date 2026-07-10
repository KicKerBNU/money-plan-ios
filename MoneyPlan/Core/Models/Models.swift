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
    /// User-picked SF Symbol; nil = derive from name via `CategoryIcon`.
    var icon: String? = nil
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
    var recurringIncomeId: Int?

    enum CodingKeys: String, CodingKey {
        case id, date, amount, note
        case accountId
        case account_id
        case accountName
        case account_name
        case recurringIncomeId
        case recurring_income_id
    }

    init(
        id: Int,
        date: String,
        amount: Double,
        accountId: Int?,
        accountName: String?,
        note: String?,
        recurringIncomeId: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.accountId = accountId
        self.accountName = accountName
        self.note = note
        self.recurringIncomeId = recurringIncomeId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        amount = try container.decode(Double.self, forKey: .amount)
        accountId = try container.decodeIfPresent(Int.self, forKey: .accountId)
            ?? container.decodeIfPresent(Int.self, forKey: .account_id)
        accountName = try container.decodeIfPresent(String.self, forKey: .accountName)
            ?? container.decodeIfPresent(String.self, forKey: .account_name)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        recurringIncomeId = Self.decodeFlexibleInt(
            from: container,
            primary: .recurringIncomeId,
            secondary: .recurring_income_id
        )
    }

    private static func decodeFlexibleInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        primary: CodingKeys,
        secondary: CodingKeys
    ) -> Int? {
        for key in [primary, secondary] {
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return value
            }
            if let string = try? container.decodeIfPresent(String.self, forKey: key),
               let value = Int(string.trimmingCharacters(in: .whitespaces)) {
                return value
            }
            if let double = try? container.decodeIfPresent(Double.self, forKey: key) {
                return Int(double)
            }
        }
        return nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(accountId, forKey: .accountId)
        try container.encodeIfPresent(accountName, forKey: .accountName)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(recurringIncomeId, forKey: .recurringIncomeId)
    }
}

struct RecurringIncome: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    var amount: Double
    var accountId: Int
    var accountName: String
    var note: String?
    var frequency: RecurrenceFrequency
    var startDate: String
    var nextDate: String
    var active: Bool
}

struct RecurringIncomeSave: Sendable {
    enum Mode: Sendable {
        case create(RecurrenceFrequency)
        case update(id: Int, enabled: Bool, frequency: RecurrenceFrequency)
    }

    let mode: Mode
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
