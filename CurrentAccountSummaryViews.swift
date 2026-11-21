import Foundation
import SwiftData
import SwiftUI

struct SpendAccountBalanceMetric: Identifiable, Equatable {
    let id: UUID
    let name: String
    let balance: Double
}

struct CurrentAccountSummaryMetrics: Equatable {
    let inAccount: Double
    let accountBalances: [SpendAccountBalanceMetric]
    let monthUnpaidExpenses: Double
    let isMonthUnpaidLoading: Bool
    let monthRemainingCalculation: MonthRemainingCalculation?
    let monthRemainingFootnote: String
    let balanceHelpText: String
    let balanceFootnote: String
    let balanceHelpTitle: String?

    var monthRemaining: Double? { monthRemainingCalculation?.result }
}

struct MonthRemainingCalculation: Equatable {
    let base: Double
    let income: Double
    let unpaidExpenses: Double

    var result: Double { base + income - unpaidExpenses }
}

struct MonthRemainingBreakdownRequest: Identifiable {
    let id = UUID()
    let month: Date
    let calculation: MonthRemainingCalculation
}

struct AccountBalanceSummaryTile: View {
    let accounts: [SpendAccountBalanceMetric]
    let footnote: String
    let onTap: () -> Void

    @State private var selectedAccountID: UUID?

    private var selectedIndex: Int {
        guard let selectedAccountID,
              let index = accounts.firstIndex(where: { $0.id == selectedAccountID })
        else {
            return 0
        }
        return index
    }

    var body: some View {
        let account = accounts[selectedIndex]

        SummaryTile(
            title: "\(AppStrings.text(.balanceThisMonth)) - \(account.name)",
            value: account.balance,
            helpText: AppStrings.text(.balanceThisMonthHelp),
            iconImageName: "SaldoDisponivelIcon",
            footnote: footnote,
            isCompact: true,
            onTap: onTap
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    rotateAccount(for: value.translation)
                }
        )
        .onChange(of: accounts.map(\.id)) { _, accountIDs in
            if let selectedAccountID, !accountIDs.contains(selectedAccountID) {
                self.selectedAccountID = accountIDs.first
            }
        }
    }

    private func rotateAccount(for translation: CGSize) {
        guard accounts.count > 1,
              abs(translation.width) > 40,
              abs(translation.width) > abs(translation.height)
        else {
            return
        }

        let offset = translation.width < 0 ? 1 : -1
        let nextIndex = (selectedIndex + offset + accounts.count) % accounts.count

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedAccountID = accounts[nextIndex].id
        }
    }
}



struct CurrentAccountMonthRemainingCard: View {
    let month: Date
    let usesSidebarNavigation: Bool
    let onTap: (MonthRemainingCalculation) -> Void

    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]

    @State private var value = 0.0
    @State private var calculation: MonthRemainingCalculation?
    @State private var isLoading = true

    var body: some View {
        SummaryTile(
            title: value < 0
                ? AppStrings.text(.monthBudgetExceeded)
                : AppStrings.text(.monthRemaining),
            value: value,
            helpText: AppStrings.text(.monthRemainingHelp),
            iconImageName: "PodeGastarIcon",
            boldHelpNote: AppStrings.text(.monthRemainingHelpNote),
            isCompact: !usesSidebarNavigation,
            isLoading: isLoading,
            titleLineLimit: 1,
            fixedHeight: usesSidebarNavigation ? nil : 82,
            onTap: {
                if let calculation {
                    onTap(calculation)
                }
            }
        )
        .task(id: refreshSignature) {
            isLoading = true
            calculation = nil
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            let updatedCalculation = calculateAvailableInMonth()
            calculation = updatedCalculation
            value = updatedCalculation.result
            isLoading = false
        }
    }


    private var refreshSignature: Int {
        var hasher = Hasher()
        let currentMonth = Date().monthStart
        let selectedMonth = month.monthStart
        hasher.combine(selectedMonth)

        transactions.forEach { transaction in
            hasher.combine(transaction.id)
            hasher.combine(transaction.amount)
            hasher.combine(transaction.day)
            hasher.combine(transaction.monthStart)
            hasher.combine(transaction.kind)
            hasher.combine(transaction.recurrenceType)
            hasher.combine(transaction.recurrenceMonth)
            hasher.combine(transaction.recurrenceEndMonthStart)
            hasher.combine(transaction.recurrenceDisabledFromMonthStart)
            hasher.combine(transaction.budgetAllocationType)
            hasher.combine(transaction.budgetMonthStart)
        }
        payments
            .filter {
                let paymentMonth = $0.monthStart.monthStart
                return paymentMonth >= currentMonth && paymentMonth <= selectedMonth
            }
            .forEach { payment in
                hasher.combine(payment.transactionID)
                hasher.combine(payment.amountPaid)
                hasher.combine(payment.occurrenceDay)
            }
        exclusions
            .filter {
                let exclusionMonth = $0.monthStart.monthStart
                return exclusionMonth >= currentMonth && exclusionMonth <= selectedMonth
            }
            .forEach { exclusion in
                hasher.combine(exclusion.transactionID)
                hasher.combine(exclusion.occurrenceDay)
            }
        spendAccounts.forEach { account in
            hasher.combine(account.id)
            hasher.combine(account.initialBalance)
            hasher.combine(account.isPrimary)
        }
        accountMovements.forEach { movement in
            hasher.combine(movement.id)
            hasher.combine(movement.accountID)
            hasher.combine(movement.amount)
            hasher.combine(movement.date)
            hasher.combine(movement.kind)
            hasher.combine(movement.transactionID)
        }

        return hasher.finalize()
    }

    private func calculateAvailableInMonth() -> MonthRemainingCalculation {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = now.monthStart
        let selectedMonth = month.monthStart
        let maximumMonth = calendar.date(byAdding: .month, value: 2, to: currentMonth)?.monthStart
            ?? currentMonth
        guard selectedMonth >= currentMonth, selectedMonth <= maximumMonth else {
            return MonthRemainingCalculation(base: 0, income: 0, unpaidExpenses: 0)
        }

        let relevantPayments = payments.filter {
            let paymentMonth = $0.monthStart.monthStart
            return paymentMonth >= currentMonth && paymentMonth <= selectedMonth
        }
        let relevantExclusions = exclusions.filter {
            let exclusionMonth = $0.monthStart.monthStart
            return exclusionMonth >= currentMonth && exclusionMonth <= selectedMonth
        }
        let calculator = MoneyCalculationService(
            transactions: transactions,
            payments: relevantPayments,
            exclusions: relevantExclusions
        )
        let totalAccountBalance: Double
        if spendAccounts.isEmpty {
            totalAccountBalance = calculator.accountSummary(until: now).availableBalance
        } else {
            totalAccountBalance = spendAccounts.reduce(0) {
                $0 + $1.balance(with: accountMovements)
            }
        }

        let transactionsByID = Dictionary(
            uniqueKeysWithValues: transactions.map { ($0.id, $0) }
        )
        let reservedForFutureBudgets = accountMovements.reduce(0) { total, movement in
            guard movement.kind == .income,
                  movement.date <= now,
                  let transactionID = movement.transactionID,
                  let transaction = transactionsByID[transactionID],
                  transaction.budgetMonth(
                    forReceivedMonth: movement.date.monthStart
                  ) > currentMonth
            else {
                return total
            }
            return total + movement.amount
        }
        let receivedIncomeKeys: Set<IncomeReceiptKey> = Set(accountMovements.compactMap { movement in
            guard movement.kind == .income,
                  let transactionID = movement.transactionID
            else { return nil }
            return IncomeReceiptKey(transactionID: transactionID, date: movement.date)
        })
        let pendingCurrentMonthIncome = calculator
            .visibleTransactions(in: currentMonth)
            .filter {
                $0.kind == TransactionKind.income.rawValue
                    && $0.isBudgeted(in: currentMonth, receivedMonth: currentMonth)
            }
            .reduce(0) { total, transaction in
                total + transaction
                    .occurrenceDays(in: currentMonth, exclusions: relevantExclusions)
                    .filter { day in
                        !receivedIncomeKeys.contains(
                            IncomeReceiptKey(
                                transactionID: transaction.id,
                                date: currentMonth.date(day: day)
                            )
                        )
                    }
                    .reduce(0) { subtotal, day in
                        subtotal + transaction.scheduledAmount(
                            in: currentMonth,
                            occurrenceDay: transaction.recurrence == .weekly ? day : nil
                        )
                    }
            }

        let currentSummary = calculator.monthSummary(in: currentMonth)
        var calculation = MonthRemainingCalculation(
            base: totalAccountBalance - reservedForFutureBudgets,
            income: pendingCurrentMonthIncome,
            unpaidExpenses: currentSummary.unpaidExpenses
        )

        guard selectedMonth > currentMonth else { return calculation }

        var projectedMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: currentMonth
        )?.monthStart
        while let projectedMonthValue = projectedMonth,
              projectedMonthValue <= selectedMonth {
            let summary = calculator.monthSummary(in: projectedMonthValue)
            calculation = MonthRemainingCalculation(
                base: calculation.result,
                income: summary.income,
                unpaidExpenses: summary.unpaidExpenses
            )
            projectedMonth = calendar.date(
                byAdding: .month,
                value: 1,
                to: projectedMonthValue
            )?.monthStart
        }

        return calculation
    }
}

struct CurrentAccountLiveSummaryBar: View {
    let month: Date
    let usesSidebarNavigation: Bool
    let showsBalanceCard: Bool
    let showsPlanningCards: Bool
    let onOpenAccounts: () -> Void
    let onOpenUnpaidExpenses: () -> Void
    let onOpenMonthRemaining: (MonthRemainingCalculation) -> Void

    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]

    @State private var accountBalances: [SpendAccountBalanceMetric] = []
    @State private var inAccount = 0.0
    @State private var balanceFootnote = ""
    @State private var monthUnpaidExpenses = 0.0
    @State private var isMonthUnpaidLoading = true

    var body: some View {
        VStack(spacing: 8) {
            if showsBalanceCard {
                if accountBalances.count > 1 {
                    AccountBalanceSummaryTile(
                        accounts: accountBalances,
                        footnote: balanceFootnote,
                        onTap: onOpenAccounts
                    )
                } else {
                    SummaryTile(
                        title: AppStrings.text(.balanceThisMonth),
                        value: inAccount,
                        helpText: AppStrings.text(.balanceThisMonthHelp),
                        iconImageName: "SaldoDisponivelIcon",
                        footnote: balanceFootnote,
                        isCompact: !usesSidebarNavigation,
                        onTap: onOpenAccounts
                    )
                }
            }

            if showsPlanningCards {
                HStack(spacing: 8) {
                    SummaryTile(
                        title: AppStrings.text(.monthUnpaid),
                        value: monthUnpaidExpenses,
                        helpText: AppStrings.text(.monthUnpaidHelp),
                        iconImageName: "FaltaPagarIcon",
                        helpArrowEdge: .bottom,
                        isCompact: !usesSidebarNavigation,
                        isLoading: isMonthUnpaidLoading,
                        titleLineLimit: 1,
                        fixedHeight: usesSidebarNavigation ? nil : 82,
                        onTap: onOpenUnpaidExpenses
                    )

                    CurrentAccountMonthRemainingCard(
                        month: month,
                        usesSidebarNavigation: usesSidebarNavigation,
                        onTap: onOpenMonthRemaining
                    )
                }
            }
        }
        .padding(.horizontal, usesSidebarNavigation ? 16 : 12)
        .padding(.top, usesSidebarNavigation ? 4 : 0)
        .padding(.bottom, usesSidebarNavigation ? 12 : 4)
        .background(AppPalette.appBackground)
        .task(id: showsBalanceCard ? balanceRefreshSignature : 0) {
            guard showsBalanceCard else { return }
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            refreshBalance()
        }
        .task(id: showsPlanningCards ? unpaidRefreshSignature : 0) {
            guard showsPlanningCards else { return }
            isMonthUnpaidLoading = true
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            monthUnpaidExpenses = calculateMonthUnpaidExpenses()
            isMonthUnpaidLoading = false
        }
    }


    private var balanceRefreshSignature: Int {
        var hasher = Hasher()
        spendAccounts.forEach { account in
            hasher.combine(account.id)
            hasher.combine(account.name)
            hasher.combine(account.initialBalance)
            hasher.combine(account.isPrimary)
        }
        accountMovements.forEach { movement in
            hasher.combine(movement.id)
            hasher.combine(movement.accountID)
            hasher.combine(movement.amount)
            hasher.combine(movement.date)
            hasher.combine(movement.kind)
        }
        return hasher.finalize()
    }

    private var unpaidRefreshSignature: Int {
        var hasher = Hasher()
        let monthStart = month.monthStart
        hasher.combine(monthStart)

        transactions.forEach { transaction in
            hasher.combine(transaction.id)
            hasher.combine(transaction.amount)
            hasher.combine(transaction.day)
            hasher.combine(transaction.monthStart)
            hasher.combine(transaction.kind)
            hasher.combine(transaction.recurrenceType)
            hasher.combine(transaction.recurrenceMonth)
            hasher.combine(transaction.recurrenceEndMonthStart)
            hasher.combine(transaction.recurrenceDisabledFromMonthStart)
        }
        payments
            .filter { $0.monthStart.monthStart == monthStart }
            .forEach { payment in
                hasher.combine(payment.transactionID)
                hasher.combine(payment.amountPaid)
                hasher.combine(payment.occurrenceDay)
            }
        exclusions
            .filter { $0.monthStart.monthStart == monthStart }
            .forEach { exclusion in
                hasher.combine(exclusion.transactionID)
                hasher.combine(exclusion.occurrenceDay)
            }

        return hasher.finalize()
    }

    private func refreshBalance() {
        let orderedAccounts = spendAccounts.sorted { first, second in
            if first.isPrimary != second.isPrimary {
                return first.isPrimary
            }
            return first.createdAt < second.createdAt
        }
        let balances = orderedAccounts.map { account in
            SpendAccountBalanceMetric(
                id: account.id,
                name: account.name,
                balance: account.balance(with: accountMovements)
            )
        }
        let totalBalance = balances.reduce(0) { $0 + $1.balance }

        accountBalances = balances
        inAccount = balances.first?.balance ?? totalBalance
        balanceFootnote = balances.count > 1
            ? String(format: AppStrings.text(.totalAllAccountsSummary), totalBalance.currencyText)
            : ""
    }

    private func calculateMonthUnpaidExpenses() -> Double {
        let monthStart = month.monthStart
        let monthPayments = payments.filter { $0.monthStart.monthStart == monthStart }
        let monthExclusions = exclusions.filter { $0.monthStart.monthStart == monthStart }
        let scopedCalculator = MoneyCalculationService(
            transactions: transactions,
            payments: monthPayments,
            exclusions: monthExclusions
        )
        let visibleTransactions = scopedCalculator.visibleTransactions(in: month)
        let monthCalculator = MoneyCalculationService(
            transactions: visibleTransactions,
            payments: monthPayments,
            exclusions: monthExclusions
        )
        return monthCalculator.monthSummary(in: month).unpaidExpenses
    }
}

struct CurrentAccountSummaryBar: View, Equatable {
    let metrics: CurrentAccountSummaryMetrics?
    let summarySignature: Int
    let showsMonthRemainingCard: Bool
    let showsMonthUnpaidCard: Bool
    let usesSidebarNavigation: Bool
    let onOpenAccounts: () -> Void
    let onOpenUnpaidExpenses: () -> Void
    let onOpenMonthRemaining: () -> Void
    let onRefresh: (Int) async -> Void

    static func == (lhs: CurrentAccountSummaryBar, rhs: CurrentAccountSummaryBar) -> Bool {
        lhs.metrics == rhs.metrics
            && lhs.summarySignature == rhs.summarySignature
            && lhs.showsMonthRemainingCard == rhs.showsMonthRemainingCard
            && lhs.showsMonthUnpaidCard == rhs.showsMonthUnpaidCard
            && lhs.usesSidebarNavigation == rhs.usesSidebarNavigation
    }

    var body: some View {
        VStack(spacing: 8) {
            if let metrics, metrics.accountBalances.count > 1 {
                AccountBalanceSummaryTile(
                    accounts: metrics.accountBalances,
                    footnote: metrics.balanceFootnote,
                    onTap: onOpenAccounts
                )
            } else {
                SummaryTile(
                    title: AppStrings.text(.balanceThisMonth),
                    value: metrics?.inAccount ?? 0,
                    helpText: metrics?.balanceHelpText ?? AppStrings.text(.balanceThisMonthHelp),
                    iconImageName: "SaldoDisponivelIcon",
                    footnote: metrics?.balanceFootnote ?? "",
                    helpTitle: metrics?.balanceHelpTitle,
                    isCompact: !usesSidebarNavigation,
                    isLoading: metrics == nil,
                    onTap: onOpenAccounts
                )
            }

            if showsMonthUnpaidCard || showsMonthRemainingCard {
                HStack(spacing: 8) {
                    if showsMonthUnpaidCard {
                        SummaryTile(
                            title: AppStrings.text(.monthUnpaid),
                            value: metrics?.monthUnpaidExpenses ?? 0,
                            helpText: AppStrings.text(.monthUnpaidHelp),
                            iconImageName: "FaltaPagarIcon",
                            helpArrowEdge: .bottom,
                            isCompact: !usesSidebarNavigation,
                            isLoading: metrics == nil || metrics?.isMonthUnpaidLoading == true,
                            titleLineLimit: 1,
                            fixedHeight: usesSidebarNavigation ? nil : 82,
                            onTap: onOpenUnpaidExpenses
                        )
                    }

                    if showsMonthRemainingCard {
                        let remaining = metrics?.monthRemaining ?? 0
                        SummaryTile(
                            title: remaining < 0 ? AppStrings.text(.monthBudgetExceeded) : AppStrings.text(.monthRemaining),
                            value: remaining,
                            helpText: AppStrings.text(.monthRemainingHelp),
                            iconImageName: "PodeGastarIcon",
                            boldHelpNote: AppStrings.text(.monthRemainingHelpNote),
                            isCompact: !usesSidebarNavigation,
                            isLoading: metrics == nil,
                            titleLineLimit: 1,
                            fixedHeight: usesSidebarNavigation ? nil : 82,
                            onTap: onOpenMonthRemaining
                        )
                    }
                }
            }
        }
        .padding(.horizontal, usesSidebarNavigation ? 16 : 12)
        .padding(.top, usesSidebarNavigation ? 4 : 0)
        .padding(.bottom, usesSidebarNavigation ? 12 : 4)
        .background(AppPalette.appBackground)
        .task(id: summarySignature) {
            await onRefresh(summarySignature)
        }
    }
}
