import SwiftUI

@MainActor
@Observable
final class AccountsViewModel {
    var accounts: [Account] = []
    var isLoading = true
    var errorMessage: String?

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

    func create(name: String) async throws {
        _ = try await FinanceAPI.createAccount(name: name)
        await load()
    }

    func rename(id: Int, name: String) async throws {
        _ = try await FinanceAPI.updateAccount(id: id, name: name)
        await load()
    }

    func delete(id: Int) async throws {
        try await FinanceAPI.deleteAccount(id: id)
        await load()
    }

    func moveAndSetDefault(from source: IndexSet, to destination: Int) async {
        var ordered = accounts
        ordered.move(fromOffsets: source, toOffset: destination)
        let snapshot = accounts
        accounts = ordered
        guard let first = ordered.first else { return }
        do {
            _ = try await FinanceAPI.setAccountDefault(id: first.id)
            await load()
        } catch {
            accounts = snapshot
            await load()
        }
    }
}

struct AccountsView: View {
    @Environment(MoneyPreferences.self) private var money
    @State private var viewModel = AccountsViewModel()
    @State private var newName = ""
    @State private var renaming: Account?
    @State private var renameText = ""
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsToolbar() }
            }
            .sheet(item: $renaming) { account in
                NavigationStack {
                    Form {
                        TextField("accountsPage.listTitle", text: $renameText)
                    }
                    .navigationTitle("expenses.renameModal.editAccount")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("common.cancel") { renaming = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("common.save") {
                                Task {
                                    try? await viewModel.rename(id: account.id, name: renameText)
                                    renaming = nil
                                }
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
                .onAppear { renameText = account.name }
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
            VStack(alignment: .leading, spacing: 16) {
                Text("accountsPage.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.muted)

                FinanceCard {
                    TextField("expenses.addAccount.placeholder", text: $newName)
                    Button("common.add") {
                        Task {
                            let name = newName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            try? await viewModel.create(name: name)
                            newName = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }

                FinanceCard {
                    Text("accountsPage.listTitle")
                        .font(.headline)
                    Text("accountsPage.dragHint")
                        .font(.caption)
                        .foregroundStyle(AppColors.muted)

                    if viewModel.accounts.isEmpty {
                        Text("accountsPage.empty")
                            .foregroundStyle(AppColors.muted)
                    } else {
                        List {
                            ForEach(viewModel.accounts) { account in
                                AccountRow(account: account) {
                                    renaming = account
                                } onDelete: {
                                    toDelete = account
                                }
                            }
                            .onMove { source, destination in
                                Task { await viewModel.moveAndSetDefault(from: source, to: destination) }
                            }
                        }
                        .listStyle(.plain)
                        .frame(minHeight: CGFloat(viewModel.accounts.count) * 80)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

private struct AccountRow: View {
    let account: Account
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(AppColors.muted)
                .accessibilityLabel("accountsPage.dragHandleAria")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name)
                        .font(.subheadline.weight(.semibold))
                    if account.isDefault {
                        Text("accountsPage.defaultBadge")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.primary.opacity(0.15), in: Capsule())
                    }
                }
                Text("accountsPage.balanceCaption")
                    .font(.caption)
                    .foregroundStyle(AppColors.muted)
                Text(CurrencyFormatter.format(account.currentBalance))
                    .font(.title3.weight(.bold))
            }
            Spacer()
            Menu {
                Button { onRename() } label: {
                    Label("common.edit", systemImage: "square.and.pencil")
                }
                Button(role: .destructive) { onDelete() } label: {
                    Label("common.delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(.vertical, 6)
    }
}
