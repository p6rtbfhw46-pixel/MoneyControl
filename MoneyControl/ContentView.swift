//
//  ContentView.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import SwiftData
import SwiftUI
import Charts
import UserNotifications

private enum MainTab {
    case currentAccount
    case credits
    case management
}

private enum AnalyticsExpenseTab {
    case whereSpent
    case budgetRule
}

private enum AnalyticsPeriod {
    case month
    case year
}

private enum CurrentAccountPaymentFilter: String, CaseIterable, Identifiable {
    case all
    case paid
    case unpaid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            AppStrings.text(.all)
        case .paid:
            AppStrings.text(.paidPlural)
        case .unpaid:
            AppStrings.text(.unpaidPlural)
        }
    }
}

private enum AnalyticsListTab: String, CaseIterable, Identifiable {
    case subscriptions
    case savings
    case incomeVsExpenses

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscriptions:
            AppStrings.text(.subscriptionsThisMonth)
        case .savings:
            AppStrings.text(.yearSavings)
        case .incomeVsExpenses:
            AppStrings.text(.incomeVsExpenses)
        }
    }
}

private enum SubscriptionAnalysisScope: String, CaseIterable, Identifiable {
    case monthly
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            AppStrings.text(.monthlyRecurrence)
        case .all:
            AppStrings.text(.all)
        }
    }
}

private struct ExpenseNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct PaymentEditorRequest: Identifiable {
    let id = UUID()
    let transaction: MoneyTransaction
    let month: Date
    let initialAmount: Double
}

private struct SavingsHistoryRequest: Identifiable {
    let month: Date

    var id: Date { month }
}

private struct SavingsHistoryLine: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: Double
    let icon: String
}

private struct ExpensePaymentReminder: Sendable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]

    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
    @AppStorage("currentAccountPaymentFilter") private var storedPaymentFilter = CurrentAccountPaymentFilter.all.rawValue
    @AppStorage("currentAccountFilteredCategories") private var storedFilteredCategories = ""
    @AppStorage("currentAccountFilteredExpenseType") private var storedFilteredExpenseType = ""
    @AppStorage("currentAccountFreeTextFilter") private var storedFreeTextFilter = ""
    @State private var selectedMonthOffset = 0
    @State private var monthNavigationDirection = 1
    @State private var selectedTab: MainTab = .currentAccount
    @State private var selectedAnalyticsExpenseTab: AnalyticsExpenseTab = .whereSpent
    @State private var selectedAnalyticsPeriod: AnalyticsPeriod = .month
    @State private var selectedAnalyticsMonthOffset = 0
    @State private var selectedAnalyticsListTab: AnalyticsListTab = .subscriptions
    @State private var selectedSubscriptionAnalysisScope: SubscriptionAnalysisScope = .monthly
    @State private var selectedInsightIndex = 0
    @State private var selectedAdviceIndex = 0
    @State private var editorRequest: TransactionEditorRequest?
    @State private var paymentEditorRequest: PaymentEditorRequest?
    @State private var showsSettings = false
    @State private var settingsInitialTab: SettingsTab = .budget
    @State private var showsQuickActions = false
    @State private var showsFilters = false
    @State private var paymentFilter: CurrentAccountPaymentFilter = .all
    @State private var filteredCategories: Set<ExpenseCategory> = []
    @State private var filteredExpenseType = ""
    @State private var freeTextFilter = ""
    @State private var expenseNotice: ExpenseNotice?
    @State private var savingsHistoryRequest: SavingsHistoryRequest?
    @State private var didLoadStoredFilters = false
    @State private var didCheckOverdueExpenses = false

    private let monthOffsets = Array(-24...24)
    private var selectedMonth: Date { Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date().monthStart) ?? Date().monthStart }
    private var currentMonth: Date { Date().monthStart }
    private var calculator: MoneyCalculationService {
        MoneyCalculationService(transactions: transactions, payments: payments, exclusions: exclusions)
    }
    private var selectedTransactions: [MoneyTransaction] { calculator.visibleTransactions(in: selectedMonth) }
    private var selectedFilteredTransactions: [MoneyTransaction] { filteredTransactions(in: selectedMonth) }
    private var currentMonthTransactions: [MoneyTransaction] { calculator.visibleTransactions(in: currentMonth) }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentYearMonths: [Date] {
        MoneyCalculationService.monthsInYear(currentYear)
    }
    private var notificationScheduleSignature: String {
        let transactionSignature = transactions
            .map { transaction in
                [
                    transaction.id.uuidString,
                    transaction.title,
                    transaction.displayName,
                    transaction.kind,
                    transaction.expenseCategory ?? "",
                    "\(transaction.day)",
                    "\(transaction.amount)",
                    transaction.monthStart.ISO8601Format(),
                    transaction.recurrenceType ?? "",
                    "\(transaction.recurrenceMonth)",
                    transaction.recurrenceEndMonthStart?.ISO8601Format() ?? ""
                ].joined(separator: "|")
            }
            .sorted()
            .joined(separator: ";")
        let paymentSignature = payments
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())|\($0.amountPaid ?? -1)" }
            .sorted()
            .joined(separator: ";")
        let exclusionSignature = exclusions
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())" }
            .sorted()
            .joined(separator: ";")

        return [transactionSignature, paymentSignature, exclusionSignature].joined(separator: "#")
    }

    private var activeFilterCount: Int {
        var count = 0
        if paymentFilter != .all { count += 1 }
        if !filteredCategories.isEmpty { count += 1 }
        if !filteredExpenseType.isEmpty { count += 1 }
        if !freeTextFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        return count
    }
    private var selectedMonthExpenseTypeOptions: [ExpenseTypePoint] {
        var options: [String: ExpenseTypePoint] = [:]

        selectedTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .forEach { transaction in
                guard !transaction.displayName.isEmpty,
                      let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
                else { return }

                let key = "\(category.rawValue)-\(transaction.displayName)"
                options[key] = ExpenseTypePoint(title: transaction.displayName, category: category, amount: 0)
            }

        return options.values.sorted { first, second in
            first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
        }
    }
    private var accountOccurrencesUntilToday: [TransactionOccurrence] {
        calculator.accountOccurrencesUntilToday(now: Date())
    }
    private var accountSummary: AccountSummary {
        calculator.accountSummary(until: Date())
    }
    private var futureBudgetReservations: [ReservedIncomeSummary] {
        accountSummary.reservedForFutureBudgets
    }
    private var firstFutureBudgetReservation: ReservedIncomeSummary? {
        futureBudgetReservations.first
    }
    private var futureBudgetReservationTotal: Double {
        accountSummary.reservedForFutureBudgetsTotal
    }
    private var futureBudgetReservationFootnote: String {
        guard let firstFutureBudgetReservation else { return "" }
        let total = futureBudgetReservationTotal
        return String(
            format: AppStrings.text(.reservedForBudgetSummary),
            total.currencyText,
            firstFutureBudgetReservation.budgetMonth.monthTitle
        )
    }
    private var balanceHelpText: String {
        guard let firstFutureBudgetReservation, futureBudgetReservationTotal > 0 else {
            return AppStrings.text(.balanceThisMonthHelp)
        }

        return String(
            format: AppStrings.text(.reservedBalanceHelpMessage),
            inAccount.currencyText,
            futureBudgetReservationTotal.currencyText,
            firstFutureBudgetReservation.budgetMonth.monthTitle,
            currentMonth.monthTitle
        )
    }

    private var monthUnpaidExpenses: Double {
        calculator.monthSummary(in: selectedMonth).unpaidExpenses
    }

    private var monthIncome: Double {
        calculator.monthSummary(in: selectedMonth).income
    }

    private var monthExpenses: Double {
        calculator.monthSummary(in: selectedMonth).expenses
    }

    private var incomeUntilToday: Double {
        accountSummary.incomeUntilToday
    }

    private var paidExpensesUntilToday: Double {
        accountSummary.paidExpensesUntilToday
    }

    private var inAccount: Double { accountSummary.availableBalance }
    private var isSelectedMonthInSpendableWindow: Bool {
        guard let maximumMonth = Calendar.current.date(byAdding: .month, value: 2, to: currentMonth) else {
            return Calendar.current.isDate(selectedMonth, equalTo: currentMonth, toGranularity: .month)
        }

        return selectedMonth >= currentMonth && selectedMonth <= maximumMonth.monthStart
    }
    private var monthRemaining: Double? {
        guard isSelectedMonthInSpendableWindow else { return nil }
        return calculator.cumulativeBudgetRemaining(through: selectedMonth)
    }
    private var selectedAnalyticsMonth: Date {
        Calendar.current.date(byAdding: .month, value: selectedAnalyticsMonthOffset, to: Date().monthStart) ?? Date().monthStart
    }
    private var analyticsMonths: [Date] {
        selectedAnalyticsPeriod == .month ? [selectedAnalyticsMonth] : currentYearMonths
    }
    private var analyticsCategoryExpenses: [CategoryExpensePoint] {
        calculator.categoryExpenses(in: analyticsMonths)
    }
    private var analyticsExpenseTotal: Double {
        analyticsCategoryExpenses.reduce(0) { $0 + $1.amount }
    }
    private var analyticsExpenseTypePoints: [ExpenseTypePoint] {
        expenseTypePoints(in: analyticsMonths)
    }
    private var budgetReferencePoints: [CategoryExpensePoint] {
        [
            CategoryExpensePoint(category: .needs, amount: 50),
            CategoryExpensePoint(category: .wants, amount: 30),
            CategoryExpensePoint(category: .savingsAndDebt, amount: 20)
        ]
    }
    private var annualBalancePoints: [MonthlyBalancePoint] {
        calculator.annualBalancePoints(in: currentYearMonths)
    }
    private var annualBalanceTotal: Double {
        annualBalancePoints.reduce(0) { $0 + $1.balance }
    }
    private var configuredSubscriptions: [MoneyTransaction] {
        transactions
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue
                    && transaction.isRecurring
                    && transaction.isActiveForSettingsList
                    && normalized(transaction.displayName).contains("subscr")
            }
            .sorted { first, second in
                if first.displayName != second.displayName {
                    return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
                }
                return first.monthStart < second.monthStart
            }
    }
    private var displayedConfiguredSubscriptions: [MoneyTransaction] {
        switch selectedSubscriptionAnalysisScope {
        case .monthly:
            configuredSubscriptions.filter { $0.recurrence == .monthly }
        case .all:
            configuredSubscriptions
        }
    }
    private var yearSavingsPoints: [MonthlyBalancePoint] {
        let currentAccountPoints = calculator.yearSavingsPoints(in: currentYearMonths)

        return currentAccountPoints.map { point in
            MonthlyBalancePoint(
                month: point.month,
                income: point.income,
                expenses: point.expenses + directSavingsAmount(in: point.month)
            )
        }
    }

    private var linkedSavingMovementIDs: Set<UUID> {
        Set(transactions.compactMap(\.linkedSavingMovementID))
    }

    private func directSavingsAmount(in month: Date) -> Double {
        let initialAmounts = savingAccounts
            .filter { Calendar.current.isDate($0.createdAt, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + max($1.initialAmount, 0) }

        let directDeposits = savingMovements
            .filter { movement in
                Calendar.current.isDate(movement.date, equalTo: month, toGranularity: .month)
                    && movement.kind == .deposit
                    && !linkedSavingMovementIDs.contains(movement.id)
            }
            .reduce(0) { $0 + abs($1.amount) }

        return initialAmounts + directDeposits
    }

    private func savingsHistoryAmount(in month: Date) -> Double {
        savingsHistoryLines(in: month).reduce(0) { $0 + $1.amount }
    }

    private func savingsHistoryLines(in month: Date) -> [SavingsHistoryLine] {
        let currentAccountLines = calculator.visibleTransactions(in: month)
            .filter { transaction in
                guard transaction.kind == TransactionKind.expense.rawValue else { return false }
                let searchableText = normalized("\(transaction.displayName) \(transaction.title)")
                return searchableText.contains("poup") || searchableText.contains("saving")
            }
            .map { transaction in
                SavingsHistoryLine(
                    title: analyticsTransactionTitle(for: transaction),
                    subtitle: "\(AppStrings.text(.currentAccountSavingSource)) · \(AppStrings.text(.day)) \(transaction.effectiveDay(in: month))",
                    amount: transaction.amount,
                    icon: "list.bullet.rectangle"
                )
            }

        let initialLines = savingAccounts
            .filter { Calendar.current.isDate($0.createdAt, equalTo: month, toGranularity: .month) && $0.initialAmount > 0 }
            .map { saving in
                SavingsHistoryLine(
                    title: saving.name,
                    subtitle: AppStrings.text(.initialSavingAmount),
                    amount: saving.initialAmount,
                    icon: "target"
                )
            }

        let directDepositLines = savingMovements
            .filter { movement in
                Calendar.current.isDate(movement.date, equalTo: month, toGranularity: .month)
                    && movement.kind == .deposit
                    && !linkedSavingMovementIDs.contains(movement.id)
            }
            .map { movement in
                SavingsHistoryLine(
                    title: movement.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? savingName(for: movement.savingID) : movement.note,
                    subtitle: "\(AppStrings.text(.directSavingMovement)) · \(movement.date.formatted(.dateTime.day().month(.abbreviated)))",
                    amount: abs(movement.amount),
                    icon: "banknote.fill"
                )
            }

        return (currentAccountLines + initialLines + directDepositLines)
            .sorted { first, second in
                if first.amount != second.amount { return first.amount > second.amount }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    private func savingName(for id: UUID) -> String {
        savingAccounts.first { $0.id == id }?.name ?? SavingsStrings.text(.saving)
    }
    private var analyticsInsights: [AnalyticsInsight] {
        calculator.analyticsInsights(currentMonth: currentMonth) + futureBudgetInsights + savingInsights + creditInsights
    }

    private var futureBudgetInsights: [AnalyticsInsight] {
        guard let firstFutureBudgetReservation, futureBudgetReservationTotal > 0 else { return [] }

        let receivedThisMonth = accountOccurrencesUntilToday
            .filter { occurrence in
                occurrence.transaction.kind == TransactionKind.income.rawValue
                    && Calendar.current.isDate(occurrence.month, equalTo: currentMonth, toGranularity: .month)
                    && occurrence.transaction.budgetMonth(forReceivedMonth: occurrence.month) > currentMonth
            }
            .reduce(0) { $0 + $1.transaction.amount }

        var insights: [AnalyticsInsight] = []
        if receivedThisMonth > 0 {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.paidInsights),
                    message: String(
                        format: AppStrings.text(.futureIncomeReceivedInsight),
                        receivedThisMonth.currencyText,
                        firstFutureBudgetReservation.budgetMonth.monthTitle
                    )
                )
            )
        }

        insights.append(
            AnalyticsInsight(
                title: AppStrings.text(.paidInsights),
                message: String(
                    format: AppStrings.text(.futureIncomeReservedInsight),
                    futureBudgetReservationTotal.currencyText,
                    firstFutureBudgetReservation.budgetMonth.monthTitle
                )
            )
        )

        return insights
    }

    private var savingInsights: [AnalyticsInsight] {
        savingTargetInsights + savingMovementInsights + balancedBudgetInsights
    }

    private var creditInsights: [AnalyticsInsight] {
        creditPayoffInsights + creditPortfolioInsights + creditSettledInsights
    }

    private var savingTargetInsights: [AnalyticsInsight] {
        let savingsWithTargets = analyticsSavingAccounts.compactMap { saving -> (saving: SavingAccount, balance: Double, target: Double, progress: Double)? in
            guard let target = saving.targetAmount, target > 0 else { return nil }
            let balance = saving.balance(with: savingMovements)
            return (saving: saving, balance: balance, target: target, progress: balance / target)
        }

        var insights: [AnalyticsInsight] = []

        savingsWithTargets
            .filter { $0.progress >= 1 }
            .forEach { item in
                insights.append(
                    AnalyticsInsight(
                        title: AppStrings.text(.savingsAnalysis),
                        message: String(
                            format: AppStrings.text(.savingTargetReachedInsight),
                            item.saving.name,
                            item.target.currencyText
                        )
                    )
                )
            }

        savingsWithTargets
            .filter { $0.progress >= 0.75 && $0.progress < 1 }
            .forEach { item in
                insights.append(
                    AnalyticsInsight(
                        title: AppStrings.text(.savingsAnalysis),
                        message: String(
                            format: AppStrings.text(.savingNearTargetInsight),
                            max(item.target - item.balance, 0).currencyText,
                            item.saving.name
                        )
                    )
                )
            }

        if savingsWithTargets.count > 1,
           let closest = savingsWithTargets
            .filter({ $0.progress < 1 })
            .max(by: { $0.progress < $1.progress }) {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.savingsAnalysis),
                    message: String(
                        format: AppStrings.text(.closestSavingTargetInsight),
                        closest.saving.name,
                        percentageText(closest.balance, total: closest.target)
                    )
                )
            )
        }

        return insights
    }

    private var savingMovementInsights: [AnalyticsInsight] {
        let currentSavings = savingsHistoryAmount(in: currentMonth)
        let previousSavings = savingsHistoryAmount(in: currentMonth.previousMonthStart)
        let currentMonthRemaining = calculator.monthSummary(in: currentMonth).remaining
        var insights: [AnalyticsInsight] = []

        if currentSavings > previousSavings {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.savingsAnalysis),
                    message: String(
                        format: AppStrings.text(.totalSavingsIncreasedInsight),
                        (currentSavings - previousSavings).currencyText
                    )
                )
            )
        }

        if currentSavings <= 0, currentMonthRemaining > 0 {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.savingsAnalysis),
                    message: String(
                        format: AppStrings.text(.noSavingMovementInsight),
                        (currentMonthRemaining * 0.10).currencyText
                    )
                )
            )
        }

        if currentMonthRemaining > 0 {
            if analyticsCreditDebtTotal <= 0 {
                let suggestedSaving = currentMonthRemaining * 0.25
                insights.append(
                    AnalyticsInsight(
                        title: AppStrings.text(.savingsAnalysis),
                        message: String(
                            format: AppStrings.text(.positiveRemainingSavingSuggestionInsight),
                            currentMonthRemaining.currencyText,
                            suggestedSaving.currencyText
                        )
                    )
                )
            }

        }

        return insights
    }

    private var balancedBudgetInsights: [AnalyticsInsight] {
        let summary = calculator.monthSummary(in: currentMonth)
        guard summary.income > 0 else { return [] }

        let savingsAndDebt = calculator.categoryAmount(in: currentMonth, category: .savingsAndDebt, paidOnly: true) + directSavingsAmount(in: currentMonth)
        let needs = calculator.categoryAmount(in: currentMonth, category: .needs, paidOnly: false)
        let wants = calculator.categoryAmount(in: currentMonth, category: .wants, paidOnly: false)
        var insights: [AnalyticsInsight] = []

        if savingsAndDebt / summary.income >= 0.20 {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.savingsAnalysis),
                    message: String(
                        format: AppStrings.text(.savingsAndDebtRuleMetInsight),
                        percentageText(savingsAndDebt, total: summary.income)
                    )
                )
            )
        }

        if summary.remaining > 0,
           needs <= summary.income * 0.50,
           wants <= summary.income * 0.30 {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.paidInsights),
                    message: String(
                        format: AppStrings.text(.balancedBudgetSurplusInsight),
                        summary.remaining.currencyText
                    )
                )
            )
        }

        return insights
    }

    private var creditExtraPaymentInsights: [AnalyticsInsight] {
        let currentMonthRemaining = calculator.monthSummary(in: currentMonth).remaining
        guard currentMonthRemaining > 0 else { return [] }
        let suggestedPayment = currentMonthRemaining * 0.25
        guard suggestedPayment > 0 else { return [] }

        return analyticsCreditAccounts.compactMap { credit in
            guard credit.balance(with: creditMovements) > 0 else { return nil }

            return AnalyticsInsight(
                title: AppStrings.text(.creditAnalysis),
                message: String(
                    format: AppStrings.text(.creditExtraPaymentInsight),
                    currentMonthRemaining.currencyText,
                    suggestedPayment.currencyText,
                    credit.name,
                    (currentMonthRemaining - suggestedPayment).currencyText
                ),
                infoTitle: AppStrings.text(.creditEstimateHelpTitle),
                infoMessage: AppStrings.text(.creditEstimateHelpMessage)
            )
        }
    }

    private var creditPayoffInsights: [AnalyticsInsight] {
        let recentMonths = (0..<6).compactMap {
            Calendar.current.date(byAdding: .month, value: -$0, to: currentMonth)
        }

        return analyticsCreditAccounts.compactMap { credit in
            let monthlyPayments = recentMonths.map { month in
                credit.monthPaid(in: month, movements: creditMovements)
            }
            let monthsWithPayments = monthlyPayments.filter { $0 > 0 }
            guard monthsWithPayments.count >= 2 else { return nil }

            let averagePayment = monthsWithPayments.reduce(0, +) / Double(monthsWithPayments.count)
            let balance = credit.balance(with: creditMovements)
            guard averagePayment > 0, balance > 0 else { return nil }

            let estimatedMonths = max(Int(ceil(balance / averagePayment)), 1)
            return AnalyticsInsight(
                title: AppStrings.text(.creditAnalysis),
                message: String(
                    format: AppStrings.text(.creditPayoffInsight),
                    averagePayment.currencyText,
                    credit.name,
                    payoffDurationText(months: estimatedMonths)
                ),
                infoTitle: AppStrings.text(.creditEstimateHelpTitle),
                infoMessage: AppStrings.text(.creditEstimateHelpMessage)
            )
        }
    }

    private var creditPortfolioInsights: [AnalyticsInsight] {
        let activeDebts = analyticsCreditAccounts
            .map { credit in (credit: credit, balance: credit.balance(with: creditMovements)) }
            .filter { $0.balance > 0 }
            .sorted { first, second in
                if first.balance != second.balance { return first.balance < second.balance }
                return first.credit.name.localizedCaseInsensitiveCompare(second.credit.name) == .orderedAscending
            }
        let totalActiveDebt = activeDebts.reduce(0) { $0 + $1.balance }
        var insights: [AnalyticsInsight] = []

        if totalActiveDebt > 0 {
            let monthlyPayment = ceil(totalActiveDebt / 100) > 12 ? 200.0 : 100.0
            let estimatedMonths = max(Int(ceil(totalActiveDebt / monthlyPayment)), 1)
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.creditAnalysis),
                    message: String(
                        format: AppStrings.text(.totalCreditPayoffPlanInsight),
                        totalActiveDebt.currencyText,
                        monthlyPayment.currencyText,
                        payoffDurationText(months: estimatedMonths)
                    ),
                    infoTitle: AppStrings.text(.creditEstimateHelpTitle),
                    infoMessage: AppStrings.text(.creditEstimateHelpMessage)
                )
            )
        }

        if activeDebts.count > 1, let smallest = activeDebts.first, let largest = activeDebts.last {
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.creditAnalysis),
                    message: String(
                        format: AppStrings.text(.smallestCreditInsight),
                        smallest.credit.name,
                        smallest.balance.currencyText
                    )
                )
            )
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.creditAnalysis),
                    message: String(
                        format: AppStrings.text(.largestCreditInsight),
                        largest.credit.name,
                        largest.balance.currencyText,
                        totalActiveDebt.currencyText
                    )
                )
            )
        }

        let previousTotalDebt = totalCreditDebt(through: currentMonth.previousMonthStart)
        let currentTotalDebt = totalCreditDebt(through: currentMonth)
        let debtDifference = currentTotalDebt - previousTotalDebt
        if previousTotalDebt > 0, abs(debtDifference) >= 0.01 {
            let key: AppTextKey = debtDifference < 0 ? .totalDebtDecreasedInsight : .totalDebtIncreasedInsight
            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.creditAnalysis),
                    message: String(format: AppStrings.text(key), abs(debtDifference).currencyText)
                )
            )
        }

        activeDebts.forEach { item in
            let averagePayment = averageRecentCreditPayment(for: item.credit, minimumMonthsWithPayments: 2)
            guard averagePayment > 0 else { return }
            let estimatedMonths = max(Int(ceil(item.balance / averagePayment)), 1)
            guard estimatedMonths <= 3 else { return }

            insights.append(
                AnalyticsInsight(
                    title: AppStrings.text(.creditAnalysis),
                    message: String(
                        format: AppStrings.text(.creditNearPayoffInsight),
                        averagePayment.currencyText,
                        item.credit.name,
                        payoffDurationText(months: estimatedMonths)
                    ),
                    infoTitle: AppStrings.text(.creditEstimateHelpTitle),
                    infoMessage: AppStrings.text(.creditEstimateHelpMessage)
                )
            )
        }

        return insights
    }

    private var creditSettledInsights: [AnalyticsInsight] {
        let activeDebts = analyticsCreditAccounts
            .map { credit in (credit: credit, balance: credit.balance(with: creditMovements)) }
            .filter { $0.balance > 0 }
            .sorted { first, second in
                if first.balance != second.balance { return first.balance < second.balance }
                return first.credit.name.localizedCaseInsensitiveCompare(second.credit.name) == .orderedAscending
            }

        return creditAccounts.flatMap { credit -> [AnalyticsInsight] in
            let previousBalance = creditBalance(for: credit, through: currentMonth.previousMonthStart)
            let currentBalance = creditBalance(for: credit, through: currentMonth)
            guard previousBalance > 0, currentBalance <= 0 else { return [] }

            let averagePayment = averageRecentCreditPayment(for: credit, minimumMonthsWithPayments: 1)
            guard averagePayment > 0 else { return [] }

            var insights = [
                AnalyticsInsight(
                    title: AppStrings.text(.creditAnalysis),
                    message: String(
                        format: AppStrings.text(.creditSettledInsight),
                        credit.name,
                        averagePayment.currencyText
                    )
                )
            ]

            if let nextCredit = activeDebts.first(where: { $0.credit.id != credit.id }) {
                insights.append(
                    AnalyticsInsight(
                        title: AppStrings.text(.creditAnalysis),
                        message: String(
                            format: AppStrings.text(.creditSettledRedirectInsight),
                            credit.name,
                            averagePayment.currencyText,
                            nextCredit.credit.name
                        )
                    )
                )
            } else {
                insights.append(
                    AnalyticsInsight(
                        title: AppStrings.text(.creditAnalysis),
                        message: String(
                            format: AppStrings.text(.debtFreeSavingsInsight),
                            averagePayment.currencyText,
                            (averagePayment * 12).currencyText
                        )
                    )
                )
            }

            return insights
        }
    }

    private func totalCreditDebt(through month: Date) -> Double {
        creditAccounts.reduce(0) { $0 + creditBalance(for: $1, through: month) }
    }

    private func creditBalance(for credit: CreditAccount, through month: Date) -> Double {
        guard credit.createdAt.monthStart <= month.monthStart else { return 0 }
        let movementsUntilMonth = creditMovements.filter { movement in
            movement.creditID == credit.id && movement.date.monthStart <= month.monthStart
        }
        return max(credit.initialDebt + movementsUntilMonth.reduce(0) { $0 + $1.balanceEffect }, 0)
    }

    private func averageRecentCreditPayment(for credit: CreditAccount, minimumMonthsWithPayments: Int) -> Double {
        let recentMonths = (0..<6).compactMap {
            Calendar.current.date(byAdding: .month, value: -$0, to: currentMonth)
        }
        let monthlyPayments = recentMonths
            .map { credit.monthPaid(in: $0, movements: creditMovements) }
            .filter { $0 > 0 }
        guard monthlyPayments.count >= minimumMonthsWithPayments else { return 0 }
        return monthlyPayments.reduce(0, +) / Double(monthlyPayments.count)
    }

    private func payoffDurationText(months: Int) -> String {
        if months < 12 {
            return "\(months) \(months == 1 ? AppStrings.text(.durationMonthSingular) : AppStrings.text(.durationMonthPlural))"
        }

        let years = months / 12
        let remainingMonths = months % 12
        let yearText = "\(years) \(years == 1 ? AppStrings.text(.durationYearSingular) : AppStrings.text(.durationYearPlural))"
        guard remainingMonths > 0 else { return yearText }

        let monthText = "\(remainingMonths) \(remainingMonths == 1 ? AppStrings.text(.durationMonthSingular) : AppStrings.text(.durationMonthPlural))"
        return "\(yearText) \(AppStrings.text(.durationAnd)) \(monthText)"
    }
    private var analyticsAnalysisTitle: String {
        switch selectedAnalyticsPeriod {
        case .month:
            "\(AppStrings.text(.monthAnalysis)) \(selectedAnalyticsMonth.monthTitle)"
        case .year:
            "\(AppStrings.text(.annualBalance)) \(currentYear)"
        }
    }
    private var currentAdvice: (title: String, message: String) {
        let adviceCards = AppStrings.analyticsAdviceCards
        let index = selectedAdviceIndex % adviceCards.count
        return adviceCards[index]
    }
    private var navigationTitle: String {
        switch selectedTab {
        case .currentAccount:
            AppStrings.text(.appName)
        case .credits:
            AppStrings.text(.credits)
        case .management:
            AppStrings.text(.management)
        }
    }

    private func categoryExpenses(in month: Date) -> [CategoryExpensePoint] {
        calculator.categoryExpenses(in: month)
    }

    private func expenseTypePoints(in months: [Date]) -> [ExpenseTypePoint] {
        calculator.expenseTypePoints(in: months, fallbackTitle: AppStrings.text(.expense))
    }

    private func incomeTotal(in month: Date) -> Double {
        calculator.incomeTotal(in: month)
    }

    private func paidExpenseTotal(in month: Date) -> Double {
        calculator.paidExpenseTotal(in: month)
    }

    private func categoryAmount(in month: Date, category: ExpenseCategory, paidOnly: Bool) -> Double {
        calculator.categoryAmount(in: month, category: category, paidOnly: paidOnly)
    }

    private func expenseAmount(in month: Date, matching keywords: [String], paidOnly: Bool) -> Double {
        calculator.expenseAmount(in: month, matching: keywords, paidOnly: paidOnly)
    }

    private func normalized(_ value: String) -> String {
        MoneyCalculationService.normalized(value)
    }

    private func filteredTransactions(in month: Date) -> [MoneyTransaction] {
        calculator
            .visibleTransactions(in: month)
            .filter { transactionMatchesCurrentAccountFilters($0, in: month) }
    }

    private func transactionMatchesCurrentAccountFilters(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        if paymentFilter != .all {
            guard transaction.kind == TransactionKind.expense.rawValue else { return false }
            let paid = isPaid(transaction, in: month)
            if paymentFilter == .paid && !paid { return false }
            if paymentFilter == .unpaid && paid { return false }
        }

        if !filteredCategories.isEmpty {
            guard transaction.kind == TransactionKind.expense.rawValue,
                  let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? ""),
                  filteredCategories.contains(category)
            else { return false }
        }

        if !filteredExpenseType.isEmpty {
            guard transaction.kind == TransactionKind.expense.rawValue,
                  transaction.displayName == filteredExpenseType
            else { return false }
        }

        let searchText = normalized(freeTextFilter.trimmingCharacters(in: .whitespacesAndNewlines))
        if !searchText.isEmpty {
            let transactionText = normalized("\(transaction.displayName) \(transaction.title) \(transaction.detailText(in: month))")
            guard transactionText.contains(searchText) else { return false }
        }

        return true
    }

    private func clearCurrentAccountFilters() {
        paymentFilter = .all
        filteredCategories = []
        filteredExpenseType = ""
        freeTextFilter = ""
    }

    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .currentAccount:
                    currentAccountView
                case .credits:
                    creditsView
                case .management:
                    managementView
                }
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    appIcon
                }
                ToolbarItem(placement: .topBarTrailing) {
                    settingsToolbarButton
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomArea
            }
            .sheet(item: $editorRequest) { request in
                TransactionEditor(request: request)
            }
            .sheet(item: $paymentEditorRequest) { request in
                PaymentAmountPicker(
                    title: request.transaction.displayName,
                    totalAmount: request.transaction.amount,
                    initialAmount: request.initialAmount,
                    paymentDate: request.month.date(day: request.transaction.effectiveDay(in: request.month)),
                    history: paymentHistoryEntries(for: request.transaction, in: request.month),
                    onConfirm: { amount in
                        addPaymentAmount(request.transaction, in: request.month, amount: amount)
                    },
                    onDeleteHistoryEntry: { entry in
                        deletePaymentHistoryEntry(entry, for: request.transaction, in: request.month)
                    }
                )
            }
            .sheet(isPresented: $showsSettings) {
                SettingsEditor(openingTab: settingsInitialTab)
            }
            .sheet(isPresented: $showsFilters) {
                CurrentAccountFilterView(
                    paymentFilter: $paymentFilter,
                    filteredCategories: $filteredCategories,
                    filteredExpenseType: $filteredExpenseType,
                    freeTextFilter: $freeTextFilter,
                    expenseTypeOptions: selectedMonthExpenseTypeOptions,
                    onClear: clearCurrentAccountFilters
                )
            }
            .sheet(item: $savingsHistoryRequest) { request in
                SavingsHistorySheet(
                    month: request.month,
                    lines: savingsHistoryLines(in: request.month),
                    total: savingsHistoryAmount(in: request.month)
                )
            }
            .alert(item: $expenseNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text(AppStrings.text(.ok)))
                )
            }
            .onAppear(perform: handleAppear)
            .task(id: notificationScheduleSignature) {
                await refreshExpensePaymentNotifications()
            }
            .onChange(of: paymentFilter) { _, _ in persistCurrentAccountFilters() }
            .onChange(of: filteredCategories) { _, _ in persistCurrentAccountFilters() }
            .onChange(of: filteredExpenseType) { _, _ in persistCurrentAccountFilters() }
            .onChange(of: freeTextFilter) { _, _ in persistCurrentAccountFilters() }
            .id(selectedCurrencyCode)
        }
    }

    private var currentAccountView: some View {
        VStack(spacing: 0) {
            summaryBar

            monthHeader

            MonthPage(
                month: selectedMonth,
                transactions: filteredTransactions(in: selectedMonth),
                payments: payments,
                paymentHistory: paymentHistory,
                creditAccounts: creditAccounts,
                savingAccounts: savingAccounts,
                onPay: { transaction, month, initialAmount in
                    paymentEditorRequest = PaymentEditorRequest(transaction: transaction, month: month, initialAmount: initialAmount)
                },
                onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: selectedMonth, editScope: $0.isRecurring ? .singleMonth : .normal) },
                onDelete: { deleteTransaction($0, in: selectedMonth) }
            )
            .id(selectedMonthOffset)
            .transition(monthPageTransition)
            .animation(.snappy, value: selectedMonthOffset)

            monthNavigationBar
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(height: 52)
        }
    }

    private var monthPageTransition: AnyTransition {
        let insertionEdge: Edge = monthNavigationDirection > 0 ? .trailing : .leading
        let removalEdge: Edge = monthNavigationDirection > 0 ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var monthHeader: some View {
        HStack(spacing: 16) {
            monthArrowButton(systemImage: "chevron.left") {
                moveMonth(by: -1)
            }
            .disabled(selectedMonthOffset <= (monthOffsets.first ?? 0))
            .opacity(selectedMonthOffset <= (monthOffsets.first ?? 0) ? 0.35 : 1)

            Text(selectedMonth.monthTitle)
                .font(.title.bold())
                .foregroundStyle(AppPalette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            monthArrowButton(systemImage: "chevron.right") {
                moveMonth(by: 1)
            }
            .disabled(selectedMonthOffset >= (monthOffsets.last ?? 0))
            .opacity(selectedMonthOffset >= (monthOffsets.last ?? 0) ? 0.35 : 1)
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(AppPalette.appBackground)
    }

    private func moveMonth(by value: Int) {
        monthNavigationDirection = value
        let nextOffset = selectedMonthOffset + value
        selectedMonthOffset = min(max(nextOffset, monthOffsets.first ?? 0), monthOffsets.last ?? 0)
    }

    private func monthArrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, AppPalette.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 1)
                        }
                        .shadow(color: AppPalette.background.opacity(0.12), radius: 10, y: 5)
                        .shadow(color: .white.opacity(0.85), radius: 2, x: -1, y: -1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var monthNavigationBar: some View {
        BudgetStatusCard(
            month: selectedMonth,
            transactions: selectedTransactions,
            payments: payments,
            budgetIncome: monthIncome,
            isCompact: true
        )
    }

    private var creditsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                analyticsNetWorthCard

                if !analyticsInsights.isEmpty {
                    analyticsInsightCarouselCard
                }

                chartCard(
                    title: analyticsAnalysisTitle,
                    total: analyticsExpenseTotal
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        analyticsPeriodControls

                        Picker("", selection: $selectedAnalyticsExpenseTab) {
                            Text(AppStrings.text(.whereSpent)).tag(AnalyticsExpenseTab.whereSpent)
                            Text(AppStrings.text(.budgetRule)).tag(AnalyticsExpenseTab.budgetRule)
                        }
                        .pickerStyle(.segmented)
                        .tint(AppPalette.background)

                        switch selectedAnalyticsExpenseTab {
                        case .whereSpent:
                            expenseTypePieChart(points: analyticsExpenseTypePoints, total: analyticsExpenseTotal)
                        case .budgetRule:
                            HStack(alignment: .top, spacing: 16) {
                                pieChartColumn(
                                    title: AppStrings.text(.actualExpenses),
                                    points: analyticsCategoryExpenses,
                                    total: analyticsExpenseTotal
                                )

                                pieChartColumn(
                                    title: AppStrings.text(.reference503020),
                                    points: budgetReferencePoints,
                                    total: 100
                                )
                            }
                        }
                    }
                }

                analyticsListsCard

                adviceCarouselCard

                analyticsSavingsCard

                analyticsCreditsCard
            }
            .padding()
        }
        .background(AppPalette.appBackground)
    }

    private var managementView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(AppStrings.text(.managementIntro))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)

                VStack(spacing: 14) {
                    managementCard(
                        title: AppStrings.text(.budgetSettings),
                        subtitle: AppStrings.text(.managementBudgetDescription),
                        systemImage: "arrow.triangle.2.circlepath",
                        tint: AppPalette.background
                    ) {
                        BudgetSettingsView()
                    }

                    managementCard(
                        title: SavingsStrings.text(.settingsTitle),
                        subtitle: AppStrings.text(.managementSavingsDescription),
                        systemImage: "target",
                        tint: AppPalette.primary
                    ) {
                        SavingsSettingsView()
                            .navigationTitle(SavingsStrings.text(.settingsTitle))
                            .navigationBarTitleDisplayMode(.inline)
                    }

                    managementCard(
                        title: CreditStrings.text(.settingsTitle),
                        subtitle: AppStrings.text(.managementCreditsDescription),
                        systemImage: "creditcard.fill",
                        tint: AppPalette.background
                    ) {
                        CreditsSettingsView()
                            .navigationTitle(CreditStrings.text(.settingsTitle))
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
        }
        .background(AppPalette.appBackground)
    }

    private func managementCard<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 54, height: 54)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var analyticsPeriodControls: some View {
        VStack(spacing: 10) {
            Picker("", selection: $selectedAnalyticsPeriod) {
                Text(AppStrings.text(.month)).tag(AnalyticsPeriod.month)
                Text(AppStrings.text(.year)).tag(AnalyticsPeriod.year)
            }
            .pickerStyle(.segmented)
            .tint(AppPalette.background)

            if selectedAnalyticsPeriod == .month {
                HStack(spacing: 12) {
                    analyticsMonthArrowButton(systemImage: "chevron.left") {
                        moveAnalyticsMonth(by: -1)
                    }
                    .disabled(selectedAnalyticsMonthOffset <= (monthOffsets.first ?? 0))
                    .opacity(selectedAnalyticsMonthOffset <= (monthOffsets.first ?? 0) ? 0.35 : 1)

                    Text(selectedAnalyticsMonth.monthTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity)

                    analyticsMonthArrowButton(systemImage: "chevron.right") {
                        moveAnalyticsMonth(by: 1)
                    }
                    .disabled(selectedAnalyticsMonthOffset >= (monthOffsets.last ?? 0))
                    .opacity(selectedAnalyticsMonthOffset >= (monthOffsets.last ?? 0) ? 0.35 : 1)
                }
            }
        }
    }

    private func analyticsMonthArrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 38, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func moveAnalyticsMonth(by value: Int) {
        let nextOffset = selectedAnalyticsMonthOffset + value
        withAnimation(.snappy) {
            selectedAnalyticsMonthOffset = min(max(nextOffset, monthOffsets.first ?? 0), monthOffsets.last ?? 0)
        }
    }

    private var analyticsInsightCarouselCard: some View {
        let insights = analyticsInsights

        let currentInsight = insights.isEmpty ? nil : insights[selectedInsightIndex % insights.count]

        return HStack(spacing: 12) {
            adviceNavigationButton(systemImage: "chevron.left") {
                moveInsight(by: -1)
            }
            .disabled(insights.count <= 1)
            .opacity(insights.count <= 1 ? 0.35 : 1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(currentInsight?.title ?? AppStrings.text(.paidInsights))
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.primary)
                        .lineLimit(1)

                    if let currentInsight,
                       let infoTitle = currentInsight.infoTitle,
                       let infoMessage = currentInsight.infoMessage {
                        Button {
                            expenseNotice = ExpenseNotice(title: infoTitle, message: infoMessage)
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(infoTitle)
                    }
                }

                Text(currentInsight?.message ?? AppStrings.text(.noInsights))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard let currentInsight,
                      let infoTitle = currentInsight.infoTitle,
                      let infoMessage = currentInsight.infoMessage else { return }
                expenseNotice = ExpenseNotice(title: infoTitle, message: infoMessage)
            }
            .id("insight-\(selectedInsightIndex)-\(insights.count)")
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer(minLength: 0)

            adviceNavigationButton(systemImage: "chevron.right") {
                moveInsight(by: 1)
            }
            .disabled(insights.count <= 1)
            .opacity(insights.count <= 1 ? 0.35 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 20)
        .frame(minHeight: 118)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppPalette.primary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard insights.count > 1, abs(value.translation.width) > 36 else { return }
                    moveInsight(by: value.translation.width < 0 ? 1 : -1)
                }
        )
        .task(id: insights.count) {
            while !Task.isCancelled && insights.count > 1 {
                try? await Task.sleep(for: .seconds(25))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    moveInsight(by: 1)
                }
            }
        }
    }

    private var analyticsListsCard: some View {
        chartCard(
            title: selectedAnalyticsListTab.title,
            total: analyticsListTotal(for: selectedAnalyticsListTab)
        ) {
            if selectedAnalyticsListTab == .subscriptions {
                subscriptionScopePicker
            }
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Picker("", selection: $selectedAnalyticsListTab) {
                    ForEach(AnalyticsListTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AppPalette.background)

                switch selectedAnalyticsListTab {
                case .subscriptions:
                    subscriptionList(displayedConfiguredSubscriptions, emptySystemImage: "play.rectangle")
                case .savings:
                    yearlySavingsList
                case .incomeVsExpenses:
                    incomeVsExpensesList
                }
            }
        }
    }

    private func analyticsListTotal(for tab: AnalyticsListTab) -> Double {
        switch tab {
        case .subscriptions:
            displayedConfiguredSubscriptions.reduce(0) { $0 + $1.amount }
        case .savings:
            yearSavingsPoints.reduce(0) { $0 + $1.expenses }
        case .incomeVsExpenses:
            annualBalancePoints.reduce(0) { $0 + $1.balance }
        }
    }

    private var subscriptionScopePicker: some View {
        Picker("", selection: $selectedSubscriptionAnalysisScope) {
            ForEach(SubscriptionAnalysisScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .tint(AppPalette.background)
        .frame(width: 150)
    }

    private var analyticsNetWorthCard: some View {
        chartCard(title: AppStrings.text(.netWorth), total: analyticsNetWorthTotal) {
            VStack(alignment: .leading, spacing: 10) {
                analyticsRow(
                    icon: "list.bullet.rectangle",
                    title: AppStrings.text(.accountBalance),
                    subtitle: AppStrings.text(.currentAccount),
                    value: inAccount.currencyText,
                    tint: inAccount >= 0 ? AppPalette.background : AppPalette.primary
                )

                analyticsRow(
                    icon: "target",
                    title: AppStrings.text(.savingsTotal),
                    subtitle: SavingsStrings.text(.settingsTitle),
                    value: analyticsSavingsTotal.currencyText,
                    tint: AppPalette.savings
                )

                analyticsRow(
                    icon: "creditcard",
                    title: AppStrings.text(.creditsDebt),
                    subtitle: CreditStrings.text(.settingsTitle),
                    value: (-analyticsCreditDebtTotal).currencyText,
                    tint: AppPalette.primary
                )
            }
        }
    }

    private var analyticsSavingsCard: some View {
        chartCard(title: SavingsStrings.text(.settingsTitle), total: analyticsSavingsTotal) {
            VStack(alignment: .leading, spacing: 10) {
                if analyticsSavingAccounts.isEmpty {
                    analyticsEmptyRow(systemImage: "target")
                } else {
                    ForEach(analyticsSavingAccounts) { saving in
                        analyticsRow(
                            icon: "target",
                            title: saving.name,
                            subtitle: analyticsSavingSubtitle(for: saving),
                            value: saving.balance(with: savingMovements).currencyText,
                            tint: AppPalette.savings
                        )
                    }
                }
            }
        }
    }

    private var analyticsCreditsCard: some View {
        chartCard(title: CreditStrings.text(.settingsTitle), total: analyticsCreditDebtTotal) {
            VStack(alignment: .leading, spacing: 10) {
                if analyticsCreditAccounts.isEmpty {
                    analyticsEmptyRow(systemImage: "creditcard")
                } else {
                    ForEach(analyticsCreditAccounts) { credit in
                        analyticsRow(
                            icon: credit.creditType.iconName,
                            title: credit.name,
                            subtitle: analyticsCreditSubtitle(for: credit),
                            value: credit.balance(with: creditMovements).currencyText,
                            tint: AppPalette.primary
                        )
                    }
                }
            }
        }
    }

    private var analyticsSavingAccounts: [SavingAccount] {
        savingAccounts
            .filter { $0.savingStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var analyticsCreditAccounts: [CreditAccount] {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var analyticsSavingsTotal: Double {
        analyticsSavingAccounts.reduce(0) { $0 + $1.balance(with: savingMovements) }
    }

    private var analyticsCreditDebtTotal: Double {
        analyticsCreditAccounts.reduce(0) { $0 + $1.balance(with: creditMovements) }
    }

    private var analyticsNetWorthTotal: Double {
        inAccount + analyticsSavingsTotal - analyticsCreditDebtTotal
    }

    private func analyticsSavingSubtitle(for saving: SavingAccount) -> String {
        let variation = saving.monthVariation(in: currentMonth, movements: savingMovements)
        var parts = ["\(SavingsStrings.text(.monthVariation)): \(variation.currencyText)"]
        if let target = saving.targetAmount, target > 0 {
            parts.append("\(SavingsStrings.text(.targetProgress)): \(percentageText(saving.balance(with: savingMovements), total: target))")
        }
        return parts.joined(separator: " · ")
    }

    private func analyticsCreditSubtitle(for credit: CreditAccount) -> String {
        let balance = credit.balance(with: creditMovements)
        let variation = credit.monthVariation(in: currentMonth, movements: creditMovements)
        var parts = [credit.creditType.title, "\(CreditStrings.text(.monthVariation)): \(variation.currencyText)"]
        if let limit = credit.creditLimit, limit > 0 {
            parts.append("\(CreditStrings.text(.usedPercentage)): \(percentageText(balance, total: limit))")
        }
        return parts.joined(separator: " · ")
    }

    private func subscriptionList(_ transactions: [MoneyTransaction], emptySystemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if transactions.isEmpty {
                analyticsEmptyRow(systemImage: emptySystemImage)
            } else {
                ForEach(transactions) { transaction in
                    analyticsRow(
                        icon: ExpenseTypeIcon.name(for: transaction.displayName),
                        title: analyticsTransactionTitle(for: transaction),
                        subtitle: analyticsConfiguredSubscriptionSubtitle(for: transaction),
                        value: transaction.amount.currencyText,
                        tint: AppPalette.primary
                    )
                }
            }
        }
    }

    private var yearlySavingsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            let visiblePoints = yearSavingsPoints.filter { $0.expenses > 0 }
            if visiblePoints.isEmpty {
                analyticsEmptyRow(systemImage: "leaf.fill")
            } else {
                ForEach(visiblePoints) { point in
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.savings)
                            .frame(width: 30, height: 30)
                            .background(AppPalette.savings.opacity(0.14), in: Circle())

                        Text(point.month.monthTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)

                        Spacer(minLength: 8)

                        Text(point.expenses.currencyText)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.savings)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Button {
                            savingsHistoryRequest = SavingsHistoryRequest(month: point.month)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppPalette.background)
                                .frame(width: 34, height: 34)
                                .background(AppPalette.surface, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppStrings.text(.savingsHistoryTitle))
                    }
                    .padding(10)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func monthlyAmountList(points: [MonthlyBalancePoint], value: @escaping (MonthlyBalancePoint) -> Double, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let visiblePoints = points.filter { value($0) > 0 }
            if visiblePoints.isEmpty {
                analyticsEmptyRow(systemImage: systemImage)
            } else {
                ForEach(visiblePoints) { point in
                    analyticsRow(
                        icon: systemImage,
                        title: point.month.monthTitle,
                        subtitle: "",
                        value: value(point).currencyText,
                        tint: AppPalette.savings
                    )
                }
            }
        }
    }

    private func analyticsEmptyRow(systemImage: String) -> some View {
        ContentUnavailableView(AppStrings.text(.noListData), systemImage: "list.bullet.rectangle")
            .foregroundStyle(AppPalette.background)
            .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func analyticsTransactionTitle(for transaction: MoneyTransaction) -> String {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? transaction.displayName : trimmedTitle
    }

    private func analyticsConfiguredSubscriptionSubtitle(for transaction: MoneyTransaction) -> String {
        let displayMonth = transaction.recurrence == .yearlyMonth
            ? Date.monthStart(forMonthNumber: transaction.recurrenceMonth)
            : transaction.monthStart
        var parts = ["\(AppStrings.text(.day)) \(transaction.day)"]

        switch transaction.recurrence {
        case .monthly:
            parts.append(RecurrenceType.monthly.title)
        case .quarterly, .semiannual, .annual:
            parts.append(Date.monthName(forMonthNumber: displayMonth.monthNumber))
            if let recurrence = transaction.recurrence {
                parts.append(recurrence.title)
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
            parts.append(AppStrings.text(.annualRecurrence))
        case nil:
            break
        }

        return parts.joined(separator: " - ")
    }

    private var incomeVsExpensesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(annualBalancePoints) { point in
                analyticsRow(
                    icon: "arrow.left.arrow.right",
                    title: point.month.monthTitle,
                    subtitle: "\(AppStrings.text(.chartIncome)): \(point.income.currencyText)\n\(AppStrings.text(.chartExpenses)): \(point.expenses.currencyText)",
                    value: point.balance.currencyText,
                    tint: point.balance >= 0 ? AppPalette.savings : AppPalette.primary
                )
            }
        }
    }

    private func analyticsRow(icon: String, title: String, subtitle: String, freeText: String = "", value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !freeText.isEmpty {
                    Text(freeText)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var adviceCarouselCard: some View {
        HStack(spacing: 12) {
            adviceNavigationButton(systemImage: "chevron.left") {
                moveAdvice(by: -1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(currentAdvice.title)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.primary)
                    .lineLimit(1)

                Text(currentAdvice.message)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .id(selectedAdviceIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer(minLength: 0)

            adviceNavigationButton(systemImage: "chevron.right") {
                moveAdvice(by: 1)
            }
        }
        .padding(14)
        .background(AppPalette.mintSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppPalette.secondary.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let adviceCount = AppStrings.analyticsAdviceCards.count
                    guard adviceCount > 1, abs(value.translation.width) > 36 else { return }
                    moveAdvice(by: value.translation.width < 0 ? 1 : -1)
                }
        )
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    moveAdvice(by: 1)
                }
            }
        }
    }

    private func adviceNavigationButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.background)
                .frame(width: 34, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func moveAdvice(by offset: Int) {
        let adviceCount = AppStrings.analyticsAdviceCards.count
        guard adviceCount > 0 else { return }

        withAnimation(.snappy) {
            selectedAdviceIndex = (selectedAdviceIndex + offset + adviceCount) % adviceCount
        }
    }

    private func moveInsight(by offset: Int) {
        let insightCount = analyticsInsights.count
        guard insightCount > 0 else { return }

        withAnimation(.snappy) {
            selectedInsightIndex = (selectedInsightIndex + offset + insightCount) % insightCount
        }
    }

    private func chartCard<Content: View>(title: String, total: Double, @ViewBuilder content: () -> Content) -> some View {
        chartCard(title: title, total: total) {
            EmptyView()
        } content: {
            content()
        }
    }

    private func chartCard<HeaderAccessory: View, Content: View>(
        title: String,
        total: Double,
        @ViewBuilder headerAccessory: () -> HeaderAccessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                headerAccessory()

                Text(total.currencyText)
                    .font(.subheadline.bold())
                    .foregroundStyle(total < 0 ? AppPalette.primary : AppPalette.background)
            }

            content()
        }
        .padding()
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }

    private func pieChartColumn(title: String, points: [CategoryExpensePoint], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            if total > 0 {
                Chart(points.filter { $0.amount > 0 }) { point in
                    SectorMark(
                        angle: .value(AppStrings.text(.value), point.amount),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(point.category.color)
                }
                .frame(height: 150)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(points) { point in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(point.category.color)
                                .frame(width: 8, height: 8)
                            Text("\(categoryShortTitle(point.category)): \(percentageText(point.amount, total: total))")
                                .font(.caption2)
                                .foregroundStyle(AppPalette.mutedText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            } else {
                ContentUnavailableView(AppStrings.text(.noTransactions), systemImage: "chart.pie")
                    .foregroundStyle(AppPalette.background)
                    .frame(height: 150)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func expenseTypePieChart(points: [ExpenseTypePoint], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if total > 0 {
                Chart(points.filter { $0.amount > 0 }) { point in
                    SectorMark(
                        angle: .value(AppStrings.text(.value), point.amount),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(point.category.color)
                }
                .frame(height: 180)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points.filter { $0.amount > 0 }) { point in
                        HStack(spacing: 10) {
                            Image(systemName: ExpenseTypeIcon.name(for: point.title))
                                .font(.caption.bold())
                                .foregroundStyle(point.category.color)
                                .frame(width: 28, height: 28)
                                .background(point.category.color.opacity(0.14), in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.title)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppPalette.background)
                                    .lineLimit(2)

                                Text(point.category.title)
                                    .font(.caption2)
                                    .foregroundStyle(AppPalette.mutedText)
                            }

                            Spacer(minLength: 8)

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(percentageText(point.amount, total: total))
                                    .font(.caption.bold())
                                    .foregroundStyle(AppPalette.background)

                                Text(point.amount.currencyText)
                                    .font(.caption2)
                                    .foregroundStyle(AppPalette.mutedText)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(AppStrings.text(.noTransactions), systemImage: "chart.pie")
                    .foregroundStyle(AppPalette.background)
                    .frame(height: 180)
            }
        }
    }

    private func categoryShortTitle(_ category: ExpenseCategory) -> String {
        switch category {
        case .needs:
            "50"
        case .wants:
            "30"
        case .savingsAndDebt:
            "20"
        }
    }

    private func percentageText(_ amount: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }

    private var appIcon: some View {
        Image("SpendWiseIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 34)
    }

    private var settingsToolbarButton: some View {
        Button {
            settingsInitialTab = .budget
            showsSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.title2)
                .foregroundStyle(AppPalette.background)
                .frame(width: 32, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var summaryBar: some View {
        VStack(spacing: 8) {
            SummaryTile(
                title: AppStrings.text(.balanceThisMonth),
                value: inAccount,
                helpText: balanceHelpText,
                footnote: futureBudgetReservationFootnote,
                helpTitle: futureBudgetReservationTotal > 0 ? AppStrings.text(.reservedBalanceHelpTitle) : nil
            )

            HStack(spacing: 8) {
                SummaryTile(
                    title: AppStrings.text(.monthUnpaid),
                    value: monthUnpaidExpenses,
                    helpText: AppStrings.text(.monthUnpaidHelp)
                )
                if let monthRemaining {
                    SummaryTile(
                        title: monthRemaining < 0 ? AppStrings.text(.monthBudgetExceeded) : AppStrings.text(.monthRemaining),
                        value: monthRemaining,
                        helpText: AppStrings.text(.monthRemainingHelp),
                        boldHelpNote: AppStrings.text(.monthRemainingHelpNote)
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 12)
        .background(AppPalette.appBackground)
    }

    private var bottomArea: some View {
        VStack(spacing: 8) {
            if showsQuickActions && selectedTab == .currentAccount {
                quickActionsBar
            }
            bottomNavigationBar
        }
        .padding(.top, 4)
        .background(AppPalette.appBackground)
    }

    private var bottomNavigationBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                bottomTabButton(
                    title: AppStrings.text(.currentAccount),
                    systemImage: "list.bullet.rectangle",
                    isSelected: selectedTab == .currentAccount,
                    doubleTapAction: {
                        withAnimation(.snappy) {
                            selectedTab = .currentAccount
                            selectedMonthOffset = 0
                        }
                    }
                ) {
                    selectedTab = .currentAccount
                }

                bottomTabButton(
                    title: AppStrings.text(.credits),
                    systemImage: "chart.bar",
                    isSelected: selectedTab == .credits
                ) {
                    selectedTab = .credits
                    showsQuickActions = false
                }

                bottomTabButton(
                    title: AppStrings.text(.management),
                    systemImage: "square.grid.2x2",
                    isSelected: selectedTab == .management
                ) {
                    selectedTab = .management
                    showsQuickActions = false
                }
            }
            .padding(6)
            .background(AppPalette.surface, in: Capsule())
            .shadow(color: AppPalette.background.opacity(0.08), radius: 14, y: 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 6)

            filterButton

            Button {
                withAnimation(.snappy) {
                    showsQuickActions.toggle()
                }
            } label: {
                Image(systemName: showsQuickActions ? "xmark" : "plus")
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .foregroundStyle(AppPalette.background)
                    .background(AppPalette.secondary, in: Circle())
                    .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 7)
            }
            .buttonStyle(.plain)
            .disabled(selectedTab != .currentAccount)
            .opacity(selectedTab == .currentAccount ? 1 : 0.35)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 0)
    }

    private var filterButton: some View {
        Button {
            showsFilters = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .foregroundStyle(AppPalette.background)
                    .background(AppPalette.surface, in: Circle())
                    .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 7)

                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 22, height: 22)
                        .background(AppPalette.primary, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(selectedTab != .currentAccount)
        .opacity(selectedTab == .currentAccount ? 1 : 0.35)
        .accessibilityLabel(AppStrings.text(.filters))
    }

    private func bottomTabButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        doubleTapAction: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
            .frame(width: isSelected ? 108 : 84, height: 60)
            .background(isSelected ? AppPalette.background : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                doubleTapAction?()
            }
        )
    }

    private var quickActionsBar: some View {
        Group {
            if hasActiveSavings && hasActiveCredits {
                HStack(spacing: 10) {
                    VStack(spacing: 10) {
                        savingQuickActionButton
                        creditQuickActionButton
                    }

                    VStack(spacing: 10) {
                        incomeQuickActionButton
                        expenseQuickActionButton
                    }
                }
            } else if hasQuickSavingsOrCredits {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        incomeQuickActionButton
                        expenseQuickActionButton
                    }

                    if hasActiveSavings {
                        savingQuickActionButton
                    }

                    if hasActiveCredits {
                        creditQuickActionButton
                    }
                }
            } else {
                HStack(spacing: 10) {
                    incomeQuickActionButton
                    expenseQuickActionButton
                }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var hasActiveSavings: Bool {
        savingAccounts.contains { $0.savingStatus == .active }
    }

    private var hasActiveCredits: Bool {
        creditAccounts.contains { $0.creditStatus == .active }
    }

    private var hasQuickSavingsOrCredits: Bool {
        hasActiveSavings || hasActiveCredits
    }

    private var savingQuickActionButton: some View {
        quickActionButton(
            title: SavingsStrings.text(.saving),
            systemImage: "banknote.fill",
            iconColor: AppPalette.savings,
            textColor: AppPalette.background,
            background: AppPalette.mintSurface
        ) {
            openPresetExpense(title: AppStrings.text(.newSavingExpense), expenseName: savingExpenseName)
        }
    }

    private var creditQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.creditPaymentExpenseButton),
            systemImage: "creditcard.fill",
            iconColor: AppPalette.primary,
            textColor: AppPalette.surface,
            background: AppPalette.background
        ) {
            openPresetExpense(title: AppStrings.text(.newCreditPaymentExpense), expenseName: creditPaymentExpenseName)
        }
    }

    private var incomeQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.income),
            systemImage: "tray.and.arrow.down.fill",
            iconColor: AppPalette.savings,
            textColor: AppPalette.background,
            background: AppPalette.secondary
        ) {
            editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
            showsQuickActions = false
        }
    }

    private var expenseQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.expense),
            systemImage: "tray.and.arrow.up.fill",
            iconColor: AppPalette.surface,
            textColor: AppPalette.surface,
            background: AppPalette.primary
        ) {
            editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
            showsQuickActions = false
        }
    }

    private func quickActionButton(title: String, systemImage: String, iconColor: Color, textColor: Color, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.headline.bold())
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(background, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var savingExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalized(name)
            return normalizedName.contains("poup") || normalizedName.contains("saving")
        } ?? ""
    }

    private var creditPaymentExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalized(name)
            return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
        } ?? ""
    }

    private func openPresetExpense(title: String, expenseName: String) {
        editorRequest = TransactionEditorRequest(
            mode: .expense,
            month: selectedMonth,
            titleOverride: title,
            initialExpenseCategory: .savingsAndDebt,
            initialExpenseName: expenseName
        )
        showsQuickActions = false
    }

    private func handleAppear() {
        loadStoredCurrentAccountFilters()
        checkOverdueExpenses()
    }

    private func loadStoredCurrentAccountFilters() {
        guard !didLoadStoredFilters else { return }
        didLoadStoredFilters = true

        paymentFilter = CurrentAccountPaymentFilter(rawValue: storedPaymentFilter) ?? .all
        filteredCategories = Set(storedFilteredCategories
            .split(separator: ",")
            .compactMap { ExpenseCategory(rawValue: String($0)) })
        filteredExpenseType = storedFilteredExpenseType
        freeTextFilter = storedFreeTextFilter
    }

    private func persistCurrentAccountFilters() {
        storedPaymentFilter = paymentFilter.rawValue
        storedFilteredCategories = filteredCategories
            .map(\.rawValue)
            .sorted()
            .joined(separator: ",")
        storedFilteredExpenseType = filteredExpenseType
        storedFreeTextFilter = freeTextFilter
    }

    private func refreshExpensePaymentNotifications() async {
        let reminders = upcomingExpensePaymentReminders()
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let existingReminderIDs = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix("spendwise-expense-due-") }
        center.removePendingNotificationRequests(withIdentifiers: existingReminderIDs)

        guard !reminders.isEmpty else { return }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            do {
                let isAllowed = try await center.requestAuthorization(options: [.alert, .sound])
                guard isAllowed else { return }
            } catch {
                return
            }
        case .denied:
            return
        @unknown default:
            return
        }

        for reminder in reminders.prefix(60) {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func upcomingExpensePaymentReminders() -> [ExpensePaymentReminder] {
        let now = Date()
        let calendar = Calendar.current
        let months = (0...4).compactMap { calendar.date(byAdding: .month, value: $0, to: currentMonth) }

        return months
            .flatMap { month in
                transactions
                    .visible(in: month, payments: payments, exclusions: exclusions)
                    .filter { transaction in
                        transaction.kind == TransactionKind.expense.rawValue && !isPaid(transaction, in: month)
                    }
                    .compactMap { reminder(for: $0, in: month, now: now) }
            }
            .filter { $0.fireDate > now }
            .sorted { $0.fireDate < $1.fireDate }
    }

    private func reminder(for transaction: MoneyTransaction, in month: Date, now: Date) -> ExpensePaymentReminder? {
        let calendar = Calendar.current
        let dueDay = transaction.effectiveDay(in: month)
        guard let dueDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: month.date(day: dueDay)) else {
            return nil
        }
        guard let reminderDay = calendar.date(byAdding: .day, value: -1, to: dueDate) else {
            return nil
        }

        var fireDate = reminderDay
        if fireDate <= now, calendar.isDate(fireDate, inSameDayAs: now), dueDate > now {
            fireDate = now.addingTimeInterval(60)
        }

        guard fireDate > now else { return nil }

        let freeText = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let type = transaction.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryText = freeText.isEmpty ? type : freeText
        let body: String
        if freeText.isEmpty || type.isEmpty || freeText == type {
            body = String(format: AppStrings.text(.expenseDueTomorrowBody), primaryText, dueDay)
        } else {
            body = String(format: AppStrings.text(.expenseDueTomorrowBodyWithType), primaryText, dueDay, type)
        }

        let identifier = "spendwise-expense-due-\(transaction.id.uuidString)-\(month.notificationIdentifierDate)"
        return ExpensePaymentReminder(
            identifier: identifier,
            title: AppStrings.text(.expenseDueTomorrowTitle),
            body: body,
            fireDate: fireDate
        )
    }

    private func checkOverdueExpenses() {
        guard !didCheckOverdueExpenses else { return }
        didCheckOverdueExpenses = true

        let todayDay = Calendar.current.component(.day, from: Date())
        let currentOverdueExpenses = unpaidExpenses(in: currentMonth, throughDay: todayDay)
        var sections: [String] = []

        previousMonthsWithUnpaidExpenses().forEach { month, expenses in
            sections.append(expenseNoticeSection(
                prefix: "\(AppStrings.text(.pastMonthsUnpaidExpensesMessagePrefix)) \(month.monthTitle)",
                expenses: expenses,
                month: month
            ))
        }

        if !currentOverdueExpenses.isEmpty {
            sections.append(expenseNoticeSection(
                prefix: AppStrings.text(.overdueExpensesMessagePrefix),
                expenses: currentOverdueExpenses,
                month: currentMonth
            ))
        }

        guard !sections.isEmpty else { return }

        expenseNotice = ExpenseNotice(
            title: AppStrings.text(.overdueExpensesTitle),
            message: sections.joined(separator: "\n\n")
        )
    }

    private func previousMonthsWithUnpaidExpenses() -> [(month: Date, expenses: [MoneyTransaction])] {
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min(),
              let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth),
              firstMonth <= previousMonth
        else { return [] }

        return months(from: firstMonth, through: previousMonth)
            .compactMap { month in
                let expenses = unpaidExpenses(in: month, throughDay: month.daysInMonth)
                return expenses.isEmpty ? nil : (month, expenses)
            }
    }

    private func unpaidExpenses(in month: Date, throughDay maxDay: Int) -> [MoneyTransaction] {
        transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue && transaction.effectiveDay(in: month) <= maxDay && !isPaid(transaction, in: month)
            }
            .sorted { first, second in
                let firstDay = first.effectiveDay(in: month)
                let secondDay = second.effectiveDay(in: month)
                if firstDay != secondDay { return firstDay < secondDay }
                return first.displayName < second.displayName
            }
    }

    private func expenseNoticeSection(prefix: String, expenses: [MoneyTransaction], month: Date) -> String {
        let lines = expenses.map {
            "\($0.displayName) - \(AppStrings.text(.overdueExpenseDueDay)) \($0.effectiveDay(in: month))"
        }

        return ([prefix] + lines).joined(separator: "\n")
    }

    private func months(from startMonth: Date, through endMonth: Date) -> [Date] {
        MoneyCalculationService.months(from: startMonth, through: endMonth)
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        calculator.isPaid(transaction, in: month)
    }

    private func paidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        calculator.paidAmount(for: transaction, in: month)
    }

    private func paymentHistoryEntries(for transaction: MoneyTransaction, in month: Date) -> [PaymentHistoryEntry] {
        paymentHistory
            .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
            .sorted { $0.paidAt > $1.paidAt }
    }

    private func addPaymentAmount(_ transaction: MoneyTransaction, in month: Date, amount: Double) {
        let paymentAmount = max(amount, 0)
        guard paymentAmount > 0 else { return }

        let monthStart = month.monthStart
        let existingPayment = payments.first { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: monthStart, toGranularity: .month) }
        let currentPaid = existingPayment?.amountPaid ?? 0
        let newPaidAmount = currentPaid + paymentAmount

        if newPaidAmount > transaction.amount {
            transaction.amount = newPaidAmount
        }

        if let existingPayment {
            existingPayment.amountPaid = newPaidAmount
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: monthStart, amountPaid: newPaidAmount))
        }

        modelContext.insert(PaymentHistoryEntry(transactionID: transaction.id, monthStart: monthStart, amount: paymentAmount))
        syncLinkedCreditPayment(for: transaction, in: month, paidAmount: newPaidAmount)
        syncLinkedSavingDeposit(for: transaction, in: month, paidAmount: newPaidAmount)
    }

    private func deletePaymentHistoryEntry(_ entry: PaymentHistoryEntry, for transaction: MoneyTransaction, in month: Date) {
        guard entry.transactionID == transaction.id else { return }

        let monthStart = month.monthStart
        guard Calendar.current.isDate(entry.monthStart, equalTo: monthStart, toGranularity: .month) else { return }

        let existingPayment = payments.first {
            $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: monthStart, toGranularity: .month)
        }
        let currentPaidAmount = existingPayment?.amountPaid ?? 0
        let newPaidAmount = max(currentPaidAmount - entry.amount, 0)

        modelContext.delete(entry)

        if let existingPayment {
            if newPaidAmount <= 0 {
                modelContext.delete(existingPayment)
            } else {
                existingPayment.amountPaid = newPaidAmount
            }
        }

        syncLinkedCreditPayment(for: transaction, in: monthStart, paidAmount: newPaidAmount)
        syncLinkedSavingDeposit(for: transaction, in: monthStart, paidAmount: newPaidAmount)
    }

    private func syncLinkedCreditPayment(for transaction: MoneyTransaction, in month: Date, paidAmount: Double) {
        guard let linkedCreditID = transaction.linkedCreditID else { return }

        if paidAmount <= 0 {
            if let linkedCreditMovementID = transaction.linkedCreditMovementID,
               let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
                modelContext.delete(movement)
            }
            transaction.linkedCreditMovementID = nil
            return
        }

        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let linkedCreditMovementID = transaction.linkedCreditMovementID,
           let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
            movement.creditID = linkedCreditID
            movement.date = month.date(day: transaction.effectiveDay(in: month))
            movement.type = CreditMovementKind.payment.rawValue
            movement.amount = paidAmount
            movement.note = note
        } else {
            let movement = CreditMovement(
                creditID: linkedCreditID,
                date: month.date(day: transaction.effectiveDay(in: month)),
                type: CreditMovementKind.payment.rawValue,
                amount: paidAmount,
                note: note
            )
            modelContext.insert(movement)
            transaction.linkedCreditMovementID = movement.id
        }
    }

    private func syncLinkedSavingDeposit(for transaction: MoneyTransaction, in month: Date, paidAmount: Double) {
        guard let linkedSavingID = transaction.linkedSavingID else { return }

        if paidAmount <= 0 {
            if let linkedSavingMovementID = transaction.linkedSavingMovementID,
               let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
                modelContext.delete(movement)
            }
            transaction.linkedSavingMovementID = nil
            return
        }

        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let linkedSavingMovementID = transaction.linkedSavingMovementID,
           let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
            movement.savingID = linkedSavingID
            movement.date = month.date(day: transaction.effectiveDay(in: month))
            movement.type = SavingMovementKind.deposit.rawValue
            movement.amount = paidAmount
            movement.note = note
        } else {
            let movement = SavingMovement(
                savingID: linkedSavingID,
                date: month.date(day: transaction.effectiveDay(in: month)),
                type: SavingMovementKind.deposit.rawValue,
                amount: paidAmount,
                note: note
            )
            modelContext.insert(movement)
            transaction.linkedSavingMovementID = movement.id
        }
    }

    private func deleteTransaction(_ transaction: MoneyTransaction, in month: Date) {
        if transaction.isRecurring {
            addExclusion(for: transaction, in: month)
            payments
                .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
                .forEach(modelContext.delete)
            paymentHistory
                .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
                .forEach(modelContext.delete)
        } else {
            if let linkedCreditMovementID = transaction.linkedCreditMovementID,
               let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
                modelContext.delete(movement)
            }
            if let linkedSavingMovementID = transaction.linkedSavingMovementID,
               let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
                modelContext.delete(movement)
            }
            payments
                .filter { $0.transactionID == transaction.id }
                .forEach(modelContext.delete)
            paymentHistory
                .filter { $0.transactionID == transaction.id }
                .forEach(modelContext.delete)
            modelContext.delete(transaction)
        }
    }

    private func addExclusion(for transaction: MoneyTransaction, in month: Date) {
        guard !exclusions.contains(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else {
            return
        }

        modelContext.insert(RecurrenceExclusion(transactionID: transaction.id, monthStart: month.monthStart))
    }
}

private struct SavingsHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let month: Date
    let lines: [SavingsHistoryLine]
    let total: Double

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(month.monthTitle)
                            .font(.title2.bold())
                            .foregroundStyle(AppPalette.background)
                        Text(total.currencyText)
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppPalette.savings)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(lines) { line in
                            HStack(spacing: 12) {
                                Image(systemName: line.icon)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppPalette.savings)
                                    .frame(width: 30, height: 30)
                                    .background(AppPalette.savings.opacity(0.14), in: Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(line.title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppPalette.background)
                                        .lineLimit(2)
                                    Text(line.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AppPalette.mutedText)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 8)

                                Text(line.amount.currencyText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppPalette.savings)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .padding(10)
                            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.text(.savingsHistoryTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                        .liquidGlassButtonStyle()
                }
            }
        }
    }
}

private struct CurrentAccountFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var paymentFilter: CurrentAccountPaymentFilter
    @Binding var filteredCategories: Set<ExpenseCategory>
    @Binding var filteredExpenseType: String
    @Binding var freeTextFilter: String

    let expenseTypeOptions: [ExpenseTypePoint]
    let onClear: () -> Void

    private var visibleExpenseTypeOptions: [ExpenseTypePoint] {
        expenseTypeOptions.filter { option in
            filteredCategories.isEmpty || filteredCategories.contains(option.category)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.text(.paymentStatus)) {
                    Picker(AppStrings.text(.paymentStatus), selection: $paymentFilter) {
                        ForEach(CurrentAccountPaymentFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.categories)) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Toggle(category.title, isOn: Binding(
                            get: { filteredCategories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    filteredCategories.insert(category)
                                } else {
                                    filteredCategories.remove(category)
                                }

                                let visibleTypes = visibleExpenseTypeOptions.map(\.title)
                                if !filteredExpenseType.isEmpty && !visibleTypes.contains(filteredExpenseType) {
                                    filteredExpenseType = ""
                                }
                            }
                        ))
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.expenseTypeFilter)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            expenseTypeFilterButton(
                                title: AppStrings.text(.all),
                                systemImage: "square.grid.2x2.fill",
                                isSelected: filteredExpenseType.isEmpty
                            ) {
                                filteredExpenseType = ""
                            }

                            ForEach(visibleExpenseTypeOptions) { option in
                                expenseTypeFilterButton(
                                    title: option.title,
                                    systemImage: ExpenseTypeIcon.name(for: option.title),
                                    isSelected: filteredExpenseType == option.title
                                ) {
                                    filteredExpenseType = option.title
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.freeTextFilter)) {
                    TextField(AppStrings.text(.searchPlaceholder), text: $freeTextFilter)
                        .textInputAutocapitalization(.never)
                }
                .listRowBackground(AppPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.background)
            .navigationTitle(AppStrings.text(.filters))
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.clearFilters), action: onClear)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
    }

    private func expenseTypeFilterButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.mutedText)
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(.caption2.weight(isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? AppPalette.background : AppPalette.mutedText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 82)
                    .frame(minHeight: 28)
            }
            .frame(width: 92)
            .frame(minHeight: 78)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

private extension Array where Element == String {
    func uniquedSorted() -> [String] {
        Array(Set(self)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, RecurrenceExclusion.self, SavingAccount.self, SavingMovement.self], inMemory: true)
}
