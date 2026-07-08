import SwiftUI

struct ExpenseFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accounts: [Account]
    let categories: [Category]
    var editing: Expense?
    var linkedRecurring: RecurringExpense?
    var onSave: (String, Double, Int, Int, String?, RecurringExpenseSave?) async throws -> Void

    @State private var date = Date()
    @State private var amountText = ""
    @State private var categoryId: Int = 0
    @State private var accountId: Int = 0
    @State private var note = ""
    @State private var isRecurring = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .monthly
    @State private var loadedRecurring: RecurringExpense?
    @State private var isSaving = false
    @State private var errorMessage = ""

    private var activeRecurring: RecurringExpense? {
        linkedRecurring ?? loadedRecurring
    }

    private var showsRecurrenceSection: Bool {
        editing == nil || editing?.recurringExpenseId != nil || activeRecurring != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("expenses.form.category", selection: $categoryId) {
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }

                    DatePicker("expenses.form.date", selection: $date, displayedComponents: .date)

                    HStack {
                        Text("expenses.form.amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(amountText.isEmpty ? AppColors.muted : .primary)
                    }

                    Picker("expenses.form.account", selection: $accountId) {
                        ForEach(accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                }

                Section {
                    TextField("expenses.form.notePlaceholder", text: $note, axis: .vertical)
                        .lineLimit(1 ... 3)
                }

                if showsRecurrenceSection {
                    Section {
                        Toggle("recurring.form.isRecurring", isOn: $isRecurring)

                        if isRecurring {
                            Picker("recurring.form.frequency", selection: $recurrenceFrequency) {
                                ForEach(RecurrenceFrequency.allCases) { frequency in
                                    Text(LocalizedStringKey(frequency.localizationKey)).tag(frequency)
                                }
                            }
                        }
                    } footer: {
                        if editing != nil, isRecurring {
                            Text("recurring.form.editLinkedFooter")
                        } else if isRecurring {
                            Text("recurring.form.footer")
                        } else if editing?.recurringExpenseId != nil {
                            Text("recurring.form.stopRecurrenceHint")
                        }
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
            .task(id: editing?.recurringExpenseId) {
                await loadLinkedRecurringIfNeeded()
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func populate() {
        if let editing {
            date = DateUtils.parseLocalISODate(editing.date) ?? Date()
            amountText = formatAmountForField(editing.amount)
            categoryId = editing.categoryId
            accountId = editing.accountId
            note = editing.note ?? ""
            if let linked = linkedRecurring {
                recurrenceFrequency = linked.frequency
            }
        } else {
            if let cat = categories.first { categoryId = cat.id }
            if let acc = DefaultAccountPicker.pick(from: accounts) { accountId = acc.id }
        }
    }

    private func formatAmountForField(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(value)
    }

    private func loadLinkedRecurringIfNeeded() async {
        if let linked = linkedRecurring {
            isRecurring = linked.active
            recurrenceFrequency = linked.frequency
        }
        guard let recurringId = editing?.recurringExpenseId else { return }
        do {
            let item = try await FinanceAPI.fetchRecurringExpense(id: recurringId)
            loadedRecurring = item
            isRecurring = item.active
            recurrenceFrequency = item.frequency
        } catch {
            loadedRecurring = nil
            if editing?.recurringExpenseId != nil {
                isRecurring = false
            }
        }
    }

    private func save() async {
        guard let amount = parsedAmount else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        let recurrenceSave: RecurringExpenseSave? = {
            if editing == nil {
                return isRecurring ? RecurringExpenseSave(mode: .create(recurrenceFrequency)) : nil
            }
            guard showsRecurrenceSection else { return nil }
            return RecurringExpenseSave(
                mode: .update(
                    id: editing?.recurringExpenseId ?? activeRecurring?.id ?? 0,
                    enabled: isRecurring,
                    frequency: recurrenceFrequency
                )
            )
        }()

        do {
            try await onSave(
                DateUtils.localISODate(from: date),
                amount,
                categoryId,
                accountId,
                note.isEmpty ? nil : note,
                recurrenceSave
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
