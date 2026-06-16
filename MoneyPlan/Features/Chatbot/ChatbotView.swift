import SwiftUI

@MainActor
@Observable
final class ChatbotViewModel {
    var messages: [ChatMessage] = []
    var input = ""
    var isSending = false
    var errorMessage: String?

    private let loadingVerbs = ["Analyzing", "Crunching", "Summing", "Comparing", "Scanning"]

    var loadingLabel: String {
        loadingVerbs.randomElement() ?? "Thinking"
    }

    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 6000 else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        input = ""
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            let reply = try await FinanceAPI.sendChat(
                messages: messages,
                clientToday: DateUtils.localISODate()
            )
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            messages.removeAll { $0.id == userMessage.id }
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        messages.removeAll()
        errorMessage = nil
    }
}

struct ChatbotView: View {
    @State private var viewModel = ChatbotViewModel()
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("chatbot.subtitle")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.muted)
                                .padding(.bottom, 8)

                            if viewModel.messages.isEmpty {
                                FinanceCard {
                                    Text("chatbot.empty")
                                        .font(.footnote)
                                        .foregroundStyle(AppColors.muted)
                                }
                            }

                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isSending {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("\(viewModel.loadingLabel)…")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.muted)
                                }
                                .padding(.leading, 8)
                            }

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(AppColors.danger)
                            }
                        }
                        .padding()
                        // Tap anywhere in the scroll content to dismiss the keyboard
                        // and reveal the tab bar again.
                        .contentShape(Rectangle())
                        .onTapGesture { isComposerFocused = false }
                    }
                    // Standard iOS swipe-down-to-dismiss for chat scroll views.
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let last = viewModel.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                ChatComposer(
                    input: $viewModel.input,
                    isSending: viewModel.isSending,
                    focus: $isComposerFocused,
                    onSend: { Task { await viewModel.send() } }
                )
            }
            .navigationTitle("chatbot.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("chatbot.clear") { viewModel.clear() }
                        .disabled(viewModel.messages.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) { SettingsToolbar() }
                // "Done" button above the keyboard so the user always has a
                // one-tap escape back to the tab bar.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done") { isComposerFocused = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Gemini/ChatGPT-style pill composer: a rounded capsule wrapping a multi-line
/// text input and a circular send button. Chat-only (no attachments).
private struct ChatComposer: View {
    @Binding var input: String
    let isSending: Bool
    /// Focus state is owned by the parent so tap-outside / "Done" can dismiss it.
    var focus: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var trimmed: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        !trimmed.isEmpty && !isSending
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("chatbot.placeholder", text: $input, axis: .vertical)
                .lineLimit(1 ... 6)
                .textFieldStyle(.plain)
                .focused(focus)
                .submitLabel(.send)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .accessibilityLabel("chatbot.inputLabel")

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.body.weight(.bold))
                            .foregroundStyle(canSend ? Color.white : AppColors.muted)
                    }
                }
                .frame(width: 34, height: 34)
                .background(canSend ? AppColors.primary : AppColors.muted.opacity(0.25), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .padding(4)
            .accessibilityLabel("chatbot.send")
        }
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(AppColors.muted.opacity(focus.wrappedValue ? 0.35 : 0.18), lineWidth: 1)
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "chatbot.you" : "chatbot.assistant")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppColors.muted)
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? AppColors.primary.opacity(0.2) : AppColors.surfaceSoft, in: RoundedRectangle(cornerRadius: 16))
            }
            if !isUser { Spacer(minLength: 48) }
        }
    }
}
