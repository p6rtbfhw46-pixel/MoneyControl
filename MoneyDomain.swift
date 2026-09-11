//
//  MoneyDomain.swift
//  MoneyControl
//

import SwiftUI

enum TransactionKind: String {
    case expense
    case income
}

enum AccountMovementKind: String, CaseIterable, Identifiable {
    case initial
    case income
    case expensePayment
    case transferIn
    case transferOut
    case adjustment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .initial:
            AppStrings.text(.accountMovementInitial)
        case .income:
            AppStrings.text(.accountMovementIncome)
        case .expensePayment:
            AppStrings.text(.accountMovementExpensePayment)
        case .transferIn:
            AppStrings.text(.accountMovementTransferIn)
        case .transferOut:
            AppStrings.text(.accountMovementTransferOut)
        case .adjustment:
            AppStrings.text(.accountMovementAdjustment)
        }
    }

    var iconName: String {
        switch self {
        case .initial:
            "wallet.pass.fill"
        case .income:
            "plus.circle.fill"
        case .expensePayment:
            "minus.circle.fill"
        case .transferIn, .transferOut:
            "arrow.left.arrow.right.circle.fill"
        case .adjustment:
            "slider.horizontal.3"
        }
    }

    var tint: Color {
        switch self {
        case .income, .transferIn:
            AppPalette.positive
        case .expensePayment, .transferOut:
            AppPalette.primary
        case .initial, .adjustment:
            AppPalette.mediumBlue
        }
    }
}

enum AuditLogAction: String {
    case expenseCreated
    case expenseUpdated
    case expenseDeleted
    case incomeCreated
    case incomeUpdated
    case incomeDeleted
    case expensePaymentCreated
    case expensePaymentDeleted
    case accountCreated
    case accountUpdated
    case accountDeleted
    case accountTransfer
    case accountBalanceAdjusted
    case creditCreated
    case creditUpdated
    case creditDeleted
    case creditMovementCreated
    case creditMovementUpdated
    case creditMovementDeleted
    case savingCreated
    case savingUpdated
    case savingDeleted
    case savingMovementCreated
    case savingMovementUpdated
    case savingMovementDeleted

    var title: String {
        let isPortuguese = AppStrings.currentLanguage == .portuguese
        switch self {
        case .expenseCreated: return isPortuguese ? "Despesa criada" : "Expense created"
        case .expenseUpdated: return isPortuguese ? "Despesa alterada" : "Expense updated"
        case .expenseDeleted: return isPortuguese ? "Despesa apagada" : "Expense deleted"
        case .incomeCreated: return isPortuguese ? "Receita criada" : "Income created"
        case .incomeUpdated: return isPortuguese ? "Receita alterada" : "Income updated"
        case .incomeDeleted: return isPortuguese ? "Receita apagada" : "Income deleted"
        case .expensePaymentCreated: return isPortuguese ? "Pagamento registado" : "Payment registered"
        case .expensePaymentDeleted: return isPortuguese ? "Pagamento apagado" : "Payment deleted"
        case .accountCreated: return isPortuguese ? "Conta criada" : "Account created"
        case .accountUpdated: return isPortuguese ? "Conta alterada" : "Account updated"
        case .accountDeleted: return isPortuguese ? "Conta apagada" : "Account deleted"
        case .accountTransfer: return isPortuguese ? "Transferência entre contas" : "Account transfer"
        case .accountBalanceAdjusted: return isPortuguese ? "Saldo ajustado" : "Balance adjusted"
        case .creditCreated: return isPortuguese ? "Crédito criado" : "Credit created"
        case .creditUpdated: return isPortuguese ? "Crédito alterado" : "Credit updated"
        case .creditDeleted: return isPortuguese ? "Crédito apagado" : "Credit deleted"
        case .creditMovementCreated: return isPortuguese ? "Movimento de crédito criado" : "Credit movement created"
        case .creditMovementUpdated: return isPortuguese ? "Movimento de crédito alterado" : "Credit movement updated"
        case .creditMovementDeleted: return isPortuguese ? "Movimento de crédito apagado" : "Credit movement deleted"
        case .savingCreated: return isPortuguese ? "Poupança criada" : "Saving created"
        case .savingUpdated: return isPortuguese ? "Poupança alterada" : "Saving updated"
        case .savingDeleted: return isPortuguese ? "Poupança apagada" : "Saving deleted"
        case .savingMovementCreated: return isPortuguese ? "Movimento de poupança criado" : "Saving movement created"
        case .savingMovementUpdated: return isPortuguese ? "Movimento de poupança alterado" : "Saving movement updated"
        case .savingMovementDeleted: return isPortuguese ? "Movimento de poupança apagado" : "Saving movement deleted"
        }
    }

    var iconName: String {
        switch self {
        case .expenseCreated, .expenseUpdated, .expenseDeleted:
            "minus.circle.fill"
        case .incomeCreated, .incomeUpdated, .incomeDeleted:
            "plus.circle.fill"
        case .expensePaymentCreated, .expensePaymentDeleted:
            "checkmark.circle.fill"
        case .accountCreated, .accountUpdated, .accountDeleted:
            "wallet.pass.fill"
        case .accountTransfer:
            "arrow.left.arrow.right.circle.fill"
        case .accountBalanceAdjusted:
            "slider.horizontal.3"
        case .creditCreated, .creditUpdated, .creditDeleted, .creditMovementCreated, .creditMovementUpdated, .creditMovementDeleted:
            "creditcard.fill"
        case .savingCreated, .savingUpdated, .savingDeleted, .savingMovementCreated, .savingMovementUpdated, .savingMovementDeleted:
            "leaf.fill"
        }
    }

    var tint: Color {
        switch self {
        case .incomeCreated, .accountCreated, .expenseDeleted, .expensePaymentDeleted:
            AppPalette.positive
        case .expenseCreated, .expensePaymentCreated, .incomeDeleted, .accountDeleted:
            AppPalette.primary
        case .expenseUpdated, .incomeUpdated, .accountUpdated, .accountTransfer, .accountBalanceAdjusted:
            AppPalette.mediumBlue
        case .creditCreated, .creditMovementDeleted, .savingCreated, .savingMovementCreated:
            AppPalette.positive
        case .creditDeleted, .creditMovementCreated, .savingDeleted, .savingMovementDeleted:
            AppPalette.primary
        case .creditUpdated, .creditMovementUpdated, .savingUpdated, .savingMovementUpdated:
            AppPalette.mediumBlue
        }
    }
}

extension AuditLogEntry {
    var auditAction: AuditLogAction {
        AuditLogAction(rawValue: action) ?? .accountUpdated
    }
}

enum AuditSnapshot {
    static func totalBalance(
        spendAccounts: [SpendAccount],
        accountMovements: [AccountMovement],
        savingAccounts: [SavingAccount],
        savingMovements: [SavingMovement],
        creditAccounts: [CreditAccount],
        creditMovements: [CreditMovement]
    ) -> Double {
        let accountsTotal = spendAccounts.reduce(0) { $0 + $1.balance(with: accountMovements) }
        let savingsTotal = savingAccounts.reduce(0) { $0 + $1.balance(with: savingMovements) }
        let creditsTotal = creditAccounts.reduce(0) { $0 + $1.balance(with: creditMovements) }
        return accountsTotal + savingsTotal - creditsTotal
    }
}

enum SpendAccountIcon: String, CaseIterable, Identifiable {
    case bank
    case wallet
    case cash
    case card
    case travel
    case home
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bank: AppStrings.text(.accountIconBank)
        case .wallet: AppStrings.text(.accountIconWallet)
        case .cash: AppStrings.text(.accountIconCash)
        case .card: AppStrings.text(.accountIconCard)
        case .travel: AppStrings.text(.accountIconTravel)
        case .home: AppStrings.text(.accountIconHome)
        case .other: AppStrings.text(.accountIconOther)
        }
    }

    var systemName: String {
        switch self {
        case .bank: "building.columns.fill"
        case .wallet: "wallet.pass.fill"
        case .cash: "banknote.fill"
        case .card: "creditcard.fill"
        case .travel: "airplane"
        case .home: "house.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}

enum SpendAccountColor: String, CaseIterable, Identifiable {
    case blue
    case green
    case orange
    case purple
    case teal
    case gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: AppStrings.text(.colorBlue)
        case .green: AppStrings.text(.colorGreen)
        case .orange: AppStrings.text(.colorOrange)
        case .purple: AppStrings.text(.colorPurple)
        case .teal: AppStrings.text(.colorTeal)
        case .gray: AppStrings.text(.colorGray)
        }
    }

    var color: Color {
        switch self {
        case .blue: AppPalette.mediumBlue
        case .green: AppPalette.savings
        case .orange: AppPalette.primary
        case .purple: .purple
        case .teal: .teal
        case .gray: AppPalette.mutedText
        }
    }
}

enum BudgetAllocation: String, CaseIterable, Identifiable {
    case currentMonth
    case nextMonth
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .currentMonth:
            AppStrings.text(.budgetAllocationCurrentMonth)
        case .nextMonth:
            AppStrings.text(.budgetAllocationNextMonth)
        case .custom:
            AppStrings.text(.budgetAllocationCustomMonth)
        }
    }
}

enum RecurrenceType: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case quarterly
    case semiannual
    case annual
    case yearlyMonth

    var id: String { rawValue }

    static var selectableCases: [RecurrenceType] {
        [.weekly, .monthly, .quarterly, .semiannual, .annual]
    }

    static var incomeSelectableCases: [RecurrenceType] {
        [.weekly, .monthly, .quarterly, .semiannual, .annual]
    }

    var intervalInMonths: Int {
        switch self {
        case .weekly:
            1
        case .monthly:
            1
        case .quarterly:
            3
        case .semiannual:
            6
        case .annual, .yearlyMonth:
            12
        }
    }

    var title: String {
        switch self {
        case .weekly:
            AppStrings.text(.weeklyRecurrence)
        case .monthly:
            AppStrings.text(.monthlyRecurrence)
        case .quarterly:
            AppStrings.text(.quarterlyRecurrence)
        case .semiannual:
            AppStrings.text(.semiannualRecurrence)
        case .annual, .yearlyMonth:
            AppStrings.text(.annualRecurrence)
        }
    }
}

enum TransactionEditScope {
    case normal
    case singleMonth
    case futureMonths
}

enum ExpenseTypeIcon {
    static func name(for title: String) -> String {
        let normalizedTitle = title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()

        if normalizedTitle.contains("transport") || normalizedTitle.contains("combustivel") || normalizedTitle.contains("fuel") || normalizedTitle.contains("carro") {
            return "car.fill"
        }
        if normalizedTitle.contains("aliment") || normalizedTitle.contains("supermercado") || normalizedTitle.contains("refeic") || normalizedTitle.contains("food") || normalizedTitle.contains("grocer") || normalizedTitle.contains("eating") {
            return "fork.knife"
        }
        if normalizedTitle.contains("habit") || normalizedTitle.contains("renda") || normalizedTitle.contains("mortgage") || normalizedTitle.contains("housing") || normalizedTitle.contains("rent") || normalizedTitle.contains("casa") {
            return "house.fill"
        }
        if normalizedTitle.contains("eletric") || normalizedTitle.contains("electric") || normalizedTitle.contains("gas") || normalizedTitle.contains("agua") || normalizedTitle.contains("water") || normalizedTitle.contains("telecom") || normalizedTitle.contains("contas") || normalizedTitle.contains("bills") {
            return "lightbulb.fill"
        }
        if normalizedTitle.contains("saude") || normalizedTitle.contains("health") {
            return "cross.case.fill"
        }
        if normalizedTitle.contains("seguro") || normalizedTitle.contains("insurance") {
            return "shield.fill"
        }
        if normalizedTitle.contains("subscr") || normalizedTitle.contains("subscription") {
            return "play.rectangle.fill"
        }
        if normalizedTitle.contains("lazer") || normalizedTitle.contains("entreten") || normalizedTitle.contains("leisure") || normalizedTitle.contains("entertainment") {
            return "sparkles"
        }
        if normalizedTitle.contains("viagem") || normalizedTitle.contains("ferias") || normalizedTitle.contains("travel") || normalizedTitle.contains("holiday") {
            return "airplane"
        }
        if normalizedTitle.contains("roupa") || normalizedTitle.contains("acessor") || normalizedTitle.contains("clothing") || normalizedTitle.contains("accessor") || normalizedTitle.contains("compras") {
            return "bag.fill"
        }
        if normalizedTitle.contains("cash") || normalizedTitle.contains("levantamento") {
            return "banknote.fill"
        }
        if normalizedTitle.contains("transferencia") || normalizedTitle.contains("saldo") || normalizedTitle.contains("balance transfer") {
            return "arrow.left.arrow.right.circle.fill"
        }
        if normalizedTitle.contains("poup") || normalizedTitle.contains("saving") {
            return "leaf.fill"
        }
        if normalizedTitle.contains("divida") || normalizedTitle.contains("amort") || normalizedTitle.contains("debt") {
            return "creditcard.fill"
        }

        return "ellipsis.circle.fill"
    }
}

enum TransactionEditorMode: String {
    case expense
    case income
    case monthlyExpense
    case periodicExpense
    case salary

    var needsExpenseClassification: Bool {
        self == .expense || self == .monthlyExpense || self == .periodicExpense
    }

    var sectionTitle: String {
        switch self {
        case .expense, .monthlyExpense, .periodicExpense:
            AppStrings.text(.details)
        case .income:
            AppStrings.text(.income)
        case .salary:
            AppStrings.text(.salary)
        }
    }

    func navigationTitle(isEditing: Bool) -> String {
        switch (self, isEditing) {
        case (.expense, false):
            return AppStrings.text(.newExpense)
        case (.expense, true):
            return AppStrings.text(.editExpense)
        case (.income, false):
            return AppStrings.text(.newIncome)
        case (.income, true):
            return AppStrings.text(.editIncome)
        case (.monthlyExpense, false):
            return AppStrings.text(.newMonthlyExpense)
        case (.monthlyExpense, true):
            return AppStrings.text(.editMonthlyExpense)
        case (.periodicExpense, false):
            return AppStrings.text(.newPeriodicExpense)
        case (.periodicExpense, true):
            return AppStrings.text(.editPeriodicExpense)
        case (.salary, false):
            return AppStrings.text(.newSalary)
        case (.salary, true):
            return AppStrings.text(.editSalary)
        }
    }
}

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case needs
    case wants
    case savingsAndDebt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needs:
            AppStrings.text(.needsCategory)
        case .wants:
            AppStrings.text(.wantsCategory)
        case .savingsAndDebt:
            AppStrings.text(.savingsAndDebtCategory)
        }
    }

    var color: Color {
        switch self {
        case .needs:
            AppPalette.background
        case .wants:
            AppPalette.primary
        case .savingsAndDebt:
            AppPalette.savings
        }
    }

    var iconName: String {
        switch self {
        case .needs:
            "lightbulb"
        case .wants:
            "sparkles"
        case .savingsAndDebt:
            "shield.checkered"
        }
    }

    var names: [String] {
        AppStrings.expenseNames(for: self)
    }
}

struct TransactionEditorRequest: Identifiable {
    let id = UUID()
    let mode: TransactionEditorMode
    let month: Date
    let transaction: MoneyTransaction?
    let editScope: TransactionEditScope
    let titleOverride: String?
    let initialExpenseCategory: ExpenseCategory?
    let initialExpenseName: String?
    let initialTitle: String?
    let initialAmount: Double?
    let initialDate: Date?
    let startsMarkedAsPaid: Bool

    init(
        mode: TransactionEditorMode,
        month: Date,
        transaction: MoneyTransaction? = nil,
        editScope: TransactionEditScope = .normal,
        titleOverride: String? = nil,
        initialExpenseCategory: ExpenseCategory? = nil,
        initialExpenseName: String? = nil,
        initialTitle: String? = nil,
        initialAmount: Double? = nil,
        initialDate: Date? = nil,
        startsMarkedAsPaid: Bool = false
    ) {
        self.mode = mode
        self.month = month
        self.transaction = transaction
        self.editScope = editScope
        self.titleOverride = titleOverride
        self.initialExpenseCategory = initialExpenseCategory
        self.initialExpenseName = initialExpenseName
        self.initialTitle = initialTitle
        self.initialAmount = initialAmount
        self.initialDate = initialDate
        self.startsMarkedAsPaid = startsMarkedAsPaid
    }

    init(transaction: MoneyTransaction, month: Date, editScope: TransactionEditScope = .normal) {
        self.mode = transaction.editorMode
        self.month = month
        self.transaction = transaction
        self.editScope = editScope
        self.titleOverride = nil
        self.initialExpenseCategory = nil
        self.initialExpenseName = nil
        self.initialTitle = nil
        self.initialAmount = nil
        self.initialDate = nil
        self.startsMarkedAsPaid = false
    }
}

extension Array where Element == MoneyTransaction {
    func visible(in month: Date, payments: [ExpensePayment], exclusions: [RecurrenceExclusion]) -> [MoneyTransaction] {
        filter { $0.occurs(in: month, exclusions: exclusions) }
            .sorted { first, second in
                let firstRank = first.listRank(in: month, payments: payments)
                let secondRank = second.listRank(in: month, payments: payments)

                if firstRank != secondRank {
                    return firstRank < secondRank
                }

                let firstDay = first.effectiveDay(in: month)
                let secondDay = second.effectiveDay(in: month)

                if firstDay != secondDay {
                    return firstDay < secondDay
                }

                return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
            }
    }
}

extension MoneyTransaction {
    var recurrence: RecurrenceType? {
        if let recurrenceType, let recurrence = RecurrenceType(rawValue: recurrenceType) {
            return recurrence
        }

        return repeatsEveryMonth ? .monthly : nil
    }

    var budgetAllocation: BudgetAllocation {
        get {
            guard kind == TransactionKind.income.rawValue,
                  let budgetAllocationType,
                  let allocation = BudgetAllocation(rawValue: budgetAllocationType)
            else { return .currentMonth }

            return allocation
        }
        set {
            budgetAllocationType = kind == TransactionKind.income.rawValue ? newValue.rawValue : nil
        }
    }

    var editorMode: TransactionEditorMode {
        if kind == TransactionKind.expense.rawValue {
            switch recurrence {
            case .weekly, .monthly, .quarterly, .semiannual, .annual, .yearlyMonth:
                return .monthlyExpense
            case nil:
                return .expense
            }
        }

        return recurrence != nil ? .salary : .income
    }

    var displayName: String {
        if kind == TransactionKind.expense.rawValue {
            return expenseName ?? title
        }
        return title
    }

    var detailText: String {
        detailText(in: nil)
    }

    func detailText(in month: Date?) -> String {
        var parts = [dayDescription(in: month)]

        if let category = ExpenseCategory(rawValue: expenseCategory ?? "") {
            parts.append(category.title)
        }

        if kind == TransactionKind.expense.rawValue, !title.isEmpty {
            parts.append(title)
        }

        if kind == TransactionKind.income.rawValue,
           let incomeDescription,
           !incomeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(incomeDescription.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if kind == TransactionKind.income.rawValue, let month {
            let budgetMonth = budgetMonth(forReceivedMonth: month)
            if !Calendar.current.isDate(budgetMonth, equalTo: month.monthStart, toGranularity: .month) {
                parts.append("\(AppStrings.text(.budgetMonth)) \(budgetMonth.monthTitle)")
            }
        } else if kind == TransactionKind.income.rawValue, recurrence != nil {
            parts.append("\(AppStrings.text(.useInBudget)) \(budgetAllocation.title)")
        }

        switch recurrence {
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
            parts.append(recurrence?.title ?? AppStrings.text(.everyMonth))
            if let recurrenceEndMonthStart {
                parts.append("\(AppStrings.text(.endDate)) \(recurrenceEndMonthStart.previousMonthStart.monthTitle)")
            }
        case .yearlyMonth:
            parts.append(AppStrings.text(.annualRecurrence))
            parts.append(Date.monthName(forMonthNumber: recurrenceMonth))
        case nil:
            break
        }

        return parts.joined(separator: " · ")
    }

    var isWholeMonthExpense: Bool {
        kind == TransactionKind.expense.rawValue && day <= 0
    }

    func dayDescription(in month: Date? = nil) -> String {
        if recurrence == .weekly {
            return weekdayDescription
        }

        if isWholeMonthExpense {
            return AppStrings.text(.monthExpense)
        }

        if day <= 0 {
            return AppStrings.text(.noSpecificDay)
        }

        let displayedDay = month.map { effectiveDay(in: $0) } ?? day
        return "\(AppStrings.text(.day)) \(displayedDay)"
    }

    func effectiveDay(in month: Date) -> Int {
        day <= 0 ? 1 : min(day, month.daysInMonth)
    }

    var weekdayDescription: String {
        Date.weekdayName(for: normalizedWeekday)
    }

    var normalizedWeekday: Int {
        min(max(day, 1), 7)
    }

    func weeklyOccurrenceDays(in month: Date) -> [Int] {
        guard recurrence == .weekly else { return [] }
        return month.days(matchingWeekday: normalizedWeekday)
    }

    func occurrenceDays(in month: Date) -> [Int] {
        let days: [Int]
        if recurrence == .weekly {
            days = weeklyOccurrenceDays(in: month)
        } else {
            days = [effectiveDay(in: month)]
        }

        guard Calendar.current.isDate(month.monthStart, equalTo: monthStart, toGranularity: .month) else {
            return days
        }

        let activationDay = Calendar.current.component(.day, from: monthStart)
        return days.filter { $0 >= activationDay }
    }

    func occurrenceDays(in month: Date, exclusions: [RecurrenceExclusion]) -> [Int] {
        occurrenceDays(in: month).filter { day in
            !exclusions.contains {
                $0.matches(transactionID: id, month: month, occurrenceDay: recurrence == .weekly ? day : nil)
            }
        }
    }

    func occurrenceCount(in month: Date) -> Int {
        max(occurrenceDays(in: month).count, 1)
    }

    func scheduledAmount(in month: Date) -> Double {
        if recurrence == .weekly {
            return amount * Double(weeklyOccurrenceDays(in: month).count)
        }

        return amount
    }

    func scheduledAmount(in month: Date, occurrenceDay: Int?) -> Double {
        recurrence == .weekly && occurrenceDay != nil ? amount : scheduledAmount(in: month)
    }

    func budgetMonth(forReceivedMonth receivedMonth: Date) -> Date {
        guard kind == TransactionKind.income.rawValue else {
            return receivedMonth.monthStart
        }

        switch budgetAllocation {
        case .currentMonth:
            return receivedMonth.monthStart
        case .nextMonth:
            return receivedMonth.nextMonthStart
        case .custom:
            return budgetMonthStart?.monthStart ?? receivedMonth.monthStart
        }
    }

    func isBudgeted(in targetBudgetMonth: Date, receivedMonth: Date) -> Bool {
        Calendar.current.isDate(
            budgetMonth(forReceivedMonth: receivedMonth),
            equalTo: targetBudgetMonth.monthStart,
            toGranularity: .month
        )
    }

    func receivedDate(in receivedMonth: Date) -> Date {
        receivedMonth.monthStart.date(day: effectiveDay(in: receivedMonth))
    }

    var isRecurring: Bool {
        recurrence != nil
    }

    var isActiveForSettingsList: Bool {
        guard isRecurring else { return false }
        return recurrenceEndMonthStart.map { $0 > Date().monthStart.nextMonthStart } ?? true
    }

    func occurs(in month: Date, exclusions: [RecurrenceExclusion]) -> Bool {
        let monthStart = month.monthStart

        if recurrenceEndMonthStart.map({ monthStart >= $0.monthStart }) == true {
            return false
        }

        if exclusions.contains(where: { $0.matches(transactionID: id, month: monthStart, occurrenceDay: nil) }) {
            return false
        }

        switch recurrence {
        case .weekly, .monthly:
            guard monthStart >= self.monthStart.monthStart else { return false }
            if recurrence == .weekly {
                return true
            }
            return true
        case .quarterly, .semiannual, .annual:
            guard monthStart >= self.monthStart.monthStart else { return false }
            let interval = recurrence?.intervalInMonths ?? 1
            let anchorMonth = recurrenceMonth > 0 ? recurrenceMonth : self.monthStart.monthNumber
            let distanceFromAnchor = (monthStart.monthNumber - anchorMonth + 12) % 12
            return distanceFromAnchor.isMultiple(of: interval)
        case .yearlyMonth:
            return monthStart >= self.monthStart.monthStart && monthStart.monthNumber == recurrenceMonth
        case nil:
            return Calendar.current.isDate(self.monthStart, equalTo: monthStart, toGranularity: .month)
        }
    }

    func listRank(in month: Date, payments: [ExpensePayment]) -> Int {
        guard kind == TransactionKind.expense.rawValue else { return 1 }
        let payment = payments.first { $0.transactionID == id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
        let scheduledAmount = scheduledAmount(in: month)
        let paidAmount = payment?.amountPaid ?? (payment == nil ? 0 : scheduledAmount)
        return paidAmount >= scheduledAmount ? 2 : 0
    }
}

extension SpendAccount {
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Conta" : name
    }

    var accountIcon: SpendAccountIcon {
        SpendAccountIcon.allCases.first { $0.systemName == iconName || $0.rawValue == iconName } ?? .wallet
    }

    var tint: Color {
        SpendAccountColor(rawValue: colorName)?.color ?? AppPalette.mediumBlue
    }

    func balance(with movements: [AccountMovement]) -> Double {
        initialBalance + movements
            .filter { $0.accountID == id }
            .reduce(0) { $0 + $1.amount }
    }
}

extension AccountMovement {
    var kind: AccountMovementKind {
        AccountMovementKind(rawValue: type) ?? .adjustment
    }

    var signedAmountText: String {
        amount >= 0 ? "+\(amount.currencyText)" : amount.currencyText
    }
}

extension ExpensePayment {
    func matches(transactionID: UUID, month: Date, occurrenceDay: Int?) -> Bool {
        self.transactionID == transactionID
            && Calendar.current.isDate(monthStart, equalTo: month.monthStart, toGranularity: .month)
            && self.occurrenceDay == occurrenceDay
    }
}

extension PaymentHistoryEntry {
    func matches(transactionID: UUID, month: Date, occurrenceDay: Int?) -> Bool {
        self.transactionID == transactionID
            && Calendar.current.isDate(monthStart, equalTo: month.monthStart, toGranularity: .month)
            && self.occurrenceDay == occurrenceDay
    }
}

extension RecurrenceExclusion {
    func matches(transactionID: UUID, month: Date, occurrenceDay: Int?) -> Bool {
        self.transactionID == transactionID
            && Calendar.current.isDate(monthStart, equalTo: month.monthStart, toGranularity: .month)
            && (self.occurrenceDay == nil || self.occurrenceDay == occurrenceDay)
    }
}

extension Date {
    var monthStart: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var nextMonthStart: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
    }

    var previousMonthStart: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
    }

    var monthNumber: Int {
        Calendar.current.component(.month, from: self)
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        formatter.dateFormat = "MMMM yyyy"
        let title = formatter.string(from: self)
        return title.prefix(1).uppercased() + title.dropFirst()
    }

    var notificationIdentifierDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        return formatter.string(from: self)
    }

    func date(day: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month], from: self)
        components.day = min(max(day, 1), daysInMonth)
        return Calendar.current.date(from: components) ?? self
    }

    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 31
    }

    func days(matchingWeekday weekday: Int) -> [Int] {
        let normalizedWeekday = min(max(weekday, 1), 7)
        return (1...daysInMonth).filter { day in
            Calendar.current.component(.weekday, from: date(day: day)) == normalizedWeekday
        }
    }

    static func weekdayName(for weekday: Int) -> String {
        let normalizedWeekday = min(max(weekday, 1), 7)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        let symbols = formatter.weekdaySymbols ?? Calendar.current.weekdaySymbols
        return symbols[normalizedWeekday - 1].prefix(1).uppercased() + symbols[normalizedWeekday - 1].dropFirst()
    }

    static func monthStart(forMonthNumber month: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components) ?? Date().monthStart
    }

    static func firstRecurringOccurrenceDate(
        recurrence: RecurrenceType,
        recurrenceMonth: Int,
        day: Int,
        onOrAfter referenceMonth: Date,
        today: Date = Date()
    ) -> Date {
        let calendar = Calendar.current
        let earliestDate = max(calendar.startOfDay(for: today), referenceMonth.monthStart)
        var candidateMonth = earliestDate.monthStart

        if day <= 0 {
            return candidateMonth
        }

        if recurrence == .weekly {
            let weekday = min(max(day, 1), 7)
            while true {
                if let occurrenceDate = candidateMonth.days(matchingWeekday: weekday)
                    .map({ candidateMonth.date(day: $0) })
                    .first(where: { $0 >= earliestDate }) {
                    return occurrenceDate
                }
                candidateMonth = candidateMonth.nextMonthStart
            }
        }

        let interval = recurrence.intervalInMonths
        let anchorMonth = recurrenceMonth > 0 ? recurrenceMonth : candidateMonth.monthNumber

        while true {
            let distanceFromAnchor = (candidateMonth.monthNumber - anchorMonth + 12) % 12
            if distanceFromAnchor.isMultiple(of: interval) {
                let occurrenceDate = candidateMonth.date(day: min(day, candidateMonth.daysInMonth))
                if occurrenceDate >= earliestDate {
                    return occurrenceDate
                }
            }
            candidateMonth = candidateMonth.nextMonthStart
        }
    }

    static func monthStart(month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components) ?? Date().monthStart
    }

    static func monthName(forMonthNumber month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        formatter.dateFormat = "MMMM"
        let title = formatter.string(from: monthStart(forMonthNumber: month))
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}

enum AppPreferences {
    static let selectedCurrencyCodeKey = "selectedCurrencyCode"
    static let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    static let appLockEnabledKey = "appLockEnabled"
    static let appLockBiometricsEnabledKey = "appLockBiometricsEnabled"
    static let notificationsEnabledKey = "notificationsEnabled"
    static let launchPaymentReminderEnabledKey = "launchPaymentReminderEnabled"

    static var deviceCurrencyCode: String {
        Locale.autoupdatingCurrent.currency?.identifier ?? "EUR"
    }

    static var selectedCurrencyCode: String {
        let storedCode = UserDefaults.standard.string(forKey: selectedCurrencyCodeKey) ?? ""
        return storedCode.isEmpty ? deviceCurrencyCode : storedCode
    }

    static var selectedCurrencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .autoupdatingCurrent
        formatter.currencyCode = selectedCurrencyCode
        return formatter.currencySymbol ?? selectedCurrencyCode
    }

    static func currencyText(for value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .autoupdatingCurrent
        formatter.currencyCode = selectedCurrencyCode
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) \(selectedCurrencyCode)"
    }
}

extension Double {
    var currencyText: String {
        AppPreferences.currencyText(for: self)
    }
}

extension View {
    @ViewBuilder
    func monthPagerStyle() -> some View {
#if os(iOS)
        tabViewStyle(.page(indexDisplayMode: .never))
#else
        self
#endif
    }

    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if prominent {
                buttonStyle(.borderedProminent)
            } else {
                buttonStyle(.bordered)
            }
        }
    }

}
