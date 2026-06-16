import SwiftUI

struct ExpenseFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accounts: [Account]
    let categories: [Category]
    var editing: Expense?
    var onSave: (String, Double, Int, Int, String?) async throws -> Void

    @State private var date = Date()
    @State private var amountText = ""
    @State private var categoryId: Int = 0
    @State private var accountId: Int = 0
    @State private var note = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("expenses.form.date", selection: $date, displayedComponents: .date)

                TextField("expenses.form.amount", text: $amountText)
                    .keyboardType(.decimalPad)

                Picker("expenses.form.category", selection: $categoryId) {
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }

                Picker("expenses.form.account", selection: $accountId) {
                    ForEach(accounts) { acc in
                        Text(acc.name).tag(acc.id)
                    }
                }

                TextField("expenses.form.note", text: $note, axis: .vertical)
                    .lineLimit(2 ... 4)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundStyle(AppColors.danger)
                        .font(.footnote)
                }
            }
            .navigationTitle(editing == nil ? "expenses.form.title" : "expenses.form.editTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || parsedAmount == nil)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func populate() {
        if let editing {
            date = DateUtils.parseLocalISODate(editing.date) ?? Date()
            amountText = String(editing.amount)
            categoryId = editing.categoryId
            accountId = editing.accountId
            note = editing.note ?? ""
        } else {
            if let cat = categories.first { categoryId = cat.id }
            if let acc = DefaultAccountPicker.pick(from: accounts) { accountId = acc.id }
        }
    }

    private func save() async {
        guard let amount = parsedAmount else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        do {
            try await onSave(DateUtils.localISODate(from: date), amount, categoryId, accountId, note.isEmpty ? nil : note)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
