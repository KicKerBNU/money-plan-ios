import Charts
import SwiftUI

// MARK: - Additional App Store screens (5–10)

struct MarketingLoginScreenshot: View {
    var body: some View {
        MarketingLoginContent()
            .preferredColorScheme(.light)
            .tint(AppColors.primary)
    }
}

struct MarketingAddExpenseScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .expenses) {
            ZStack(alignment: .bottom) {
                MarketingExpensesContent()
                    .opacity(0.35)
                    .allowsHitTesting(false)

                MarketingExpenseFormPanel()
            }
        }
    }
}

struct MarketingOverviewScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .expenses) {
            MarketingOverviewContent()
        }
    }
}

struct MarketingStatsScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .expenses) {
            MarketingStatsContent()
        }
    }
}

struct MarketingExpensesByCategoryScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .expenses) {
            MarketingExpensesByCategoryContent()
        }
    }
}

struct MarketingSettingsScreenshot: View {
    var body: some View {
        MarketingScreenshotShell(tab: .expenses) {
            MarketingSettingsContent()
        }
    }
}

// MARK: - Segmented control (ImageRenderer-safe; `Picker` shows yellow error banners)

private struct MarketingSegmentedControl: View {
    let items: [LocalizedStringKey]
    let selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(index == selectedIndex ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .foregroundStyle(index == selectedIndex ? Color.primary : Color.secondary)
            }
        }
        .padding(4)
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Login (full screen, no tab bar)

private struct MarketingLoginContent: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 8)

                    Image(systemName: "dollarsign")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Money Plan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                    .textCase(.uppercase)

                Text("auth.login.title")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 14) {
                MarketingSegmentedControl(
                    items: ["auth.login.modeSignIn", "auth.login.modeSignUp"],
                    selectedIndex: 0
                )

                VStack(spacing: 0) {
                    loginFieldRow(icon: "envelope", label: "auth.login.emailLabel", value: "you@example.com")
                    Divider().padding(.leading, 52)
                    loginFieldRow(icon: "lock", label: "auth.login.passwordLabel", value: "••••••••")
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.08))
                )

                HStack {
                    Spacer()
                    Text("auth.login.forgotPassword")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppColors.primary)
                }

                Text("auth.login.emailSubmit")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                    Text("auth.login.or")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                }

                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.body.weight(.semibold))
                    Text("Sign in with Apple")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(.white)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.body.weight(.semibold))
                    Text("auth.login.googleButton")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 48)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.99, blue: 0.98),
                    Color(red: 0.93, green: 0.98, blue: 0.96),
                    Color.white,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func loginFieldRow(icon: String, label: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.body)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Add expense sheet

private struct MarketingExpenseFormPanel: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingSheetHeader(title: "expenses.form.title")

            VStack(alignment: .leading, spacing: 16) {
                formRow(label: "expenses.form.date", value: "Jun 8, 2026")
                formRow(label: "expenses.form.amount", value: "42.50")
                formRow(label: "expenses.form.category", value: "Food")
                formRow(label: "expenses.form.account", value: "Main Checking")
                formRow(label: "expenses.form.note", value: "Lunch with team")

                Text("common.save")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundStyle(.white)
                    .padding(.top, 8)
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 24, y: -4)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func formRow(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
            Text(value)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

private struct MarketingSheetHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        HStack {
            Text("common.cancel")
                .foregroundStyle(AppColors.primary)
            Spacer()
            Text(title)
                .font(.headline)
            Spacer()
            Text("common.save")
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Overview

private struct MarketingOverviewContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "overview.title") {
                EmptyView()
            } trailing: {
                MarketingToolbarGear()
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("overview.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                MarketingSegmentedControl(
                    items: ["overview.period.week", "overview.period.month", "overview.period.year"],
                    selectedIndex: 1
                )

                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppColors.muted)
                    Spacer()
                    Text("June 2026")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.muted)
                }

                FinanceCard {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        KPIView(title: "overview.kpiIncome", value: CurrencyFormatter.format(data.totalIncome), valueColor: AppColors.positive)
                        KPIView(title: "overview.kpiExpenses", value: CurrencyFormatter.format(data.totalSpent), valueColor: AppColors.danger)
                        KPIView(title: "overview.kpiNet", value: CurrencyFormatter.formatSigned(data.netBalance), valueColor: AppColors.positive)
                        KPIView(title: "overview.kpiSavingsRate", value: "\(Int(data.savingsRate * 100))%")
                    }
                }

                FinanceCard {
                    Text("overview.chartTitle")
                        .font(.headline)
                    Chart {
                        ForEach(Array(data.chartBuckets.enumerated()), id: \.offset) { _, bucket in
                            BarMark(x: .value("Label", bucket.label), y: .value("Income", bucket.income))
                                .foregroundStyle(AppColors.positive)
                            BarMark(x: .value("Label", bucket.label), y: .value("Expenses", bucket.expenses))
                                .foregroundStyle(AppColors.danger)
                        }
                    }
                    .frame(height: 180)
                }

                FinanceCard {
                    Text("overview.insightsTitle")
                        .font(.headline)
                    Text("You retained roughly \(Int(data.savingsRate * 100))% of income.")
                        .font(.subheadline)
                    Text("Rent is about 83% of spending.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.muted)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Stats

private struct MarketingStatsContent: View {
    private let stats = MarketingScreenshotData.monthlyStats

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "stats.title") {
                EmptyView()
            } trailing: {
                MarketingToolbarGear()
            }

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
                                Text(cat.categoryName)
                                Spacer()
                                Text(CurrencyFormatter.format(cat.totalAmount))
                                    .font(.subheadline.weight(.semibold))
                            }
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.primary.opacity(0.25))
                                    .frame(width: geo.size.width * CGFloat(cat.totalAmount / maxTotal))
                                    .frame(maxHeight: .infinity, alignment: .leading)
                            }
                            .frame(height: 8)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Expenses filtered by category

private struct MarketingExpensesByCategoryContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "expenses.title") {
                EmptyView()
            } trailing: {
                HStack {
                    Image(systemName: "plus")
                    MarketingToolbarGear()
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("2 \(String(localized: "expenses.entriesThisMonth"))")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    KPIView(title: "expenses.summary.totalSpent", value: CurrencyFormatter.format(113.60))
                    KPIView(title: "expenses.summary.cashFlow", value: CurrencyFormatter.formatSigned(data.cashFlow), valueColor: AppColors.positive)
                }

                HStack(spacing: 8) {
                    chip("expenses.filters.all", selected: false)
                    chipLiteral("Food", selected: true)
                    chipLiteral("Transport", selected: false)
                    chipLiteral("Rent", selected: false)
                }

                FinanceCard {
                    ForEach(data.foodExpenses) { expense in
                        MarketingExpenseRow(expense: expense)
                        if expense.id != data.foodExpenses.last?.id { Divider() }
                    }
                }

                FinanceCard {
                    Text("expenses.panels.byCategory")
                        .font(.headline)
                    ForEach(data.categoryBreakdown.prefix(4), id: \.name) { row in
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

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func chip(_ key: LocalizedStringKey, selected: Bool) -> some View {
        Text(key)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: Capsule())
    }

    private func chipLiteral(_ title: String, selected: Bool) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: Capsule())
    }
}

// MARK: - Settings / preferences

private struct MarketingSettingsContent: View {
    var body: some View {
        VStack(spacing: 0) {
            MarketingNavBar(title: "expenses.title") {
                EmptyView()
            } trailing: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(AppColors.primary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Customize your experience")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    Label("theme.label", systemImage: "moon")
                        .font(.headline)
                    VStack(spacing: 8) {
                        settingsOption("theme.light", icon: "sun.max", selected: true)
                        settingsOption("theme.dark", icon: "moon", selected: false)
                        settingsOption("theme.system", icon: "circle.lefthalf.filled", selected: false)
                    }
                }

                FinanceCard {
                    HStack {
                        Label("preferences.currency", systemImage: "dollarsign.circle")
                            .font(.headline)
                        Spacer()
                        Text(verbatim: "EUR")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                    }

                    VStack(spacing: 8) {
                        currencyRow("EUR", selected: true)
                        currencyRow("USD", selected: false)
                        currencyRow("BRL", selected: false)
                        currencyRow("GBP", selected: false)
                    }
                }

                FinanceCard {
                    Label("appNav.logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.danger)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func settingsOption(_ label: LocalizedStringKey, icon: String, selected: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(selected ? AppColors.primary : AppColors.muted)
                .frame(width: 24)
            Text(label)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(12)
        .background(selected ? AppColors.primary.opacity(0.1) : AppColors.surfaceSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func currencyRow(_ code: String, selected: Bool) -> some View {
        HStack {
            Text(verbatim: code)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(12)
        .background(selected ? AppColors.primary.opacity(0.1) : AppColors.surfaceSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
