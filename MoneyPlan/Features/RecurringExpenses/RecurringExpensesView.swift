import SwiftUI

@MainActor
@Observable
final class RecurringExpensesViewModel {
    var items: [RecurringExpense] = []
    var accounts: [Account] = []
    var categories: [Category] = []
    var isLoading = true
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let recurring = FinanceAPI.fetchRecurringExpenses()
            async let acc = FinanceAPI.fetchAccounts()
            async let cat = FinanceAPI.fetchCategories()
            items = try await recurring
            accounts = try await acc
            categories = try await cat
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ item: RecurringExpense) async throws {
        let saved = try await FinanceAPI.updateRecurringExpense(
            id: item.id,
            amount: item.amount,
            categoryId: item.categoryId,
            accountId: item.accountId,
            note: item.note,
            frequency: item.frequency,
            startDate: item.startDate
        )
        let synced: RecurringExpense
        if item.active != saved.active {
            synced = try await FinanceAPI.setRecurringExpenseActive(id: item.id, active: item.active)
        } else {
            synced = saved
        }
        if let index = items.firstIndex(where: { $0.id == synced.id }) {
            items[index] = synced
        }
    }

    func setActive(_ item: RecurringExpense, active: Bool) async {
        do {
            let saved = try await FinanceAPI.setRecurringExpenseActive(id: item.id, active: active)
            if let index = items.firstIndex(where: { $0.id == saved.id }) {
                items[index] = saved
            } else {
                items.append(saved)
            }
        } catch {
            await load()
        }
    }

    func delete(_ item: RecurringExpense) async {
        let snapshot = items
        items.removeAll { $0.id == item.id }
        do {
            try await FinanceAPI.deleteRecurringExpense(id: item.id)
        } catch {
            items = snapshot
            await load()
        }
    }
}

struct RecurringExpensesView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = RecurringExpensesViewModel()
    @State private var editingItem: RecurringExpense?
    @State private var itemToDelete: RecurringExpense?

    var body: some View {
        let _ = money.activeCurrency
        Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("common.unexpectedError", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView("recurring.empty.title", systemImage: "arrow.triangle.2.circlepath", description: Text("recurring.empty.body"))
                } else {
                    List {
                        ForEach(viewModel.items) { item in
                            RecurringExpenseRow(
                                item: item,
                                onToggleActive: { active in
                                    Task { await viewModel.setActive(item, active: active) }
                                }
                            )
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                    } label: {
                                        Label("common.delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("recurring.title")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(item: $editingItem) { item in
                RecurringExpenseEditSheet(
                    item: item,
                    accounts: viewModel.accounts,
                    categories: viewModel.categories
                ) { updated in
                    try await viewModel.update(updated)
                }
            }
            .confirmationDialog(
                "recurring.confirmDelete.title",
                isPresented: Binding(
                    get: { itemToDelete != nil },
                    set: { if !$0 { itemToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("common.delete", role: .destructive) {
                    if let item = itemToDelete {
                        Task { await viewModel.delete(item) }
                    }
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("recurring.confirmDelete.body")
            }
    }
}

private struct RecurringExpenseRow: View {
    let item: RecurringExpense
    var onToggleActive: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(CurrencyFormatter.format(item.amount))
                    .font(.headline)
                    .foregroundStyle(item.active ? .primary : AppColors.muted)
                Spacer()
                if item.active {
                    Text(LocalizedStringKey(item.frequency.localizationKey))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.muted.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("recurring.status.paused")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(AppColors.muted)
                        .background(AppColors.muted.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Text("\(item.categoryName) · \(item.accountName)")
                .font(.subheadline)
                .foregroundStyle(AppColors.muted)
            if item.active {
                Text(String(format: String(localized: "recurring.nextDue"), DateUtils.formatShortDate(item.nextDate)))
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
            }
            if let note = item.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
            }
            Toggle("recurring.form.isRecurring", isOn: Binding(
                get: { item.active },
                set: { onToggleActive($0) }
            ))
            .font(.subheadline)
        }
        .padding(.vertical, 4)
        .opacity(item.active ? 1 : 0.85)
    }
}

private struct RecurringExpenseEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accounts: [Account]
    let categories: [Category]
    var onSave: (RecurringExpense) async throws -> Void

    @State private var amountText: String
    @State private var categoryId: Int
    @State private var accountId: Int
    @State private var note: String
    @State private var frequency: RecurrenceFrequency
    @State private var startDate: Date
    @State private var isActive: Bool
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let itemId: Int

    init(
        item: RecurringExpense,
        accounts: [Account],
        categories: [Category],
        onSave: @escaping (RecurringExpense) async throws -> Void
    ) {
        self.accounts = accounts
        self.categories = categories
        self.onSave = onSave
        itemId = item.id
        _amountText = State(initialValue: String(item.amount))
        _categoryId = State(initialValue: item.categoryId)
        _accountId = State(initialValue: item.accountId)
        _note = State(initialValue: item.note ?? "")
        _frequency = State(initialValue: item.frequency)
        _startDate = State(initialValue: DateUtils.parseLocalISODate(item.startDate) ?? Date())
        _isActive = State(initialValue: item.active)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("expenses.form.amount", text: $amountText)
                    .keyboardType(.decimalPad)

                Picker("expenses.form.category", selection: $categoryId) {
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }

                Picker("expenses.form.account", selection: $accountId) {
                    ForEach(accounts) { acc in
                        Text(acc.name).tag(acc.id)
                    }
                }

                Picker("recurring.form.frequency", selection: $frequency) {
                    ForEach(RecurrenceFrequency.allCases) { option in
                        Text(LocalizedStringKey(option.localizationKey)).tag(option)
                    }
                }

                DatePicker("recurring.form.startDate", selection: $startDate, displayedComponents: .date)

                Toggle("recurring.form.isRecurring", isOn: $isActive)

                TextField("expenses.form.note", text: $note, axis: .vertical)
                    .lineLimit(2 ... 4)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(AppColors.danger)
                        .font(.footnote)
                }
            }
            .navigationTitle("recurring.edit.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || parsedAmount == nil)
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func save() async {
        guard let amount = parsedAmount else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        let categoryName = categories.first(where: { $0.id == categoryId })?.name ?? ""
        let accountName = accounts.first(where: { $0.id == accountId })?.name ?? ""
        let startIso = DateUtils.localISODate(from: startDate)

        var updated = RecurringExpense(
            id: itemId,
            amount: amount,
            categoryId: categoryId,
            categoryName: categoryName,
            accountId: accountId,
            accountName: accountName,
            note: note.isEmpty ? nil : note,
            frequency: frequency,
            startDate: startIso,
            nextDate: startIso,
            active: isActive
        )

        do {
            try await onSave(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
