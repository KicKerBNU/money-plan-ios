import SwiftUI

/// Disclosure + permission before the expense assistant sends data to OpenAI (Guideline 5.1.1(i)).
struct ExpenseChatConsentSheet: View {
    let onAgree: () -> Void
    let onDecline: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let privacyURL = URL(string: "https://www.moneyplann.com/privacy")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("chatbot.consent.intro")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.muted)

                    consentBlock(
                        title: "chatbot.consent.whatTitle",
                        body: "chatbot.consent.whatBody"
                    )
                    consentBlock(
                        title: "chatbot.consent.whoTitle",
                        body: "chatbot.consent.whoBody"
                    )
                    consentBlock(
                        title: "chatbot.consent.howTitle",
                        body: "chatbot.consent.howBody"
                    )

                    Button {
                        openURL(privacyURL)
                    } label: {
                        Label("chatbot.consent.privacyLink", systemImage: "hand.raised")
                            .font(.footnote.weight(.semibold))
                    }
                }
                .padding()
            }
            .navigationTitle("chatbot.consent.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("chatbot.consent.decline") {
                        onDecline()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("chatbot.consent.agree") {
                        onAgree()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func consentBlock(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(body)
                .font(.footnote)
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColors.surfaceSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Inline disclosure when the user declined or has not yet agreed.
struct ExpenseChatConsentBanner: View {
    let onAgree: () -> Void

    @Environment(\.openURL) private var openURL

    private let privacyURL = URL(string: "https://www.moneyplann.com/privacy")!

    var body: some View {
        FinanceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("chatbot.consent.title")
                    .font(.subheadline.weight(.semibold))

                Text("chatbot.consent.bannerBody")
                    .font(.footnote)
                    .foregroundStyle(AppColors.muted)

                HStack(spacing: 10) {
                    Button("chatbot.consent.agree") { onAgree() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.primary)

                    Button("chatbot.consent.privacyLink") { openURL(privacyURL) }
                        .font(.footnote.weight(.semibold))
                }
            }
        }
    }
}
