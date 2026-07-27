import Charts
import SwiftUI

// MARK: - Additional App Store screens (5–10)

struct MarketingLoginScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.login) {
            MarketingLoginContent()
                .preferredColorScheme(.light)
                .tint(AppColors.primary)
        }
    }
}

struct MarketingAddExpenseScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.addExpense) {
            MarketingScreenshotShell(tab: .expenses) {
                ZStack(alignment: .bottom) {
                    MarketingExpensesContent()
                        .allowsHitTesting(false)

                    // Scrim keeps the Expenses title black (not washed-out gray).
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()

                    MarketingExpenseFormPanel()
                }
            }
        }
    }
}

struct MarketingOverviewScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.overview) {
            MarketingScreenshotShell(tab: .expenses) {
                MarketingOverviewContent()
            }
        }
    }
}

struct MarketingStatsScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.stats) {
            MarketingScreenshotShell(tab: .expenses) {
                MarketingStatsContent()
            }
        }
    }
}

struct MarketingExpensesByCategoryScreenshot: View {
    var body: some View {
        MarketingCategoriesScreenshot()
    }
}

struct MarketingSettingsScreenshot: View {
    var body: some View {
        MarketingScreenshotFrame(copy: MarketingScreenshotCopy.settings) {
            MarketingScreenshotShell(tab: .accounts) {
                MarketingSettingsContent()
            }
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
                Image("MarketingAppIcon")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 14, x: 0, y: 8)

                Text("Money Plann")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
                    .textCase(.uppercase)

                Text("auth.login.title")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("auth.login.description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                    Text("auth.login.or")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Rectangle().fill(Color.black.opacity(0.12)).frame(height: 1)
                }

                MarketingSignInWithAppleButton()

                MarketingGoogleSignInButton()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, MarketingPhoneMetrics.topSafeArea + 12)
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
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.45))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            MarketingSheetHeader(title: "expenses.form.title")

            VStack(spacing: 12) {
                formSection {
                    formPickerRow(label: "expenses.form.category", value: "Food")
                    Divider().padding(.leading, 16)
                    formPickerRow(label: "expenses.form.date", value: "Jul 8, 2026")
                    Divider().padding(.leading, 16)
                    formValueRow(label: "expenses.form.amount", value: "€42.50")
                    Divider().padding(.leading, 16)
                    formPickerRow(label: "expenses.form.account", value: "Bank Accounts")
                }

                formSection {
                    Text("Note (optional)")
                        .font(.body)
                        .foregroundStyle(AppColors.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                formSection {
                    HStack {
                        Text("recurring.form.isRecurring")
                        Spacer()
                        MarketingToggleOff()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 24, y: -4)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func formSection<C: View>(@ViewBuilder content: () -> C) -> some View {
        content()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formPickerRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppColors.muted)
            Spacer()
            Text(value)
                .foregroundStyle(Color.primary)
                .fontWeight(.medium)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formValueRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppColors.muted)
            Spacer()
            Text(value)
                .foregroundStyle(Color.primary)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

struct MarketingOverviewContent: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(spacing: 0) {
            MarketingLargeTitleBar(title: "overview.title") {
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

struct MarketingStatsContent: View {
    private let stats = MarketingScreenshotData.monthlyStats

    var body: some View {
        VStack(spacing: 0) {
            // Short title matches visual weight of Expenses / Income / Accounts.
            MarketingLargeTitleBar(title: "Stats") {
                MarketingToolbarGear()
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                    Spacer()
                    Text("July 2026")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primary)
                }
                .padding(.top, 4)

                FinanceCard {
                    Text(CurrencyFormatter.format(stats.total))
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.primary)
                    Text(String(format: String(localized: "stats.spentAcrossCategories"), stats.categories.count))
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)
                }

                FinanceCard {
                    Text("stats.lineupTitle")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    let maxTotal = stats.categories.map(\.totalAmount).max() ?? 1

                    ForEach(stats.categories) { cat in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                CategoryIconView(name: cat.categoryName)
                                Text(cat.categoryName)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text(CurrencyFormatter.format(cat.totalAmount))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.primary)
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

// MARK: - Settings page

struct MarketingSettingsContent: View {
    var body: some View {
        VStack(spacing: 0) {
            MarketingLargeTitleBar(title: "settings.title") {
                EmptyView()
            }

            VStack(spacing: 24) {
                settingsSection(title: "settings.section.preferences") {
                    settingsRow(icon: "tag", title: "settings.categories")
                    settingsRow(icon: "moon", title: "settings.appearance")
                }

                settingsSection(title: "settings.section.planning") {
                    settingsRow(icon: "arrow.triangle.2.circlepath", title: "recurring.settingsMenu")
                    settingsRow(icon: "arrow.up.circle", title: "recurringIncome.settingsMenu")
                    settingsRow(icon: "coloncurrencysign.circle", title: "preferences.currency", value: "EUR (€)")
                }

                settingsSection {
                    settingsRow(icon: "rectangle.portrait.and.arrow.right", title: "appNav.logout", showsChevron: false)
                    settingsRow(icon: "trash", title: "auth.deleteAccount.menu", iconColor: AppColors.danger, titleColor: AppColors.danger, showsChevron: false)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    private func settingsSection(title: LocalizedStringKey? = nil, @ViewBuilder rows: @escaping () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.muted)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .padding(.leading, 4)
            }
            FinanceCard {
                VStack(spacing: 0) {
                    rows()
                }
            }
        }
    }

    private func settingsRow(
        icon: String,
        title: LocalizedStringKey,
        value: String? = nil,
        iconColor: Color = AppColors.primary,
        titleColor: Color = .primary,
        showsChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 26)
            Text(title)
                .foregroundStyle(titleColor)
            Spacer(minLength: 8)
            if let value {
                Text(verbatim: value)
                    .foregroundStyle(.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.muted.opacity(0.6))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}

// MARK: - Toggle (ImageRenderer-safe; `Toggle` shows yellow error banners)

private struct MarketingToggleOff: View {
    var body: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 51, height: 31)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
                    .padding(2)
            }
    }
}

// MARK: - Social buttons (ImageRenderer-safe; SignInWithAppleButton does not rasterize)

private enum MarketingSocialButtonMetrics {
    static let height: CGFloat = 50
    static let cornerRadius: CGFloat = 12
}

/// Matches `LoginView` `.whiteOutline` Sign in with Apple on a light background.
private struct MarketingSignInWithAppleButton: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "apple.logo")
                .font(.body.weight(.semibold))
            Text("Sign in with Apple")
                .font(.body.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: MarketingSocialButtonMetrics.height)
        .foregroundStyle(.black)
        .background(Color.white, in: RoundedRectangle(cornerRadius: MarketingSocialButtonMetrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MarketingSocialButtonMetrics.cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
        )
    }
}

/// Matches `LoginView.googleSignInButton`.
private struct MarketingGoogleSignInButton: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("GoogleG")
                .resizable()
                .interpolation(.high)
                .frame(width: 18, height: 18)
            Text("auth.login.googleButton")
                .font(.body.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: MarketingSocialButtonMetrics.height)
        .foregroundStyle(.primary)
        .background(Color.white, in: RoundedRectangle(cornerRadius: MarketingSocialButtonMetrics.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MarketingSocialButtonMetrics.cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
        )
    }
}
