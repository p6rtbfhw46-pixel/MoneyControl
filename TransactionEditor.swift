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
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""

    let request: TransactionEditorRequest

    @State private var title = ""
    @State private var day = 1
    @State private var amountValue = 0.0
    @State private var expenseCategory: ExpenseCategory?
    @State private var expenseName = ""
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
    @State private var selectedCreditID: UUID?

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
        mode == .expense
            && expenseCategory == .savingsAndDebt
            && isDebtAmortizationExpense
            && !activeCreditAccounts.isEmpty
    }
    private var isDebtAmortizationExpense: Bool {
        let normalizedName = expenseName
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
        return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
    }
    private var expenseCategoryBinding: Binding<ExpenseCategory?> {
        Binding(
            get: { expenseCategory },
            set: { newCategory in
                if expenseCategory != newCategory {
                    expenseName = ""
                }
                expenseCategory = newCategory
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(mode.navigationTitle(isEditing: editedTransaction != nil))
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

                        Picker(AppStrings.text(.category503020), selection: expenseCategoryBinding) {
                            ForEach(ExpenseCategory.allCases) { category in
                                Text(category.title).tag(category as ExpenseCategory?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(AppPalette.background)

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
                            Picker(CreditStrings.text(.credit), selection: $selectedCreditID) {
                                Text(CreditStrings.text(.selectCredit)).tag(nil as UUID?)
                                ForEach(activeCreditAccounts) { credit in
                                    Text(credit.name).tag(credit.id as UUID?)
                                }
                            }
                            .tint(AppPalette.background)
                        }
                    }
                    .listRowBackground(AppPalette.surface)
                }

                if mode == .monthlyExpense {
                    Section(AppStrings.text(.recurrence)) {
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
                    .disabled(isSingleMonthRecurringEdit)
                    .listRowBackground(AppPalette.surface)
                }

                if mode == .periodicExpense {
                    Section(AppStrings.text(.recurrence)) {
                        Picker(AppStrings.text(.month), selection: $recurrenceMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(Date.monthName(forMonthNumber: month)).tag(month)
                            }
                        }
                        .tint(AppPalette.primary)
                    }
                    .disabled(isSingleMonthRecurringEdit)
                    .listRowBackground(AppPalette.surface)
                }

                if isSingleMonthRecurringEdit {
                    Text("Está a editar apenas o registo deste mês. Para alterar todos os meses desta despesa recorrente, utilize as Configurações.")
                        .font(.footnote)
                        .foregroundStyle(AppPalette.mutedText)
                        .listRowBackground(AppPalette.appBackground)
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
                            Text("\(day)")
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
                            Toggle(isOn: $markExpenseAsPaid) {
                                Text(markExpenseAsPaid ? AppStrings.text(.paidExpense) : AppStrings.text(.unpaidExpense))
                                    .font(.caption.weight(.semibold))
                            }
                            .toggleStyle(.switch)
                            .tint(AppPalette.primary)
                            .fixedSize()
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
                DayPicker(month: mode == .periodicExpense ? pickerMonth : request.month, selectedDay: $day)
            }
            .alert("Editar apenas este mês", isPresented: $showsSingleMonthRecurringEditInfo) {
                Button(AppStrings.text(.ok)) {
                    hasConfirmedSingleMonthRecurringEditInfo = true
                    save()
                }
            } message: {
                Text("Está a editar apenas o registo deste mês. Para alterar todos os meses desta despesa recorrente, utilize as Configurações.")
            }
            .onAppear(perform: loadInitialValues)
            .id(selectedCurrencyCode)
        }
    }

    private var parsedValue: Double? {
        amountValue > 0 ? amountValue : nil
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
            return
        }

        title = transaction.title
        day = transaction.day
        amountValue = transaction.amount
        expenseCategory = ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
        expenseName = transaction.expenseName ?? ""
        selectedCreditID = transaction.linkedCreditID
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

            guard let parsedValue else {
                showValidation(AppStrings.text(.fillValue))
                return
            }

            if isSingleMonthRecurringEdit && !hasConfirmedSingleMonthRecurringEditInfo {
                showsSingleMonthRecurringEditInfo = true
                return
            }

            saveExpense(value: parsedValue, category: expenseCategory)
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

            saveIncome(value: parsedValue, title: trimmedTitle)
        }

        dismiss()
    }

    private func saveExpense(value: Double, category: ExpenseCategory) {
        let transaction = targetTransaction()
        transaction.title = title.trimmingCharacters(in: .whitespaces)
        transaction.day = request.editScope == .singleMonth ? min(day, request.month.daysInMonth) : day
        transaction.amount = value
        transaction.kind = TransactionKind.expense.rawValue
        transaction.expenseCategory = category.rawValue
        transaction.expenseName = expenseName

        if request.editScope == .singleMonth {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = nil
            transaction.recurrenceMonth = 0
            transaction.recurrenceEndMonthStart = nil
            transaction.monthStart = request.month.monthStart
        } else {
            switch mode {
            case .monthlyExpense:
                transaction.repeatsEveryMonth = true
                transaction.recurrenceType = RecurrenceType.monthly.rawValue
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
                transaction.monthStart = request.month.monthStart
            case .income, .salary:
                break
            }
        }

        finishSaving(transaction)
        markAsFullyPaidIfNeeded(transaction, value: value)
        syncLinkedCreditPaymentIfNeeded(transaction, value: value)
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
            transaction.repeatsEveryMonth = true
            transaction.recurrenceType = RecurrenceType.monthly.rawValue
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
            monthStart: request.month.monthStart,
            amount: 0,
            kind: mode.needsExpenseClassification ? TransactionKind.expense.rawValue : TransactionKind.income.rawValue
        )
    }

    private func finishSaving(_ transaction: MoneyTransaction) {
        switch request.editScope {
        case .normal:
            if editedTransaction == nil {
                modelContext.insert(transaction)
            }
        case .singleMonth:
            if let editedTransaction {
                addExclusion(for: editedTransaction, in: request.month)
                deletePayments(for: editedTransaction, from: request.month, onlySameMonth: true)
            }
            modelContext.insert(transaction)
        case .futureMonths:
            if let editedTransaction {
                editedTransaction.recurrenceEndMonthStart = request.month.monthStart
                deletePayments(for: editedTransaction, from: request.month, onlySameMonth: false)
            }
            modelContext.insert(transaction)
        }
    }

    private func markAsFullyPaidIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        guard canMarkExpenseAsPaid, markExpenseAsPaid else { return }

        let paymentMonth = request.month.monthStart
        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: paymentMonth, toGranularity: .month) }) {
            payment.amountPaid = value
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: paymentMonth, amountPaid: value))
        }
    }

    private func syncLinkedCreditPaymentIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        let shouldLinkPayment = mode == .expense && isDebtAmortizationExpense && selectedCreditID != nil

        guard shouldLinkPayment, let selectedCreditID else {
            deleteLinkedCreditMovementIfNeeded(for: transaction)
            transaction.linkedCreditID = nil
            transaction.linkedCreditMovementID = nil
            return
        }

        transaction.linkedCreditID = selectedCreditID

        let paymentMonth = request.month.monthStart
        let paidAmount = payments
            .first { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: paymentMonth, toGranularity: .month) }
            .map { min($0.amountPaid ?? value, value) } ?? 0

        guard paidAmount > 0 else {
            deleteLinkedCreditMovementIfNeeded(for: transaction)
            transaction.linkedCreditMovementID = nil
            return
        }

        let paymentDate = request.month.date(day: transaction.day)
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
}

struct DayPicker: View {
    @Environment(\.dismiss) private var dismiss
    let month: Date
    @Binding var selectedDay: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...month.daysInMonth, id: \.self) { day in
                    Button {
                        selectedDay = day
                        dismiss()
                    } label: {
                        Text("\(day)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
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
            .background(AppPalette.appBackground.ignoresSafeArea())
            .navigationTitle(month.monthTitle)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(AppPalette.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
            }
        }
    }
}
