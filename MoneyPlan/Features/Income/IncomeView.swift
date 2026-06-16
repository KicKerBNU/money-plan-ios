import SwiftUI

@MainActor
@Observable
final class IncomeViewModel {
    var entries: [IncomeEntry] = []
    var accounts: [Account] = []
    var isLoading = true
    var errorMessage: String?

    private let yearMonth = DateUtils.currentYearMonth()

    var total: Double { entries.reduce(0) { $0 + $1.amount } }
    var lastDate: String? { entries.map(\.date).sorted().last }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let inc = FinanceAPI.fetchIncomes(year: yearMonth.year, month: yearMonth.month)
            async let acc = FinanceAPI.fetchAccounts()
            entries = try await inc
            accounts = try await acc
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(date: String, amount: Double, accountId: Int, note: String?) async throws {
        _ = try await FinanceAPI.createIncome(date: date, amount: amount, accountId: accountId, note: note)
        await load()
    }

    func update(_ entry: IncomeEntry) async throws {
        guard let accountId = entry.accountId else { return }
        _ = try await FinanceAPI.updateIncome(
            id: entry.id,
            date: entry.date,
            amount: entry.amount,
            accountId: accountId,
            note: entry.note
        )
        await load()
    }

    func delete(_ entry: IncomeEntry) async {
        let snapshot = entries
        entries.removeAll { $0.id == entry.id }
        do {
            try await FinanceAPI.deleteIncome(id: entry.id)
        } catch {
            entries = snapshot
            await load()
        }
    }
}

struct IncomeView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = IncomeViewModel()
    @State private var date = Date()
    @State private var amountText = ""
    @State private var note = ""
    @State private var accountId = 0
    @State private var editing: IncomeEntry?
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
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .onAppear {
                if let acc = DefaultAccountPicker.pick(from: viewModel.accounts) {
                    accountId = acc.id
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("income.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    KPIView(title: "income.summary.totalIncome", value: CurrencyFormatter.format(viewModel.total))
                    if let last = viewModel.lastDate {
                        Text(String(format: String(localized: "income.summary.lastEntry"), viewModel.entries.count, DateUtils.formatShortDate(last)))
                            .font(.caption)
                            .foregroundStyle(AppColors.muted)
                    }
                }

                FinanceCard {
                    Text(editing == nil ? "income.quickAdd.title" : "expenses.form.editTitle")
                        .font(.headline)

                    Form {
                        DatePicker("income.form.date", selection: $date, displayedComponents: .date)
                        TextField("income.form.amount", text: $amountText)
                            .keyboardType(.decimalPad)
                        Picker("expenses.form.account", selection: $accountId) {
                            ForEach(viewModel.accounts) { acc in
                                Text(acc.name).tag(acc.id)
                            }
                        }
                        TextField("income.form.notePlaceholder", text: $note)
                    }
                    .frame(height: 280)

                    Button(editing == nil ? "income.form.submit" : "common.save") {
                        Task { await submit() }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }

                FinanceCard {
                    Text("income.recent.title")
                        .font(.headline)

                    if viewModel.entries.isEmpty {
                        Text("expenses.empty")
                            .foregroundStyle(AppColors.muted)
                    } else {
                        ForEach(viewModel.entries) { entry in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(CurrencyFormatter.format(entry.amount))
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(DateUtils.formatShortDate(entry.date)) · \(entry.accountName ?? "")")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.muted)
                                }
                                Spacer()
                                Menu {
                                    Button {
                                        editing = entry
                                        populateForm(entry)
                                    } label: {
                                        Label("common.edit", systemImage: "square.and.pencil")
                                    }
                                    Button(role: .destructive) { toDelete = entry } label: {
                                        Label("common.delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
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

    private func populateForm(_ entry: IncomeEntry) {
        date = DateUtils.parseLocalISODate(entry.date) ?? Date()
        amountText = String(entry.amount)
        note = entry.note ?? ""
        accountId = entry.accountId ?? accountId
    }

    private func submit() async {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        let iso = DateUtils.localISODate(from: date)
        do {
            if var entry = editing {
                entry.date = iso
                entry.amount = amount
                entry.accountId = accountId
                entry.note = note.isEmpty ? nil : note
                try await viewModel.update(entry)
                editing = nil
                amountText = ""
                note = ""
            } else {
                try await viewModel.create(date: iso, amount: amount, accountId: accountId, note: note.isEmpty ? nil : note)
                amountText = ""
                note = ""
            }
        } catch {}
    }
}
