import SwiftUI

/// Add / edit account form, presented as a bottom sheet (same pattern as income & expense forms).
struct AccountFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    var editing: Account?
    /// (name, startingBalance, setAsDefault)
    var onSave: (String, Double, Bool) async throws -> Void

    @State private var name = ""
    @State private var balanceText = ""
    @State private var isDefault = false
    @State private var isSaving = false
    @State private var errorMessage = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedBalance: Double {
        Double(balanceText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("accountsPage.form.namePlaceholder", text: $name)
                }

                Section {
                    HStack {
                        Text("accountsPage.form.startingBalance")
                        Spacer()
                        TextField("0.00", text: $balanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(balanceText.isEmpty ? AppColors.muted : .primary)
                    }
                }

                Section {
                    Toggle("accountsPage.form.setDefault", isOn: $isDefault)
                        .disabled(editing?.isDefault == true)
                } footer: {
                    if editing?.isDefault == true {
                        Text("accountsPage.form.defaultLockedFooter")
                    }
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(AppColors.danger)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(editing == nil ? "accountsPage.form.addTitle" : "accountsPage.form.editTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("common.save") {
                            Task { await save() }
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                }
            }
            .onAppear(perform: populate)
        }
        .tint(AppColors.primary)
        .interactiveDismissDisabled(isSaving)
    }

    private func populate() {
        guard let editing else { return }
        name = editing.name
        isDefault = editing.isDefault
        balanceText = formatBalanceForField(editing.initialBalance)
    }

    private func formatBalanceForField(_ value: Double) -> String {
        if value == 0 { return "" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(value)
    }

    private func save() async {
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        do {
            try await onSave(trimmedName, parsedBalance, isDefault)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
