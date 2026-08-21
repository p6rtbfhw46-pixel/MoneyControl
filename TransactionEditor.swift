//
//  TransactionEditor.swift
//  MoneyControl
//

import SwiftData
import SwiftUI

struct TransactionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""

    let request: TransactionEditorRequest

    @State private var title = ""
    @State private var day = 1
    @State private var amountValue = 0.0
    @State private var expenseCategory: ExpenseCategory?
    @State private var expenseName = ""
    @State private var selectedRecurrenceType: RecurrenceType = .monthly
    @State private var recurrenceMonth = Calendar.current.component(.month, from: Date())
    @State private var hasEndDate = false
    @State private var endMonth = Calendar.current.component(.month, from: Date())
    @State private var endYear = Calendar.current.component(.year, from: Date())
    @State private var showsDayPicker = false
    @State private var validationMessage: String?
    @State private var markExpenseAsPaid = false
    @State private var didLoad = false
    @State private var showsSingleMonthRecurringEditInfo = false
    @State private var hasConfirmedSingleMonthRecurringEditInfo = false
    @State private var showsValueBelowPaidConfirmation = false
    @State private var hasConfirmedValueBelowPaid = false
    @State private var selectedCreditID: UUID?
    @State private var selectedSavingID: UUID?
    @State private var selectedTransactionDate = Date()

    private var mode: TransactionEditorMode { request.mode }
    private var editedTransaction: MoneyTransaction? { request.transaction }
    private var pickerMonth: Date { Date.monthStart(forMonthNumber: recurrenceMonth) }
    private var endYearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 30))
    }
    private var selectedEndMonthStart: Date {
        Date.monthStart(month: endMonth, year: endYear)
    }
    private var isSingleMonthRecurringEdit: Bool {
        request.editScope == .singleMonth && editedTransaction?.isRecurring == true
    }
    private var canMarkExpenseAsPaid: Bool {
        mode == .expense && editedTransaction == nil
    }
    private var activeCreditAccounts: [CreditAccount] {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    private var shouldShowCreditPicker: Bool {
        mode.needsExpenseClassification
            && expenseCategory == .savingsAndDebt
            && isDebtAmortizationExpense
            && !activeCreditAccounts.isEmpty
    }
    private var activeSavingAccounts: [SavingAccount] {
        savingAccounts
            .filter { $0.savingStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    private var shouldShowSavingPicker: Bool {
        mode.needsExpenseClassification
            && expenseCategory == .savingsAndDebt
            && isSavingExpense
            && !activeSavingAccounts.isEmpty
    }
    private var isDebtAmortizationExpense: Bool {
        let normalizedName = normalizedExpenseName
        return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
    }
    private var isSavingExpense: Bool {
        let normalizedName = normalizedExpenseName
        return normalizedName.contains("poup") || normalizedName.contains("saving")
    }
    private var normalizedExpenseName: String {
        expenseName
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
    private var paidAmountForEditedMonth: Double {
        guard mode.needsExpenseClassification, let editedTransaction else { return 0 }
        return payments
            .first { $0.transactionID == editedTransaction.id && Calendar.current.isDate($0.monthStart, equalTo: request.month, toGranularity: .month) }
            .flatMap(\.amountPaid) ?? 0
    }
    private var canMoveEditedExpenseDate: Bool {
        mode.needsExpenseClassification && editedTransaction != nil && (mode == .expense || request.editScope == .singleMonth)
    }
    private var selectedExpenseMonthStart: Date {
        canMoveEditedExpenseDate ? selectedTransactionDate.monthStart : request.month.monthStart
    }
    private var selectedExpenseDay: Int {
        canMoveEditedExpenseDate ? Calendar.current.component(.day, from: selectedTransactionDate) : day
    }
    private var expenseCategoryBinding: Binding<ExpenseCategory?> {
        Binding(
            get: { expenseCategory },
            set: { newCategory in
                if expenseCategory != newCategory {
                    expenseName = ""
                    selectedCreditID = nil
                    selectedSavingID = nil
                }
                expenseCategory = newCategory
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(request.titleOverride ?? mode.navigationTitle(isEditing: editedTransaction != nil))
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, validationMessage == nil ? 10 : 6)

                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Form {
                if mode.needsExpenseClassification {
                    Section(AppStrings.text(.classification)) {
                        HStack(spacing: 10) {
                            Text(AppStrings.text(.category503020))
                                .font(.subheadline.bold())
                                .foregroundStyle(AppPalette.background)

                            HelpIconButton(
                                title: AppStrings.text(.rule503020Title),
                                message: AppStrings.text(.rule503020Help)
                            )

                            Spacer()
                        }

                        ExpenseCategorySegmentedPicker(selection: expenseCategoryBinding)

                        Picker(AppStrings.text(.expenseType), selection: $expenseName) {
                            Text(AppStrings.text(.select)).tag("")
                            ForEach(expenseCategory?.names ?? [], id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .font(.headline)
                        .tint(AppPalette.background)
                        .disabled(expenseCategory == nil)

                        if shouldShowCreditPicker {
                            HStack(spacing: 10) {
                                Picker(CreditStrings.text(.credit), selection: $selectedCreditID) {
                                    Text(CreditStrings.text(.selectCredit)).tag(nil as UUID?)
                                    ForEach(activeCreditAccounts) { credit in
                                        Text(credit.name).tag(credit.id as UUID?)
                                    }
                                }
                                .tint(AppPalette.background)

                                HelpIconButton(
                                    title: AppStrings.text(.linkedTrackingOptionalHelpTitle),
                                    message: AppStrings.text(.linkedTrackingOptionalHelpMessage)
                                )
                            }
                        }

                        if shouldShowSavingPicker {
                            HStack(spacing: 10) {
                                Picker(SavingsStrings.text(.saving), selection: $selectedSavingID) {
                                    Text(SavingsStrings.text(.selectSaving)).tag(nil as UUID?)
                                    ForEach(activeSavingAccounts) { saving in
                                        Text(saving.name).tag(saving.id as UUID?)
                                    }
                                }
                                .tint(AppPalette.background)

                                HelpIconButton(
                                    title: AppStrings.text(.linkedTrackingOptionalHelpTitle),
                                    message: AppStrings.text(.linkedTrackingOptionalHelpMessage)
                                )
                            }
                        }
                    }
                    .listRowBackground(AppPalette.surface)
                }

                if mode == .monthlyExpense || mode == .salary {
                    Section(AppStrings.text(.recurrence)) {
                        if isSingleMonthRecurringEdit {
                            recurrenceSettingsOnlyMessage
                        } else {
                            Picker(AppStrings.text(.periodicity), selection: $selectedRecurrenceType) {
                                ForEach(RecurrenceType.selectableCases) { recurrence in
                                    Text(recurrence.title).tag(recurrence)
                                }
                            }
                            .tint(AppPalette.primary)

                            if mode == .monthlyExpense {
                                Toggle(AppStrings.text(.endDate), isOn: $hasEndDate)
                                    .tint(AppPalette.primary)

                                if hasEndDate {
                                    Picker(AppStrings.text(.month), selection: $endMonth) {
                                        ForEach(1...12, id: \.self) { month in
                                            Text(Date.monthName(forMonthNumber: month)).tag(month)
                                        }
                                    }
                                    .tint(AppPalette.primary)

                                    Picker(AppStrings.text(.year), selection: $endYear) {
                                        ForEach(endYearRange, id: \.self) { year in
                                            Text("\(year)").tag(year)
                                        }
                                    }
                                    .tint(AppPalette.primary)
                                } else {
                                    LabeledContent(AppStrings.text(.endDate), value: AppStrings.text(.noEndDate))
                                }
                            }
                        }
                    }
                    .listRowBackground(AppPalette.surface)
                }

                if mode == .periodicExpense {
                    Section(AppStrings.text(.recurrence)) {
                        if isSingleMonthRecurringEdit {
                            recurrenceSettingsOnlyMessage
                        } else {
                            Picker(AppStrings.text(.month), selection: $recurrenceMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(Date.monthName(forMonthNumber: month)).tag(month)
                                }
                            }
                            .tint(AppPalette.primary)
                        }
                    }
                    .listRowBackground(AppPalette.surface)
                }

                Section {
                    TextField(
                        "",
                        text: $title,
                        prompt: Text(mode.needsExpenseClassification ? AppStrings.text(.freeText) : AppStrings.text(.name))
                            .foregroundStyle(AppPalette.background.opacity(0.65))
                    )
                    .foregroundStyle(AppPalette.background)
                    .tint(AppPalette.primary)

                    Button {
                        showsDayPicker = true
                    } label: {
                        HStack {
                            Text(AppStrings.text(.day))
                            Spacer()
                            Text(daySelectionText)
                                .foregroundStyle(AppPalette.mutedText)
                        }
                    }
                    .foregroundStyle(AppPalette.background)

                    MoneyAmountPicker(
                        title: AppStrings.text(.value),
                        amount: $amountValue,
                        maximumAmount: 1_000_000,
                        onConfirm: save
                    )
                } header: {
                    HStack(spacing: 12) {
                        Text(mode.sectionTitle)

                        Spacer()

                        if canMarkExpenseAsPaid {
                            HStack(spacing: 8) {
                                Toggle(isOn: $markExpenseAsPaid) {
                                    Text(markExpenseAsPaid ? AppStrings.text(.paidExpense) : AppStrings.text(.unpaidExpense))
                                        .font(.caption.weight(.semibold))
                                }
                                .toggleStyle(.switch)
                                .tint(AppPalette.primary)
                                .fixedSize()

                                HelpIconButton(
                                    title: AppStrings.text(.paidToggleHelpTitle),
                                    message: AppStrings.text(.paidToggleHelpMessage)
                                )
                            }
                        }
                    }
                }
                .listRowBackground(AppPalette.surface)

                }
                .scrollContentBackground(.hidden)
                .background(AppPalette.appBackground)
            }
            .animation(.snappy, value: validationMessage)
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.background)
            .background(AppPalette.appBackground)
            .navigationTitle("")
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.save), action: save)
                }
            }
            .sheet(isPresented: $showsDayPicker) {
                if canMoveEditedExpenseDate {
                    TransactionDatePicker(selectedDate: $selectedTransactionDate)
                } else {
                    DayPicker(month: mode == .periodicExpense ? pickerMonth : request.month, selectedDay: $day)
                }
            }
            .alert("Editar apenas este mês", isPresented: $showsSingleMonthRecurringEditInfo) {
                Button(AppStrings.text(.ok)) {
                    hasConfirmedSingleMonthRecurringEditInfo = true
                    save()
                }
            } message: {
                Text(singleMonthRecurringEditMessage)
            }
            .alert(AppStrings.text(.valueBelowPaidTitle), isPresented: $showsValueBelowPaidConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.ok)) {
                    hasConfirmedValueBelowPaid = true
                    amountValue = paidAmountForEditedMonth
                    save()
                }
            } message: {
                Text(AppStrings.text(.valueBelowPaidMessage))
            }
            .onAppear(perform: loadInitialValues)
            .id(selectedCurrencyCode)
        }
    }

    private var parsedValue: Double? {
        amountValue > 0 ? amountValue : nil
    }

    private var daySelectionText: String {
        if canMoveEditedExpenseDate {
            let formatter = DateFormatter()
            formatter.locale = SpendWiseRegionalFormat.locale
            formatter.calendar = SpendWiseRegionalFormat.calendar
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: selectedTransactionDate)
        }
        return "\(day)"
    }

    private var singleMonthRecurringEditMessage: String {
        mode == .salary ? AppStrings.text(.recurringIncomeSettingsOnlyMessage) : AppStrings.text(.recurrenceSettingsOnlyMessage)
    }

    private var recurrenceSettingsOnlyMessage: some View {
        Text(singleMonthRecurringEditMessage)
            .font(.subheadline)
            .foregroundStyle(AppPalette.mutedText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 4)
    }

    private func showValidation(_ message: String) {
        validationMessage = message
    }

    private func loadInitialValues() {
        guard !didLoad else { return }
        didLoad = true

        guard let transaction = editedTransaction else {
            recurrenceMonth = Calendar.current.component(.month, from: request.month)
            day = min(Calendar.current.component(.day, from: Date()), request.month.daysInMonth)
            selectedTransactionDate = request.month.date(day: day)
            expenseCategory = request.initialExpenseCategory
            expenseName = request.initialExpenseName ?? ""
            return
        }

        title = transaction.title
        if let recurrence = transaction.recurrence {
            selectedRecurrenceType = recurrence == .yearlyMonth ? .annual : recurrence
        }
        let initialMonth = request.editScope == .singleMonth ? request.month.monthStart : transaction.monthStart.monthStart
        day = min(transaction.day, initialMonth.daysInMonth)
        selectedTransactionDate = initialMonth.date(day: day)
        amountValue = transaction.amount
        expenseCategory = ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
        expenseName = transaction.expenseName ?? ""
        selectedCreditID = transaction.linkedCreditID
        selectedSavingID = transaction.linkedSavingID
        recurrenceMonth = transaction.recurrenceMonth > 0 ? transaction.recurrenceMonth : Calendar.current.component(.month, from: transaction.monthStart)

        if let endMonthStart = transaction.recurrenceEndMonthStart?.previousMonthStart {
            hasEndDate = true
            endMonth = Calendar.current.component(.month, from: endMonthStart)
            endYear = Calendar.current.component(.year, from: endMonthStart)
        }
    }

    private func save() {
        validationMessage = nil

        if mode.needsExpenseClassification {
            guard let expenseCategory else {
                showValidation(AppStrings.text(.selectExpenseType))
                return
            }

            guard !expenseName.isEmpty else {
                showValidation(AppStrings.text(.selectExpenseName))
                return
            }

            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                showValidation(AppStrings.text(.fillFreeText))
                return
            }

            guard let parsedValue else {
                showValidation(AppStrings.text(.fillValue))
                return
            }

            if paidAmountForEditedMonth > parsedValue && !hasConfirmedValueBelowPaid {
                showsValueBelowPaidConfirmation = true
                return
            }

            if isSingleMonthRecurringEdit && !hasConfirmedSingleMonthRecurringEditInfo {
                showsSingleMonthRecurringEditInfo = true
                return
            }

            saveExpense(value: max(parsedValue, paidAmountForEditedMonth), category: expenseCategory, title: trimmedTitle)
        } else {
            let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
            guard !trimmedTitle.isEmpty else {
                showValidation(AppStrings.text(.fillName))
                return
            }

            guard let parsedValue else {
                showValidation(AppStrings.text(.fillValue))
                return
            }

            if isSingleMonthRecurringEdit && !hasConfirmedSingleMonthRecurringEditInfo {
                showsSingleMonthRecurringEditInfo = true
                return
            }

            saveIncome(value: parsedValue, title: trimmedTitle)
        }

        dismiss()
    }

    private func saveExpense(value: Double, category: ExpenseCategory, title: String) {
        let transaction = targetTransaction()
        let originalMonthStart = transaction.monthStart.monthStart
        transaction.title = title
        transaction.day = canMoveEditedExpenseDate ? selectedExpenseDay : (request.editScope == .singleMonth ? min(day, request.month.daysInMonth) : day)
        transaction.amount = value
        transaction.kind = TransactionKind.expense.rawValue
        transaction.expenseCategory = category.rawValue
        transaction.expenseName = expenseName

        if request.editScope == .singleMonth {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = nil
            transaction.recurrenceMonth = 0
            transaction.recurrenceEndMonthStart = nil
            transaction.monthStart = selectedExpenseMonthStart
        } else {
            switch mode {
            case .monthlyExpense:
                transaction.repeatsEveryMonth = selectedRecurrenceType == .monthly
                transaction.recurrenceType = selectedRecurrenceType.rawValue
                transaction.recurrenceMonth = 0
                transaction.recurrenceEndMonthStart = hasEndDate ? selectedEndMonthStart.nextMonthStart : nil
                transaction.monthStart = request.month.monthStart
            case .periodicExpense:
                transaction.repeatsEveryMonth = false
                transaction.recurrenceType = RecurrenceType.yearlyMonth.rawValue
                transaction.recurrenceMonth = recurrenceMonth
                transaction.recurrenceEndMonthStart = nil
                transaction.monthStart = request.editScope == .futureMonths ? request.month.monthStart : Date.monthStart(forMonthNumber: recurrenceMonth)
            case .expense:
                transaction.repeatsEveryMonth = false
                transaction.recurrenceType = nil
                transaction.recurrenceMonth = 0
                transaction.recurrenceEndMonthStart = nil
                transaction.monthStart = canMoveEditedExpenseDate ? selectedExpenseMonthStart : request.month.monthStart
            case .income, .salary:
                break
            }
        }

        finishSaving(transaction, originalMonthStart: originalMonthStart)
        markAsFullyPaidIfNeeded(transaction, value: value)
        syncLinkedCreditPaymentIfNeeded(transaction, value: value)
        syncLinkedSavingDepositIfNeeded(transaction, value: value)
    }

    private func saveIncome(value: Double, title: String) {
        let transaction = targetTransaction()
        transaction.title = title
        transaction.day = day
        transaction.amount = value
        transaction.kind = TransactionKind.income.rawValue
        transaction.expenseCategory = nil
        transaction.expenseName = nil

        if mode == .salary && request.editScope != .singleMonth {
            transaction.repeatsEveryMonth = selectedRecurrenceType == .monthly
            transaction.recurrenceType = selectedRecurrenceType.rawValue
        } else {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = nil
        }

        transaction.recurrenceMonth = 0
        transaction.monthStart = request.month.monthStart
        finishSaving(transaction)
    }

    private func targetTransaction() -> MoneyTransaction {
        if let editedTransaction, request.editScope == .normal {
            return editedTransaction
        }

        return MoneyTransaction(
            title: "",
            day: day,
            monthStart: canMoveEditedExpenseDate ? selectedExpenseMonthStart : request.month.monthStart,
            amount: 0,
            kind: mode.needsExpenseClassification ? TransactionKind.expense.rawValue : TransactionKind.income.rawValue
        )
    }

    private func finishSaving(_ transaction: MoneyTransaction, originalMonthStart: Date? = nil) {
        switch request.editScope {
        case .normal:
            if editedTransaction == nil {
                modelContext.insert(transaction)
            } else if let originalMonthStart, !Calendar.current.isDate(originalMonthStart, equalTo: transaction.monthStart, toGranularity: .month) {
                movePaymentsAndHistory(for: transaction, from: originalMonthStart, to: transaction.monthStart)
            }
        case .singleMonth:
            if let editedTransaction {
                let paymentToTransfer = payment(for: editedTransaction, in: request.month)
                let historyToTransfer = paymentHistoryEntries(for: editedTransaction, in: request.month)
                addExclusion(for: editedTransaction, in: request.month)
                deletePayments(for: editedTransaction, from: request.month, onlySameMonth: true)
                deletePaymentHistory(for: editedTransaction, from: request.month, onlySameMonth: true)
                transferPayment(paymentToTransfer, history: historyToTransfer, to: transaction, in: transaction.monthStart)
            }
            modelContext.insert(transaction)
        case .futureMonths:
            if let editedTransaction {
                editedTransaction.recurrenceEndMonthStart = request.month.monthStart
                deletePayments(for: editedTransaction, from: request.month, onlySameMonth: false)
                deletePaymentHistory(for: editedTransaction, from: request.month, onlySameMonth: false)
            }
            modelContext.insert(transaction)
        }
    }

    private func markAsFullyPaidIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        guard canMarkExpenseAsPaid, markExpenseAsPaid else { return }

        let paymentMonth = transaction.monthStart.monthStart
        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: paymentMonth, toGranularity: .month) }) {
            payment.amountPaid = value
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: paymentMonth, amountPaid: value))
        }
        modelContext.insert(PaymentHistoryEntry(transactionID: transaction.id, monthStart: paymentMonth, amount: value))
    }

    private func syncLinkedCreditPaymentIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        let shouldLinkPayment = mode.needsExpenseClassification && isDebtAmortizationExpense && selectedCreditID != nil

        guard shouldLinkPayment, let selectedCreditID else {
            deleteLinkedCreditMovementIfNeeded(for: transaction)
            transaction.linkedCreditID = nil
            transaction.linkedCreditMovementID = nil
            return
        }

        transaction.linkedCreditID = selectedCreditID

        let paidAmount = paidAmountForLinkedMovement(transaction, value: value)

        guard paidAmount > 0 else {
            deleteLinkedCreditMovementIfNeeded(for: transaction)
            transaction.linkedCreditMovementID = nil
            return
        }

        let paymentDate = transaction.monthStart.date(day: transaction.day)
        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let movementID = transaction.linkedCreditMovementID,
           let movement = creditMovements.first(where: { $0.id == movementID }) {
            movement.creditID = selectedCreditID
            movement.date = paymentDate
            movement.type = CreditMovementKind.payment.rawValue
            movement.amount = paidAmount
            movement.note = note
        } else {
            let movement = CreditMovement(
                creditID: selectedCreditID,
                date: paymentDate,
                type: CreditMovementKind.payment.rawValue,
                amount: paidAmount,
                note: note
            )
            modelContext.insert(movement)
            transaction.linkedCreditMovementID = movement.id
        }
    }

    private func deleteLinkedCreditMovementIfNeeded(for transaction: MoneyTransaction) {
        guard let movementID = transaction.linkedCreditMovementID,
              let movement = creditMovements.first(where: { $0.id == movementID })
        else { return }
        modelContext.delete(movement)
    }

    private func paidAmountForLinkedMovement(_ transaction: MoneyTransaction, value: Double) -> Double {
        if canMarkExpenseAsPaid && markExpenseAsPaid {
            return value
        }

        let paymentMonth = transaction.monthStart.monthStart
        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: paymentMonth, toGranularity: .month) }) {
            return min(payment.amountPaid ?? value, value)
        }

        if request.editScope == .singleMonth, let editedTransaction, let transferredPayment = payment(for: editedTransaction, in: request.month) {
            return min(transferredPayment.amountPaid ?? value, value)
        }

        return 0
    }

    private func syncLinkedSavingDepositIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        let shouldLinkDeposit = mode.needsExpenseClassification && isSavingExpense && selectedSavingID != nil

        guard shouldLinkDeposit, let selectedSavingID else {
            deleteLinkedSavingMovementIfNeeded(for: transaction)
            transaction.linkedSavingID = nil
            transaction.linkedSavingMovementID = nil
            return
        }

        transaction.linkedSavingID = selectedSavingID

        let paidAmount = paidAmountForLinkedMovement(transaction, value: value)

        guard paidAmount > 0 else {
            deleteLinkedSavingMovementIfNeeded(for: transaction)
            transaction.linkedSavingMovementID = nil
            return
        }

        let depositDate = transaction.monthStart.date(day: transaction.day)
        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let movementID = transaction.linkedSavingMovementID,
           let movement = savingMovements.first(where: { $0.id == movementID }) {
            movement.savingID = selectedSavingID
            movement.date = depositDate
            movement.type = SavingMovementKind.deposit.rawValue
            movement.amount = paidAmount
            movement.note = note
        } else {
            let movement = SavingMovement(
                savingID: selectedSavingID,
                date: depositDate,
                type: SavingMovementKind.deposit.rawValue,
                amount: paidAmount,
                note: note
            )
            modelContext.insert(movement)
            transaction.linkedSavingMovementID = movement.id
        }
    }

    private func deleteLinkedSavingMovementIfNeeded(for transaction: MoneyTransaction) {
        guard let movementID = transaction.linkedSavingMovementID,
              let movement = savingMovements.first(where: { $0.id == movementID })
        else { return }
        modelContext.delete(movement)
    }

    private func payment(for transaction: MoneyTransaction, in month: Date) -> ExpensePayment? {
        payments.first { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
    }

    private func paymentHistoryEntries(for transaction: MoneyTransaction, in month: Date) -> [PaymentHistoryEntry] {
        paymentHistory.filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
    }

    private func transferPayment(_ payment: ExpensePayment?, history: [PaymentHistoryEntry], to transaction: MoneyTransaction, in month: Date) {
        if let amountPaid = payment?.amountPaid, amountPaid > 0 {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: month.monthStart, amountPaid: amountPaid))
        }

        history.forEach { entry in
            let newEntry = PaymentHistoryEntry(
                transactionID: transaction.id,
                monthStart: month.monthStart,
                amount: entry.amount,
                paidAt: entry.paidAt
            )
            newEntry.id = entry.id
            modelContext.insert(newEntry)
        }
    }

    private func movePaymentsAndHistory(for transaction: MoneyTransaction, from oldMonth: Date, to newMonth: Date) {
        payments
            .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: oldMonth, toGranularity: .month) }
            .forEach { $0.monthStart = newMonth.monthStart }

        paymentHistory
            .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: oldMonth, toGranularity: .month) }
            .forEach { $0.monthStart = newMonth.monthStart }
    }

    private func addExclusion(for transaction: MoneyTransaction, in month: Date) {
        guard !exclusions.contains(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else {
            return
        }

        modelContext.insert(RecurrenceExclusion(transactionID: transaction.id, monthStart: month.monthStart))
    }

    private func deletePayments(for transaction: MoneyTransaction, from month: Date, onlySameMonth: Bool) {
        payments
            .filter { payment in
                payment.transactionID == transaction.id && (onlySameMonth
                    ? Calendar.current.isDate(payment.monthStart, equalTo: month, toGranularity: .month)
                    : payment.monthStart >= month.monthStart)
            }
            .forEach(modelContext.delete)
    }

    private func deletePaymentHistory(for transaction: MoneyTransaction, from month: Date, onlySameMonth: Bool) {
        paymentHistory
            .filter { entry in
                entry.transactionID == transaction.id && (onlySameMonth
                    ? Calendar.current.isDate(entry.monthStart, equalTo: month, toGranularity: .month)
                    : entry.monthStart >= month.monthStart)
            }
            .forEach(modelContext.delete)
    }
}

struct DayPicker: View {
    @Environment(\.dismiss) private var dismiss
    let month: Date
    @Binding var selectedDay: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(1...month.daysInMonth, id: \.self) { day in
                        Button {
                            selectedDay = day
                            dismiss()
                        } label: {
                            Text("\(day)")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(day == selectedDay ? AppPalette.background : AppPalette.surface, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(day == selectedDay ? AppPalette.surface : AppPalette.background)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8).stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()

                Spacer(minLength: 0)
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .environment(\.locale, SpendWiseRegionalFormat.locale)
            .environment(\.calendar, SpendWiseRegionalFormat.calendar)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(AppPalette.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
            }
        }
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }
}

struct TransactionDatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(AppStrings.text(.day), selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppPalette.primary)
                    .padding(.horizontal)
                    .padding(.top, 0)
                    .environment(\.locale, SpendWiseRegionalFormat.locale)
                    .environment(\.calendar, SpendWiseRegionalFormat.calendar)

                Spacer(minLength: 0)
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .environment(\.locale, SpendWiseRegionalFormat.locale)
            .environment(\.calendar, SpendWiseRegionalFormat.calendar)
            .navigationTitle(AppStrings.text(.day))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
    }
}

private struct ExpenseCategorySegmentedPicker: View {
    @Binding var selection: ExpenseCategory?

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(ExpenseCategory.allCases) { category in
                    Button {
                        select(category)
                    } label: {
                        Text(category.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(1)
                            .allowsTightening(true)
                            .padding(.horizontal, 6)
                            .foregroundStyle(selection == category ? AppPalette.surface : AppPalette.background)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background {
                                if selection == category {
                                    selectedSegmentBackground(for: category)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == category ? .isSelected : [])
                }
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        selectCategory(at: value.location.x, width: proxy.size.width)
                    }
            )
            .padding(4)
            .segmentContainerBackground()
        }
        .frame(height: 52)
    }

    @ViewBuilder
    private func selectedSegmentBackground(for category: ExpenseCategory) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Capsule()
                .fill(category.color.opacity(0.78))
                .glassEffect(.regular.tint(category.color).interactive(), in: Capsule())
        } else {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [category.color.opacity(0.92), category.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Capsule()
                        .stroke(AppPalette.surface.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: category.color.opacity(0.25), radius: 6, y: 2)
        }
    }

    private func select(_ category: ExpenseCategory) {
        withAnimation(.snappy(duration: 0.18)) {
            selection = category
        }
    }

    private func selectCategory(at locationX: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let segmentWidth = width / CGFloat(ExpenseCategory.allCases.count)
        let rawIndex = Int((locationX / segmentWidth).rounded(.down))
        let index = min(max(rawIndex, 0), ExpenseCategory.allCases.count - 1)
        let category = ExpenseCategory.allCases[index]

        guard selection != category else { return }
        select(category)
    }
}

private extension View {
    @ViewBuilder
    func segmentContainerBackground() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AppPalette.surface.opacity(0.55), lineWidth: 1)
                }
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AppPalette.surface.opacity(0.75), lineWidth: 1)
                }
                .shadow(color: AppPalette.background.opacity(0.06), radius: 8, y: 3)
        }
    }
}

private enum SpendWiseRegionalFormat {
    static var locale: Locale {
        Locale(identifier: AppStrings.currentLocaleIdentifier)
    }

    static var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = locale
        return calendar
    }
}

private extension Date {
    var regionMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = SpendWiseRegionalFormat.locale
        formatter.calendar = SpendWiseRegionalFormat.calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        let title = formatter.string(from: self)
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}
