//
//  ContentView.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import SwiftData
import SwiftUI
import Charts

private struct TransactionOccurrence {
    let transaction: MoneyTransaction
    let month: Date
}

private enum MainTab {
    case currentAccount
    case credits
}

private enum AnalyticsExpenseTab {
    case whereSpent
    case budgetRule
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

private struct CategoryExpensePoint: Identifiable {
    let category: ExpenseCategory
    let amount: Double

    var id: String { category.rawValue }
}

private struct ExpenseTypePoint: Identifiable {
    let title: String
    let category: ExpenseCategory
    let amount: Double

    var id: String { "\(category.rawValue)-\(title)" }
}

private struct AnalyticsInsight: Identifiable {
    let title: String
    let message: String

    var id: String { "\(title)-\(message)" }
}

private struct ExpenseNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct MonthlyBalancePoint: Identifiable {
    let month: Date
    let income: Double
    let expenses: Double

    var id: Date { month }
    var balance: Double { income - expenses }
    var monthLabel: String { month.formatted(.dateTime.month(.abbreviated)) }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var exclusions: [RecurrenceExclusion]

    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
    @State private var selectedMonthOffset = 0
    @State private var selectedTab: MainTab = .currentAccount
    @State private var selectedAnalyticsExpenseTab: AnalyticsExpenseTab = .whereSpent
    @State private var selectedAnalyticsListTab: AnalyticsListTab = .subscriptions
    @State private var selectedInsightIndex = 0
    @State private var selectedAdviceIndex = 0
    @State private var editorRequest: TransactionEditorRequest?
    @State private var showsSettings = false
    @State private var showsQuickActions = false
    @State private var expenseNotice: ExpenseNotice?
    @State private var didCheckOverdueExpenses = false

    private let monthOffsets = Array(-24...24)
    private var selectedMonth: Date { Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date().monthStart) ?? Date().monthStart }
    private var currentMonth: Date { Date().monthStart }
    private var selectedTransactions: [MoneyTransaction] { transactions.visible(in: selectedMonth, payments: payments, exclusions: exclusions) }
    private var currentMonthTransactions: [MoneyTransaction] { transactions.visible(in: currentMonth, payments: payments, exclusions: exclusions) }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentYearMonths: [Date] {
        (1...12).map { Date.monthStart(month: $0, year: currentYear) }
    }
    private var accountOccurrencesUntilToday: [TransactionOccurrence] {
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min() else { return [] }

        return months(from: firstMonth, through: currentMonth).flatMap { month in
            let maxDay = Calendar.current.isDate(month, equalTo: currentMonth, toGranularity: .month)
                ? Calendar.current.component(.day, from: Date())
                : month.daysInMonth

            return transactions
                .visible(in: month, payments: payments, exclusions: exclusions)
                .filter { transaction in
                    if transaction.kind == TransactionKind.income.rawValue {
                        return transaction.effectiveDay(in: month) <= maxDay
                    }

                    return transaction.effectiveDay(in: month) <= maxDay || paidAmount(for: transaction, in: month) > 0
                }
                .map { TransactionOccurrence(transaction: $0, month: month) }
        }
    }

    private var monthUnpaidExpenses: Double {
        selectedTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + max($1.amount - paidAmount(for: $1, in: selectedMonth), 0) }
    }

    private var monthIncome: Double {
        selectedTransactions
            .filter { $0.kind == TransactionKind.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthExpenses: Double {
        selectedTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private var incomeUntilToday: Double {
        accountOccurrencesUntilToday
            .filter { $0.transaction.kind == TransactionKind.income.rawValue }
            .reduce(0) { $0 + $1.transaction.amount }
    }

    private var paidExpensesUntilToday: Double {
        accountOccurrencesUntilToday
            .filter { $0.transaction.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + paidAmount(for: $1.transaction, in: $1.month) }
    }

    private var inAccount: Double { incomeUntilToday - paidExpensesUntilToday }
    private var monthRemaining: Double { monthIncome - monthExpenses }
    private var currentMonthCategoryExpenses: [CategoryExpensePoint] {
        categoryExpenses(in: currentMonth)
    }
    private var currentMonthExpenseTotal: Double {
        currentMonthCategoryExpenses.reduce(0) { $0 + $1.amount }
    }
    private var currentMonthExpenseTypePoints: [ExpenseTypePoint] {
        expenseTypePoints(in: [currentMonth])
    }
    private var budgetReferencePoints: [CategoryExpensePoint] {
        [
            CategoryExpensePoint(category: .needs, amount: 50),
            CategoryExpensePoint(category: .wants, amount: 30),
            CategoryExpensePoint(category: .savingsAndDebt, amount: 20)
        ]
    }
    private var annualBalancePoints: [MonthlyBalancePoint] {
        currentYearMonths.map { month in
            let monthTransactions = transactions.visible(in: month, payments: payments, exclusions: exclusions)
            let income = monthTransactions
                .filter { $0.kind == TransactionKind.income.rawValue }
                .reduce(0) { $0 + $1.amount }
            let expenses = monthTransactions
                .filter { $0.kind == TransactionKind.expense.rawValue }
                .reduce(0) { $0 + $1.amount }

            return MonthlyBalancePoint(month: month, income: income, expenses: expenses)
        }
    }
    private var annualBalanceTotal: Double {
        annualBalancePoints.reduce(0) { $0 + $1.balance }
    }
    private var currentMonthSubscriptions: [MoneyTransaction] {
        currentMonthTransactions
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue && normalized(transaction.displayName).contains("subscr")
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    private var yearSavingsPoints: [MonthlyBalancePoint] {
        currentYearMonths.map { month in
            MonthlyBalancePoint(
                month: month,
                income: 0,
                expenses: expenseAmount(in: month, matching: ["poup", "saving"], paidOnly: false)
            )
        }
    }
    private var analyticsInsights: [AnalyticsInsight] {
        let previousMonth = currentMonth.previousMonthStart
        guard paidExpenseTotal(in: previousMonth) > 0 else { return [] }

        var insights: [AnalyticsInsight] = []
        let currentRestaurants = expenseAmount(in: currentMonth, matching: ["refeic", "restaurante"], paidOnly: true)
        let previousRestaurants = expenseAmount(in: previousMonth, matching: ["refeic", "restaurante"], paidOnly: true)
        if previousRestaurants > 0, currentRestaurants > previousRestaurants {
            insights.append(AnalyticsInsight(
                title: AppStrings.text(.paidInsights),
                message: String(format: AppStrings.text(.restaurantsIncreasedInsight), percentageText(currentRestaurants - previousRestaurants, total: previousRestaurants))
            ))
        }

        let currentGroceries = expenseAmount(in: currentMonth, matching: ["aliment", "supermercado"], paidOnly: true)
        let previousGroceries = expenseAmount(in: previousMonth, matching: ["aliment", "supermercado"], paidOnly: true)
        if previousGroceries > 0, currentGroceries < previousGroceries {
            insights.append(AnalyticsInsight(
                title: AppStrings.text(.paidInsights),
                message: String(format: AppStrings.text(.groceriesDecreasedInsight), percentageText(previousGroceries - currentGroceries, total: previousGroceries))
            ))
        }

        let currentSavings = categoryAmount(in: currentMonth, category: .savingsAndDebt, paidOnly: true)
        let previousSavings = categoryAmount(in: previousMonth, category: .savingsAndDebt, paidOnly: true)
        if currentSavings > previousSavings {
            insights.append(AnalyticsInsight(
                title: AppStrings.text(.paidInsights),
                message: String(format: AppStrings.text(.savingsIncreasedInsight), (currentSavings - previousSavings).currencyText)
            ))
        }

        let subscriptions = expenseAmount(in: currentMonth, matching: ["subscr"], paidOnly: true)
        let income = incomeTotal(in: currentMonth)
        if income > 0, subscriptions > 0 {
            insights.append(AnalyticsInsight(
                title: AppStrings.text(.paidInsights),
                message: String(format: AppStrings.text(.subscriptionsIncomeInsight), percentageText(subscriptions, total: income))
            ))
        }

        return insights
    }
    private var currentMonthAnalysisTitle: String {
        "\(AppStrings.text(.monthAnalysis)) \(currentMonth.monthTitle)"
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
        }
    }

    private func categoryExpenses(in month: Date) -> [CategoryExpensePoint] {
        let monthTransactions = transactions.visible(in: month, payments: payments, exclusions: exclusions)

        return ExpenseCategory.allCases.map { category in
            let amount = monthTransactions
                .filter { transaction in
                    transaction.kind == TransactionKind.expense.rawValue && transaction.expenseCategory == category.rawValue
                }
                .reduce(0) { $0 + $1.amount }

            return CategoryExpensePoint(category: category, amount: amount)
        }
    }

    private func expenseTypePoints(in months: [Date]) -> [ExpenseTypePoint] {
        var totals: [String: (title: String, category: ExpenseCategory, amount: Double)] = [:]

        months.forEach { month in
            transactions
                .visible(in: month, payments: payments, exclusions: exclusions)
                .filter { $0.kind == TransactionKind.expense.rawValue }
                .forEach { transaction in
                    let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? "") ?? .needs
                    let title = transaction.displayName.isEmpty ? AppStrings.text(.expense) : transaction.displayName
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

    private func incomeTotal(in month: Date) -> Double {
        transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { $0.kind == TransactionKind.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private func paidExpenseTotal(in month: Date) -> Double {
        transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + paidAmount(for: $1, in: month) }
    }

    private func categoryAmount(in month: Date, category: ExpenseCategory, paidOnly: Bool) -> Double {
        transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue && transaction.expenseCategory == category.rawValue
            }
            .reduce(0) { total, transaction in
                total + (paidOnly ? paidAmount(for: transaction, in: month) : transaction.amount)
            }
    }

    private func expenseAmount(in month: Date, matching keywords: [String], paidOnly: Bool) -> Double {
        transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { transaction in
                guard transaction.kind == TransactionKind.expense.rawValue else { return false }
                let searchableText = normalized("\(transaction.displayName) \(transaction.title)")
                return keywords.contains { searchableText.contains($0) }
            }
            .reduce(0) { total, transaction in
                total + (paidOnly ? paidAmount(for: transaction, in: month) : transaction.amount)
            }
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }

    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .currentAccount:
                    currentAccountView
                case .credits:
                    creditsView
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
            .sheet(isPresented: $showsSettings) {
                SettingsEditor()
            }
            .alert(item: $expenseNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text(AppStrings.text(.ok)))
                )
            }
            .onAppear(perform: handleAppear)
            .id(selectedCurrencyCode)
        }
    }

    private var currentAccountView: some View {
        VStack(spacing: 0) {
            summaryBar

            monthHeader

            TabView(selection: $selectedMonthOffset) {
                ForEach(monthOffsets, id: \.self) { offset in
                    let month = Calendar.current.date(byAdding: .month, value: offset, to: Date().monthStart) ?? Date().monthStart

                    MonthPage(
                        month: month,
                        transactions: transactions.visible(in: month, payments: payments, exclusions: exclusions),
                        payments: payments,
                        onSetPaidAmount: setPaidAmount,
                        onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: month, editScope: $0.isRecurring ? .singleMonth : .normal) },
                        onDelete: { deleteTransaction($0, in: month) }
                    )
                    .tag(offset)
                }
            }
            .monthPagerStyle()

            monthNavigationBar
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(height: 52)
        }
    }

    private var monthHeader: some View {
        HStack(spacing: 16) {
            monthArrowButton(systemImage: "chevron.left") {
                selectedMonthOffset = max(selectedMonthOffset - 1, monthOffsets.first ?? 0)
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
                selectedMonthOffset = min(selectedMonthOffset + 1, monthOffsets.last ?? 0)
            }
            .disabled(selectedMonthOffset >= (monthOffsets.last ?? 0))
            .opacity(selectedMonthOffset >= (monthOffsets.last ?? 0) ? 0.35 : 1)
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(AppPalette.appBackground)
    }

    private func monthArrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var monthNavigationBar: some View {
        BudgetStatusCard(
            month: selectedMonth,
            transactions: selectedTransactions,
            payments: payments,
            isCompact: true
        )
    }

    private var creditsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                chartCard(
                    title: currentMonthAnalysisTitle,
                    total: currentMonthExpenseTotal
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("", selection: $selectedAnalyticsExpenseTab) {
                            Text(AppStrings.text(.whereSpent)).tag(AnalyticsExpenseTab.whereSpent)
                            Text(AppStrings.text(.budgetRule)).tag(AnalyticsExpenseTab.budgetRule)
                        }
                        .pickerStyle(.segmented)
                        .tint(AppPalette.background)

                        switch selectedAnalyticsExpenseTab {
                        case .whereSpent:
                            expenseTypePieChart(points: currentMonthExpenseTypePoints, total: currentMonthExpenseTotal)
                        case .budgetRule:
                            HStack(alignment: .top, spacing: 16) {
                                pieChartColumn(
                                    title: AppStrings.text(.actualExpenses),
                                    points: currentMonthCategoryExpenses,
                                    total: currentMonthExpenseTotal
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

                if !analyticsInsights.isEmpty {
                    analyticsInsightCarouselCard
                }

                analyticsListsCard

                adviceCarouselCard
            }
            .padding()
        }
        .background(AppPalette.appBackground)
    }

    private var analyticsInsightCarouselCard: some View {
        let insights = analyticsInsights

        return HStack(spacing: 12) {
            adviceNavigationButton(systemImage: "chevron.left") {
                moveInsight(by: -1)
            }
            .disabled(insights.count <= 1)
            .opacity(insights.count <= 1 ? 0.35 : 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppStrings.text(.paidInsights))
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.primary)
                    .lineLimit(1)

                Text(insights.isEmpty ? AppStrings.text(.noInsights) : insights[selectedInsightIndex % insights.count].message)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
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
        .padding(14)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppPalette.primary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
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
        chartCard(title: selectedAnalyticsListTab.title, total: analyticsListTotal(for: selectedAnalyticsListTab)) {
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
                    transactionList(currentMonthSubscriptions, emptySystemImage: "play.rectangle")
                case .savings:
                    monthlyAmountList(points: yearSavingsPoints, value: { $0.expenses }, systemImage: "leaf.fill")
                case .incomeVsExpenses:
                    incomeVsExpensesList
                }
            }
        }
    }

    private func analyticsListTotal(for tab: AnalyticsListTab) -> Double {
        switch tab {
        case .subscriptions:
            currentMonthSubscriptions.reduce(0) { $0 + $1.amount }
        case .savings:
            yearSavingsPoints.reduce(0) { $0 + $1.expenses }
        case .incomeVsExpenses:
            annualBalancePoints.reduce(0) { $0 + $1.balance }
        }
    }

    private func transactionList(_ transactions: [MoneyTransaction], emptySystemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if transactions.isEmpty {
                analyticsEmptyRow(systemImage: emptySystemImage)
            } else {
                ForEach(transactions) { transaction in
                    analyticsRow(
                        icon: expenseIconName(for: transaction.displayName),
                        title: transaction.displayName,
                        subtitle: analyticsTransactionSubtitle(for: transaction, in: currentMonth),
                        freeText: transaction.title,
                        value: transaction.amount.currencyText,
                        tint: AppPalette.primary
                    )
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

    private func analyticsTransactionSubtitle(for transaction: MoneyTransaction, in month: Date) -> String {
        var parts = ["\(AppStrings.text(.day)) \(transaction.effectiveDay(in: month))"]
        if let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? "") {
            parts.append(category.title)
        }
        switch transaction.recurrence {
        case .monthly:
            parts.append(AppStrings.text(.everyMonth))
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            break
        }
        return parts.joined(separator: " · ")
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
                        .lineLimit(3)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

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
                            Image(systemName: expenseIconName(for: point.title))
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

    private func expenseIconName(for title: String) -> String {
        let normalizedTitle = title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()

        if normalizedTitle.contains("transport") || normalizedTitle.contains("combustivel") || normalizedTitle.contains("carro") {
            return "car.fill"
        }

        if normalizedTitle.contains("aliment") || normalizedTitle.contains("supermercado") || normalizedTitle.contains("refeic") {
            return "fork.knife"
        }

        if normalizedTitle.contains("habit") || normalizedTitle.contains("renda") || normalizedTitle.contains("credito") || normalizedTitle.contains("casa") {
            return "house.fill"
        }

        if normalizedTitle.contains("eletric") || normalizedTitle.contains("gas") || normalizedTitle.contains("agua") || normalizedTitle.contains("telecom") || normalizedTitle.contains("contas") {
            return "lightbulb.fill"
        }

        if normalizedTitle.contains("seguro") {
            return "shield.fill"
        }

        if normalizedTitle.contains("subscr") {
            return "play.rectangle.fill"
        }

        if normalizedTitle.contains("lazer") || normalizedTitle.contains("entreten") {
            return "sparkles"
        }

        if normalizedTitle.contains("viagem") || normalizedTitle.contains("ferias") {
            return "airplane"
        }

        if normalizedTitle.contains("roupa") || normalizedTitle.contains("acessor") || normalizedTitle.contains("compras") {
            return "bag.fill"
        }

        if normalizedTitle.contains("poup") {
            return "leaf.fill"
        }

        if normalizedTitle.contains("divida") || normalizedTitle.contains("amort") {
            return "creditcard.fill"
        }

        return "ellipsis.circle.fill"
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
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var settingsToolbarButton: some View {
        Button {
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
                helpText: AppStrings.text(.balanceThisMonthHelp)
            )

            HStack(spacing: 8) {
                SummaryTile(
                    title: AppStrings.text(.monthUnpaid),
                    value: monthUnpaidExpenses,
                    helpText: AppStrings.text(.monthUnpaidHelp)
                )
                SummaryTile(
                    title: AppStrings.text(.monthRemaining),
                    value: monthRemaining,
                    helpText: AppStrings.text(.monthRemainingHelp)
                )
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
        HStack(spacing: 14) {
            HStack(spacing: 4) {
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
            }
            .padding(6)
            .background(AppPalette.surface, in: Capsule())
            .shadow(color: AppPalette.background.opacity(0.08), radius: 14, y: 8)

            Spacer()

            Button {
                withAnimation(.snappy) {
                    showsQuickActions.toggle()
                }
            } label: {
                Image(systemName: showsQuickActions ? "xmark" : "plus")
                    .font(.title2)
                    .frame(width: 58, height: 58)
                    .foregroundStyle(AppPalette.background)
                    .background(AppPalette.secondary, in: Circle())
                    .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 7)
            }
            .buttonStyle(.plain)
            .disabled(selectedTab != .currentAccount)
            .opacity(selectedTab == .currentAccount ? 1 : 0.35)
        }
        .padding(.horizontal)
        .padding(.bottom, 0)
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
            .frame(width: 126, height: 60)
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
        HStack(spacing: 10) {
            Button {
                editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
                showsQuickActions = false
            } label: {
                Label(AppStrings.text(.income), systemImage: "plus.circle")
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AppPalette.secondary, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
                showsQuickActions = false
            } label: {
                Label(AppStrings.text(.expense), systemImage: "minus.circle")
                    .foregroundStyle(AppPalette.surface)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AppPalette.primary, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func handleAppear() {
        checkOverdueExpenses()
    }

    private func checkOverdueExpenses() {
        guard !didCheckOverdueExpenses else { return }
        didCheckOverdueExpenses = true

        let todayDay = Calendar.current.component(.day, from: Date())
        let currentOverdueExpenses = unpaidExpenses(in: currentMonth, throughDay: todayDay)
        let previousMonthUnpaidExpenses: [MoneyTransaction]

        if todayDay == 1, let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            previousMonthUnpaidExpenses = unpaidExpenses(in: previousMonth, throughDay: previousMonth.daysInMonth)
        } else {
            previousMonthUnpaidExpenses = []
        }

        var sections: [String] = []

        if !previousMonthUnpaidExpenses.isEmpty, let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            sections.append(expenseNoticeSection(
                prefix: "\(AppStrings.text(.previousMonthUnpaidExpensesMessagePrefix)) \(previousMonth.monthTitle)",
                expenses: previousMonthUnpaidExpenses,
                month: previousMonth
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

    private func unpaidExpenses(in month: Date, throughDay maxDay: Int) -> [MoneyTransaction] {
        transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue && transaction.effectiveDay(in: month) <= maxDay && !isPaid(transaction, in: month)
            }
            .sorted { first, second in
                let firstDay = first.effectiveDay(in: month)
                let secondDay = second.effectiveDay(in: month)

                if firstDay != secondDay {
                    return firstDay < secondDay
                }

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
        let monthCount = Calendar.current.dateComponents([.month], from: startMonth.monthStart, to: endMonth.monthStart).month ?? 0
        guard monthCount >= 0 else { return [] }

        return (0...monthCount).compactMap {
            Calendar.current.date(byAdding: .month, value: $0, to: startMonth.monthStart)
        }
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        paidAmount(for: transaction, in: month) >= transaction.amount
    }

    private func paidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        guard transaction.kind == TransactionKind.expense.rawValue else { return 0 }
        guard let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else { return 0 }
        return min(payment.amountPaid ?? transaction.amount, transaction.amount)
    }

    private func setPaidAmount(_ transaction: MoneyTransaction, in month: Date, amount: Double) {
        let clampedAmount = min(max(amount, 0), transaction.amount)

        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) {
            if clampedAmount <= 0 {
                modelContext.delete(payment)
            } else {
                payment.amountPaid = clampedAmount
            }
        } else if clampedAmount > 0 {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: month.monthStart, amountPaid: clampedAmount))
        }
    }

    private func deleteTransaction(_ transaction: MoneyTransaction, in month: Date) {
        if transaction.isRecurring {
            addExclusion(for: transaction, in: month)
            payments
                .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
                .forEach(modelContext.delete)
        } else {
            payments
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

#Preview {
    ContentView()
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, RecurrenceExclusion.self], inMemory: true)
}
