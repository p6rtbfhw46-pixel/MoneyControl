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
    @State private var didLoad = false
    @State private var showsSingleMonthRecurringEditInfo = false
    @State private var hasConfirmedSingleMonthRecurringEditInfo = false

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
            Form {
                if mode.needsExpenseClassification {
                    Section(AppStrings.text(.classification)) {
                        HStack(spacing: 10) {
                            Text("Categoria 50/30/20")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppPalette.background)

                            HelpIconButton(
                                title: "Regra 50/30/20",
                                message: "A metodologia 50/30/20 ajuda a distribuir o rendimento de forma equilibrada: 50% para necessidades, 30% para desejos e 20% para poupança. Não é uma regra obrigatória, mas uma referência para uma melhor gestão financeira."
                            )

                            Spacer()
                        }

                        Picker("Categoria 50/30/20", selection: expenseCategoryBinding) {
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

                Section(mode.sectionTitle) {
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
                        maximumAmount: 20_000,
                        onConfirm: save
                    )
                }
                .listRowBackground(AppPalette.surface)

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(AppPalette.destructive)
                }
            }
            .scrollContentBackground(.hidden)
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.background)
            .background(AppPalette.appBackground)
            .navigationTitle(mode.navigationTitle(isEditing: editedTransaction != nil))
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
        }
    }

    private var parsedValue: Double? {
        amountValue > 0 ? amountValue : nil
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
        recurrenceMonth = transaction.recurrenceMonth > 0 ? transaction.recurrenceMonth : Calendar.current.component(.month, from: transaction.monthStart)

        if let endMonthStart = transaction.recurrenceEndMonthStart?.previousMonthStart {
            hasEndDate = true
            endMonth = Calendar.current.component(.month, from: endMonthStart)
            endYear = Calendar.current.component(.year, from: endMonthStart)
        }
    }

    private func save() {
        validationMessage = nil

        guard let parsedValue else {
            validationMessage = AppStrings.text(.fillValue)
            return
        }

        if mode.needsExpenseClassification {
            guard let expenseCategory else {
                validationMessage = AppStrings.text(.selectExpenseType)
                return
            }

            guard !expenseName.isEmpty else {
                validationMessage = AppStrings.text(.selectExpenseName)
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
                validationMessage = AppStrings.text(.fillName)
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
