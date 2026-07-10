import SwiftUI

struct ExpensesView: View {
    @Binding var showAddSheet: Bool
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = ExpensesViewModel()
    @State private var editingExpense: Expense?
    @State private var expenseToDelete: Expense?

    /// Segment / legend colors assigned by breakdown rank (matches design mockup).
    private static let chartPalette: [Color] = [
        AppColors.primary,
        Color(.systemRed),
        Color(.systemYellow),
        Color(.systemGray),
        Color(.systemPurple),
        Color(.systemOrange),
        Color(.systemBlue),
        Color(.systemTeal),
    ]

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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddAndSettingsToolbar(addAccessibilityLabel: "expenses.actions.addExpense") {
                        showAddSheet = true
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "expenses.searchPlaceholder")
            .sheet(isPresented: $showAddSheet) {
                ExpenseFormSheet(accounts: viewModel.accounts, categories: viewModel.categories) { date, amount, categoryId, accountId, note, recurrence in
                    try await viewModel.createExpense(
                        date: date,
                        amount: amount,
                        categoryId: categoryId,
                        accountId: accountId,
                        note: note,
                        recurrence: recurrence
                    )
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingExpense) { expense in
                ExpenseFormSheet(
                    accounts: viewModel.accounts,
                    categories: viewModel.categories,
                    editing: expense,
                    linkedRecurring: viewModel.linkedRecurring(for: expense)
                ) { date, amount, categoryId, accountId, note, recurrence in
                    try await viewModel.saveExpenseEdit(
                        original: expense,
                        date: date,
                        amount: amount,
                        categoryId: categoryId,
                        accountId: accountId,
                        note: note,
                        recurrence: recurrence
                    )
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var expensesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                periodPicker
                summaryCard

                if viewModel.filteredExpenses.isEmpty {
                    EmptyStateView(
                        title: "expenses.emptyMonth.title",
                        message: "expenses.emptyMonth.description",
                        actionTitle: "expenses.emptyMonth.cta"
                    ) {
                        showAddSheet = true
                    }
                } else {
                    groupedList
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var periodPicker: some View {
        HStack {
            Button {
                Task { await viewModel.shiftPeriod(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(AppColors.primary)
            .accessibilityLabel("expenses.period.prev")

            Spacer()

            Text(viewModel.periodLabel)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button {
                Task { await viewModel.shiftPeriod(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(AppColors.primary)
            .accessibilityLabel("expenses.period.next")
        }
        .padding(.top, 4)
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        FinanceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("expenses.summary.totalSpent")
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                        Text(CurrencyFormatter.format(viewModel.totalSpent))
                            .font(.title3.weight(.bold))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("expenses.summary.cashFlow")
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                        Text(CurrencyFormatter.formatSigned(viewModel.cashFlow))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(viewModel.cashFlow >= 0 ? AppColors.positive : AppColors.danger)
                    }
                }

                if !viewModel.categoryBreakdown.isEmpty, viewModel.totalSpent > 0 {
                    categoryBar
                    legendGrid
                }
            }
        }
    }

    private var categoryBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(viewModel.categoryBreakdown.enumerated()), id: \.element.name) { index, row in
                    Rectangle()
                        .fill(chartColor(at: index))
                        .frame(width: geo.size.width * row.amount / viewModel.totalSpent)
                }
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }

    private var legendGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(Array(viewModel.categoryBreakdown.enumerated()), id: \.element.name) { index, row in
                HStack(spacing: 6) {
                    Circle()
                        .fill(chartColor(at: index))
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

    private func chartColor(at index: Int) -> Color {
        index < Self.chartPalette.count ? Self.chartPalette[index] : Color(.systemGray3)
    }

    // MARK: - Date-grouped list

    private var groupedList: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(viewModel.dateGroups, id: \.date) { group in
                VStack(spacing: 8) {
                    HStack {
                        Text(dayHeader(group.date))
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
                            ExpenseRow(
                                expense: expense,
                                icon: viewModel.categories.first(where: { $0.id == expense.categoryId })?.icon
                            ) {
                                editingExpense = expense
                            } onDelete: {
                                expenseToDelete = expense
                            } onFullSwipe: {
                                Task { await viewModel.deleteExpense(expense) }
                            }

                            if expense.id != group.items.last?.id {
                                Divider()
                                    .padding(.leading, 58)
                            }
                        }
                    }
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.primary.opacity(0.08))
                    )
                }
            }
        }
    }

    /// "2026-07-01" -> "JUL 1" (localized month abbreviation).
    private func dayHeader(_ iso: String) -> String {
        guard let date = DateUtils.parseLocalISODate(iso) else { return iso }
        return date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }
}

private struct ExpenseRow: View {
    let expense: Expense
    var icon: String? = nil
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onFullSwipe: () -> Void

    private var subtitle: String {
        var parts = [DateUtils.formatShortDate(expense.date), expense.accountName]
        if let note = expense.note, !note.isEmpty {
            parts.append(note)
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        SwipeToDeleteRow(onTap: onEdit, onDelete: onDelete, onFullSwipe: onFullSwipe) {
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
        .contextMenu {
            Button { onEdit() } label: {
                Label("common.edit", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("common.delete", systemImage: "trash")
            }
        }
    }
}
