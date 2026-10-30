//
//  MoneyCalculationService.swift
//  MoneyControl
//

import Foundation

struct TransactionOccurrence {
    let transaction: MoneyTransaction
    let month: Date
}

struct IncomeAccountOccurrence {
    let transaction: MoneyTransaction
    let receivedDate: Date
    let amount: Double
}

struct ReservedIncomeSummary: Equatable {
    let budgetMonth: Date
    let amount: Double
}

struct AccountSummary: Equatable {
    let availableBalance: Double
    let incomeUntilToday: Double
    let paidExpensesUntilToday: Double
    let reservedForFutureBudgets: [ReservedIncomeSummary]

    var reservedForFutureBudgetsTotal: Double {
        reservedForFutureBudgets.reduce(0) { $0 + $1.amount }
    }
}

struct MonthBudgetSummary: Equatable {
    let income: Double
    let expenses: Double
    let unpaidExpenses: Double

    var remaining: Double { income - expenses }
}

struct CategoryExpensePoint: Identifiable, Equatable {
    let category: ExpenseCategory
    let amount: Double

    var id: String { category.rawValue }
}

struct ExpenseTypePoint: Identifiable, Equatable {
    let title: String
    let category: ExpenseCategory
    let amount: Double

    var id: String { "\(category.rawValue)-\(title)" }
}

struct MonthlyBalancePoint: Identifiable, Equatable {
    let month: Date
    let income: Double
    let expenses: Double

    var id: Date { month }
    var balance: Double { income - expenses }
    var monthLabel: String { month.formatted(.dateTime.month(.abbreviated)) }
}

struct MoneyCalculationService {
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let exclusions: [RecurrenceExclusion]
    var calendar = Calendar.current

    func visibleTransactions(in month: Date) -> [MoneyTransaction] {
        transactions.visible(in: month, payments: payments, exclusions: exclusions)
    }

    func scheduledAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        if transaction.recurrence == .weekly {
            return transaction.occurrenceDays(in: month, exclusions: exclusions)
                .reduce(0) { total, occurrenceDay in
                    total + transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                }
        }

        return transaction.scheduledAmount(in: month)
    }

    func paidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        if transaction.recurrence == .weekly {
            return transaction.occurrenceDays(in: month, exclusions: exclusions)
                .reduce(0) { total, occurrenceDay in
                    total + paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
                }
        }

        return paidAmount(for: transaction, in: month, occurrenceDay: nil)
    }

    func paidAmount(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Double {
        guard transaction.kind == TransactionKind.expense.rawValue else { return 0 }
        let normalizedOccurrenceDay = transaction.recurrence == .weekly ? occurrenceDay : nil
        let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: normalizedOccurrenceDay)
        if transaction.recurrence == .weekly, let normalizedOccurrenceDay {
            let paidAmount = weeklyPaidAmount(
                for: transaction,
                in: month,
                occurrenceDay: normalizedOccurrenceDay,
                scheduledAmount: scheduledAmount
            )
            return min(paidAmount, scheduledAmount)
        }

        let matchingPayments = payments.filter { payment in
            payment.transactionID == transaction.id
                && calendar.isDate(payment.monthStart, equalTo: month, toGranularity: .month)
                && (transaction.recurrence != .weekly || payment.occurrenceDay == normalizedOccurrenceDay)
        }
        let paidAmount = matchingPayments.reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
        return min(paidAmount, scheduledAmount)
    }

    private func weeklyPaidAmount(
        for transaction: MoneyTransaction,
        in month: Date,
        occurrenceDay: Int,
        scheduledAmount: Double
    ) -> Double {
        let monthPayments = payments.filter {
            $0.transactionID == transaction.id
                && calendar.isDate($0.monthStart, equalTo: month, toGranularity: .month)
        }
        let exactPaid = monthPayments
            .filter { $0.occurrenceDay == occurrenceDay }
            .reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
        let legacyPaid = monthPayments
            .filter { $0.occurrenceDay == nil }
            .reduce(0) { $0 + ($1.amountPaid ?? self.scheduledAmount(for: transaction, in: month)) }

        guard legacyPaid > 0 else { return exactPaid }

        let earlierScheduledAmount = transaction
            .occurrenceDays(in: month, exclusions: exclusions)
            .filter { $0 < occurrenceDay }
            .reduce(0) { total, day in
                total + transaction.scheduledAmount(in: month, occurrenceDay: day)
            }
        let legacyAllocation = min(max(legacyPaid - earlierScheduledAmount, 0), scheduledAmount)

        return exactPaid + legacyAllocation
    }

    func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        paidAmount(for: transaction, in: month) >= scheduledAmount(for: transaction, in: month)
    }

    func accountSummary(until now: Date) -> AccountSummary {
        let occurrences = accountOccurrencesUntilToday(now: now)
        let income = occurrences
            .filter { $0.transaction.kind == TransactionKind.income.rawValue }
            .reduce(0) { total, occurrence in
                let maxDay = calendar.isDate(occurrence.month, equalTo: now.monthStart, toGranularity: .month)
                    ? calendar.component(.day, from: now)
                    : occurrence.month.daysInMonth
                return total + receivedIncomeAmount(
                    for: occurrence.transaction,
                    in: occurrence.month,
                    throughDay: maxDay
                )
            }
        let paidExpenses = occurrences
            .filter { $0.transaction.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + paidAmount(for: $1.transaction, in: $1.month) }

        return AccountSummary(
            availableBalance: income - paidExpenses,
            incomeUntilToday: income,
            paidExpensesUntilToday: paidExpenses,
            reservedForFutureBudgets: reservedIncomeForFutureBudgets(until: now)
        )
    }

    func accountOccurrencesUntilToday(now: Date) -> [TransactionOccurrence] {
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min() else { return [] }
        let currentMonth = now.monthStart

        return Self.months(from: firstMonth, through: currentMonth).flatMap { month in
            let maxDay = calendar.isDate(month, equalTo: currentMonth, toGranularity: .month)
                ? calendar.component(.day, from: now)
                : month.daysInMonth

            return visibleTransactions(in: month)
                .filter { transaction in
                    if transaction.kind == TransactionKind.income.rawValue {
                        if transaction.recurrence == .weekly {
                            return transaction
                                .occurrenceDays(in: month, exclusions: exclusions)
                                .contains { $0 <= maxDay }
                        }
                        return transaction.effectiveDay(in: month) <= maxDay
                    }

                    return transaction.effectiveDay(in: month) <= maxDay || paidAmount(for: transaction, in: month) > 0
                }
                .map { TransactionOccurrence(transaction: $0, month: month) }
        }
    }

    func monthSummary(in month: Date) -> MonthBudgetSummary {
        let visible = visibleTransactions(in: month)
        let income = incomeTotal(in: month)
        let expenses = visible
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + scheduledAmount(for: $1, in: month) }
        let unpaid = visible
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + max(scheduledAmount(for: $1, in: month) - paidAmount(for: $1, in: month), 0) }

        return MonthBudgetSummary(income: income, expenses: expenses, unpaidExpenses: unpaid)
    }

    func cumulativeBudgetRemaining(through month: Date) -> Double {
        guard let firstMonth = firstBudgetRelevantMonth(through: month) else { return 0 }

        return Self.months(from: firstMonth, through: month.monthStart)
            .reduce(0) { $0 + monthSummary(in: $1).remaining }
    }

    func categoryExpenses(in month: Date, paidOnly: Bool = false) -> [CategoryExpensePoint] {
        categoryExpenses(in: [month], paidOnly: paidOnly)
    }

    func categoryExpenses(in months: [Date], paidOnly: Bool = false) -> [CategoryExpensePoint] {
        ExpenseCategory.allCases.map { category in
            let amount = months.reduce(0) { total, month in
                total + categoryAmount(in: month, category: category, paidOnly: paidOnly)
            }
            return CategoryExpensePoint(category: category, amount: amount)
        }
    }

    func expenseTypePoints(in months: [Date], fallbackTitle: String, paidOnly: Bool = false) -> [ExpenseTypePoint] {
        var totals: [String: (title: String, category: ExpenseCategory, amount: Double)] = [:]

        months.forEach { month in
            visibleTransactions(in: month)
                .filter { $0.kind == TransactionKind.expense.rawValue }
                .forEach { transaction in
                    let amount = paidOnly ? paidAmount(for: transaction, in: month) : scheduledAmount(for: transaction, in: month)
                    guard amount > 0 else { return }

                    let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? "") ?? .needs
                    let title = transaction.displayName.isEmpty ? fallbackTitle : transaction.displayName
                    let key = "\(category.rawValue)-\(title)"
                    let currentAmount = totals[key]?.amount ?? 0
                    totals[key] = (title, category, currentAmount + amount)
                }
        }

        return totals.values
            .map { ExpenseTypePoint(title: $0.title, category: $0.category, amount: $0.amount) }
            .sorted { first, second in
                if first.amount != second.amount {
                    return first.amount > second.amount
                }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    func incomeTotal(in month: Date) -> Double {
        incomeOccurrences(budgetedIn: month)
            .reduce(0) { total, transaction in
                total + scheduledAmount(for: transaction, in: month)
            }
    }

    func incomeOccurrences(budgetedIn budgetMonth: Date) -> [MoneyTransaction] {
        guard let firstMonth = transactions
            .filter({ $0.kind == TransactionKind.income.rawValue })
            .map(\.monthStart.monthStart)
            .min()
        else { return [] }

        return Self.months(from: firstMonth, through: budgetMonth.monthStart)
            .flatMap { receivedMonth in
                visibleTransactions(in: receivedMonth)
                    .filter {
                        $0.kind == TransactionKind.income.rawValue
                            && $0.isBudgeted(in: budgetMonth, receivedMonth: receivedMonth)
                    }
            }
    }

    func recurringIncomeOccurrencesDue(after startDate: Date, through now: Date) -> [IncomeAccountOccurrence] {
        guard startDate < now else { return [] }

        return transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring }
            .flatMap { transaction -> [IncomeAccountOccurrence] in
                let firstMonth = max(transaction.monthStart.monthStart, startDate.monthStart)
                guard firstMonth <= now.monthStart else { return [] }

                return Self.months(from: firstMonth, through: now.monthStart)
                    .filter { transaction.occurs(in: $0, exclusions: exclusions) }
                    .flatMap { month in
                        transaction.occurrenceDays(in: month, exclusions: exclusions)
                            .map { occurrenceDay in
                                IncomeAccountOccurrence(
                                    transaction: transaction,
                                    receivedDate: month.date(day: occurrenceDay),
                                    amount: transaction.scheduledAmount(
                                        in: month,
                                        occurrenceDay: transaction.recurrence == .weekly ? occurrenceDay : nil
                                    )
                                )
                            }
                    }
                    .filter { $0.receivedDate > startDate && $0.receivedDate <= now }
            }
            .sorted { $0.receivedDate < $1.receivedDate }
    }

    func reservedIncomeForFutureBudgets(until now: Date) -> [ReservedIncomeSummary] {
        let currentMonth = now.monthStart
        let receivedIncome = accountOccurrencesUntilToday(now: now)
            .filter { $0.transaction.kind == TransactionKind.income.rawValue }
            .filter { $0.transaction.budgetMonth(forReceivedMonth: $0.month) > currentMonth }

        let totals = receivedIncome.reduce(into: [Date: Double]()) { result, occurrence in
            let budgetMonth = occurrence.transaction.budgetMonth(forReceivedMonth: occurrence.month)
            let maxDay = calendar.isDate(occurrence.month, equalTo: currentMonth, toGranularity: .month)
                ? calendar.component(.day, from: now)
                : occurrence.month.daysInMonth
            result[budgetMonth, default: 0] += receivedIncomeAmount(
                for: occurrence.transaction,
                in: occurrence.month,
                throughDay: maxDay
            )
        }

        return totals
            .map { ReservedIncomeSummary(budgetMonth: $0.key, amount: $0.value) }
            .sorted { $0.budgetMonth < $1.budgetMonth }
    }

    private func receivedIncomeAmount(
        for transaction: MoneyTransaction,
        in month: Date,
        throughDay maxDay: Int
    ) -> Double {
        transaction
            .occurrenceDays(in: month, exclusions: exclusions)
            .filter { $0 <= maxDay }
            .reduce(0) { total, occurrenceDay in
                total + transaction.scheduledAmount(
                    in: month,
                    occurrenceDay: transaction.recurrence == .weekly ? occurrenceDay : nil
                )
            }
    }

    private func firstBudgetRelevantMonth(through month: Date) -> Date? {
        let receivedMonths = transactions.map(\.monthStart.monthStart)
        let budgetMonths = transactions
            .filter { $0.kind == TransactionKind.income.rawValue }
            .compactMap { transaction -> Date? in
                if transaction.budgetAllocation == .custom {
                    return transaction.budgetMonthStart?.monthStart
                }
                return transaction.monthStart.monthStart
            }

        return (receivedMonths + budgetMonths)
            .filter { $0 <= month.monthStart }
            .min()
    }

    func paidExpenseTotal(in month: Date) -> Double {
        visibleTransactions(in: month)
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + paidAmount(for: $1, in: month) }
    }

    func categoryAmount(in month: Date, category: ExpenseCategory, paidOnly: Bool) -> Double {
        visibleTransactions(in: month)
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.expenseCategory == category.rawValue }
            .reduce(0) { total, transaction in
                total + (paidOnly ? paidAmount(for: transaction, in: month) : scheduledAmount(for: transaction, in: month))
            }
    }

    func expenseAmount(in month: Date, matching keywords: [String], paidOnly: Bool) -> Double {
        visibleTransactions(in: month)
            .filter { transaction in
                guard transaction.kind == TransactionKind.expense.rawValue else { return false }
                let searchableText = Self.normalized("\(transaction.displayName) \(transaction.title)")
                return keywords.contains { searchableText.contains($0) }
            }
            .reduce(0) { total, transaction in
                total + (paidOnly ? paidAmount(for: transaction, in: month) : scheduledAmount(for: transaction, in: month))
            }
    }

    func annualBalancePoints(in months: [Date], paidOnly: Bool = false) -> [MonthlyBalancePoint] {
        months.map { month in
            let summary = monthSummary(in: month)
            let expenses = paidOnly ? paidExpenseTotal(in: month) : summary.expenses
            return MonthlyBalancePoint(month: month, income: summary.income, expenses: expenses)
        }
    }

    func yearSavingsPoints(in months: [Date]) -> [MonthlyBalancePoint] {
        months.map { month in
            MonthlyBalancePoint(
                month: month,
                income: 0,
                expenses: expenseAmount(in: month, matching: ["poup", "saving"], paidOnly: false)
            )
        }
    }

    static func monthsInYear(_ year: Int) -> [Date] {
        (1...12).map { Date.monthStart(month: $0, year: year) }
    }

    static func months(from startMonth: Date, through endMonth: Date) -> [Date] {
        let monthCount = Calendar.current.dateComponents([.month], from: startMonth.monthStart, to: endMonth.monthStart).month ?? 0
        guard monthCount >= 0 else { return [] }

        return (0...monthCount).compactMap {
            Calendar.current.date(byAdding: .month, value: $0, to: startMonth.monthStart)
        }
    }

    static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }

    static func percentageText(_ amount: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }
}
