import SwiftUI

@MainActor
@Observable
final class AccountsViewModel {
    var accounts: [Account] = []
    var isLoading = true
    var errorMessage: String?

    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.currentBalance }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            accounts = try await FinanceAPI.fetchAccounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, initialBalance: Double, setDefault: Bool) async throws {
        let account = try await FinanceAPI.createAccount(
            name: name,
            initialBalance: initialBalance == 0 ? nil : initialBalance
        )
        if setDefault {
            _ = try await FinanceAPI.setAccountDefault(id: account.id)
        }
        await load()
    }

    func update(id: Int, name: String, initialBalance: Double, setDefault: Bool) async throws {
        _ = try await FinanceAPI.updateAccount(id: id, name: name, initialBalance: initialBalance)
        if setDefault {
            _ = try await FinanceAPI.setAccountDefault(id: id)
        }
        await load()
    }

    func delete(id: Int) async throws {
        try await FinanceAPI.deleteAccount(id: id)
        await load()
    }
}

struct AccountsView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = AccountsViewModel()
    @State private var showAddSheet = false
    @State private var editingAccount: Account?
    @State private var toDelete: Account?

    var body: some View {
        let _ = money.activeCurrency
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else {
                    content
                }
            }
            .navigationTitle("accountsPage.title")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddAndSettingsToolbar(addAccessibilityLabel: "accountsPage.actions.addAccount") {
                        showAddSheet = true
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AccountFormSheet { name, balance, setDefault in
                    try await viewModel.create(name: name, initialBalance: balance, setDefault: setDefault)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingAccount) { account in
                AccountFormSheet(editing: account) { name, balance, setDefault in
                    try await viewModel.update(
                        id: account.id,
                        name: name,
                        initialBalance: balance,
                        setDefault: setDefault
                    )
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "expenses.confirmDelete.accountTitle",
                isPresented: Binding(get: { toDelete != nil }, set: { if !$0 { toDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("common.delete", role: .destructive) {
                    if let account = toDelete {
                        Task { try? await viewModel.delete(id: account.id) }
                    }
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("expenses.confirmDelete.accountBody")
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.accounts.isEmpty {
                    FinanceCard {
                        EmptyStateView(
                            title: "accountsPage.empty.title",
                            message: "accountsPage.empty.body",
                            actionTitle: "accountsPage.actions.addAccount"
                        ) {
                            showAddSheet = true
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    cardsCarousel
                    allAccountsSection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Cards carousel

    /// 1 account: card proportions preserved (~60% width). 2: split the row. 3+: scroll horizontally.
    @ViewBuilder
    private var cardsCarousel: some View {
        if viewModel.accounts.count == 1, let account = viewModel.accounts.first {
            HStack {
                AccountCard(account: account, isFlexible: true)
                    .frame(maxWidth: 230)
                    .onTapGesture { editingAccount = account }
                    .contextMenu { rowMenu(for: account) }

                Spacer(minLength: 0)
            }
        } else if viewModel.accounts.count == 2 {
            HStack(spacing: 12) {
                ForEach(viewModel.accounts) { account in
                    AccountCard(account: account, isFlexible: true)
                        .onTapGesture { editingAccount = account }
                        .contextMenu { rowMenu(for: account) }
                }
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.accounts) { account in
                        AccountCard(account: account, isFlexible: false)
                            .onTapGesture { editingAccount = account }
                            .contextMenu { rowMenu(for: account) }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    // MARK: - All accounts list

    private var allAccountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("accountsPage.allAccounts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.muted)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.leading, 4)

            FinanceCard {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
                        if index > 0 {
                            Divider()
                                .padding(.leading, 52)
                        }

                        AccountRow(account: account)
                            .contentShape(Rectangle())
                            .onTapGesture { editingAccount = account }
                            .contextMenu { rowMenu(for: account) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowMenu(for account: Account) -> some View {
        Button {
            editingAccount = account
        } label: {
            Label("common.edit", systemImage: "square.and.pencil")
        }

        Button(role: .destructive) {
            toDelete = account
        } label: {
            Label("common.delete", systemImage: "trash")
        }
    }
}

// MARK: - Carousel card

private struct AccountCard: View {
    let account: Account
    /// Flexible cards stretch to share the row (1–2 accounts); fixed cards scroll in the carousel.
    var isFlexible = false
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    /// Diagonal metallic sheen (light silver / dark charcoal) matching the design mockup.
    private var metallicGradient: LinearGradient {
        let stops: [Gradient.Stop] = isDark
            ? [
                .init(color: Color(white: 0.32), location: 0.0),
                .init(color: Color(white: 0.17), location: 0.38),
                .init(color: Color(white: 0.08), location: 0.62),
                .init(color: Color(white: 0.15), location: 1.0),
            ]
            : [
                .init(color: Color(white: 0.97), location: 0.0),
                .init(color: Color(white: 0.84), location: 0.38),
                .init(color: Color(white: 0.72), location: 0.62),
                .init(color: Color(white: 0.88), location: 1.0),
            ]
        return LinearGradient(stops: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var tileBackground: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var badgeBackground: Color {
        isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.82)
    }

    private var badgeForeground: Color {
        .white
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: AccountIcon.symbol(for: account.name))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isDark ? .white : .black)
                    .frame(width: 34, height: 34)
                    .background(tileBackground, in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                Spacer(minLength: 8)

                if account.isDefault {
                    Text("accountsPage.defaultBadge")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(badgeForeground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(badgeBackground, in: Capsule())
                }
            }

            Spacer(minLength: 20)

            Text(account.name)
                .font(.footnote)
                .foregroundStyle(isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.55))
                .lineLimit(1)

            Text(CurrencyFormatter.format(account.currentBalance))
                .font(.title3.weight(.bold))
                .foregroundStyle(isDark ? .white : .black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: isFlexible ? .infinity : nil, alignment: .topLeading)
        .frame(width: isFlexible ? nil : 190, height: 148, alignment: .topLeading)
        .background(metallicGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isDark
                            ? [Color.white.opacity(0.22), Color.white.opacity(0.04)]
                            : [Color.white.opacity(0.9), Color.black.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(isDark ? 0.4 : 0.12), radius: 10, y: 6)
    }
}

// MARK: - List row

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AccountIconView(name: account.name)

            HStack(spacing: 6) {
                Text(account.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)

                if account.isDefault {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColors.primary)
                        .accessibilityLabel("accountsPage.defaultBadge")
                }
            }

            Spacer(minLength: 8)

            Text(CurrencyFormatter.format(account.currentBalance))
                .font(.body.weight(.semibold))
                .foregroundStyle(account.currentBalance < 0 ? AppColors.danger : .primary)
        }
        .padding(.vertical, 10)
    }
}
