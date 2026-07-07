import Foundation

@MainActor
@Observable
final class IncomeViewModel {
    var entries: [IncomeEntry] = []
    var accounts: [Account] = []
    var recurringIncomes: [RecurringIncome] = []
    var isLoading = true
    var errorMessage: String?

    private(set) var year: Int
    private(set) var month: Int

    init() {
        let current = DateUtils.currentYearMonth()
        year = current.year
        month = current.month
    }

    var total: Double { entries.reduce(0) { $0 + $1.amount } }
    var lastDate: String? { entries.map(\.date).sorted().last }

    var periodLabel: String {
        guard let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return "\(month)/\(year)"
        }
        return DateUtils.formatMonthYear(date)
    }

    func shiftPeriod(by delta: Int) async {
        var nextMonth = month + delta
        var nextYear = year
        if nextMonth > 12 {
            nextMonth = 1
            nextYear += 1
        } else if nextMonth < 1 {
            nextMonth = 12
            nextYear -= 1
        }
        year = nextYear
        month = nextMonth
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let inc = FinanceAPI.fetchIncomes(year: year, month: month)
            async let acc = FinanceAPI.fetchAccounts()
            async let recurring = FinanceAPI.fetchRecurringIncomes()
            entries = try await inc
            accounts = try await acc
            recurringIncomes = try await recurring
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func freshEntry(for entry: IncomeEntry) -> IncomeEntry {
        entries.first(where: { $0.id == entry.id }) ?? entry
    }

    func resolveRecurring(for entry: IncomeEntry) -> RecurringIncome? {
        if let recurringId = entry.recurringIncomeId,
           let match = recurringIncomes.first(where: { $0.id == recurringId }) {
            return match
        }

        guard let accountId = entry.accountId else { return nil }
        let entryNote = normalizedNote(entry.note)

        return recurringIncomes.first { template in
            template.accountId == accountId
                && amountsEqual(template.amount, entry.amount)
                && template.startDate == entry.date
                && notesCompatible(entryNote, normalizedNote(template.note))
        }
    }

    func resolveRecurringId(for entry: IncomeEntry) -> Int? {
        entry.recurringIncomeId ?? resolveRecurring(for: entry)?.id
    }

    func linkedRecurring(for entry: IncomeEntry) -> RecurringIncome? {
        resolveRecurring(for: entry)
    }

    func isRecurringEntry(_ entry: IncomeEntry) -> Bool {
        resolveRecurringId(for: entry) != nil
    }

    func create(
        date: String,
        amount: Double,
        accountId: Int,
        note: String?,
        recurrence: RecurringIncomeSave?
    ) async throws {
        let createFrequency: RecurrenceFrequency? = {
            if case .create(let frequency) = recurrence?.mode { return frequency }
            return nil
        }()
        _ = try await FinanceAPI.createIncome(
            date: date,
            amount: amount,
            accountId: accountId,
            note: note,
            recurrenceFrequency: createFrequency
        )
        await load()
    }

    func saveEdit(
        original: IncomeEntry,
        date: String,
        amount: Double,
        accountId: Int,
        note: String?,
        recurrence: RecurringIncomeSave?
    ) async throws {
        let (recurrenceEnabled, recurrenceFrequency) = recurrencePayload(
            from: recurrence,
            original: original
        )
        _ = try await FinanceAPI.updateIncome(
            id: original.id,
            date: date,
            amount: amount,
            accountId: accountId,
            note: note,
            recurrenceEnabled: recurrenceEnabled,
            recurrenceFrequency: recurrenceFrequency
        )
        await load()
    }

    private func recurrencePayload(
        from recurrence: RecurringIncomeSave?,
        original: IncomeEntry
    ) -> (Bool?, RecurrenceFrequency?) {
        guard let recurrence else {
            return (nil, nil)
        }

        switch recurrence.mode {
        case .create(let frequency):
            return (true, frequency)
        case .update(_, let enabled, let frequency):
            let hasLink = resolveRecurringId(for: original) != nil
            guard hasLink || enabled else { return (nil, nil) }
            return (enabled, enabled ? frequency : nil)
        }
    }

    func delete(_ entry: IncomeEntry) async {
        let snapshot = entries
        entries.removeAll { $0.id == entry.id }
        do {
            try await FinanceAPI.deleteIncome(id: entry.id)
            await load()
        } catch {
            entries = snapshot
            await load()
        }
    }

    private func normalizedNote(_ note: String?) -> String {
        note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func notesCompatible(_ entryNote: String, _ templateNote: String) -> Bool {
        entryNote.isEmpty || templateNote.isEmpty || entryNote == templateNote
    }

    private func amountsEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.000_1
    }
}
