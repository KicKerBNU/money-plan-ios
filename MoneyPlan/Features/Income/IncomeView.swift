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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddAndSettingsToolbar(addAccessibilityLabel: "income.actions.addIncome") {
                        showAddSheet = true
                    }
                }
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                periodPicker

                totalHero

                recentSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
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
            .accessibilityLabel("income.period.prev")

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
            .accessibilityLabel("income.period.next")
        }
        .padding(.top, 4)
    }

    private var totalHero: some View {
        VStack(spacing: 8) {
            Text("income.summary.totalIncome")
                .font(.subheadline)
                .foregroundStyle(AppColors.muted)

            Text(CurrencyFormatter.format(viewModel.total))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("income.recent.title")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.leading, 4)

            FinanceCard {
                if viewModel.entries.isEmpty {
                    EmptyStateView(
                        title: "income.empty.title",
                        message: "income.empty.body",
                        actionTitle: "income.actions.addIncome"
                    ) {
                        showAddSheet = true
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 {
                                Divider()
                                    .padding(.leading, 52)
                            }

                            IncomeEntryRow(
                                entry: entry,
                                title: entryTitle(for: entry),
                                isRecurring: viewModel.isRecurringEntry(entry)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    await viewModel.load()
                                    editingEntry = viewModel.freshEntry(for: entry)
                                }
                            }
                            .contextMenu {
                                Button {
                                    Task {
                                        await viewModel.load()
                                        editingEntry = viewModel.freshEntry(for: entry)
                                    }
                                } label: {
                                    Label("common.edit", systemImage: "square.and.pencil")
                                }

                                Button(role: .destructive) {
                                    toDelete = entry
                                } label: {
                                    Label("common.delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func entryTitle(for entry: IncomeEntry) -> String {
        if let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            return note
        }
        return entry.accountName ?? String(localized: "income.title")
    }
}

private struct IncomeEntryRow: View {
    let entry: IncomeEntry
    let title: String
    let isRecurring: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            IncomeIconView(label: title)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)

                    if isRecurring {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                            .accessibilityLabel("recurringIncome.form.isRecurring")
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(CurrencyFormatter.format(entry.amount))
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
    }

    private var subtitle: String {
        let date = DateUtils.formatShortDate(entry.date)
        let account = entry.accountName ?? ""
        if account.isEmpty { return date }
        return "\(date) · \(account)"
    }
}
