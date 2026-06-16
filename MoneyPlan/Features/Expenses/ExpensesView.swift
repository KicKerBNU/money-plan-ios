import SwiftUI

struct ExpensesView: View {
    @Binding var showAddSheet: Bool
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = ExpensesViewModel()
    @State private var editingExpense: Expense?
    @State private var expenseToDelete: Expense?
    @State private var showTripRange = false
    @State private var tripStart = Date()
    @State private var tripEnd = Date()

    var body: some View {
        // Re-render when the user picks a new currency in Settings.
        let _ = money.activeCurrency
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("common.unexpectedError", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    expensesContent
                }
            }
            .navigationTitle("expenses.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("expenses.actions.addExpense")
                        SettingsToolbar()
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "expenses.searchPlaceholder")
            .sheet(isPresented: $showAddSheet) {
                ExpenseFormSheet(accounts: viewModel.accounts, categories: viewModel.categories) { date, amount, categoryId, accountId, note in
                    try await viewModel.createExpense(date: date, amount: amount, categoryId: categoryId, accountId: accountId, note: note)
                }
            }
            .sheet(item: $editingExpense) { expense in
                ExpenseFormSheet(accounts: viewModel.accounts, categories: viewModel.categories, editing: expense) { date, amount, categoryId, accountId, note in
                    var updated = expense
                    updated.date = date
                    updated.amount = amount
                    updated.categoryId = categoryId
                    updated.accountId = accountId
                    updated.note = note
                    if let cat = viewModel.categories.first(where: { $0.id == categoryId }) { updated.categoryName = cat.name }
                    if let acc = viewModel.accounts.first(where: { $0.id == accountId }) { updated.accountName = acc.name }
                    await viewModel.updateExpenseOptimistic(updated)
                }
            }
            .confirmationDialog(
                "expenses.confirmDelete.expenseTitle",
                isPresented: Binding(
                    get: { expenseToDelete != nil },
                    set: { if !$0 { expenseToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("common.delete", role: .destructive) {
                    if let expense = expenseToDelete {
                        Task { await viewModel.deleteExpense(expense) }
                    }
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("expenses.confirmDelete.expenseBody")
            }
            .sheet(isPresented: $showTripRange) {
                NavigationStack {
                    Form {
                        DatePicker("expenses.filters.from", selection: $tripStart, displayedComponents: .date)
                        DatePicker("expenses.filters.to", selection: $tripEnd, displayedComponents: .date)
                    }
                    .navigationTitle("expenses.filters.tripWeekModalTitle")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("common.cancel") { showTripRange = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("expenses.filters.applyRange") {
                                viewModel.dateRangeStart = DateUtils.localISODate(from: tripStart)
                                viewModel.dateRangeEnd = DateUtils.localISODate(from: tripEnd)
                                showTripRange = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var expensesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(viewModel.expenses.count) \(String(localized: "expenses.entriesThisMonth"))")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                summaryRow
                filterRow
                categoryChips

                if viewModel.filteredExpenses.isEmpty {
                    EmptyStateView(
                        title: "expenses.emptyMonth.title",
                        message: "expenses.emptyMonth.description",
                        actionTitle: "expenses.emptyMonth.cta"
                    ) {
                        showAddSheet = true
                    }
                } else {
                    expenseList
                }

                if !viewModel.categoryBreakdown.isEmpty {
                    categoryPanel
                }

                if !viewModel.accounts.isEmpty {
                    accountsPanel
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var summaryRow: some View {
        FinanceCard {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                KPIView(title: "expenses.summary.totalSpent", value: CurrencyFormatter.format(viewModel.totalSpent))
                KPIView(title: "expenses.summary.cashFlow", value: CurrencyFormatter.formatSigned(viewModel.cashFlow), valueColor: viewModel.cashFlow >= 0 ? AppColors.positive : AppColors.danger)
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(localized: "expenses.filters.last3Days", isSelected: false) { viewModel.applyQuickRange(days: 3) }
                FilterChip(localized: "expenses.filters.last7Days", isSelected: false) { viewModel.applyQuickRange(days: 7) }
                FilterChip(localized: "expenses.filters.tripWeek", isSelected: false) { showTripRange = true }
                if viewModel.dateRangeStart != nil {
                    FilterChip(localized: "expenses.filters.clearDate", isSelected: true) { viewModel.clearDateRange() }
                }
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(localized: "expenses.filters.all", isSelected: viewModel.selectedCategoryIds.isEmpty) {
                    viewModel.selectedCategoryIds.removeAll()
                }
                ForEach(viewModel.categories.prefix(6)) { cat in
                    FilterChip(literal: cat.name, isSelected: viewModel.selectedCategoryIds.contains(cat.id)) {
                        if viewModel.selectedCategoryIds.contains(cat.id) {
                            viewModel.selectedCategoryIds.remove(cat.id)
                        } else {
                            viewModel.selectedCategoryIds.insert(cat.id)
                        }
                    }
                }
            }
        }
    }

    private var expenseList: some View {
        FinanceCard {
            if viewModel.canReorder {
                Text("expenses.list.reorderHint")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                    .padding(.bottom, 8)
            }

            ForEach(viewModel.filteredExpenses) { expense in
                ExpenseRow(expense: expense) {
                    editingExpense = expense
                } onDelete: {
                    expenseToDelete = expense
                }
                Divider()
            }
        }
    }

    private var categoryPanel: some View {
        FinanceCard {
            Text("expenses.panels.byCategory")
                .font(.headline)
            ForEach(viewModel.categoryBreakdown, id: \.name) { row in
                HStack {
                    CategoryIconView(name: row.name)
                    Text(row.name)
                    Spacer()
                    Text(CurrencyFormatter.format(row.amount))
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var accountsPanel: some View {
        FinanceCard {
            Text("expenses.panels.byAccount")
                .font(.headline)
            ForEach(viewModel.accounts) { account in
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundStyle(AppColors.muted)
                    Text(account.name)
                    Spacer()
                    Text(CurrencyFormatter.format(account.currentBalance))
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct FilterChip: View {
    private enum Title {
        case localized(LocalizedStringKey)
        case literal(String)
    }

    private let title: Title
    private let isSelected: Bool
    private let action: () -> Void

    /// Catalog key — must use a distinct label so Swift does not pick `String` overload
    /// for literals like `"expenses.filters.last3Days"` (both inits would otherwise match).
    init(localized title: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) {
        self.title = .localized(title)
        self.isSelected = isSelected
        self.action = action
    }

    /// User-defined labels (e.g. category names) — not looked up in the string catalog.
    init(literal title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = .literal(title)
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                switch title {
                case .localized(let key):
                    Text(key)
                case .literal(let value):
                    Text(value)
                }
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ExpenseRow: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void

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
            Menu {
                Button { onEdit() } label: {
                    Label("common.edit", systemImage: "square.and.pencil")
                }
                Button(role: .destructive) { onDelete() } label: {
                    Label("common.delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(AppColors.muted)
            }
        }
        .padding(.vertical, 4)
    }
}
