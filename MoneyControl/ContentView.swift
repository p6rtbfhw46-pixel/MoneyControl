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
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]

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
    @State private var selectedInsightIndex = 0
    @State private var selectedAdviceIndex = 0
    @State private var editorRequest: TransactionEditorRequest?
    @State private var paymentEditorRequest: PaymentEditorRequest?
    @State private var showsSettings = false
    @State private var showsQuickActions = false
    @State private var showsFilters = false
    @State private var paymentFilter: CurrentAccountPaymentFilter = .all
    @State private var filteredCategories: Set<ExpenseCategory> = []
    @State private var filteredExpenseType = ""
    @State private var freeTextFilter = ""
    @State private var expenseNotice: ExpenseNotice?
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
        calculator.accountSummary(until: Date()).incomeUntilToday
    }

    private var paidExpensesUntilToday: Double {
        calculator.accountSummary(until: Date()).paidExpensesUntilToday
    }

    private var inAccount: Double { calculator.accountSummary(until: Date()).availableBalance }
    private var monthRemaining: Double { calculator.monthSummary(in: selectedMonth).remaining }
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
    private var currentMonthSubscriptions: [MoneyTransaction] {
        currentMonthTransactions
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue && normalized(transaction.displayName).contains("subscr")
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    private var yearSavingsPoints: [MonthlyBalancePoint] {
        calculator.yearSavingsPoints(in: currentYearMonths)
    }
    private var analyticsInsights: [AnalyticsInsight] {
        calculator.analyticsInsights(currentMonth: currentMonth)
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
                    onConfirm: { amount in
                        setPaidAmount(request.transaction, in: request.month, amount: amount)
                    }
                )
            }
            .sheet(isPresented: $showsSettings) {
                SettingsEditor()
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
                creditAccounts: creditAccounts,
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

            filterButton

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

    private var filterButton: some View {
        Button {
            showsFilters = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title2)
                    .frame(width: 58, height: 58)
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

        syncLinkedCreditPayment(for: transaction, in: month, paidAmount: clampedAmount)
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

    private func deleteTransaction(_ transaction: MoneyTransaction, in month: Date) {
        if transaction.isRecurring {
            addExclusion(for: transaction, in: month)
            payments
                .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
                .forEach(modelContext.delete)
        } else {
            if let linkedCreditMovementID = transaction.linkedCreditMovementID,
               let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
                modelContext.delete(movement)
            }
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
                                    systemImage: expenseIconName(for: option.title),
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
}

private extension Array where Element == String {
    func uniquedSorted() -> [String] {
        Array(Set(self)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, RecurrenceExclusion.self], inMemory: true)
}
