//
//  MoneyCalculationService.swift
//  MoneyControl
//

import Foundation

struct TransactionOccurrence {
    let transaction: MoneyTransaction
    let month: Date
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

struct AnalyticsInsight: Identifiable, Equatable {
    let title: String
    let message: String
    let infoTitle: String?
    let infoMessage: String?

    init(title: String, message: String, infoTitle: String? = nil, infoMessage: String? = nil) {
        self.title = title
        self.message = message
        self.infoTitle = infoTitle
        self.infoMessage = infoMessage
    }

    var id: String { "\(title)-\(message)" }
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

    func paidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        guard transaction.kind == TransactionKind.expense.rawValue else { return 0 }
        guard let payment = payments.first(where: { $0.transactionID == transaction.id && calendar.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else { return 0 }
        return min(payment.amountPaid ?? transaction.amount, transaction.amount)
    }

    func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        paidAmount(for: transaction, in: month) >= transaction.amount
    }

    func accountSummary(until now: Date) -> AccountSummary {
        let occurrences = accountOccurrencesUntilToday(now: now)
        let income = occurrences
            .filter { $0.transaction.kind == TransactionKind.income.rawValue }
            .reduce(0) { $0 + $1.transaction.amount }
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
            .reduce(0) { $0 + $1.amount }
        let unpaid = visible
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + max($1.amount - paidAmount(for: $1, in: month), 0) }

        return MonthBudgetSummary(income: income, expenses: expenses, unpaidExpenses: unpaid)
    }

    func cumulativeBudgetRemaining(through month: Date) -> Double {
        guard let firstMonth = firstBudgetRelevantMonth(through: month) else { return 0 }

        return Self.months(from: firstMonth, through: month.monthStart)
            .reduce(0) { $0 + monthSummary(in: $1).remaining }
    }

    func categoryExpenses(in month: Date) -> [CategoryExpensePoint] {
        categoryExpenses(in: [month])
    }

    func categoryExpenses(in months: [Date]) -> [CategoryExpensePoint] {
        ExpenseCategory.allCases.map { category in
            let amount = months.reduce(0) { total, month in
                total + categoryAmount(in: month, category: category, paidOnly: false)
            }
            return CategoryExpensePoint(category: category, amount: amount)
        }
    }

    func expenseTypePoints(in months: [Date], fallbackTitle: String) -> [ExpenseTypePoint] {
        var totals: [String: (title: String, category: ExpenseCategory, amount: Double)] = [:]

        months.forEach { month in
            visibleTransactions(in: month)
                .filter { $0.kind == TransactionKind.expense.rawValue }
                .forEach { transaction in
                    let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? "") ?? .needs
                    let title = transaction.displayName.isEmpty ? fallbackTitle : transaction.displayName
                    let key = "\(category.rawValue)-\(title)"
                    let currentAmount = totals[key]?.amount ?? 0
                    totals[key] = (title, category, currentAmount + transaction.amount)
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
            .reduce(0) { $0 + $1.amount }
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

    func reservedIncomeForFutureBudgets(until now: Date) -> [ReservedIncomeSummary] {
        let currentMonth = now.monthStart
        let receivedIncome = accountOccurrencesUntilToday(now: now)
            .filter { $0.transaction.kind == TransactionKind.income.rawValue }
            .filter { $0.transaction.budgetMonth(forReceivedMonth: $0.month) > currentMonth }

        let totals = receivedIncome.reduce(into: [Date: Double]()) { result, occurrence in
            let budgetMonth = occurrence.transaction.budgetMonth(forReceivedMonth: occurrence.month)
            result[budgetMonth, default: 0] += occurrence.transaction.amount
        }

        return totals
            .map { ReservedIncomeSummary(budgetMonth: $0.key, amount: $0.value) }
            .sorted { $0.budgetMonth < $1.budgetMonth }
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
                total + (paidOnly ? paidAmount(for: transaction, in: month) : transaction.amount)
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
                total + (paidOnly ? paidAmount(for: transaction, in: month) : transaction.amount)
            }
    }

    func annualBalancePoints(in months: [Date]) -> [MonthlyBalancePoint] {
        months.map { month in
            let summary = monthSummary(in: month)
            return MonthlyBalancePoint(month: month, income: summary.income, expenses: summary.expenses)
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

    func analyticsInsights(currentMonth: Date) -> [AnalyticsInsight] {
        let previousMonth = currentMonth.previousMonthStart
        guard paidExpenseTotal(in: previousMonth) > 0 else { return [] }

        var insights: [AnalyticsInsight] = []
        let title = AppStrings.text(.paidInsights)

        let currentRestaurants = expenseAmount(in: currentMonth, matching: ["refeic", "restaurante"], paidOnly: true)
        let previousRestaurants = expenseAmount(in: previousMonth, matching: ["refeic", "restaurante"], paidOnly: true)
        if previousRestaurants > 0, currentRestaurants > previousRestaurants {
            insights.append(AnalyticsInsight(
                title: title,
                message: String(format: AppStrings.text(.restaurantsIncreasedInsight), Self.percentageText(currentRestaurants - previousRestaurants, total: previousRestaurants))
            ))
        }

        let currentGroceries = expenseAmount(in: currentMonth, matching: ["aliment", "supermercado"], paidOnly: true)
        let previousGroceries = expenseAmount(in: previousMonth, matching: ["aliment", "supermercado"], paidOnly: true)
        if previousGroceries > 0, currentGroceries < previousGroceries {
            insights.append(AnalyticsInsight(
                title: title,
                message: String(format: AppStrings.text(.groceriesDecreasedInsight), Self.percentageText(previousGroceries - currentGroceries, total: previousGroceries))
            ))
        }

        let currentSavings = categoryAmount(in: currentMonth, category: .savingsAndDebt, paidOnly: true)
        let previousSavings = categoryAmount(in: previousMonth, category: .savingsAndDebt, paidOnly: true)
        if currentSavings > previousSavings {
            insights.append(AnalyticsInsight(
                title: title,
                message: String(format: AppStrings.text(.savingsIncreasedInsight), (currentSavings - previousSavings).currencyText)
            ))
        }

        let subscriptions = expenseAmount(in: currentMonth, matching: ["subscr"], paidOnly: true)
        let income = incomeTotal(in: currentMonth)
        if income > 0, subscriptions > 0 {
            insights.append(AnalyticsInsight(
                title: title,
                message: String(format: AppStrings.text(.subscriptionsIncomeInsight), Self.percentageText(subscriptions, total: income))
            ))
        }

        return insights
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
