import SwiftUI

/// App Store Connect **6.5"** accepted preview size (portrait). Not the same as screenshot pixels.
enum AppPreviewSpec {
    static let width: CGFloat = 886
    static let height: CGFloat = 1920
    static let fps = 30
    static let durationSeconds = 20.0
    static var frameCount: Int { Int(durationSeconds * Double(fps)) }
}

enum AppPreviewID: Int, CaseIterable {
    case trackSpending = 1
    case incomeAndAccounts = 2
    case aiAssistant = 3

    var outputFilename: String {
        switch self {
        case .trackSpending: "preview-01-track-spending"
        case .incomeAndAccounts: "preview-02-income-accounts"
        case .aiAssistant: "preview-03-ai-assistant"
        }
    }
}

/// Renders a single App Preview frame (886×1920) for export via `ImageRenderer` + ffmpeg.
struct MarketingAppPreviewFrame: View {
    let preview: AppPreviewID
    let frameIndex: Int

    private var progress: Double {
        Double(frameIndex) / Double(AppPreviewSpec.frameCount)
    }

    var body: some View {
        Group {
            switch preview {
            case .trackSpending:
                trackSpendingFrame
            case .incomeAndAccounts:
                incomeAndAccountsFrame
            case .aiAssistant:
                MarketingChatbotAnimatedScreenshot(progress: progress)
            }
        }
        .frame(width: AppPreviewSpec.width, height: AppPreviewSpec.height)
        .clipped()
        .preferredColorScheme(.light)
        .tint(AppColors.primary)
    }

    // MARK: - Preview 1: Expenses → filters → stats

    @ViewBuilder
    private var trackSpendingFrame: some View {
        tripleCrossfade(
            segments: [
                AnyView(MarketingExpensesScreenshot()),
                AnyView(MarketingExpensesByCategoryScreenshot()),
                AnyView(MarketingStatsScreenshot()),
            ]
        )
    }

    // MARK: - Preview 2: Income → accounts → overview

    @ViewBuilder
    private var incomeAndAccountsFrame: some View {
        tripleCrossfade(
            segments: [
                AnyView(MarketingIncomeScreenshot()),
                AnyView(MarketingAccountsScreenshot()),
                AnyView(MarketingOverviewScreenshot()),
            ]
        )
    }

    /// Three equal beats (~6.2s each) with a 0.5s crossfade — total 20s, first frame is in-app UI.
    @ViewBuilder
    private func tripleCrossfade(segments: [AnyView]) -> some View {
        let t = Double(frameIndex) / Double(AppPreviewSpec.fps)
        let segmentLength = AppPreviewSpec.durationSeconds / Double(segments.count)
        let fade = 0.5
        let index = min(Int(t / segmentLength), segments.count - 1)
        let local = t - Double(index) * segmentLength
        let blend = local > (segmentLength - fade) ? (local - (segmentLength - fade)) / fade : 0
        let next = (index + 1) % segments.count

        if blend <= 0.001 {
            segments[index]
        } else {
            ZStack {
                segments[index].opacity(1 - blend)
                segments[next].opacity(blend)
            }
        }
    }
}

// MARK: - Preview 3: animated chat

struct MarketingChatbotAnimatedScreenshot: View {
    let progress: Double

    private let userText = "How much did I spend on food this month?"
    private let assistantText =
        "You've spent €113.60 on Food in June across 2 entries — groceries (€45.20) and dinner out (€68.40)."

    var body: some View {
        MarketingScreenshotShell(tab: .chat) {
            VStack(spacing: 0) {
                MarketingNavBar(title: "chatbot.title") {
                    Text("chatbot.clear")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.muted)
                } trailing: {
                    MarketingToolbarGear()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("chatbot.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.muted)
                        .padding(.bottom, 8)

                    if visibleUserCount > 0 {
                        MarketingAnimatedChatBubble(
                            role: .user,
                            content: String(userText.prefix(visibleUserCount))
                        )
                    }

                    if visibleAssistantCount > 0 {
                        MarketingAnimatedChatBubble(
                            role: .assistant,
                            content: String(assistantText.prefix(visibleAssistantCount))
                        )
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                MarketingChatComposer()
            }
        }
    }

    private var visibleUserCount: Int {
        let start = 0.12
        let end = 0.38
        guard progress >= start else { return 0 }
        guard progress <= end else { return userText.count }
        let t = (progress - start) / (end - start)
        return Int(Double(userText.count) * t)
    }

    private var visibleAssistantCount: Int {
        let start = 0.48
        let end = 0.92
        guard progress >= start else { return 0 }
        guard progress <= end else { return assistantText.count }
        let t = (progress - start) / (end - start)
        return Int(Double(assistantText.count) * t)
    }
}

private struct MarketingAnimatedChatBubble: View {
    let role: ChatRole
    let content: String

    private var isUser: Bool { role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "chatbot.you" : "chatbot.assistant")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColors.muted)
                Text(content)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: RoundedRectangle(cornerRadius: 16))
            }
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

/// Exposed for the chat composer in animated preview.
struct MarketingChatComposer: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text("Ask about your spending…")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "arrow.up")
                .font(.body.weight(.bold))
                .foregroundStyle(AppColors.muted)
                .frame(width: 34, height: 34)
                .background(AppColors.muted.opacity(0.25), in: Circle())
                .padding(4)
        }
        .background(Capsule(style: .continuous).fill(.regularMaterial))
        .overlay(Capsule(style: .continuous).strokeBorder(AppColors.muted.opacity(0.18), lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
