import SwiftUI

struct IncomeFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accounts: [Account]
    var editing: IncomeEntry?
    var linkedRecurring: RecurringIncome?
    var onSave: (String, Double, Int, String?, RecurringIncomeSave?) async throws -> Void

    @State private var date = Date()
    @State private var amountText = ""
    @State private var accountId: Int = 0
    @State private var note = ""
    @State private var isRecurring = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .monthly
    @State private var loadedRecurring: RecurringIncome?
    @State private var isSaving = false
    @State private var errorMessage = ""

    private var activeRecurring: RecurringIncome? {
        loadedRecurring ?? linkedRecurring
    }

    private var resolvedRecurringId: Int? {
        editing?.recurringIncomeId ?? activeRecurring?.id ?? linkedRecurring?.id
    }

    private var hasExistingRecurrenceLink: Bool {
        resolvedRecurringId != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("income.form.date", selection: $date, displayedComponents: .date)

                    HStack {
                        Text("income.form.amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(amountText.isEmpty ? AppColors.muted : .primary)
                    }

                    if accounts.isEmpty {
                        LabeledContent("income.form.account") {
                            Text("—")
                                .foregroundStyle(AppColors.muted)
                        }
                    } else {
                        Picker("income.form.account", selection: $accountId) {
                            ForEach(accounts) { acc in
                                Text(acc.name).tag(acc.id)
                            }
                        }
                    }
                }

                Section {
                    TextField("income.form.notePlaceholder", text: $note, axis: .vertical)
                        .lineLimit(1 ... 3)
                }

                Section {
                    Toggle("recurringIncome.form.isRecurring", isOn: $isRecurring)

                    if isRecurring {
                        Picker("recurring.form.frequency", selection: $recurrenceFrequency) {
                            ForEach(RecurrenceFrequency.allCases) { frequency in
                                Text(LocalizedStringKey(frequency.localizationKey)).tag(frequency)
                            }
                        }
                    }
                } footer: {
                    if editing != nil, isRecurring {
                        Text("recurringIncome.form.editLinkedFooter")
                    } else if isRecurring {
                        Text("recurringIncome.form.footer")
                    } else if hasExistingRecurrenceLink {
                        Text("recurringIncome.form.stopRecurrenceHint")
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
            .navigationTitle(editing == nil ? "income.form.addTitle" : "income.form.editTitle")
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
                        .disabled(parsedAmount == nil || accountId <= 0)
                    }
                }
            }
            .task(id: editing?.id) {
                populateFormFields()
                await loadLinkedRecurringIfNeeded()
            }
            // Accounts can finish loading after the sheet is presented — backfill
            // the selection so the picker never holds an invalid tag.
            .onChange(of: accounts) {
                if !accounts.contains(where: { $0.id == accountId }) {
                    accountId = DefaultAccountPicker.pick(from: accounts)?.id ?? 0
                }
            }
        }
        .tint(AppColors.primary)
        .interactiveDismissDisabled(isSaving)
    }

    private var parsedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func populateFormFields() {
        guard let editing else {
            amountText = ""
            if let acc = DefaultAccountPicker.pick(from: accounts) {
                accountId = acc.id
            }
            return
        }

        date = DateUtils.parseLocalISODate(editing.date) ?? Date()
        amountText = formatAmountForField(editing.amount)
        note = editing.note ?? ""

        if let aid = editing.accountId, aid > 0 {
            accountId = aid
        } else if let acc = DefaultAccountPicker.pick(from: accounts) {
            accountId = acc.id
        }
    }

    private func formatAmountForField(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(value)
    }

    private func loadLinkedRecurringIfNeeded() async {
        if let hint = linkedRecurring {
            recurrenceFrequency = hint.frequency
            isRecurring = hint.active
        } else if editing?.recurringIncomeId != nil {
            isRecurring = true
        }

        guard let recurringId = resolvedRecurringId ?? linkedRecurring?.id else { return }

        do {
            let item = try await FinanceAPI.fetchRecurringIncome(id: recurringId)
            loadedRecurring = item
            isRecurring = item.active
            recurrenceFrequency = item.frequency
        } catch {
            if let fallback = linkedRecurring ?? loadedRecurring {
                loadedRecurring = fallback
                isRecurring = fallback.active
                recurrenceFrequency = fallback.frequency
            } else {
                loadedRecurring = nil
                isRecurring = true
            }
        }
    }

    private func save() async {
        guard let amount = parsedAmount, accountId > 0 else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }

        let recurrenceSave: RecurringIncomeSave? = {
            if editing == nil {
                return isRecurring ? RecurringIncomeSave(mode: .create(recurrenceFrequency)) : nil
            }

            if isRecurring {
                if let existingId = resolvedRecurringId {
                    return RecurringIncomeSave(
                        mode: .update(
                            id: existingId,
                            enabled: true,
                            frequency: recurrenceFrequency
                        )
                    )
                }
                return RecurringIncomeSave(mode: .create(recurrenceFrequency))
            }

            if hasExistingRecurrenceLink, let existingId = resolvedRecurringId {
                return RecurringIncomeSave(
                    mode: .update(
                        id: existingId,
                        enabled: false,
                        frequency: recurrenceFrequency
                    )
                )
            }

            return nil
        }()

        do {
            try await onSave(
                DateUtils.localISODate(from: date),
                amount,
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
