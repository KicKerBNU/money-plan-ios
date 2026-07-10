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
        category: "ORGANIZE SPENDING",
        headline: "Custom categories with icons",
        subheadline: nil
    )
    static let categories = MarketingScreenshotCopyItem(
        category: "ORGANIZE SPENDING",
        headline: "Custom categories with icons",
        subheadline: nil
    )
    static let settings = MarketingScreenshotCopyItem(
        category: "YOUR PREFERENCES",
        headline: "Settings in one dedicated place",
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
            ZStack(alignment: .bottom) {
                MarketingCanvasBackground(isPad: isPad)

                VStack(spacing: 0) {
                    marketingHeader(isPad: isPad)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                MarketingPhoneMockup(
                    isPad: isPad,
                    canvas: geo.size,
                    maxPhoneHeight: geo.size.height - headerReserve(isPad: isPad) + (isPad ? 0 : 12),
                    content: phoneContent
                )
            }
        }
    }

    /// Vertical space reserved for logo + headline so the phone mockup does not overlap copy.
    private func headerReserve(isPad: Bool) -> CGFloat {
        if isPad {
            return copy.subheadline != nil ? 250 : 210
        }
        var height: CGFloat = 28 + 22 // brand lockup
        if !copy.category.isEmpty { height += 18 }
        height += copy.subheadline != nil ? 78 : 58 // headline (+ optional subheadline)
        height += 10
        return height
    }

    @ViewBuilder
    private func marketingHeader(isPad: Bool) -> some View {
        VStack(spacing: 0) {
            MarketingBrandLockup(isPad: isPad)
                .padding(.top, isPad ? 44 : 28)

            if !copy.category.isEmpty {
                Text(copy.category)
                    .font(.system(size: isPad ? 13 : 10, weight: .semibold, design: .rounded))
                    .tracking(isPad ? 2.2 : 1.6)
                    .foregroundStyle(MarketingBrandPalette.label.opacity(0.88))
                    .padding(.top, isPad ? 14 : 10)
            }

            Text(copy.headline)
                .font(.system(size: isPad ? 34 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(MarketingBrandPalette.headline)
                .multilineTextAlignment(.center)
                .lineSpacing(isPad ? 3 : 2)
                .minimumScaleFactor(0.82)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, isPad ? 44 : 22)
                .padding(.top, copy.category.isEmpty ? (isPad ? 16 : 12) : (isPad ? 10 : 8))

            if let subheadline = copy.subheadline {
                Text(subheadline)
                    .font(.system(size: isPad ? 17 : 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MarketingBrandPalette.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, isPad ? 40 : 24)
                    .padding(.top, 6)
            }
        }
        .padding(.bottom, isPad ? 12 : 8)
    }
}

// MARK: - Phone mockup

private struct MarketingPhoneMockup<Content: View>: View {
    let isPad: Bool
    let canvas: CGSize
    let maxPhoneHeight: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        let horizontalInset: CGFloat = isPad ? 72 : 10
        let maxWidth = canvas.width - horizontalInset * 2
        let widthFromHeight = maxPhoneHeight / MarketingPhoneMetrics.aspect
        let phoneWidth = min(maxWidth, widthFromHeight)
        let phoneHeight = phoneWidth * MarketingPhoneMetrics.aspect
        let screenRadius = phoneWidth * 0.105
        let bezelWidth: CGFloat = isPad ? 12 : 10
        let scale = phoneWidth / MarketingPhoneMetrics.contentWidth

        ZStack {
            RoundedRectangle(cornerRadius: screenRadius + 6, style: .continuous)
                .fill(MarketingBrandPalette.bezel)
                .frame(width: phoneWidth + bezelWidth, height: phoneHeight + bezelWidth)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 14)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            RoundedRectangle(cornerRadius: screenRadius, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(width: phoneWidth, height: phoneHeight)
                .overlay {
                    content()
                        .frame(
                            width: MarketingPhoneMetrics.contentWidth,
                            height: MarketingPhoneMetrics.contentHeight
                        )
                        .scaleEffect(scale, anchor: .top)
                        .frame(width: phoneWidth, height: phoneHeight, alignment: .top)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
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
        .padding(.bottom, isPad ? 0 : -16)
    }
}
