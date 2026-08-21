//
//  MoneyDomain.swift
//  MoneyControl
//

import SwiftUI

enum TransactionKind: String {
    case expense
    case income
}

enum RecurrenceType: String, CaseIterable, Identifiable {
    case monthly
    case quarterly
    case semiannual
    case annual
    case yearlyMonth

    var id: String { rawValue }

    static var selectableCases: [RecurrenceType] {
        [.monthly, .quarterly, .semiannual, .annual]
    }

    var intervalInMonths: Int {
        switch self {
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

    init(
        mode: TransactionEditorMode,
        month: Date,
        transaction: MoneyTransaction? = nil,
        editScope: TransactionEditScope = .normal,
        titleOverride: String? = nil,
        initialExpenseCategory: ExpenseCategory? = nil,
        initialExpenseName: String? = nil
    ) {
        self.mode = mode
        self.month = month
        self.transaction = transaction
        self.editScope = editScope
        self.titleOverride = titleOverride
        self.initialExpenseCategory = initialExpenseCategory
        self.initialExpenseName = initialExpenseName
    }

    init(transaction: MoneyTransaction, month: Date, editScope: TransactionEditScope = .normal) {
        self.mode = transaction.editorMode
        self.month = month
        self.transaction = transaction
        self.editScope = editScope
        self.titleOverride = nil
        self.initialExpenseCategory = nil
        self.initialExpenseName = nil
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

    var editorMode: TransactionEditorMode {
        if kind == TransactionKind.expense.rawValue {
            switch recurrence {
            case .monthly, .quarterly, .semiannual, .annual, .yearlyMonth:
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
        let displayedDay = month.map { effectiveDay(in: $0) } ?? day
        var parts = ["\(AppStrings.text(.day)) \(displayedDay)"]

        if let category = ExpenseCategory(rawValue: expenseCategory ?? "") {
            parts.append(category.title)
        }

        if kind == TransactionKind.expense.rawValue, !title.isEmpty {
            parts.append(title)
        }

        switch recurrence {
        case .monthly, .quarterly, .semiannual, .annual:
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

    func effectiveDay(in month: Date) -> Int {
        min(day, month.daysInMonth)
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

        if exclusions.contains(where: { $0.transactionID == id && Calendar.current.isDate($0.monthStart, equalTo: monthStart, toGranularity: .month) }) {
            return false
        }

        switch recurrence {
        case .monthly, .quarterly, .semiannual, .annual:
            guard monthStart >= self.monthStart.monthStart else { return false }
            let distance = Calendar.current.dateComponents([.month], from: self.monthStart.monthStart, to: monthStart).month ?? 0
            return distance >= 0 && distance.isMultiple(of: recurrence?.intervalInMonths ?? 1)
        case .yearlyMonth:
            return monthStart >= self.monthStart.monthStart && monthStart.monthNumber == recurrenceMonth
        case nil:
            return Calendar.current.isDate(self.monthStart, equalTo: monthStart, toGranularity: .month)
        }
    }

    func listRank(in month: Date, payments: [ExpensePayment]) -> Int {
        guard kind == TransactionKind.expense.rawValue else { return 1 }
        let payment = payments.first { $0.transactionID == id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
        let paidAmount = payment?.amountPaid ?? (payment == nil ? 0 : amount)
        return paidAmount >= amount ? 2 : 0
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

    static func monthStart(forMonthNumber month: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components) ?? Date().monthStart
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
