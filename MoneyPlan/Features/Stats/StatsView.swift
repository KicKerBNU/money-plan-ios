import SwiftUI

@MainActor
@Observable
final class StatsViewModel {
    var stats: MonthlyExpensesStats?
    var isLoading = true
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let ym = DateUtils.currentYearMonth()
        do {
            stats = try await FinanceAPI.fetchMonthlyStats(year: ym.year, month: ym.month)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct StatsView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = StatsViewModel()

    var body: some View {
        let _ = money.activeCurrency
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else if let stats = viewModel.stats {
                    content(stats)
                } else {
                    ContentUnavailableView("common.unexpectedError", systemImage: "chart.bar")
                }
            }
            .navigationTitle("stats.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsToolbar() }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private func content(_ stats: MonthlyExpensesStats) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("stats.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    Text(CurrencyFormatter.format(stats.total))
                        .font(.largeTitle.weight(.bold))
                    Text(String(format: String(localized: "stats.spentAcrossCategories"), stats.categories.count))
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)
                }

                FinanceCard {
                    Text("stats.lineupTitle")
                        .font(.headline)
                    let maxTotal = stats.categories.map(\.totalAmount).max() ?? 1

                    ForEach(stats.categories) { cat in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                CategoryIconView(name: cat.categoryName)
                                Text(SeedLocalization.localizedCategoryName(cat.categoryName))
                                Spacer()
                                Text(CurrencyFormatter.format(cat.totalAmount))
                                    .font(.subheadline.weight(.semibold))
                            }
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.primary.opacity(0.25))
                                    .frame(width: geo.size.width * CGFloat(cat.totalAmount / maxTotal))
                            }
                            .frame(height: 8)
                            Text("\(cat.entryCount) \(String(localized: "stats.entryLabel"))")
                                .font(.caption2)
                                .foregroundStyle(AppColors.muted)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
