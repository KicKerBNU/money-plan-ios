import SwiftUI
import Charts

@MainActor
@Observable
final class OverviewViewModel {
    var preset: OverviewPreset = .month
    var anchor = Date()
    var expenses: [Expense] = []
    var incomes: [IncomeEntry] = []
    var accounts: [Account] = []
    var isLoading = true
    var errorMessage: String?

    var periodRange: PeriodRange { OverviewPeriod.range(preset: preset, anchor: anchor) }

    var totalIncome: Double { incomes.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }
    var net: Double { totalIncome - totalExpenses }
    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return max(0, net / totalIncome)
    }
    var accountsBalance: Double { accounts.reduce(0) { $0 + $1.currentBalance } }

    var categoryTotals: [(name: String, amount: Double, share: Double)] {
        var map: [String: Double] = [:]
        for e in expenses { map[e.categoryName, default: 0] += e.amount }
        return map.map { (name: $0.key, amount: $0.value, share: totalExpenses > 0 ? $0.value / totalExpenses : 0) }
            .sorted { $0.amount > $1.amount }
    }

    var chartBuckets: [(label: String, income: Double, expenses: Double)] {
        let keys = OverviewPeriod.listBucketKeys(preset: preset, start: periodRange.start, end: periodRange.end)
        var inc = Dictionary(uniqueKeysWithValues: keys.map { ($0, 0.0) })
        var exp = inc

        for i in incomes {
            let key = OverviewPeriod.bucketKey(for: i.date, preset: preset)
            if inc[key] != nil { inc[key, default: 0] += i.amount }
        }
        for e in expenses {
            let key = OverviewPeriod.bucketKey(for: e.date, preset: preset)
            if exp[key] != nil { exp[key, default: 0] += e.amount }
        }

        return keys.map { key in
            let label: String
            if preset == .year {
                label = String(key.suffix(2))
            } else if let date = DateUtils.parseLocalISODate(key) {
                label = preset == .week
                    ? date.formatted(.dateTime.weekday(.abbreviated))
                    : String(Calendar.current.component(.day, from: date))
            } else {
                label = key
            }
            return (label, inc[key] ?? 0, exp[key] ?? 0)
        }
    }

    var insights: [(message: String, tab: AppTab?)] {
        guard !isLoading, errorMessage == nil else { return [] }
        var items: [(String, AppTab?)] = []

        if totalIncome == 0 && totalExpenses == 0 {
            items.append((String(localized: "overview.insights.emptyPeriod"), .expenses))
            return items
        }
        if net < 0 && totalExpenses > 0 {
            items.append((String(localized: "overview.insights.deficit"), .expenses))
        }
        if let top = categoryTotals.first, totalExpenses > 0, top.share >= 0.35 {
            // Was `.stats` — the Stats tab was removed from the bottom bar, so we
            // surface this insight via the Expenses screen (top categories panel) instead.
            items.append(("\(top.name) is about \(Int(top.share * 100))% of spending.", .expenses))
        }
        if net > 0, savingsRate >= 0.1, totalIncome > 0 {
            items.append(("You retained roughly \(Int(savingsRate * 100))% of income.", nil))
        }
        if items.isEmpty, totalExpenses > 0 {
            items.append((String(localized: "overview.insights.allGood"), nil))
        }
        return items
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let range = periodRange
        do {
            async let exp = FinanceAPI.fetchExpenses(startDate: range.start, endDate: range.end)
            async let inc = FinanceAPI.fetchIncomes(startDate: range.start, endDate: range.end)
            async let acc = FinanceAPI.fetchAccounts()
            expenses = try await exp
            incomes = try await inc
            accounts = try await acc
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previousPeriod() {
        anchor = OverviewPeriod.shiftAnchor(preset: preset, anchor: anchor, delta: -1)
    }

    func nextPeriod() {
        anchor = OverviewPeriod.shiftAnchor(preset: preset, anchor: anchor, delta: 1)
    }
}

struct OverviewView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = OverviewViewModel()

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
            .navigationTitle("overview.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsToolbar() }
            }
            .onChange(of: viewModel.preset) { _, _ in Task { await viewModel.load() } }
            .onChange(of: viewModel.anchor) { _, _ in Task { await viewModel.load() } }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("overview.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                Picker("Period", selection: $viewModel.preset) {
                    Text("overview.period.week").tag(OverviewPreset.week)
                    Text("overview.period.month").tag(OverviewPreset.month)
                    Text("overview.period.year").tag(OverviewPreset.year)
                }
                .pickerStyle(.segmented)

                HStack {
                    Button { viewModel.previousPeriod() } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("overview.periodPrev")
                    Spacer()
                    Text(periodLabel)
                        .font(.headline)
                    Spacer()
                    Button { viewModel.nextPeriod() } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("overview.periodNext")
                }

                FinanceCard {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        KPIView(title: "overview.kpiIncome", value: CurrencyFormatter.format(viewModel.totalIncome), valueColor: AppColors.positive)
                        KPIView(title: "overview.kpiExpenses", value: CurrencyFormatter.format(viewModel.totalExpenses), valueColor: AppColors.danger)
                        KPIView(title: "overview.kpiNet", value: CurrencyFormatter.formatSigned(viewModel.net), valueColor: viewModel.net >= 0 ? AppColors.positive : AppColors.danger)
                        KPIView(title: "overview.kpiSavingsRate", value: "\(Int(viewModel.savingsRate * 100))%")
                        KPIView(title: "overview.kpiAccounts", value: CurrencyFormatter.format(viewModel.accountsBalance))
                    }
                }

                FinanceCard {
                    Text("overview.chartTitle")
                        .font(.headline)
                    if viewModel.chartBuckets.allSatisfy({ $0.income == 0 && $0.expenses == 0 }) {
                        Text("overview.chartEmpty")
                            .foregroundStyle(AppColors.muted)
                    } else {
                        Chart {
                            ForEach(Array(viewModel.chartBuckets.enumerated()), id: \.offset) { _, bucket in
                                BarMark(x: .value("Label", bucket.label), y: .value("Income", bucket.income))
                                    .foregroundStyle(AppColors.positive)
                                BarMark(x: .value("Label", bucket.label), y: .value("Expenses", bucket.expenses))
                                    .foregroundStyle(AppColors.danger)
                            }
                        }
                        .frame(height: 220)
                    }
                }

                FinanceCard {
                    Text("overview.categoriesTitle")
                        .font(.headline)
                    ForEach(viewModel.categoryTotals.prefix(5), id: \.name) { row in
                        HStack {
                            CategoryIconView(name: row.name)
                            Text(row.name)
                            Spacer()
                            Text(CurrencyFormatter.format(row.amount))
                        }
                    }
                }

                FinanceCard {
                    Text("overview.insightsTitle")
                        .font(.headline)
                    ForEach(Array(viewModel.insights.enumerated()), id: \.offset) { _, insight in
                        Text(insight.message)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var periodLabel: String {
        switch viewModel.preset {
        case .week:
            let start = DateUtils.parseLocalISODate(viewModel.periodRange.start) ?? viewModel.anchor
            let end = DateUtils.parseLocalISODate(viewModel.periodRange.end) ?? viewModel.anchor
            return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
        case .month:
            return DateUtils.formatMonthYear(viewModel.anchor)
        case .year:
            return String(Calendar.current.component(.year, from: viewModel.anchor))
        }
    }
}
