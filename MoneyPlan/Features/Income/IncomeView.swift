import SwiftUI

struct IncomeView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = IncomeViewModel()
    @State private var showAddSheet = false
    @State private var editingEntry: IncomeEntry?
    @State private var toDelete: IncomeEntry?

    var body: some View {
        let _ = money.activeCurrency
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else {
                    content
                }
            }
            .navigationTitle("income.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("income.actions.addIncome")
                }
                ToolbarItem(placement: .topBarTrailing) { SettingsToolbar() }
            }
            .confirmationDialog(
                "income.confirmDelete.title",
                isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("common.delete", role: .destructive) {
                    if let entry = toDelete { Task { await viewModel.delete(entry) } }
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("income.confirmDelete.body")
            }
            .sheet(isPresented: $showAddSheet) {
                IncomeFormSheet(accounts: viewModel.accounts) { date, amount, accountId, note, recurrence in
                    try await viewModel.create(
                        date: date,
                        amount: amount,
                        accountId: accountId,
                        note: note,
                        recurrence: recurrence
                    )
                }
            }
            .sheet(item: $editingEntry) { entry in
                IncomeFormSheet(
                    accounts: viewModel.accounts,
                    editing: entry,
                    linkedRecurring: viewModel.linkedRecurring(for: entry)
                ) { date, amount, accountId, note, recurrence in
                    try await viewModel.saveEdit(
                        original: entry,
                        date: date,
                        amount: amount,
                        accountId: accountId,
                        note: note,
                        recurrence: recurrence
                    )
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("income.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                HStack {
                    Button {
                        Task { await viewModel.shiftPeriod(by: -1) }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("income.period.prev")

                    Spacer()

                    Text(viewModel.periodLabel)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Button {
                        Task { await viewModel.shiftPeriod(by: 1) }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("income.period.next")
                }
                .padding(.horizontal, 4)

                FinanceCard {
                    KPIView(
                        title: "income.summary.totalIncome",
                        value: CurrencyFormatter.format(viewModel.total),
                        valueColor: AppColors.positive
                    )
                    if let last = viewModel.lastDate {
                        Text(String(format: String(localized: "income.summary.lastEntry"), viewModel.entries.count, DateUtils.formatShortDate(last)))
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                    }

                    Button {
                        showAddSheet = true
                    } label: {
                        Label("income.actions.addIncome", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }

                FinanceCard {
                    Text("income.recent.title")
                        .font(.headline)

                    if viewModel.entries.isEmpty {
                        VStack(spacing: 8) {
                            Text("income.empty.title")
                                .font(.subheadline.weight(.semibold))
                            Text("income.empty.body")
                                .font(.caption)
                                .foregroundStyle(AppColors.muted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    } else {
                        ForEach(viewModel.entries) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(CurrencyFormatter.format(entry.amount))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppColors.positive)
                                        if viewModel.isRecurringEntry(entry) {
                                            Image(systemName: "arrow.up.circle")
                                                .font(.caption2)
                                                .foregroundStyle(AppColors.primary)
                                                .accessibilityLabel("recurringIncome.form.isRecurring")
                                        }
                                    }
                                    Text(entryTitle(for: entry))
                                        .font(.subheadline)
                                    Text("\(DateUtils.formatShortDate(entry.date)) · \(entry.accountName ?? "")")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.muted)
                                }
                                Spacer()
                                Menu {
                                    Button {
                                        Task {
                                            await viewModel.load()
                                            editingEntry = viewModel.freshEntry(for: entry)
                                        }
                                    } label: {
                                        Label("common.edit", systemImage: "square.and.pencil")
                                    }
                                    Button(role: .destructive) { toDelete = entry } label: {
                                        Label("common.delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(AppColors.muted)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func entryTitle(for entry: IncomeEntry) -> String {
        if let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            return note
        }
        return entry.accountName ?? String(localized: "income.title")
    }
}
