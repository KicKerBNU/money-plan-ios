import SwiftUI

struct MarketingScreenshotCopyItem {
    let category: String
    let headline: String
    let subheadline: String?
}

/// App Store marketing copy paired with each screenshot slot.
enum MarketingScreenshotCopy {
    static let expensesHero = MarketingScreenshotCopyItem(
        category: "",
        headline: "Your personal finance app",
        subheadline: "Expenses, income, accounts & AI chat"
    )
    static let expenses = MarketingScreenshotCopyItem(
        category: "EXPENSE TRACKING",
        headline: "How much did I spend this month?",
        subheadline: "Track spending, income, and every account"
    )
    static let income = MarketingScreenshotCopyItem(
        category: "INCOME & CASH FLOW",
        headline: "Track salary and side income",
        subheadline: nil
    )
    static let chatbot = MarketingScreenshotCopyItem(
        category: "AI EXPENSE ASSISTANT",
        headline: "Ask about your spending in plain language",
        subheadline: nil
    )
    static let accounts = MarketingScreenshotCopyItem(
        category: "ACCOUNT OVERVIEW",
        headline: "See every account balance",
        subheadline: nil
    )
    static let login = MarketingScreenshotCopyItem(
        category: "SECURE SIGN-IN",
        headline: "Start in under a minute",
        subheadline: "Email, Apple, or Google"
    )
    static let addExpense = MarketingScreenshotCopyItem(
        category: "QUICK ENTRY",
        headline: "Log an expense in seconds",
        subheadline: nil
    )
    static let overview = MarketingScreenshotCopyItem(
        category: "SPENDING INSIGHTS",
        headline: "See income vs expenses at a glance",
        subheadline: nil
    )
    static let stats = MarketingScreenshotCopyItem(
        category: "CATEGORY BREAKDOWN",
        headline: "Know where your money goes",
        subheadline: nil
    )
    static let expensesByCategory = MarketingScreenshotCopyItem(
        category: "SMART FILTERS",
        headline: "Drill down by food, rent, and more",
        subheadline: nil
    )
    static let settings = MarketingScreenshotCopyItem(
        category: "YOUR PREFERENCES",
        headline: "Light, dark, and multi-currency",
        subheadline: nil
    )
}

/// Wraps app UI in a polished App Store marketing frame.
struct MarketingScreenshotFrame<Content: View>: View {
    let copy: MarketingScreenshotCopyItem
    @ViewBuilder var phoneContent: () -> Content

    init(
        category: String,
        headline: String,
        subheadline: String? = nil,
        @ViewBuilder phoneContent: @escaping () -> Content
    ) {
        copy = MarketingScreenshotCopyItem(
            category: category,
            headline: headline,
            subheadline: subheadline
        )
        self.phoneContent = phoneContent
    }

    init(
        copy: MarketingScreenshotCopyItem,
        @ViewBuilder phoneContent: @escaping () -> Content
    ) {
        self.copy = copy
        self.phoneContent = phoneContent
    }

    var body: some View {
        GeometryReader { geo in
            let isPad = MarketingLayout.usesPadLayout(width: geo.size.width)
            ZStack {
                MarketingCanvasBackground(isPad: isPad)

                VStack(spacing: 0) {
                    MarketingBrandLockup(isPad: isPad)
                        .padding(.top, isPad ? 64 : 48)

                    if !copy.category.isEmpty {
                        Text(copy.category)
                            .font(.system(size: isPad ? 14 : 11, weight: .semibold, design: .rounded))
                            .tracking(isPad ? 2.4 : 1.8)
                            .foregroundStyle(MarketingBrandPalette.label.opacity(0.88))
                            .padding(.top, isPad ? 28 : 22)
                    }

                    Text(copy.headline)
                        .font(.system(size: isPad ? 42 : 30, weight: .bold, design: .rounded))
                        .foregroundStyle(MarketingBrandPalette.headline)
                        .multilineTextAlignment(.center)
                        .lineSpacing(isPad ? 4 : 3)
                        .minimumScaleFactor(0.78)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, isPad ? 52 : 34)
                        .padding(.top, copy.category.isEmpty ? (isPad ? 28 : 22) : (isPad ? 18 : 14))

                    if let subheadline = copy.subheadline {
                        Text(subheadline)
                            .font(.system(size: isPad ? 20 : 15, weight: .medium, design: .rounded))
                            .foregroundStyle(MarketingBrandPalette.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, isPad ? 48 : 32)
                            .padding(.top, 10)
                    }

                    Spacer(minLength: isPad ? 12 : 8)

                    let bottomPadding: CGFloat = isPad ? 20 : 14
                    let reservedTop: CGFloat = isPad
                        ? (copy.subheadline != nil ? 340 : 300)
                        : (copy.subheadline != nil ? 258 : 228)
                    let maxPhoneHeight = max(geo.size.height - reservedTop - bottomPadding, 420)

                    MarketingPhoneMockup(
                        isPad: isPad,
                        canvas: geo.size,
                        maxPhoneHeight: maxPhoneHeight,
                        content: phoneContent
                    )
                    .padding(.bottom, bottomPadding)
                }
            }
        }
    }
}

// MARK: - Phone mockup

private enum MarketingPhoneMockupMetrics {
    static let contentWidth: CGFloat = 390
    static let contentHeight: CGFloat = 844
}

private struct MarketingPhoneMockup<Content: View>: View {
    let isPad: Bool
    let canvas: CGSize
    var maxPhoneHeight: CGFloat?
    @ViewBuilder var content: () -> Content

    var body: some View {
        let aspect = MarketingPhoneMockupMetrics.contentHeight / MarketingPhoneMockupMetrics.contentWidth
        let widthCap = isPad ? min(canvas.width * 0.44, 400) : canvas.width * 0.76
        let heightLimit = maxPhoneHeight ?? .infinity
        let phoneHeight = min(widthCap * aspect, heightLimit)
        let phoneWidth = phoneHeight / aspect
        let screenRadius = phoneWidth * 0.115
        let bezelWidth: CGFloat = 10

        ZStack {
            RoundedRectangle(cornerRadius: screenRadius + 6, style: .continuous)
                .fill(MarketingBrandPalette.bezel)
                .frame(width: phoneWidth + bezelWidth, height: phoneHeight + bezelWidth)
                .shadow(color: .black.opacity(0.35), radius: 28, y: 18)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(width: phoneWidth, height: phoneHeight)
                .overlay {
                    content()
                        .frame(
                            width: MarketingPhoneMockupMetrics.contentWidth,
                            height: MarketingPhoneMockupMetrics.contentHeight
                        )
                        .scaleEffect(phoneWidth / MarketingPhoneMockupMetrics.contentWidth, anchor: .top)
                        .frame(width: phoneWidth, height: phoneHeight, alignment: .top)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: phoneWidth * 0.26, height: phoneWidth * 0.065)
                        .padding(.top, phoneWidth * 0.028)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.45), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
        }
        .frame(width: phoneWidth + bezelWidth, height: phoneHeight + bezelWidth)
    }
}
