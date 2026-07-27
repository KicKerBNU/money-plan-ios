import SwiftUI

struct MarketingScreenshotCopyItem {
    let category: String
    let headline: String
    let subheadline: String?
}

/// App Store marketing copy paired with each screenshot slot.
enum MarketingScreenshotCopy {
    /// Pan pair 01 — left half of continuous phone
    static let panLeft = MarketingScreenshotCopyItem(
        category: "",
        headline: "Need clarity\non spending?",
        subheadline: nil
    )
    /// Pan pair 02 — right half continues the same phone
    static let panRight = MarketingScreenshotCopyItem(
        category: "",
        headline: "Your month,\nrevealed.",
        subheadline: nil
    )
    static let expensesHero = MarketingScreenshotCopyItem(
        category: "",
        headline: "Your personal finance app",
        subheadline: "Expenses, income, accounts & AI chat"
    )
    static let expenses = MarketingScreenshotCopyItem(
        category: "EXPENSE TRACKING",
        headline: "Track every purchase\nin seconds",
        subheadline: nil
    )
    static let income = MarketingScreenshotCopyItem(
        category: "INCOME & CASH FLOW",
        headline: "Salary, freelance,\nall in one place",
        subheadline: nil
    )
    static let chatbot = MarketingScreenshotCopyItem(
        category: "AI EXPENSE ASSISTANT",
        headline: "Ask your money\nanything",
        subheadline: nil
    )
    static let accounts = MarketingScreenshotCopyItem(
        category: "ACCOUNT OVERVIEW",
        headline: "Cash, cards &\nbank balances",
        subheadline: nil
    )
    static let login = MarketingScreenshotCopyItem(
        category: "SECURE SIGN-IN",
        headline: "Start in under\na minute",
        subheadline: nil
    )
    static let addExpense = MarketingScreenshotCopyItem(
        category: "QUICK ENTRY",
        headline: "Log an expense\nin seconds",
        subheadline: nil
    )
    static let overview = MarketingScreenshotCopyItem(
        category: "SPENDING INSIGHTS",
        headline: "Income vs expenses\nat a glance",
        subheadline: nil
    )
    static let stats = MarketingScreenshotCopyItem(
        category: "CATEGORY BREAKDOWN",
        headline: "Know where your\nmoney goes",
        subheadline: nil
    )
    static let expensesByCategory = MarketingScreenshotCopyItem(
        category: "ORGANIZE SPENDING",
        headline: "Custom categories\nwith icons",
        subheadline: nil
    )
    static let categories = MarketingScreenshotCopyItem(
        category: "ORGANIZE SPENDING",
        headline: "Custom categories\nwith icons",
        subheadline: nil
    )
    static let settings = MarketingScreenshotCopyItem(
        category: "YOUR PREFERENCES",
        headline: "Settings in one\ndedicated place",
        subheadline: nil
    )
}

/// Wraps app UI in a polished App Store marketing frame.
/// Phone size and vertical position are fixed so every slide matches.
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
            let headerH = MarketingScreenshotMetrics.headerHeight(isPad: isPad)
            let phoneW = MarketingScreenshotMetrics.phoneWidth(canvas: geo.size, isPad: isPad)
            let phoneCenterY = MarketingScreenshotMetrics.phoneCenterY(canvas: geo.size, isPad: isPad)

            ZStack {
                MarketingCanvasBackground(isPad: isPad)

                VStack(spacing: 0) {
                    marketingHeader(isPad: isPad)
                        .frame(height: headerH, alignment: .top)
                    Spacer(minLength: 0)
                }

                MarketingPhoneChrome(phoneWidth: phoneW, isPad: isPad, content: phoneContent)
                    .position(x: geo.size.width / 2, y: phoneCenterY)
            }
            .clipped()
        }
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
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, isPad ? 44 : 22)
                .padding(.top, copy.category.isEmpty ? (isPad ? 16 : 12) : (isPad ? 10 : 8))

            if let subheadline = copy.subheadline {
                Text(subheadline)
                    .font(.system(size: isPad ? 17 : 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MarketingBrandPalette.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, isPad ? 40 : 24)
                    .padding(.top, 6)
            }
        }
        .padding(.bottom, isPad ? 16 : 12)
    }
}

// MARK: - Shared phone chrome

/// Device bezel + scaled screen content. Used by upright slides and the pan pair.
struct MarketingPhoneChrome<Content: View>: View {
    let phoneWidth: CGFloat
    let isPad: Bool
    var bezelExtra: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        let phoneHeight = MarketingScreenshotMetrics.phoneHeight(phoneWidth: phoneWidth)
        let screenRadius = phoneWidth * 0.105
        let bezel = MarketingScreenshotMetrics.bezel(isPad: isPad) + bezelExtra
        let scale = phoneWidth / MarketingPhoneMetrics.contentWidth

        ZStack {
            RoundedRectangle(cornerRadius: screenRadius + 6, style: .continuous)
                .fill(MarketingBrandPalette.bezel)
                .frame(width: phoneWidth + bezel, height: phoneHeight + bezel)
                .shadow(color: .black.opacity(0.32), radius: 22, y: 14)
                .shadow(color: .black.opacity(0.10), radius: 5, y: 2)

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
        .frame(width: phoneWidth + bezel, height: phoneHeight + bezel)
    }
}
