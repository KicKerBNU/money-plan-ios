import SwiftUI

/// Hero App Store slide — floating UI cards (competitor-style) instead of a phone frame.
struct MarketingHeroExpensesScreenshot: View {
    var body: some View {
        GeometryReader { geo in
            let isPad = MarketingLayout.usesPadLayout(width: geo.size.width)
            ZStack {
                MarketingCanvasBackground(isPad: isPad)

                VStack(spacing: 0) {
                    MarketingBrandLockup(isPad: isPad)
                        .padding(.top, isPad ? 64 : 48)

                    Text(MarketingScreenshotCopy.expensesHero.headline)
                        .font(.system(size: isPad ? 42 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketingBrandPalette.headline)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isPad ? 4 : 2)
                        .minimumScaleFactor(0.82)
                        .lineLimit(3)
                        .padding(.horizontal, isPad ? 52 : 28)
                        .padding(.top, isPad ? 28 : 22)

                    if let sub = MarketingScreenshotCopy.expensesHero.subheadline {
                        Text(sub)
                            .font(.system(size: isPad ? 20 : 15, weight: .medium, design: .rounded))
                            .foregroundStyle(MarketingBrandPalette.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, isPad ? 48 : 32)
                            .padding(.top, 10)
                    }

                    Spacer(minLength: isPad ? 24 : 16)

                    MarketingHeroFloatingCards(isPad: isPad, canvas: geo.size)

                    Spacer(minLength: isPad ? 48 : 36)
                }
            }
        }
    }
}

private struct MarketingHeroFloatingCards: View {
    let isPad: Bool
    let canvas: CGSize

    var body: some View {
        let scale = isPad ? 1.15 : 1.0
        ZStack {
            heroCard(width: 200 * scale, rotation: -14, offset: CGSize(width: -92 * scale, height: -36 * scale)) {
                MarketingHeroCashFlowCard()
            }

            heroCard(width: 188 * scale, rotation: 10, offset: CGSize(width: 98 * scale, height: -52 * scale)) {
                MarketingHeroAccountsCard()
            }

            heroCard(width: 220 * scale, rotation: -4, offset: CGSize(width: 0, height: 72 * scale)) {
                MarketingHeroExpensesCard()
            }
        }
        .frame(height: isPad ? 340 : 280)
    }

    private func heroCard<C: View>(
        width: CGFloat,
        rotation: Double,
        offset: CGSize,
        @ViewBuilder content: () -> C
    ) -> some View {
        content()
            .frame(width: width)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, y: 12)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
    }
}

private struct MarketingHeroCashFlowCard: View {
    private let data = MarketingScreenshotData.self

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cash flow")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
            Text(CurrencyFormatter.formatSigned(data.cashFlow))
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.positive)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Income")
                        .font(.caption2)
                        .foregroundStyle(AppColors.muted)
                    Text(CurrencyFormatter.format(data.totalIncome))
                        .font(.caption.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Spent")
                        .font(.caption2)
                        .foregroundStyle(AppColors.muted)
                    Text(CurrencyFormatter.format(data.totalSpent))
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(14)
    }
}

private struct MarketingHeroAccountsCard: View {
    private let accounts = MarketingScreenshotData.accounts

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your accounts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
            ForEach(accounts.prefix(2)) { account in
                HStack {
                    Text(account.name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Spacer()
                    Text(CurrencyFormatter.format(account.currentBalance))
                        .font(.caption.weight(.bold))
                }
            }
        }
        .padding(14)
    }
}

private struct MarketingHeroExpensesCard: View {
    private let expenses = MarketingScreenshotData.expenses

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent expenses")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
            ForEach(expenses.prefix(2)) { expense in
                HStack(spacing: 8) {
                    CategoryIconView(name: expense.categoryName)
                        .scaleEffect(0.85)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(expense.categoryName)
                            .font(.caption.weight(.semibold))
                        Text(DateUtils.formatShortDate(expense.date))
                            .font(.caption2)
                            .foregroundStyle(AppColors.muted)
                    }
                    Spacer()
                    Text(CurrencyFormatter.format(expense.amount))
                        .font(.caption.weight(.bold))
                }
            }
        }
        .padding(14)
    }
}
