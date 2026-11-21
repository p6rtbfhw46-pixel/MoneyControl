//
//  ContentView.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import SwiftData
import SwiftUI
import Charts
import UIKit
import UserNotifications

private enum MainTab: CaseIterable, Identifiable {
    case currentAccount
    case credits
    case management

    var id: Self { self }

    var title: String {
        switch self {
        case .currentAccount:
            AppStrings.text(.currentAccount)
        case .credits:
            AppStrings.text(.credits)
        case .management:
            AppStrings.text(.management)
        }
    }

    var systemImage: String {
        switch self {
        case .currentAccount:
            "list.bullet.rectangle"
        case .credits:
            "chart.bar"
        case .management:
            "square.grid.2x2"
        }
    }

    var bannerColor: Color {
        switch self {
        case .currentAccount:
            AppPalette.mediumBlue
        case .credits:
            AppPalette.positive
        case .management:
            AppPalette.purple
        }
    }
}

private enum PhoneTab: Hashable, Identifiable {
    case currentAccount
    case credits
    case management
    case filters

    var id: Self { self }

    var mainTab: MainTab? {
        switch self {
        case .currentAccount:
            .currentAccount
        case .credits:
            .credits
        case .management:
            .management
        case .filters:
            nil
        }
    }
}


private enum CurrentAccountSidebarTab: CaseIterable, Identifiable {
    case monthlyList
    case calendar

    var id: Self { self }

    var title: String {
        switch self {
        case .monthlyList:
            AppStrings.text(.currentAccountMonthlyList)
        case .calendar:
            AppStrings.text(.currentAccountCalendar)
        }
    }

    var systemImage: String {
        switch self {
        case .monthlyList:
            "list.bullet.rectangle"
        case .calendar:
            "calendar"
        }
    }
}

enum CurrentAccountPaymentFilter: String, CaseIterable, Identifiable {
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

enum CurrentAccountIncomeFilter: String, CaseIterable, Identifiable {
    case all
    case received
    case pending

    var id: String { rawValue }

    var title: String {
        let isPortuguese = AppStrings.currentLanguage == .portuguese
        switch self {
        case .all:
            return AppStrings.text(.all)
        case .received:
            return isPortuguese ? "Recebidos" : "Received"
        case .pending:
            return isPortuguese ? "Por receber" : "Pending"
        }
    }
}

enum CurrentAccountSortOrder: String, CaseIterable, Identifiable {
    case paymentStatusNewestFirst
    case currentPaymentStatusOrder
    case dateNewestFirst
    case dateOldestFirst
    case amountHighestFirst
    case amountLowestFirst
    case nameAscending

    var id: String { rawValue }

    var title: String {
        let isPortuguese = AppStrings.currentLanguage == .portuguese
        switch self {
        case .paymentStatusNewestFirst:
            return isPortuguese ? "Por pagar e pagas — mais recente primeiro" : "Unpaid and paid — newest first"
        case .currentPaymentStatusOrder:
            return isPortuguese ? "Por pagar mais recentes primeiro — Pagas mais antigas primeiro" : "Newest unpaid first — Oldest paid first"
        case .dateNewestFirst:
            return isPortuguese ? "Data — mais recente primeiro" : "Date — newest first"
        case .dateOldestFirst:
            return isPortuguese ? "Data — mais antiga primeiro" : "Date — oldest first"
        case .amountHighestFirst:
            return isPortuguese ? "Valor — maior primeiro" : "Amount — highest first"
        case .amountLowestFirst:
            return isPortuguese ? "Valor — menor primeiro" : "Amount — lowest first"
        case .nameAscending:
            return isPortuguese ? "Texto livre — A a Z" : "Free text — A to Z"
        }
    }

    var systemImage: String {
        switch self {
        case .paymentStatusNewestFirst:
            "checkmark.circle.fill"
        case .currentPaymentStatusOrder:
            "clock.arrow.circlepath"
        case .dateNewestFirst:
            "calendar.badge.clock"
        case .dateOldestFirst:
            "calendar"
        case .amountHighestFirst:
            "arrow.down.circle"
        case .amountLowestFirst:
            "arrow.up.circle"
        case .nameAscending:
            "textformat.abc"
        }
    }
}

@MainActor
@Observable
private final class CurrentAccountScrollState {
    var isHidden = false
}

private struct PhoneCurrentAccountActionsOverlay: View {
    let activeFilterCount: Int
    let scrollState: CurrentAccountScrollState
    let showsSavingAction: Bool
    let showsCreditAction: Bool
    let activePlannings: [Planning]
    let onExpense: () -> Void
    let onIncome: () -> Void
    let onSaving: () -> Void
    let onCredit: () -> Void
    let onReceipt: () -> Void
    let onFilters: () -> Void
    let onPlanning: (Planning) -> Void

    @State private var showsQuickActions = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
                if showsQuickActions {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.82)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.snappy) {
                                showsQuickActions = false
                            }
                        }
                        .transition(.opacity)
                }

                VStack(alignment: .trailing, spacing: 10) {
                    if showsQuickActions {
                        quickActions
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    ForEach(activePlannings) { planning in
                        planningButton(planning)
                    }

                    bottomActionButton(
                        systemImage: showsQuickActions ? "xmark" : "plus",
                        accessibilityLabel: AppStrings.text(.add)
                    ) {
                        withAnimation(.snappy) {
                            showsQuickActions.toggle()
                        }
                    }

                    bottomActionButton(
                        systemImage: "line.3.horizontal.decrease",
                        badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil,
                        accessibilityLabel: AppStrings.text(.filters)
                    ) {
                        showsQuickActions = false
                        onFilters()
                    }

                }
                .padding(.trailing, 18)
                .padding(.bottom, 44)
                .offset(y: scrollState.isHidden ? 180 : 0)
                .opacity(scrollState.isHidden ? 0 : 1)
                .allowsHitTesting(!scrollState.isHidden)
                .animation(.snappy, value: scrollState.isHidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private var quickActions: some View {
        VStack(alignment: .trailing, spacing: 10) {
            quickActionButton(
                title: AppStrings.text(.expense),
                imageName: "QuickActionDespesa",
                action: closeAndRun(onExpense)
            )

            quickActionButton(
                title: AppStrings.text(.income),
                imageName: "QuickActionReceita",
                action: closeAndRun(onIncome)
            )

            if showsSavingAction {
                quickActionButton(
                    title: SavingsStrings.text(.saving),
                    imageName: "QuickActionPoupanca",
                    action: closeAndRun(onSaving)
                )
            }

            if showsCreditAction {
                quickActionButton(
                    title: CreditStrings.text(.credit),
                    imageName: "QuickActionCredito",
                    action: closeAndRun(onCredit)
                )
            }

            quickActionButton(
                title: AppStrings.text(.readReceipt),
                imageName: "QuickActionLerFatura",
                action: closeAndRun(onReceipt)
            )
        }
    }

    private func closeAndRun(_ action: @escaping () -> Void) -> () -> Void {
        {
            showsQuickActions = false
            action()
        }
    }

    private func quickActionButton(title: String, imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 124, height: 34)
                    .background(AppPalette.surface.opacity(0.98), in: Capsule())
                    .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)

            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func planningButton(_ planning: Planning) -> some View {
        Button {
            showsQuickActions = false
            onPlanning(planning)
        } label: {
            Image(systemName: planning.planningType.iconName)
                .font(.title3.weight(.bold))
                .foregroundStyle(planning.planningType.color)
                .frame(width: 58, height: 58)
                .background(AppPalette.surface.opacity(0.96), in: Circle())
                .overlay {
                    Circle()
                        .stroke(planning.planningType.color.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(planning.name)
    }

    private func bottomActionButton(
        systemImage: String,
        badge: String? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background.opacity(0.82))
                    .frame(width: 58, height: 58)
                    .background {
                        Circle()
                            .fill(AppPalette.surface.opacity(0.58))
                            .overlay {
                                Circle()
                                    .stroke(.black.opacity(0.6), lineWidth: 0.4)
                            }
                            .shadow(color: AppPalette.background.opacity(0.12), radius: 12, y: 6)
                    }
                    .contentShape(Circle())

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 22, height: 22)
                        .background(AppPalette.primary, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct ExpenseNoticeItem {
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?

    var day: Int {
        occurrenceDay ?? transaction.effectiveDay(in: month)
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

private struct OverdueExpenseNoticeSheet: View {
    let title: String
    let message: String
    let onConfirm: (Bool) -> Void

    @State private var suppressForToday = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(message)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        suppressForToday.toggle()
                    } label: {
                        Label {
                            Text(AppStrings.text(.doNotShowAgainToday))
                        } icon: {
                            Image(systemName: suppressForToday ? "checkmark.square.fill" : "square")
                                .foregroundStyle(suppressForToday ? AppPalette.primary : AppPalette.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(suppressForToday ? .isSelected : [])
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) {
                        onConfirm(suppressForToday)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .presentationDetents([.medium, .large])
    }
}

private struct PaymentEditorRequest: Identifiable {
    let id = UUID()
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?
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


private extension View {
    func analyticsDetailDestinations(
        saving: Binding<SavingAccount?>,
        credit: Binding<CreditAccount?>
    ) -> some View {
        navigationDestination(item: saving) { saving in
            SavingDetailView(saving: saving)
        }
        .navigationDestination(item: credit) { credit in
            CreditDetailView(credit: credit)
        }
    }
}


private struct ExpensePaymentReminder: Sendable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var auditLogEntries: [AuditLogEntry]
    @Query private var plannings: [Planning]
    @Query private var planningMovements: [PlanningMovement]

    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
    @AppStorage(AppColorPalette.storageKey) private var selectedColorPalette = AppColorPalette.original.rawValue
    @AppStorage(AppPreferences.notificationsEnabledKey) private var notificationsEnabled = true
    @AppStorage(AppPreferences.launchPaymentReminderEnabledKey) private var launchPaymentReminderEnabled = true
    @AppStorage(AppPreferences.overdueExpenseNoticeSuppressedAtKey) private var overdueExpenseNoticeSuppressedAt = 0.0
    @AppStorage(AppPreferences.showsCurrentAccountBalanceCardKey) private var showsCurrentAccountBalanceCard = true
    @AppStorage(AppPreferences.showsCurrentAccountPlanningCardsKey) private var showsCurrentAccountPlanningCards = true
    @AppStorage("currentAccountPaymentFilter") private var storedPaymentFilter = CurrentAccountPaymentFilter.all.rawValue
    @AppStorage("currentAccountIncomeFilter") private var storedIncomeFilter = CurrentAccountIncomeFilter.all.rawValue
    @AppStorage("currentAccountFilteredCategories") private var storedFilteredCategories = ""
    @AppStorage("currentAccountFilteredExpenseType") private var storedFilteredExpenseType = ""
    @AppStorage("currentAccountFreeTextFilter") private var storedFreeTextFilter = ""
    @AppStorage("currentAccountSortOrder") private var storedSortOrder = CurrentAccountSortOrder.currentPaymentStatusOrder.rawValue
    @State private var selectedMonthOffset = 0
    @State private var monthNavigationDirection = 1
    @State private var selectedTab: MainTab = .currentAccount
    @State private var selectedPhoneTab: PhoneTab = .currentAccount
    @State private var currentAccountScrollState = CurrentAccountScrollState()
    @State private var managementNavigationResetID = UUID()
    @State private var showsPhoneAccountsManagement = false
    @State private var selectedCurrentAccountSidebarTab: CurrentAccountSidebarTab = .monthlyList
    @State private var selectedAnalyticsSidebarTab: AnalyticsSidebarTab = .overview
    @State private var analyticsSavingsCreditsFilter: AnalyticsSavingsCreditsFilter = .all
    @State private var selectedManagementSidebarTab: ManagementSidebarTab = .accounts
    @State private var selectedAnalyticsExpenseTab: AnalyticsExpenseTab = .whereSpent
    @State private var selectedAnalyticsPeriod: AnalyticsPeriod = .month
    @State private var selectedAnalyticsMonthOffset = 0
    @State private var selectedSubscriptionAnalysisScope: SubscriptionAnalysisScope = .monthly
    @State private var selectedAnalyticsHistoryFilterMode: AnalyticsHistoryFilterMode = .month
    @State private var selectedAnalyticsHistoryMonthOffset = 0
    @State private var analyticsHistoryStartDate = Date().monthStart
    @State private var analyticsHistoryEndDate = Date()
    @State private var selectedLightweightEvolutionKind: LightweightEvolutionKind = .balance
    @State private var selectedAnalyticsSavingDetail: SavingAccount?
    @State private var selectedAnalyticsCreditDetail: CreditAccount?
    @State private var analyticsExpenseDetailRequest: AnalyticsExpenseDetailRequest?
    @State private var lightweightEvolutionTable: LightweightEvolutionTable = .empty
    @State private var lightweightEvolutionSignatureSnapshot = ""
    @State private var isLightweightEvolutionLoading = false
    @State private var expandedLightweightEvolutionMarkerID: Date?
    @State private var selectedAdviceIndex = 0
    @State private var showsSavingsPotentialDetails = false
    @State private var annualAllocationPercentage = 25
    @State private var showsAnnualAllocationMonths = false
    @State private var excludedAnnualAllocationMonths: Set<Int> = []
    @State private var annualAllocationDetailsKind: AnnualAllocationSimulationKind?
    @State private var editorRequest: TransactionEditorRequest?
    @State private var saveNoticeCenter = SaveResultNoticeCenter.shared
    @State private var paymentEditorRequest: PaymentEditorRequest?
    @State private var isProcessingPaymentChange = false
    @State private var currentAccountCreditMovementRequest: CurrentAccountCreditMovementRequest?
    @State private var selectedPlanningShortcut: Planning?
    @State private var calendarTransactionRequest: CalendarTransactionRequest?
    @State private var calendarPopoverRequest: CalendarTransactionRequest?
    @State private var calendarDayRequest: CalendarDayRequest?
    @State private var calendarDayExpandedTransactionID: UUID?
    @State private var showsSettings = false
    @State private var settingsInitialTab: SettingsTab = .budget
    @State private var showsQuickActions = false
    @State private var showsRecurringQuickActions = false
    @State private var showsReceiptScanner = false
    @State private var showsFilters = false
    @State private var showsUnpaidExpensesBreakdown = false
    @State private var monthRemainingBreakdownRequest: MonthRemainingBreakdownRequest?
    @State private var paymentFilter: CurrentAccountPaymentFilter = .all
    @State private var incomeFilter: CurrentAccountIncomeFilter = .all
    @State private var filteredCategories: Set<ExpenseCategory> = []
    @State private var filteredExpenseType = ""
    @State private var freeTextFilter = ""
    @State private var sortOrder: CurrentAccountSortOrder = .currentPaymentStatusOrder
    @State private var filtersAffectSummaryCards = false
    @State private var expenseNotice: ExpenseNotice?
    @State private var overdueExpenseNotice: ExpenseNotice?
    @State private var savingsHistoryRequest: SavingsHistoryRequest?
    @State private var currentAccountSummaryMetrics: CurrentAccountSummaryMetrics?
    @State private var currentAccountSummaryMetricsSignature: Int?
    @State private var didLoadStoredFilters = false
    @State private var didCheckOverdueExpenses = false
    @State private var didRunStartupMaintenance = false
    @State private var didFinishStartupMaintenance = false

    private let monthOffsets = Array(-12...12)
    private var selectedMonth: Date { Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date().monthStart) ?? Date().monthStart }
    private var currentMonth: Date { Date().monthStart }
    private var managementRecurringMonthlyBalance: Double {
        let currentMonthIncome = transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring && $0.isActiveForSettingsList && $0.recurrence == .monthly }
            .reduce(0) { $0 + $1.scheduledAmount(in: currentMonth) }
        let currentMonthExpenses = transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring && $0.isActiveForSettingsList && $0.recurrence == .monthly }
            .reduce(0) { $0 + $1.scheduledAmount(in: currentMonth) }
        return currentMonthIncome - currentMonthExpenses
    }
    private var managementTotalSaved: Double {
        savingAccounts
            .filter { $0.savingStatus == .active }
            .reduce(0) { $0 + $1.balance(with: savingMovements) }
    }
    private var managementTotalDebt: Double {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .reduce(0) { $0 + $1.balance(with: creditMovements) }
    }
    private var managementActivePlanningCount: Int {
        plannings.filter { $0.planningStatus == .active }.count
    }

    private var activePlanningShortcuts: [Planning] {
        plannings
            .filter { $0.planningStatus == .active }
            .sorted { first, second in
                if first.createdAt != second.createdAt {
                    return first.createdAt > second.createdAt
                }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    private var managementActivePlanningSummary: String {
        if AppStrings.currentLanguage == .portuguese {
            return managementActivePlanningCount == 1 ? "Ativo" : "Ativos"
        } else {
            return managementActivePlanningCount == 1 ? "Active" : "Active"
        }
    }
    private var primarySpendAccount: SpendAccount? {
        spendAccounts.first(where: \.isPrimary) ?? spendAccounts.first
    }
    private var totalSpendAccountsBalance: Double {
        spendAccounts.reduce(0) { $0 + $1.balance(with: accountMovements) }
    }
    private var primarySpendAccountBalance: Double? {
        primarySpendAccount?.balance(with: accountMovements)
    }
    private var hasMultipleSpendAccounts: Bool {
        spendAccounts.count > 1
    }
    private var selectedMonthShowsCurrentDay: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }
    private var shouldShowMonthUnpaidCard: Bool {
        selectedMonth.monthStart >= currentMonth.monthStart
    }
    private var currentDayNumber: Int {
        Calendar.current.component(.day, from: Date())
    }
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
    private var notificationScheduleSignature: Int {
        var hasher = Hasher()
        hasher.combine(notificationsEnabled)

        transactions.forEach { transaction in
            hasher.combine(transaction.id)
            hasher.combine(transaction.title)
            hasher.combine(transaction.displayName)
            hasher.combine(transaction.kind)
            hasher.combine(transaction.day)
            hasher.combine(transaction.amount)
            hasher.combine(transaction.monthStart)
            hasher.combine(transaction.recurrenceType)
            hasher.combine(transaction.recurrenceMonth)
            hasher.combine(transaction.recurrenceEndMonthStart)
        }

        payments.forEach { payment in
            hasher.combine(payment.transactionID)
            hasher.combine(payment.monthStart)
            hasher.combine(payment.occurrenceDay)
            hasher.combine(payment.amountPaid)
        }

        exclusions.forEach { exclusion in
            hasher.combine(exclusion.transactionID)
            hasher.combine(exclusion.monthStart)
        }

        return hasher.finalize()
    }

    private var currentAccountBalanceOnlySignature: Int {
        var hasher = Hasher()
        let monthStart = selectedMonth.monthStart
        hasher.combine(selectedMonthOffset)
        hasher.combine(filtersAffectSummaryCards)
        if filtersAffectSummaryCards {
            hasher.combine(paymentFilter.rawValue)
            hasher.combine(incomeFilter.rawValue)
            hasher.combine(filteredExpenseType)
            hasher.combine(freeTextFilter)
            filteredCategories
                .map(\.rawValue)
                .sorted()
                .forEach { hasher.combine($0) }
        }

        // Keep this signature cheap: do not resolve recurrences or build
        // the filtered month list while SwiftUI is presenting the new month.
        transactions.forEach { transaction in
            hasher.combine(transaction.id)
            hasher.combine(transaction.amount)
            hasher.combine(transaction.day)
            hasher.combine(transaction.kind)
            hasher.combine(transaction.recurrenceType)
            hasher.combine(transaction.recurrenceEndMonthStart)
        }

        payments
            .filter { $0.monthStart == monthStart }
            .forEach { payment in
                hasher.combine(payment.transactionID)
                hasher.combine(payment.occurrenceDay)
                hasher.combine(payment.amountPaid)
            }

        exclusions
            .filter { $0.monthStart == monthStart }
            .forEach { exclusion in
                hasher.combine(exclusion.transactionID)
                hasher.combine(exclusion.occurrenceDay)
            }

        spendAccounts.forEach { account in
            hasher.combine(account.id)
            hasher.combine(account.name)
            hasher.combine(account.initialBalance)
            hasher.combine(account.isPrimary)
        }

        accountMovements.forEach { movement in
            hasher.combine(movement.accountID)
            hasher.combine(movement.amount)
            hasher.combine(movement.date)
        }

        return hasher.finalize()
    }

    private var currentAccountSummarySignature: Int {
        var hasher = Hasher()
        hasher.combine(selectedMonthOffset)
        hasher.combine(filtersAffectSummaryCards)
        if filtersAffectSummaryCards {
            hasher.combine(paymentFilter.rawValue)
            hasher.combine(incomeFilter.rawValue)
            hasher.combine(filteredExpenseType)
            hasher.combine(freeTextFilter)
            filteredCategories
                .map(\.rawValue)
                .sorted()
                .forEach { hasher.combine($0) }
        }

        transactions.forEach { transaction in
            hasher.combine(transaction.id)
            hasher.combine(transaction.title)
            hasher.combine(transaction.displayName)
            hasher.combine(transaction.kind)
            hasher.combine(transaction.expenseCategory)
            hasher.combine(transaction.day)
            hasher.combine(transaction.amount)
            hasher.combine(transaction.monthStart)
            hasher.combine(transaction.recurrenceType)
            hasher.combine(transaction.recurrenceMonth)
            hasher.combine(transaction.recurrenceEndMonthStart)
            hasher.combine(transaction.budgetAllocationType)
            hasher.combine(transaction.budgetMonthStart)
        }

        payments.forEach { payment in
            hasher.combine(payment.transactionID)
            hasher.combine(payment.monthStart)
            hasher.combine(payment.occurrenceDay)
            hasher.combine(payment.amountPaid)
        }

        exclusions.forEach { exclusion in
            hasher.combine(exclusion.transactionID)
            hasher.combine(exclusion.monthStart)
        }

        spendAccounts.forEach { account in
            hasher.combine(account.id)
            hasher.combine(account.initialBalance)
            hasher.combine(account.isPrimary)
        }

        accountMovements.forEach { movement in
            hasher.combine(movement.accountID)
            hasher.combine(movement.amount)
            hasher.combine(movement.date)
        }

        return hasher.finalize()
    }

    private var activeFilterCount: Int {
        var count = 0
        if paymentFilter != .all { count += 1 }
        if incomeFilter != .all { count += 1 }
        if !filteredCategories.isEmpty { count += 1 }
        if !filteredExpenseType.isEmpty { count += 1 }
        if !freeTextFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        return count
    }
    private var shouldApplyFiltersToSummaryCards: Bool {
        filtersAffectSummaryCards && activeFilterCount > 0
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
    private var balanceCardFootnote: String {
        var parts: [String] = []
        if hasMultipleSpendAccounts {
            parts.append(String(format: AppStrings.text(.totalAllAccountsSummary), totalSpendAccountsBalance.currencyText))
        }
        if !futureBudgetReservationFootnote.isEmpty {
            parts.append(futureBudgetReservationFootnote)
        }
        return parts.joined(separator: "\n")
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
        guard shouldApplyFiltersToSummaryCards else {
            return unpaidExpenses(in: selectedMonth)
        }

        return selectedFilteredTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { total, transaction in
                total + filteredUnpaidAmount(for: transaction, in: selectedMonth)
            }
    }

    private func filteredUnpaidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        transaction.occurrenceDays(in: month, exclusions: exclusions).reduce(0) { total, day in
            let occurrenceDay = transaction.recurrence == .weekly ? day : nil
            let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
            let paidAmount = paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
            let isPaid = paidAmount >= scheduledAmount

            if paymentFilter == .paid && !isPaid { return total }
            if paymentFilter == .unpaid && isPaid { return total }

            return total + max(scheduledAmount - paidAmount, 0)
            }
    }

    private func unpaidExpenses(in month: Date) -> Double {
        calculator.monthSummary(in: month).unpaidExpenses
    }

    private var unpaidExpenseLines: [UnpaidExpenseLine] {
        let sourceTransactions = shouldApplyFiltersToSummaryCards ? selectedFilteredTransactions : selectedTransactions

        return sourceTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .flatMap { transaction in
                transaction.occurrenceDays(in: selectedMonth, exclusions: exclusions).compactMap { day -> UnpaidExpenseLine? in
                    let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                    let scheduledAmount = transaction.scheduledAmount(in: selectedMonth, occurrenceDay: occurrenceDay)
                    let paidAmount = paidAmount(for: transaction, in: selectedMonth, occurrenceDay: occurrenceDay)
                    let remainingAmount = max(scheduledAmount - paidAmount, 0)
                    guard remainingAmount > 0.005 else { return nil }

                    return UnpaidExpenseLine(
                        title: unpaidExpenseTitle(for: transaction),
                        subtitle: unpaidExpenseSubtitle(for: transaction, day: day),
                        day: day,
                        scheduledAmount: scheduledAmount,
                        paidAmount: paidAmount,
                        remainingAmount: remainingAmount,
                        isWeekly: transaction.recurrence == .weekly
                    )
                }
            }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    private var unpaidExpenseLinesTotal: Double {
        unpaidExpenseLines.reduce(0) { $0 + $1.remainingAmount }
    }

    private func unpaidExpenseTitle(for transaction: MoneyTransaction) -> String {
        let title = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? transaction.displayName : title
    }

    private func unpaidExpenseSubtitle(for transaction: MoneyTransaction, day: Int) -> String {
        var parts = ["Dia \(day)"]

        if transaction.recurrence == .weekly {
            parts.append(AppStrings.text(.weeklyRecurrence))
        }

        if !transaction.displayName.isEmpty, transaction.displayName != transaction.title {
            parts.append(transaction.displayName)
        }

        return parts.joined(separator: " - ")
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

    private var inAccount: Double { primarySpendAccountBalance ?? accountSummary.availableBalance }
    private var totalAvailableBalance: Double {
        spendAccounts.isEmpty ? accountSummary.availableBalance : totalSpendAccountsBalance
    }
    private var currentSpendableBalance: Double {
        totalAvailableBalance - futureBudgetReservationTotal
    }

    private func auditBalanceAfter(delta: Double = 0) -> Double {
        totalAvailableBalance + delta
    }

    private func insertAuditLog(
        action: AuditLogAction,
        title: String,
        details: String = "",
        note: String = "",
        amount: Double = 0,
        balanceAfter: Double? = nil,
        accountID: UUID? = nil,
        relatedAccountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        creditID: UUID? = nil,
        savingID: UUID? = nil,
        date: Date = Date()
    ) {
        modelContext.insert(AuditLogEntry(
            date: date,
            action: action.rawValue,
            title: title,
            details: details,
            note: note,
            amount: amount,
            balanceAfter: balanceAfter ?? auditBalanceAfter(),
            accountID: accountID,
            relatedAccountID: relatedAccountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID,
            creditID: creditID,
            savingID: savingID
        ))
    }
    private var isSelectedMonthInSpendableWindow: Bool {
        guard let maximumMonth = Calendar.current.date(byAdding: .month, value: 2, to: currentMonth) else {
            return Calendar.current.isDate(selectedMonth, equalTo: currentMonth, toGranularity: .month)
        }

        return selectedMonth >= currentMonth && selectedMonth <= maximumMonth.monthStart
    }
    private var monthRemaining: Double? {
        guard isSelectedMonthInSpendableWindow else { return nil }

        let calendar = Calendar.current
        let selectedMonthStart = selectedMonth.monthStart
        let currentMonthStart = currentMonth.monthStart
        let pendingCurrentMonthIncome = currentAccountPendingIncome(
            in: currentMonthStart,
            using: calculator
        )
        var projectedRemaining = currentSpendableBalance + pendingCurrentMonthIncome - unpaidExpenses(in: currentMonthStart)

        guard selectedMonthStart > currentMonthStart else {
            return shouldApplyFiltersToSummaryCards
                ? currentSpendableBalance + pendingCurrentMonthIncome - monthUnpaidExpenses
                : projectedRemaining
        }

        var projectedMonth = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)?.monthStart
        while let month = projectedMonth, month <= selectedMonthStart {
            let summary = calculator.monthSummary(in: month)
            projectedRemaining += summary.income - summary.unpaidExpenses
            projectedMonth = calendar.date(byAdding: .month, value: 1, to: month)?.monthStart
        }

        return projectedRemaining
    }
    @MainActor
    private func refreshCurrentAccountSummaryMetrics(for signature: Int) async {
        guard currentAccountSummaryMetrics == nil || currentAccountSummaryMetricsSignature != signature else {
            return
        }

        currentAccountSummaryMetrics = nil

        // The balance is independent and available immediately.
        currentAccountSummaryMetrics = makeCurrentAccountBalanceOnlyMetrics(
            monthUnpaidExpenses: 0,
            isMonthUnpaidLoading: true
        )
        currentAccountSummaryMetricsSignature = signature

        // Present the month first. The unpaid card owns this separate,
        // cancellable background calculation.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        let month = selectedMonth
        let unpaidExpenses = currentAccountMonthUnpaidExpenses(in: month)

        guard !Task.isCancelled,
              signature == currentAccountBalanceOnlySignature
        else { return }

        currentAccountSummaryMetrics = makeCurrentAccountBalanceOnlyMetrics(
            monthUnpaidExpenses: unpaidExpenses,
            isMonthUnpaidLoading: false
        )
    }

    private func currentAccountSummaryBackgroundMonths(now: Date) -> [Date] {
        let currentMonthStart = now.monthStart
        let selectedMonthStart = selectedMonth.monthStart
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min() else {
            return [currentMonthStart, selectedMonthStart]
        }

        let lastMonth = max(currentMonthStart, selectedMonthStart)
        return months(from: firstMonth, through: lastMonth)
    }

    private func currentAccountMonthUnpaidExpenses(in month: Date) -> Double {
        let monthStart = month.monthStart
        let monthPayments = payments.filter { $0.monthStart == monthStart }
        let monthExclusions = exclusions.filter { $0.monthStart == monthStart }

        // Resolve visibility using only records capable of affecting this month.
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

        guard shouldApplyFiltersToSummaryCards else {
            return monthCalculator.monthSummary(in: month).unpaidExpenses
        }

        let receivedIncomeKeys = receivedIncomeKeys
        return visibleTransactions
            .filter {
                transactionMatchesCurrentAccountFilters(
                    $0,
                    in: month,
                    receivedIncomeKeys: receivedIncomeKeys
                )
            }
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { total, transaction in
                total + transaction.occurrenceDays(in: month, exclusions: monthExclusions)
                    .reduce(0) { occurrenceTotal, day in
                        let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                        let scheduled = transaction.scheduledAmount(
                            in: month,
                            occurrenceDay: occurrenceDay
                        )
                        let paid = monthCalculator.paidAmount(
                            for: transaction,
                            in: month,
                            occurrenceDay: occurrenceDay
                        )
                        return occurrenceTotal + max(scheduled - paid, 0)
                    }
            }
    }

    private func makeCurrentAccountBalanceOnlyMetrics(
        monthUnpaidExpenses: Double,
        isMonthUnpaidLoading: Bool
    ) -> CurrentAccountSummaryMetrics {
        let orderedSpendAccounts = spendAccounts.sorted { first, second in
            if first.isPrimary != second.isPrimary {
                return first.isPrimary
            }
            return first.createdAt < second.createdAt
        }
        let accountBalances = orderedSpendAccounts.map { account in
            SpendAccountBalanceMetric(
                id: account.id,
                name: account.name,
                balance: account.balance(with: accountMovements)
            )
        }
        let totalBalance = accountBalances.reduce(0) { $0 + $1.balance }
        let primaryBalance = accountBalances.first?.balance
        let fallbackBalance = spendAccounts.isEmpty
            ? MoneyCalculationService(
                transactions: transactions,
                payments: payments,
                exclusions: exclusions
            ).accountSummary(until: Date()).availableBalance
            : totalBalance
        let balanceFootnote = accountBalances.count > 1
            ? String(format: AppStrings.text(.totalAllAccountsSummary), totalBalance.currencyText)
            : ""

        return CurrentAccountSummaryMetrics(
            inAccount: primaryBalance ?? fallbackBalance,
            accountBalances: accountBalances,
            monthUnpaidExpenses: monthUnpaidExpenses,
            isMonthUnpaidLoading: isMonthUnpaidLoading,
            monthRemainingCalculation: nil,
            monthRemainingFootnote: "",
            balanceHelpText: AppStrings.text(.balanceThisMonthHelp),
            balanceFootnote: balanceFootnote,
            balanceHelpTitle: nil
        )
    }

    private func makeCurrentAccountSummaryMetrics(
        backgroundResult: MoneyCalculationBackgroundResult
    ) -> CurrentAccountSummaryMetrics {
        let calculator = MoneyCalculationService(transactions: transactions, payments: payments, exclusions: exclusions)
        let accountSummary = backgroundResult.accountSummary
        let orderedSpendAccounts = spendAccounts.sorted { first, second in
            if first.isPrimary != second.isPrimary {
                return first.isPrimary
            }
            return first.createdAt < second.createdAt
        }
        let accountBalances = orderedSpendAccounts.map { account in
            SpendAccountBalanceMetric(
                id: account.id,
                name: account.name,
                balance: account.balance(with: accountMovements)
            )
        }
        let totalSpendAccountsBalance = spendAccounts.reduce(0) { $0 + $1.balance(with: accountMovements) }
        let primarySpendAccount = spendAccounts.first(where: \.isPrimary) ?? spendAccounts.first
        let primarySpendAccountBalance = primarySpendAccount?.balance(with: accountMovements)
        let inAccount = primarySpendAccountBalance ?? accountSummary.availableBalance
        let totalAvailableBalance = spendAccounts.isEmpty ? accountSummary.availableBalance : totalSpendAccountsBalance
        let futureBudgetReservations = accountSummary.reservedForFutureBudgets
        let firstFutureBudgetReservation = futureBudgetReservations.first
        let futureBudgetReservationTotal = accountSummary.reservedForFutureBudgetsTotal
        let futureBudgetReservationFootnote: String

        if let firstFutureBudgetReservation {
            futureBudgetReservationFootnote = String(
                format: AppStrings.text(.reservedForBudgetSummary),
                futureBudgetReservationTotal.currencyText,
                firstFutureBudgetReservation.budgetMonth.monthTitle
            )
        } else {
            futureBudgetReservationFootnote = ""
        }

        var balanceFootnoteParts: [String] = []
        if spendAccounts.count > 1 {
            balanceFootnoteParts.append(String(format: AppStrings.text(.totalAllAccountsSummary), totalSpendAccountsBalance.currencyText))
        }
        if !futureBudgetReservationFootnote.isEmpty {
            balanceFootnoteParts.append(futureBudgetReservationFootnote)
        }

        let balanceHelpText: String
        if let firstFutureBudgetReservation, futureBudgetReservationTotal > 0 {
            balanceHelpText = String(
                format: AppStrings.text(.reservedBalanceHelpMessage),
                inAccount.currencyText,
                futureBudgetReservationTotal.currencyText,
                firstFutureBudgetReservation.budgetMonth.monthTitle,
                currentMonth.monthTitle
            )
        } else {
            balanceHelpText = AppStrings.text(.balanceThisMonthHelp)
        }

        let monthUnpaidExpenses = currentAccountMonthUnpaidExpenses(
            using: calculator,
            backgroundResult: backgroundResult
        )
        let currentSpendableBalance = totalAvailableBalance - futureBudgetReservationTotal
        let pendingCurrentMonthIncome = currentAccountPendingIncome(
            in: currentMonth,
            using: calculator
        )
        let monthRemainingCalculation = currentAccountMonthRemainingCalculation(
            backgroundResult: backgroundResult,
            currentSpendableBalance: currentSpendableBalance,
            pendingCurrentMonthIncome: pendingCurrentMonthIncome,
            monthUnpaidExpenses: monthUnpaidExpenses
        )
        let monthRemainingFootnote = currentAccountMonthRemainingFootnote(
            backgroundResult: backgroundResult,
            monthUnpaidExpenses: monthUnpaidExpenses
        )

        return CurrentAccountSummaryMetrics(
            inAccount: inAccount,
            accountBalances: accountBalances,
            monthUnpaidExpenses: monthUnpaidExpenses,
            isMonthUnpaidLoading: false,
            monthRemainingCalculation: monthRemainingCalculation,
            monthRemainingFootnote: monthRemainingFootnote,
            balanceHelpText: balanceHelpText,
            balanceFootnote: balanceFootnoteParts.joined(separator: "\n"),
            balanceHelpTitle: futureBudgetReservationTotal > 0 ? AppStrings.text(.reservedBalanceHelpTitle) : nil
        )
    }

    private func currentAccountMonthUnpaidExpenses(
        using calculator: MoneyCalculationService,
        backgroundResult: MoneyCalculationBackgroundResult
    ) -> Double {
        guard shouldApplyFiltersToSummaryCards else {
            return backgroundResult.monthSummaries[selectedMonth.monthStart]?.unpaidExpenses ?? 0
        }

        return filteredTransactions(in: selectedMonth)
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { total, transaction in
                total + filteredUnpaidAmount(for: transaction, in: selectedMonth)
            }
    }

    private func currentAccountMonthRemainingCalculation(
        backgroundResult: MoneyCalculationBackgroundResult,
        currentSpendableBalance: Double,
        pendingCurrentMonthIncome: Double,
        monthUnpaidExpenses: Double
    ) -> MonthRemainingCalculation? {
        guard isSelectedMonthInSpendableWindow else { return nil }

        let calendar = Calendar.current
        let selectedMonthStart = selectedMonth.monthStart
        let currentMonthStart = currentMonth.monthStart
        let currentMonthUnpaid = shouldApplyFiltersToSummaryCards && selectedMonthStart == currentMonthStart
            ? monthUnpaidExpenses
            : backgroundResult.monthSummaries[currentMonthStart]?.unpaidExpenses ?? 0
        var calculation = MonthRemainingCalculation(
            base: currentSpendableBalance,
            income: pendingCurrentMonthIncome,
            unpaidExpenses: currentMonthUnpaid
        )

        guard selectedMonthStart > currentMonthStart else {
            return calculation
        }

        var projectedMonth = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)?.monthStart
        while let month = projectedMonth, month <= selectedMonthStart {
            guard let summary = backgroundResult.monthSummaries[month] else { break }
            calculation = MonthRemainingCalculation(
                base: calculation.result,
                income: summary.income,
                unpaidExpenses: summary.unpaidExpenses
            )
            projectedMonth = calendar.date(byAdding: .month, value: 1, to: month)?.monthStart
        }

        return calculation
    }

    private func currentAccountPendingIncome(
        in month: Date,
        using calculator: MoneyCalculationService
    ) -> Double {
        let monthStart = month.monthStart
        let incomeTransactions = shouldApplyFiltersToSummaryCards
            ? filteredTransactions(in: monthStart)
            : calculator.visibleTransactions(in: monthStart)
        let receivedKeys = receivedIncomeKeys

        return incomeTransactions
            .filter {
                $0.kind == TransactionKind.income.rawValue
                    && $0.isBudgeted(in: monthStart, receivedMonth: monthStart)
            }
            .reduce(0) { total, transaction in
                let pendingAmount = transaction
                    .occurrenceDays(in: monthStart, exclusions: exclusions)
                    .filter { day in
                        !receivedKeys.contains(
                            IncomeReceiptKey(
                                transactionID: transaction.id,
                                date: monthStart.date(day: day)
                            )
                        )
                    }
                    .reduce(0) { subtotal, day in
                        subtotal + transaction.scheduledAmount(
                            in: monthStart,
                            occurrenceDay: transaction.recurrence == .weekly ? day : nil
                        )
                    }
                return total + pendingAmount
            }
    }

    private func currentAccountMonthRemainingFootnote(
        backgroundResult: MoneyCalculationBackgroundResult,
        monthUnpaidExpenses: Double
    ) -> String {
        guard Calendar.current.isDate(selectedMonth, equalTo: currentMonth, toGranularity: .month) else { return "" }

        let previousUnpaidExpenses = previousMonthsUnpaidExpensesTotal(
            backgroundResult: backgroundResult
        )
        guard previousUnpaidExpenses > 0.005 else { return "" }

        let totalUnpaidExpenses = previousUnpaidExpenses + monthUnpaidExpenses
        return String(
            format: AppStrings.text(.monthRemainingUnpaidBreakdown),
            previousUnpaidExpenses.currencyText,
            monthUnpaidExpenses.currencyText,
            totalUnpaidExpenses.currencyText
        )
    }

    private func previousMonthsUnpaidExpensesTotal(
        backgroundResult: MoneyCalculationBackgroundResult
    ) -> Double {
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min(),
              let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)?.monthStart,
              firstMonth <= previousMonth
        else { return 0 }

        return months(from: firstMonth, through: previousMonth)
            .reduce(0) { total, month in
                total + (backgroundResult.monthSummaries[month]?.unpaidExpenses ?? 0)
            }
    }
    private var selectedAnalyticsMonth: Date {
        Calendar.current.date(byAdding: .month, value: selectedAnalyticsMonthOffset, to: Date().monthStart) ?? Date().monthStart
    }
    private var analyticsMonths: [Date] {
        selectedAnalyticsPeriod == .month ? [selectedAnalyticsMonth] : currentYearMonths
    }
    private var analyticsCategoryExpenses: [CategoryExpensePoint] {
        calculator.categoryExpenses(in: analyticsMonths, paidOnly: false)
            .map { CategoryExpensePoint(category: $0.category, amount: sanitizedChartAmount($0.amount)) }
    }
    private var analyticsExpenseTotal: Double {
        analyticsCategoryExpenses.reduce(0) { $0 + $1.amount }
    }
    private var analyticsExpenseTypePoints: [ExpenseTypePoint] {
        expenseTypePoints(in: analyticsMonths)
            .map { ExpenseTypePoint(title: $0.title, category: $0.category, amount: sanitizedChartAmount($0.amount)) }
            .filter { $0.amount > 0 }
    }

    private func analyticsExpenseDetailLines(
        for request: AnalyticsExpenseDetailRequest
    ) -> [AnalyticsExpenseDetailLine] {
        request.months
            .flatMap { month in
                calculator.visibleTransactions(in: month)
                    .filter { transaction in
                        transaction.kind == TransactionKind.expense.rawValue
                            && transaction.displayName == request.title
                            && transaction.expenseCategory == request.category.rawValue
                    }
                    .flatMap { transaction in
                        transaction.occurrenceDays(in: month, exclusions: exclusions).map { day in
                            let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                            return AnalyticsExpenseDetailLine(
                                id: "\(transaction.id.uuidString)-\(month.notificationIdentifierDate)-\(day)",
                                name: analyticsTransactionTitle(for: transaction),
                                date: month.date(day: day),
                                amount: transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay),
                                icon: ExpenseTypeIcon.name(for: transaction.displayName),
                                tint: request.category.color
                            )
                        }
                    }
                }
            .filter { $0.amount > 0 }
            .sorted { first, second in
                if first.date != second.date { return first.date < second.date }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }
    private var budgetReferencePoints: [CategoryExpensePoint] {
        [
            CategoryExpensePoint(category: .needs, amount: 50),
            CategoryExpensePoint(category: .wants, amount: 30),
            CategoryExpensePoint(category: .savingsAndDebt, amount: 20)
        ]
    }
    private var configuredSubscriptions: [MoneyTransaction] {
        return transactions
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
    private var linkedSavingMovementIDs: Set<UUID> {
        Set(transactions.compactMap(\.linkedSavingMovementID))
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
                    subtitle: "\(AppStrings.text(.currentAccountSavingSource)) · \(transaction.dayDescription(in: month))",
                    amount: transaction.amount,
                    icon: "list.bullet.rectangle"
                )
            }

        let initialLines = savingAccounts
            .filter { Calendar.current.isDate($0.createdAt, equalTo: month, toGranularity: .month) && $0.initialAmount > 0 }
            .map { saving in
                SavingsHistoryLine(
                    title: saving.displayName,
                    subtitle: AppStrings.text(.initialSavingAmount),
                    amount: saving.initialAmount,
                    icon: "target"
                )
            }

        let directDepositLines = savingMovements
            .filter { movement in
                Calendar.current.isDate(movement.date, equalTo: month, toGranularity: .month)
                    && movement.kind == .deposit
                    && movement.linkedTransactionID == nil
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
    private var analyticsAnalysisTitle: String {
        switch selectedAnalyticsPeriod {
        case .month:
            "\(AppStrings.text(.monthAnalysis)) \(selectedAnalyticsMonth.monthTitle)"
        case .year:
            "\(AppStrings.text(.annualBalance)) \(currentYear)"
        }
    }
    private var navigationTitle: String {
        switch selectedTab {
        case .currentAccount:
            usesSidebarNavigation ? selectedCurrentAccountSidebarTab.title : AppStrings.text(.appName)
        case .credits:
            usesSidebarNavigation ? selectedAnalyticsSidebarTab.title : AppStrings.text(.credits)
        case .management:
            usesSidebarNavigation ? selectedManagementSidebarTab.title : AppStrings.text(.management)
        }
    }

    private func categoryExpenses(in month: Date) -> [CategoryExpensePoint] {
        calculator.categoryExpenses(in: month)
    }

    private func expenseTypePoints(in months: [Date]) -> [ExpenseTypePoint] {
        calculator.expenseTypePoints(in: months, fallbackTitle: AppStrings.text(.expense), paidOnly: false)
    }

    private func sanitizedChartAmount(_ amount: Double) -> Double {
        amount.isFinite ? max(amount, 0) : 0
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
        let receivedIncomeKeys = receivedIncomeKeys
        return calculator
            .visibleTransactions(in: month)
            .filter { transactionMatchesCurrentAccountFilters($0, in: month, receivedIncomeKeys: receivedIncomeKeys) }
    }

    private func transactionMatchesCurrentAccountFilters(
        _ transaction: MoneyTransaction,
        in month: Date,
        receivedIncomeKeys: Set<IncomeReceiptKey>
    ) -> Bool {
        if transaction.kind == TransactionKind.expense.rawValue,
           paymentFilter != .all,
           !transactionHasOccurrenceMatchingPaymentFilter(transaction, in: month) {
            return false
        }

        if transaction.kind == TransactionKind.income.rawValue,
           incomeFilter != .all,
           !transactionHasOccurrenceMatchingIncomeFilter(transaction, in: month, receivedIncomeKeys: receivedIncomeKeys) {
            return false
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

    private func transactionHasOccurrenceMatchingPaymentFilter(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        transaction.occurrenceDays(in: month, exclusions: exclusions).contains { day in
            let occurrenceDay = transaction.recurrence == .weekly ? day : nil
            let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
            let paidAmount = paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
            let isPaid = paidAmount >= scheduledAmount

            switch paymentFilter {
            case .all:
                return true
            case .paid:
                return isPaid
            case .unpaid:
                return !isPaid
            }
        }
    }

    private func transactionHasOccurrenceMatchingIncomeFilter(
        _ transaction: MoneyTransaction,
        in month: Date,
        receivedIncomeKeys: Set<IncomeReceiptKey>
    ) -> Bool {
        transaction.occurrenceDays(in: month, exclusions: exclusions).contains { day in
            let receivedDate = month.monthStart.date(day: transaction.recurrence == .weekly ? day : transaction.effectiveDay(in: month))
            let isReceived = receivedIncomeKeys.contains(IncomeReceiptKey(transactionID: transaction.id, date: receivedDate))

            switch incomeFilter {
            case .all:
                return true
            case .received:
                return isReceived
            case .pending:
                return !isReceived
            }
        }
    }

    private var receivedIncomeKeys: Set<IncomeReceiptKey> {
        Set(accountMovements.compactMap { movement in
            guard movement.kind == .income, let transactionID = movement.transactionID else { return nil }
            return IncomeReceiptKey(transactionID: transactionID, date: movement.date)
        })
    }

    private func incomeWasReceived(
        _ transaction: MoneyTransaction,
        in month: Date,
        occurrenceDay: Int?
    ) -> Bool {
        guard transaction.kind == TransactionKind.income.rawValue else { return false }
        let day = transaction.recurrence == .weekly
            ? (occurrenceDay ?? transaction.effectiveDay(in: month))
            : transaction.effectiveDay(in: month)
        return receivedIncomeKeys.contains(
            IncomeReceiptKey(transactionID: transaction.id, date: month.monthStart.date(day: day))
        )
    }

    private func clearCurrentAccountFilters() {
        paymentFilter = .all
        incomeFilter = .all
        filteredCategories = []
        filteredExpenseType = ""
        freeTextFilter = ""
    }

    var body: some View {
        let _ = selectedColorPalette

        Group {
            if usesSidebarNavigation {
                sidebarNavigation
            } else {
                phoneNavigation
            }
        }
        .sheet(item: $editorRequest) { request in
            TransactionEditor(request: request, onSaved: showSaveToast)
        }
        .sheet(item: $paymentEditorRequest) { request in
            let occurrenceDay = normalizedPaymentOccurrenceDay(for: request.transaction, occurrenceDay: request.occurrenceDay)
            PaymentAmountPicker(
                title: request.transaction.displayName,
                freeTextTitle: request.transaction.title,
                brandIconURL: request.transaction.customIconURL,
                brandDomain: request.transaction.customIconBrandDomain,
                totalAmount: request.transaction.scheduledAmount(in: request.month, occurrenceDay: occurrenceDay),
                initialAmount: request.initialAmount,
                paymentDate: request.month.date(day: request.occurrenceDay ?? request.transaction.effectiveDay(in: request.month)),
                futureFlexiblePaymentMonth: request.transaction.isWholeMonthExpense ? request.month.monthTitle : nil,
                history: paymentHistoryEntries(for: request.transaction, in: request.month, occurrenceDay: occurrenceDay),
                accounts: spendAccounts,
                accountMovements: accountMovements,
                transactionAccountID: request.transaction.accountID,
                isProcessing: $isProcessingPaymentChange,
                onConfirm: { amount, note, accountID in
                    performPaymentChange {
                        addPaymentAmount(request.transaction, in: request.month, occurrenceDay: occurrenceDay, amount: amount, note: note, accountID: accountID)
                    }
                },
                onConfirmAndCloseBudgetWithConsumedValue: { amount, note, accountID, consumedValue in
                    performPaymentChange {
                        closeBudgetWithConsumedValue(
                            request.transaction,
                            in: request.month,
                            occurrenceDay: occurrenceDay,
                            consumedValue: consumedValue,
                            additionalPaymentAmount: amount,
                            note: note,
                            accountID: accountID
                        )
                    }
                },
                onCloseBudgetWithConsumedValue: { consumedValue in
                    performPaymentChange {
                        closeBudgetWithConsumedValue(request.transaction, in: request.month, occurrenceDay: occurrenceDay, consumedValue: consumedValue)
                    }
                },
                onDeleteHistoryEntry: { entry in
                    deletePaymentHistoryEntry(entry, for: request.transaction, in: request.month, occurrenceDay: occurrenceDay)
                }
            )
        }
        .sheet(item: $currentAccountCreditMovementRequest) { request in
            CurrentAccountCreditMovementEditor(request: request)
        }
        .sheet(item: $calendarTransactionRequest) { request in
            calendarTransactionDetailSheet(for: request)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsEditor(openingTab: settingsInitialTab)
        }
        .sheet(isPresented: $showsFilters) {
            CurrentAccountFilterView(
                paymentFilter: $paymentFilter,
                incomeFilter: $incomeFilter,
                filteredCategories: $filteredCategories,
                filteredExpenseType: $filteredExpenseType,
                freeTextFilter: $freeTextFilter,
                filtersAffectSummaryCards: $filtersAffectSummaryCards,
                sortOrder: $sortOrder,
                expenseTypeOptions: selectedMonthExpenseTypeOptions,
                onClear: clearCurrentAccountFilters
            )
        }
        .sheet(isPresented: $showsUnpaidExpensesBreakdown) {
            UnpaidExpensesBreakdownSheet(
                month: selectedMonth,
                lines: unpaidExpenseLines,
                total: unpaidExpenseLinesTotal
            )
        }
        .sheet(item: $monthRemainingBreakdownRequest) { request in
            MonthRemainingBreakdownSheet(
                month: request.month,
                calculation: request.calculation
            )
        }
        .sheet(isPresented: $showsReceiptScanner) {
            receiptScannerSheet
        }
        .sheet(item: $savingsHistoryRequest) { request in
            SavingsHistorySheet(
                month: request.month,
                lines: savingsHistoryLines(in: request.month),
                total: savingsHistoryAmount(in: request.month)
            )
        }
        .sheet(item: $analyticsExpenseDetailRequest) { request in
            AnalyticsExpenseDetailSheet(
                request: request,
                lines: analyticsExpenseDetailLines(for: request)
            )
        }
        .alert(item: $expenseNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(AppStrings.text(.ok)))
            )
        }
        .sheet(item: $overdueExpenseNotice) { notice in
            OverdueExpenseNoticeSheet(
                title: notice.title,
                message: notice.message,
                onConfirm: { suppressForToday in
                    if suppressForToday {
                        overdueExpenseNoticeSuppressedAt = Date().timeIntervalSinceReferenceDate
                    }
                    overdueExpenseNotice = nil
                }
            )
        }
        .task {
            await handleStartupMaintenance()
        }
        .task {
            await monitorCalendarDayChanges()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, didFinishStartupMaintenance else { return }
            Task { @MainActor in
                await refreshDueAutomaticMovements()
            }
        }
        .task(id: notificationScheduleSignature) {
            await refreshExpensePaymentNotifications()
        }
        .onChange(of: paymentFilter) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: incomeFilter) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: filteredCategories) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: filteredExpenseType) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: freeTextFilter) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: sortOrder) { _, _ in persistCurrentAccountFilters() }
        .overlay(alignment: .top) {
            if let notice = saveNoticeCenter.notice {
                SaveResultToast(notice: notice, onDismiss: saveNoticeCenter.dismiss)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2000)
            }
        }
        .overlay {
            if isProcessingPaymentChange {
                ZStack {
                    Color.black.opacity(0.16)
                        .ignoresSafeArea()

                    ProgressView(AppStrings.currentLanguage == .portuguese ? "A atualizar pagamento…" : "Updating payment…")
                        .padding(.horizontal, 22)
                        .padding(.vertical, 18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 12)
                }
                .transition(.opacity)
                .zIndex(3000)
            }
        }
        .allowsHitTesting(!isProcessingPaymentChange)
        .id(selectedCurrencyCode)
    }

    private func performPaymentChange(_ change: @escaping @MainActor () -> Void) {
        guard !isProcessingPaymentChange else { return }
        isProcessingPaymentChange = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            change()
            await Task.yield()
            isProcessingPaymentChange = false
        }
    }

    private func showSaveToast(_ notice: SaveResultNotice) {
        saveNoticeCenter.show(notice)
        editorRequest = nil
    }

    private var receiptScannerSheet: some View {
        ReceiptScannerView(
            onComplete: handleReceiptScanResult,
            onCancel: { showsReceiptScanner = false },
            onFailure: handleReceiptScanFailure
        )
    }

    private var usesSidebarNavigation: Bool {
        UIDevice.current.userInterfaceIdiom != .phone
    }

    private var phoneTabSelection: Binding<PhoneTab> {
        Binding(
            get: { selectedPhoneTab },
            set: { newValue in
                selectedPhoneTab = newValue
                handlePhoneTabSelection(newValue)
            }
        )
    }

    private var phoneNavigation: some View {
        TabView(selection: phoneTabSelection) {
            phoneCurrentAccountNavigation
            .tabItem {
                Label(MainTab.currentAccount.title, systemImage: MainTab.currentAccount.systemImage)
            }
            .tag(PhoneTab.currentAccount)

            phoneCreditsNavigation
            .tabItem {
                Label(MainTab.credits.title, systemImage: MainTab.credits.systemImage)
            }
            .tag(PhoneTab.credits)

            phoneManagementNavigation
            .id(managementNavigationResetID)
            .tabItem {
                Label(MainTab.management.title, systemImage: MainTab.management.systemImage)
            }
            .tag(PhoneTab.management)

        }
        .tint(selectedPhoneTabTint)
        .minimizeTabBarOnScrollDownIfAvailable()
        .overlay {
            if selectedPhoneTab == .currentAccount {
                PhoneCurrentAccountActionsOverlay(
                    activeFilterCount: activeFilterCount,
                    scrollState: currentAccountScrollState,
                    showsSavingAction: hasActiveSavings,
                    showsCreditAction: hasActiveCredits,
                    activePlannings: activePlanningShortcuts,
                    onExpense: {
                        editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
                    },
                    onIncome: {
                        editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
                    },
                    onSaving: {
                        openPresetExpense(title: AppStrings.text(.newSavingExpense), expenseName: savingExpenseName)
                    },
                    onCredit: openCurrentAccountCreditMovement,
                    onReceipt: openReceiptScanner,
                    onFilters: {
                        showsFilters = true
                    },
                    onPlanning: { planning in
                        selectedPlanningShortcut = planning
                    }
                )
            }
        }
        .sheet(item: $selectedPlanningShortcut) { planning in
            NavigationStack {
                PlanningDetailView(planning: planning)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(AppStrings.text(.ok)) {
                                selectedPlanningShortcut = nil
                            }
                        }
                    }
            }
        }
    }

    private var showsPhoneAnalyticsBackButton: Bool {
        selectedAnalyticsSidebarTab == .savingsCredits || selectedAnalyticsSidebarTab == .history
    }

    private var selectedPhoneTabTint: Color {
        switch selectedPhoneTab {
        case .currentAccount, .filters:
            MainTab.currentAccount.bannerColor
        case .credits:
            MainTab.credits.bannerColor
        case .management:
            MainTab.management.bannerColor
        }
    }

    private func phoneNavigationTitle(for tab: MainTab) -> String {
        switch tab {
        case .currentAccount:
            AppStrings.text(.appName)
        case .credits:
            AppStrings.text(.credits)
        case .management:
            AppStrings.text(.management)
        }
    }

    private func handlePhoneTabSelection(_ tab: PhoneTab) {
        if let mainTab = tab.mainTab {
            if tab == .credits && selectedTab != .credits {
                selectedAnalyticsSidebarTab = .overview
            }
            if tab == .management && selectedTab != .management {
                managementNavigationResetID = UUID()
            }
            selectMainTab(mainTab)
        } else {
            guard selectedTab == .currentAccount else {
                selectedPhoneTab = phoneTab(for: selectedTab)
                return
            }

            selectedPhoneTab = .currentAccount
            selectMainTab(.currentAccount)
            showsFilters = true
        }
    }

    private func phoneTab(for tab: MainTab) -> PhoneTab {
        switch tab {
        case .currentAccount:
            .currentAccount
        case .credits:
            .credits
        case .management:
            .management
        }
    }

    private var phoneCurrentAccountNavigation: some View {
        PhoneTabNavigationRoot(
            title: phoneNavigationTitle(for: .currentAccount),
            content: {
                if selectedPhoneTab == .currentAccount || selectedPhoneTab == .filters {
                    currentAccountView
                } else {
                    PhoneActionPlaceholder()
                }
            },
            leading: {
                AppIconView()
            },
            trailing: {
                settingsToolbarButton
            }
        )
    }

    private var phoneCreditsNavigation: some View {
        PhoneTabNavigationRoot(
            title: phoneNavigationTitle(for: .credits),
            content: {
                Group {
                    if selectedPhoneTab == .credits {
                        creditsView
                    } else {
                        PhoneActionPlaceholder()
                    }
                }
                .analyticsDetailDestinations(
                    saving: $selectedAnalyticsSavingDetail,
                    credit: $selectedAnalyticsCreditDetail
                )
            },
            leading: {
                if showsPhoneAnalyticsBackButton {
                    analyticsBackButton
                } else {
                    AppIconView()
                }
            },
            trailing: {
                settingsToolbarButton
            }
        )
    }

    private var phoneManagementNavigation: some View {
        PhoneTabNavigationRoot(
            title: phoneNavigationTitle(for: .management),
            content: {
                Group {
                    if selectedPhoneTab == .management {
                        managementView
                    } else {
                        PhoneActionPlaceholder()
                    }
                }
                .navigationDestination(isPresented: $showsPhoneAccountsManagement) {
                    AccountsSettingsView()
                }
            },
            leading: {
                AppIconView()
            },
            trailing: {
                settingsToolbarButton
            }
        )
    }

    private var sidebarNavigation: some View {
        SidebarNavigationLayout(
            sidebar: {
                sidebarMenu
            },
            detail: {
                mainContent
            },
            bottomActions: {
                sidebarQuickActionsArea
            }
        )
    }

    private var mainContent: some View {
        SidebarMainContent(
            title: navigationTitle,
            selectedSaving: $selectedAnalyticsSavingDetail,
            selectedCredit: $selectedAnalyticsCreditDetail,
            content: {
                switch selectedTab {
                case .currentAccount:
                    currentAccountView
                case .credits:
                    creditsView
                case .management:
                    managementView
                }
            },
            trailing: {
                settingsToolbarButton
            }
        )
    }

    private var sidebarMenu: some View {
        List {
            Section {
                ForEach(CurrentAccountSidebarTab.allCases) { tab in
                    currentAccountSidebarMenuButton(for: tab)
                }
            } header: {
                currentAccountSidebarHeader
            }

            Section {
                sidebarSummaryTiles
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(AnalyticsSidebarTab.allCases) { tab in
                    analyticsSidebarMenuButton(for: tab)
                }
            } header: {
                SidebarSectionHeaderLabel(title: AppStrings.text(.analyticsMenuTitle), systemImage: MainTab.credits.systemImage)
            }

            Section {
                managementSidebarMenuButton(for: .accounts)
                managementSidebarMenuButton(for: .recurringExpenses)
                managementSidebarMenuButton(for: .recurringIncome)
            } header: {
                recurringSidebarHeader
            }

            Section {
                ForEach([ManagementSidebarTab.savings, ManagementSidebarTab.credits, ManagementSidebarTab.planning]) { tab in
                    managementSidebarMenuButton(for: tab)
                }
            } header: {
                SidebarSectionHeaderLabel(title: AppStrings.text(.management), systemImage: MainTab.management.systemImage)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.appName))
    }

    private func sidebarMenuButton(for tab: MainTab) -> some View {
        Button {
            selectMainTab(tab)
        } label: {
            Label(tab.title, systemImage: tab.systemImage)
                .font(.body.weight(selectedTab == tab ? .semibold : .regular))
                .foregroundStyle(selectedTab == tab ? AppPalette.primary : AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedTab == tab ? AppPalette.paleOrange.opacity(0.55) : Color.clear)
    }

    private var currentAccountSidebarHeader: some View {
        CurrentAccountSidebarHeader(
            systemImage: MainTab.currentAccount.systemImage,
            activeFilterCount: activeFilterCount,
            showsQuickActions: showsQuickActions,
            onFilters: {
                selectMainTab(.currentAccount)
                showsFilters = true
            },
            onAdd: {
                selectMainTab(.currentAccount)
                withAnimation(.snappy) {
                    showsRecurringQuickActions = false
                    showsQuickActions.toggle()
                }
            }
        )
    }

    private var recurringSidebarHeader: some View {
        RecurringSidebarHeader(
            showsQuickActions: showsRecurringQuickActions,
            onAdd: {
                selectedManagementSidebarTab = .recurringExpenses
                selectMainTab(.management)
                withAnimation(.snappy) {
                    showsQuickActions = false
                    showsRecurringQuickActions.toggle()
                }
            }
        )
    }

    private func currentAccountSidebarMenuButton(for tab: CurrentAccountSidebarTab) -> some View {
        SidebarSubmenuButton(
            title: tab.title,
            systemImage: tab.systemImage,
            isSelected: selectedTab == .currentAccount && selectedCurrentAccountSidebarTab == tab
        ) {
            selectedCurrentAccountSidebarTab = tab
            selectMainTab(.currentAccount)
        }
    }

    private func analyticsSidebarMenuButton(for tab: AnalyticsSidebarTab) -> some View {
        SidebarSubmenuButton(
            title: tab.title,
            systemImage: tab.systemImage,
            isSelected: selectedTab == .credits && selectedAnalyticsSidebarTab == tab
        ) {
            if tab == .savingsCredits {
                analyticsSavingsCreditsFilter = .all
            }
            selectedAnalyticsSidebarTab = tab
            selectMainTab(.credits)
        }
    }

    private func managementSidebarMenuButton(for tab: ManagementSidebarTab) -> some View {
        SidebarSubmenuButton(
            title: tab.title,
            systemImage: tab.systemImage,
            isSelected: selectedTab == .management && selectedManagementSidebarTab == tab
        ) {
            selectedManagementSidebarTab = tab
            selectMainTab(.management)
        }
    }

    private var sidebarSummaryTiles: some View {
        SidebarSummaryTiles(
            balance: inAccount,
            balanceHelpText: balanceHelpText,
            reservationFootnote: futureBudgetReservationFootnote,
            hasFutureReservation: futureBudgetReservationTotal > 0,
            shouldShowMonthUnpaid: shouldShowMonthUnpaidCard,
            monthUnpaid: monthUnpaidExpenses,
            monthRemaining: monthRemaining,
            onMonthUnpaidTap: {
                showsUnpaidExpensesBreakdown = true
            },
            onMonthRemainingTap: {
                presentMonthRemainingBreakdown(
                    currentAccountSummaryMetrics?.monthRemainingCalculation
                )
            }
        )
    }

    private var sidebarQuickActionsArea: some View {
        Group {
            if showsQuickActions && selectedTab == .currentAccount {
                quickActionsBar
                    .padding(.vertical, 8)
                    .background(AppPalette.appBackground)
            } else if showsRecurringQuickActions && selectedTab == .management {
                recurringQuickActionsBar
                    .padding(.vertical, 8)
                    .background(AppPalette.appBackground)
            }
        }
    }


    @ViewBuilder
    private var currentAccountView: some View {
        if usesSidebarNavigation && selectedCurrentAccountSidebarTab == .calendar {
            currentAccountCalendarView
        } else {
            currentAccountMonthlyListView
        }
    }

    private var currentAccountMonthlyListView: some View {
        let monthStart = selectedMonth.monthStart
        let monthPayments = payments.filter { $0.monthStart.monthStart == monthStart }
        let monthPaymentHistory = paymentHistory.filter { $0.monthStart.monthStart == monthStart }
        let monthExclusions = exclusions.filter { $0.monthStart.monthStart == monthStart }
        let monthIncomeKeys = Set(receivedIncomeKeys.filter {
            $0.receivedDay.monthStart == monthStart
        })

        return VStack(spacing: 0) {
            currentAccountHero

            if !usesSidebarNavigation {
                summaryBar
            }

            monthHeader

            MonthPage(
                month: selectedMonth,
                transactions: filteredTransactions(in: selectedMonth),
                payments: monthPayments,
                paymentHistory: monthPaymentHistory,
                exclusions: monthExclusions,
                receivedIncomeKeys: monthIncomeKeys,
                paymentFilter: paymentFilter,
                incomeFilter: incomeFilter,
                sortOrder: sortOrder,
                hasActiveFilters: activeFilterCount > 0,
                creditAccounts: creditAccounts,
                savingAccounts: savingAccounts,
                onPay: { transaction, month, occurrenceDay, initialAmount in
                    paymentEditorRequest = PaymentEditorRequest(transaction: transaction, month: month, occurrenceDay: occurrenceDay, initialAmount: initialAmount)
                },
                onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: selectedMonth, editScope: $0.isRecurring ? .singleMonth : .normal) },
                onDelete: { deleteTransaction($0, in: selectedMonth, occurrenceDay: $1) },
                onScrollDirectionChanged: { isScrollingDown in
                    guard currentAccountScrollState.isHidden != isScrollingDown else { return }
                    currentAccountScrollState.isHidden = isScrollingDown
                }
            )
            .id(selectedMonthOffset)
            .transition(monthPageTransition)
            .animation(.snappy, value: selectedMonthOffset)
        }
    }

    private var currentAccountCalendarView: some View {
        let transactionsByDay = CurrentAccountCalendarData.transactionsByDay(
            transactions: filteredTransactions(in: selectedMonth),
            month: selectedMonth,
            exclusions: exclusions
        )

        return VStack(spacing: 0) {
            currentAccountHero

            if !usesSidebarNavigation {
                summaryBar
            }

            monthHeader

            CurrentAccountCalendarGrid(
                month: selectedMonth,
                today: Date(),
                days: monthCalendarDays,
                weekdaySymbols: calendarWeekdaySymbols,
                transactionsByDay: transactionsByDay,
                creditAccounts: creditAccounts,
                savingAccounts: savingAccounts,
                dayRequest: $calendarDayRequest,
                transactionRequest: $calendarPopoverRequest,
                expandedTransactionID: $calendarDayExpandedTransactionID,
                paidAmount: { paidAmount(for: $0, in: $1, occurrenceDay: $2) },
                incomeWasReceived: { incomeWasReceived($0, in: $1, occurrenceDay: $2) },
                hasPaymentHistory: { hasPaymentHistory(for: $0, in: $1, occurrenceDay: $2) },
                isPaid: { isPaid($0, in: $1, occurrenceDay: $2) },
                onPay: { transaction, month, occurrenceDay, initialAmount in
                    paymentEditorRequest = PaymentEditorRequest(
                        transaction: transaction,
                        month: month,
                        occurrenceDay: occurrenceDay,
                        initialAmount: initialAmount
                    )
                },
                onEdit: { transaction, month, _ in
                    editorRequest = TransactionEditorRequest(
                        transaction: transaction,
                        month: month,
                        editScope: transaction.isRecurring ? .singleMonth : .normal
                    )
                },
                onDelete: { transaction, month, occurrenceDay in
                    deleteTransaction(transaction, in: month, occurrenceDay: occurrenceDay)
                }
            )
            .id(selectedMonthOffset)
            .transition(monthPageTransition)
            .animation(.snappy, value: selectedMonthOffset)
        }
    }

    private var calendarWeekdaySymbols: [String] {
        CurrentAccountCalendarData.weekdaySymbols(
            localeIdentifier: AppStrings.currentLocaleIdentifier,
            firstWeekday: Calendar.current.firstWeekday
        )
    }

    private var monthCalendarDays: [Int?] {
        CurrentAccountCalendarData.calendarDays(
            in: selectedMonth,
            firstWeekday: Calendar.current.firstWeekday
        )
    }

    private func calendarTransactionDetailSheet(for request: CalendarTransactionRequest) -> some View {
        CurrentAccountCalendarTransactionDetailSheet(
            title: CurrentAccountCalendarData.transactionTitle(request.transaction),
            transaction: request.transaction,
            month: request.month,
            occurrenceDay: request.occurrenceDay,
            amountPaid: paidAmount(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
            incomeWasReceived: incomeWasReceived(request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
            hasPaymentHistory: hasPaymentHistory(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            onClose: {
                calendarTransactionRequest = nil
            },
            onPay: {
                calendarTransactionRequest = nil
                paymentEditorRequest = PaymentEditorRequest(
                    transaction: request.transaction,
                    month: request.month,
                    occurrenceDay: request.occurrenceDay,
                    initialAmount: paidAmount(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay)
                )
            },
            onEdit: {
                calendarTransactionRequest = nil
                editorRequest = TransactionEditorRequest(
                    transaction: request.transaction,
                    month: request.month,
                    editScope: request.transaction.isRecurring ? .singleMonth : .normal
                )
            },
            onDelete: {
                calendarTransactionRequest = nil
                deleteTransaction(request.transaction, in: request.month, occurrenceDay: request.occurrenceDay)
            }
        )
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
        CurrentAccountMonthHeader(
            month: selectedMonth,
            showsCurrentDay: selectedMonthShowsCurrentDay,
            currentDayNumber: currentDayNumber,
            usesSidebarNavigation: usesSidebarNavigation,
            canMoveToPreviousMonth: selectedMonthOffset > (monthOffsets.first ?? 0),
            canMoveToNextMonth: selectedMonthOffset < (monthOffsets.last ?? 0),
            moveToPreviousMonth: { moveMonth(by: -1) },
            moveToNextMonth: { moveMonth(by: 1) }
        )
    }

    private func moveMonth(by value: Int) {
        monthNavigationDirection = value
        let nextOffset = selectedMonthOffset + value
        selectedMonthOffset = min(max(nextOffset, monthOffsets.first ?? 0), monthOffsets.last ?? 0)
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

    private var sidebarMonthFooterBar: some View {
        monthNavigationBar
    }

    private func areaHeroImage(
        _ name: String,
        aspectRatio: CGFloat,
        horizontalPadding: CGFloat? = nil
    ) -> some View {
        AreaHeroImage(
            name: name,
            aspectRatio: aspectRatio,
            horizontalPadding: horizontalPadding ?? 12,
            usesSidebarNavigation: usesSidebarNavigation
        )
    }

    private var currentAccountHero: some View {
        ZStack(alignment: .topTrailing) {
            areaHeroImage(
                localizedHeroAsset(portuguese: "CurrentAccountHero", english: "CurrentAccountHeroEnglish"),
                aspectRatio: currentAccountHeroAspectRatio
            )

            Button {
                let shouldShowCards = !(showsCurrentAccountBalanceCard || showsCurrentAccountPlanningCards)
                showsCurrentAccountBalanceCard = shouldShowCards
                showsCurrentAccountPlanningCards = shouldShowCards
            } label: {
                Image(systemName: showsCurrentAccountBalanceCard || showsCurrentAccountPlanningCards ? "eye" : "eye.slash")
                    .font(.system(size: usesSidebarNavigation ? 19 : 17, weight: .semibold))
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(
                showsCurrentAccountBalanceCard || showsCurrentAccountPlanningCards
                    ? (AppStrings.currentLanguage == .portuguese ? "Ocultar cartões da conta corrente" : "Hide current account cards")
                    : (AppStrings.currentLanguage == .portuguese ? "Mostrar cartões da conta corrente" : "Show current account cards")
            )
            .padding(.top, usesSidebarNavigation ? 20 : 16)
            .padding(.trailing, usesSidebarNavigation ? 28 : 24)
        }
    }

    private func localizedHeroAsset(portuguese: String, english: String) -> String {
        AppStrings.currentLanguage == .portuguese ? portuguese : english
    }

    private func localizedAreaHeroImage(
        imageName: String,
        title: String,
        subtitle: String,
        aspectRatio: CGFloat,
        horizontalPadding: CGFloat? = nil
    ) -> some View {
        let sidePadding = horizontalPadding ?? 12
        let effectiveAspectRatio = usesSidebarNavigation ? aspectRatio / 0.8 : aspectRatio
        let textMaxWidth: CGFloat = usesSidebarNavigation ? 500 : 235
        let textLeadingPadding: CGFloat = usesSidebarNavigation ? 54 : 28

        return ZStack(alignment: .leading) {
            Image(imageName)
                .resizable()
                .scaledToFill()

            VStack(alignment: .leading, spacing: usesSidebarNavigation ? 14 : 10) {
                Text(title)
                    .font(.system(size: usesSidebarNavigation ? 42 : 28, weight: .bold))
                    .foregroundStyle(AppPalette.surface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.system(size: usesSidebarNavigation ? 24 : 16, weight: .regular))
                    .foregroundStyle(AppPalette.surface)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: textMaxWidth, alignment: .leading)
            .padding(.leading, textLeadingPadding)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(effectiveAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppPalette.background.opacity(0.10), radius: 18, y: 8)
        .padding(.horizontal, sidePadding)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var currentAccountHeroAspectRatio: CGFloat {
        usesSidebarNavigation ? 1334.0 / 310.0 : 1334.0 / 250.0
    }

    @ViewBuilder
    private var creditsView: some View {
        if usesSidebarNavigation {
            sidebarCreditsView
        } else {
            phoneCreditsView
        }
    }

    private var sidebarCreditsView: some View {
        SidebarAnalyticsScreen(
            heroName: localizedHeroAsset(portuguese: "AnalyticsHero", english: "AnalyticsHeroEnglish")
        ) {
            selectedAnalyticsContent
        }
    }

    private var phoneCreditsView: some View {
        PhoneAnalyticsScreen(
            heroName: localizedHeroAsset(portuguese: "AnalyticsHero", english: "AnalyticsHeroEnglish"),
            selection: $selectedAnalyticsSidebarTab,
            tabs: phoneAnalyticsTabs,
            onAppear: normalizePhoneAnalyticsTabIfNeeded
        ) {
            selectedAnalyticsContent
        }
    }

    private var phoneAnalyticsTabs: [AnalyticsSidebarTab] {
        [.overview, .monthYear, .summaries]
    }

    private var phoneRenderableAnalyticsTabs: [AnalyticsSidebarTab] {
        phoneAnalyticsTabs + [.savingsCredits, .history]
    }

    private func normalizePhoneAnalyticsTabIfNeeded() {
        guard !usesSidebarNavigation,
              !phoneRenderableAnalyticsTabs.contains(selectedAnalyticsSidebarTab)
        else { return }

        selectedAnalyticsSidebarTab = .overview
    }

    private func openAnalyticsTab(
        _ tab: AnalyticsSidebarTab,
        savingsCreditsFilter: AnalyticsSavingsCreditsFilter = .all
    ) {
        if tab == .savingsCredits {
            analyticsSavingsCreditsFilter = savingsCreditsFilter
        }
        selectedAnalyticsSidebarTab = usesSidebarNavigation || phoneRenderableAnalyticsTabs.contains(tab) ? tab : .overview
        selectedPhoneTab = .credits
        selectMainTab(.credits)
    }

    @ViewBuilder
    private var selectedAnalyticsContent: some View {
        switch selectedAnalyticsSidebarTab {
        case .overview:
            analyticsOverviewContent
        case .monthYear:
            analyticsMonthYearCard
        case .summaries:
            analyticsSummariesContent
        case .savingsCredits:
            analyticsSavingsCreditsContent
        case .history:
            analyticsHistoryCard
        }
    }

    private var analyticsOverviewContent: some View {
        AnalyticsOverviewSection(
            netWorthTotal: analyticsNetWorthTotal,
            netWorthVariationRatio: analyticsNetWorthVariationRatio,
            trendHelpMessage: analyticsNetWorthTrendHelpMessage,
            currentAccountBalance: inAccount,
            savingsTotal: analyticsSavingsTotal,
            creditDebtTotal: analyticsCreditDebtTotal,
            usesWideLayout: usesSidebarNavigation,
            onCurrentAccount: {
                selectedPhoneTab = .currentAccount
                selectMainTab(.currentAccount)
            },
            onSavings: {
                openAnalyticsTab(.savingsCredits, savingsCreditsFilter: .savings)
            },
            onCredits: {
                openAnalyticsTab(.savingsCredits, savingsCreditsFilter: .credits)
            },
            onSavingsCredits: {
                openAnalyticsTab(.savingsCredits)
            },
            onHistory: {
                openAnalyticsTab(.history)
            }
        ) {
            analyticsQuickSummaryCardsGrid
        }
    }

    private var analyticsMonthYearCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            AnalyticsMonthYearExpenseCard(
                title: analyticsAnalysisTitle,
                total: analyticsExpenseTotal,
                period: $selectedAnalyticsPeriod,
                selectedMonthOffset: $selectedAnalyticsMonthOffset,
                selectedExpenseTab: $selectedAnalyticsExpenseTab,
                monthOffsets: monthOffsets,
                selectedMonth: selectedAnalyticsMonth
            ) {
                analyticsExpenseTabContent
            }

            lightweightEvolutionSection
        }
    }

    private var lightweightEvolutionUnavailableSection: some View {
        AnalyticsEvolutionUnavailableCard()
    }

    @ViewBuilder
    private var analyticsExpenseTabContent: some View {
        switch selectedAnalyticsExpenseTab {
        case .whereSpent:
            AnalyticsExpenseTypeBreakdown(
                points: analyticsExpenseTypePoints,
                total: analyticsExpenseTotal
            ) { point in
                analyticsExpenseDetailRequest = AnalyticsExpenseDetailRequest(
                    title: point.title,
                    category: point.category,
                    months: analyticsMonths,
                    amount: point.amount,
                    total: analyticsExpenseTotal
                )
            }
        case .budgetRule:
            AnalyticsBudgetRuleComparison(
                actualPoints: analyticsCategoryExpenses,
                referencePoints: budgetReferencePoints,
                actualTotal: analyticsExpenseTotal
            )
        }
    }

    private var lightweightEvolutionSection: some View {
        let points = sanitizedLightweightEvolutionPoints(
            lightweightEvolutionTable.points(for: selectedLightweightEvolutionKind)
        )
        let currentValue = currentLightweightEvolutionValue(
            for: selectedLightweightEvolutionKind
        )
        let maxValue = points.map(\.value).max() ?? 0
        let monthEndValue = points.last(where: {
            Calendar.current.isDate($0.month, equalTo: Date(), toGranularity: .month)
        })?.value ?? currentValue
        let savingsPoints = sanitizedLightweightEvolutionPoints(
            lightweightEvolutionTable.points(for: .savings)
        )
        let creditPoints = sanitizedLightweightEvolutionPoints(
            lightweightEvolutionTable.points(for: .credits)
        )

        return AnalyticsEvolutionSection(
            selectedKind: $selectedLightweightEvolutionKind,
            expandedMarkerID: $expandedLightweightEvolutionMarkerID,
            points: points,
            isLoading: isLightweightEvolutionLoading,
            currentValue: displayedLightweightEvolutionRoundedValue(
                currentValue,
                for: selectedLightweightEvolutionKind
            ),
            maximumValue: displayedLightweightEvolutionRoundedValue(
                maxValue,
                for: selectedLightweightEvolutionKind
            ),
            monthEndValue: displayedLightweightEvolutionRoundedValue(
                monthEndValue,
                for: selectedLightweightEvolutionKind
            ),
            savingsPoints: savingsPoints,
            savingsValue: displayedLightweightEvolutionValue(
                currentLightweightEvolutionValue(for: .savings),
                for: .savings
            ),
            creditPoints: creditPoints,
            creditValue: displayedLightweightEvolutionValue(
                currentLightweightEvolutionValue(for: .credits),
                for: .credits
            ),
            onLoad: scheduleLightweightEvolutionTableRefreshIfNeeded
        )
    }


    private var analyticsSavingsCreditsContent: some View {
        VStack(spacing: 16) {
            if analyticsSavingsCreditsFilter != .credits {
                if !activeRecurringPlans.isEmpty {
                    annualAllocationSimulationCard(for: .savings)
                }
                analyticsSavingsCard
            }

            if analyticsSavingsCreditsFilter != .savings {
                if !activeRecurringPlans.isEmpty {
                    annualAllocationSimulationCard(for: .credits)
                }
                analyticsCreditsCard
            }
        }
        .sheet(item: $annualAllocationDetailsKind) { kind in
            annualAllocationDetailsSheet(for: kind)
        }
    }

    private var analyticsBackButton: some View {
        TopToolbarIconButton(
            systemImage: "chevron.left",
            accessibilityLabel: "Voltar"
        ) {
            selectedAnalyticsSidebarTab = .overview
        }
    }

    @ViewBuilder
    private var managementView: some View {
        if usesSidebarNavigation {
            ManagementSidebarScreen(
                heroName: localizedHeroAsset(portuguese: "ManagementHero", english: "ManagementHeroEnglish")
            ) {
                selectedManagementSidebarContent
            }
        } else {
            managementCardsView
        }
    }

    @ViewBuilder
    private var selectedManagementSidebarContent: some View {
        switch selectedManagementSidebarTab {
        case .accounts:
            AccountsSettingsView()
        case .recurringExpenses:
            BudgetSettingsView(openingList: 0, showsListControls: false)
        case .recurringIncome:
            BudgetSettingsView(openingList: 1, showsListControls: false)
        case .savings:
            SavingsSettingsView()
                .navigationTitle(SavingsStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        case .credits:
            CreditsSettingsView()
                .navigationTitle(CreditStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        case .planning:
            planningManagementView
        }
    }

    private var managementCardsView: some View {
        ManagementOverviewScreen(
            heroName: localizedHeroAsset(portuguese: "ManagementHero", english: "ManagementHeroEnglish"),
            recurringMonthlyBalance: managementRecurringMonthlyBalance,
            accountCount: spendAccounts.count,
            accountsBalance: totalSpendAccountsBalance,
            totalSaved: managementTotalSaved,
            totalDebt: managementTotalDebt,
            activePlanningSummary: managementActivePlanningSummary,
            activePlanningCount: managementActivePlanningCount
        )
        .navigationDestination(for: ManagementSidebarTab.self) { tab in
            managementDestination(for: tab)
        }
    }

    @ViewBuilder
    private func managementDestination(for tab: ManagementSidebarTab) -> some View {
        switch tab {
        case .accounts:
            AccountsSettingsView()
        case .recurringExpenses:
            BudgetSettingsView()
        case .recurringIncome:
            BudgetSettingsView(openingList: 1, showsListControls: false)
        case .savings:
            SavingsSettingsView()
                .navigationTitle(SavingsStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        case .credits:
            CreditsSettingsView()
                .navigationTitle(CreditStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        case .planning:
            planningManagementView
        }
    }

    private var planningManagementView: some View {
        PlanningManagementView()
    }

    @ViewBuilder
    private var analyticsSummariesContent: some View {
        savingsPotentialCard
        AnalyticsAdviceCarousel(selectedIndex: $selectedAdviceIndex)
        analyticsListsCard
    }

    private var analyticsListsCard: some View {
        AnalyticsChartCard(
            title: AppStrings.text(.subscriptionsThisMonth),
            total: displayedConfiguredSubscriptions.reduce(0) { $0 + $1.amount }
        ) {
            subscriptionScopePicker
        } content: {
            AnalyticsSubscriptionList(transactions: displayedConfiguredSubscriptions)
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

    private var analyticsQuickSummaryCardsGrid: some View {
        AnalyticsQuickSummaryCards(
            savingSubtitle: largestSaving?.displayName ?? AppStrings.text(.noSavings),
            savingValue: largestSaving.map { $0.balance(with: savingMovements).currencyText } ?? Double.zero.currencyText,
            creditIcon: largestCredit?.creditType.iconName ?? "creditcard",
            creditSubtitle: largestCredit?.displayName ?? AppStrings.text(.noCredits),
            creditValue: largestCredit.map { (-$0.balance(with: creditMovements)).currencyText } ?? Double.zero.currencyText,
            savingsAction: {
                if let largestSaving {
                    selectedAnalyticsSavingDetail = largestSaving
                }
            },
            creditsAction: {
                if let largestCredit {
                    selectedAnalyticsCreditDetail = largestCredit
                }
            }
        )
        .frame(maxWidth: .infinity)
    }

    private var annualAllocationFraction: Double {
        Double(annualAllocationPercentage) / 100
    }

    private var annualRecurringAllocation: Double {
        monthlyRecurringSavingsDetails.reduce(0) { total, detail in
            guard !excludedAnnualAllocationMonths.contains(detail.month.monthNumber) else {
                return total
            }
            return total + max(detail.remaining, 0) * annualAllocationFraction
        }
    }

    private func annualPlannedCreditPayments(for creditID: UUID) -> Double {
        let linkedPlans = activeRecurringPlans.filter {
            $0.kind == TransactionKind.expense.rawValue
                && $0.linkedCreditID == creditID
        }

        return currentYearMonths.reduce(0) { total, month in
            guard !excludedAnnualAllocationMonths.contains(month.monthNumber) else {
                return total
            }

            let monthlyPayment = linkedPlans.reduce(0.0) {
                $0 + simulatedRecurringAmount(for: $1, in: month)
            }
            return total + monthlyPayment
        }
    }

    private func annualAllocationRows(
        for kind: AnnualAllocationSimulationKind
    ) -> [AnnualAllocationSimulationRow] {
        let allocation = annualRecurringAllocation

        switch kind {
        case .savings:
            return analyticsSavingAccounts.map { saving in
                let startingValue = saving.balance(with: savingMovements)
                return AnnualAllocationSimulationRow(
                    id: String(describing: saving.id),
                    name: saving.displayName,
                    startingValue: startingValue,
                    plannedRecurringPaymentValue: 0,
                    allocatedValue: allocation,
                    projectedValue: startingValue + allocation
                )
            }
        case .credits:
            return analyticsCreditAccounts.map { credit in
                let startingValue = credit.balance(with: creditMovements)
                let recurringPayments = annualPlannedCreditPayments(for: credit.id)
                let debtAfterRecurringPayments = max(startingValue - recurringPayments, 0)
                let appliedValue = min(debtAfterRecurringPayments, allocation)
                return AnnualAllocationSimulationRow(
                    id: String(describing: credit.id),
                    name: credit.displayName,
                    startingValue: startingValue,
                    plannedRecurringPaymentValue: min(startingValue, recurringPayments),
                    allocatedValue: appliedValue,
                    projectedValue: max(debtAfterRecurringPayments - allocation, 0)
                )
            }
        }
    }

    private func annualAllocationTotalRow(
        for kind: AnnualAllocationSimulationKind
    ) -> AnnualAllocationSimulationRow {
        let allocation = annualRecurringAllocation

        switch kind {
        case .savings:
            let startingValue = analyticsSavingsTotal
            return AnnualAllocationSimulationRow(
                id: "savings-total",
                name: AppStrings.text(.annualSimulationTotal),
                startingValue: startingValue,
                plannedRecurringPaymentValue: 0,
                allocatedValue: allocation,
                projectedValue: startingValue + allocation
            )
        case .credits:
            let startingValue = analyticsCreditDebtTotal
            let recurringPayments = analyticsCreditAccounts.reduce(0.0) { total, credit in
                let creditDebt = credit.balance(with: creditMovements)
                let plannedPayments = annualPlannedCreditPayments(for: credit.id)
                return total + min(creditDebt, plannedPayments)
            }
            let debtAfterRecurringPayments = max(startingValue - recurringPayments, 0)
            return AnnualAllocationSimulationRow(
                id: "credits-total",
                name: AppStrings.text(.annualSimulationTotal),
                startingValue: startingValue,
                plannedRecurringPaymentValue: recurringPayments,
                allocatedValue: min(debtAfterRecurringPayments, allocation),
                projectedValue: max(debtAfterRecurringPayments - allocation, 0)
            )
        }
    }

    private func annualAllocationSimulationCard(
        for kind: AnnualAllocationSimulationKind
    ) -> some View {
        let tint = kind == .savings ? AppPalette.savings : AppPalette.primary
        let rows = annualAllocationRows(for: kind)
        let totalRow = annualAllocationTotalRow(for: kind)
        let title = kind == .savings
            ? AppStrings.text(.annualSimulationSavingsTitle)
            : AppStrings.text(.annualSimulationCreditTitle)
        let subtitle = String(
            format: AppStrings.text(.annualSimulationSubtitle),
            annualAllocationPercentage
        )
        let presentedRows = rows.map { row in
            AnnualAllocationRowPresentation(
                row: row,
                payoffEstimate: kind == .credits
                    ? annualCreditPayoffEstimate(for: row)
                    : nil
            )
        }
        let presentedTotal = AnnualAllocationRowPresentation(
            row: totalRow,
            payoffEstimate: kind == .credits
                ? annualCreditPayoffEstimate(for: totalRow)
                : nil
        )

        return AnnualAllocationSimulationCard(
            allocationPercentage: $annualAllocationPercentage,
            showsMonths: $showsAnnualAllocationMonths,
            excludedMonths: $excludedAnnualAllocationMonths,
            kind: kind,
            tint: tint,
            title: title,
            subtitle: subtitle,
            months: currentYearMonths,
            recurringAllocation: annualRecurringAllocation,
            rows: presentedRows,
            total: presentedTotal
        ) {
            annualAllocationDetailsKind = kind
        }
    }

    private func annualCreditPayoffEstimate(
        for row: AnnualAllocationSimulationRow
    ) -> String {
        let debt = row.startingValue
        guard debt > 0 else {
            return AppStrings.text(.annualSimulationAlreadyPaid)
        }

        let annualPayment = row.plannedRecurringPaymentValue + annualRecurringAllocation
        guard annualPayment > 0 else {
            return AppStrings.text(.annualSimulationPayoffUnavailable)
        }

        let estimatedMonthsValue = ceil((debt / annualPayment) * 12)
        guard estimatedMonthsValue.isFinite,
              estimatedMonthsValue <= Double(Int.max) else {
            return AppStrings.text(.annualSimulationPayoffUnavailable)
        }

        let estimatedMonths = max(Int(estimatedMonthsValue), 1)
        let duration = annualCreditPayoffDuration(months: estimatedMonths)
        return String(
            format: AppStrings.text(.annualSimulationPayoffEstimate),
            duration
        )
    }

    private func annualCreditPayoffDuration(months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        var components: [String] = []

        if years > 0 {
            let yearUnit = years == 1
                ? AppStrings.text(.durationYearSingular)
                : AppStrings.text(.durationYearPlural)
            components.append("\(years) \(yearUnit)")
        }

        if remainingMonths > 0 {
            let monthUnit = remainingMonths == 1
                ? AppStrings.text(.durationMonthSingular)
                : AppStrings.text(.durationMonthPlural)
            components.append("\(remainingMonths) \(monthUnit)")
        }

        return components.joined(separator: " \(AppStrings.text(.durationAnd)) ")
    }

    private func annualAllocationDetailsSheet(
        for kind: AnnualAllocationSimulationKind
    ) -> some View {
        let tint = kind == .savings ? AppPalette.savings : AppPalette.primary
        let title = kind == .savings
            ? AppStrings.text(.annualSimulationSavingsTitle)
            : AppStrings.text(.annualSimulationCreditTitle)
        let months = monthlyRecurringSavingsDetails.map { detail in
            let isExcluded = excludedAnnualAllocationMonths.contains(detail.month.monthNumber)
            let positiveRemaining = max(detail.remaining, 0)

            return AnnualAllocationMonthPresentation(
                month: detail.month,
                isExcluded: isExcluded,
                income: detail.income,
                expenses: detail.expenses,
                remaining: positiveRemaining,
                allocationPercentage: annualAllocationPercentage,
                appliedValue: isExcluded ? 0 : positiveRemaining * annualAllocationFraction
            )
        }

        return AnnualAllocationDetailsView(
            kind: kind,
            title: title,
            tint: tint,
            months: months,
            annualAllocation: annualRecurringAllocation
        ) {
            annualAllocationDetailsKind = nil
        }
    }

    private var analyticsSavingsCard: some View {
        AnalyticsChartCard(title: SavingsStrings.text(.settingsTitle), total: analyticsSavingsTotal) {
            AnalyticsSavingsAccountList(
                accounts: analyticsSavingAccounts,
                movements: savingMovements,
                currentMonth: currentMonth
            )
        }
    }

    private var analyticsCreditsCard: some View {
        AnalyticsChartCard(title: CreditStrings.text(.settingsTitle), total: analyticsCreditDebtTotal) {
            AnalyticsCreditAccountList(
                accounts: analyticsCreditAccounts,
                movements: creditMovements,
                currentMonth: currentMonth
            )
        }
    }

    private var analyticsHistoryCard: some View {
        AnalyticsChartCard(
            title: AppStrings.text(.movementHistory),
            total: analyticsHistoryTotal
        ) {
            AnalyticsHistoryContent(
                filterMode: $selectedAnalyticsHistoryFilterMode,
                selectedMonthOffset: $selectedAnalyticsHistoryMonthOffset,
                startDate: $analyticsHistoryStartDate,
                endDate: $analyticsHistoryEndDate,
                monthOffsets: monthOffsets,
                selectedMonth: selectedAnalyticsHistoryMonth,
                lines: analyticsHistoryLines
            )
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
        totalSpendAccountsBalance + analyticsSavingsTotal - analyticsCreditDebtTotal
    }

    private var previousAnalyticsNetWorthTotal: Double? {
        let previousAccountBalance = spendAccounts.reduce(0) { total, account in
            let movements = accountMovements.filter { $0.accountID == account.id && $0.date < currentMonth }
            return total + account.balance(with: movements)
        }
        let previousSavingsTotal = analyticsSavingAccounts.reduce(0) { total, saving in
            let movements = savingMovements.filter { $0.savingID == saving.id && $0.date < currentMonth }
            return total + saving.balance(with: movements)
        }
        let previousCreditDebtTotal = analyticsCreditAccounts.reduce(0) { total, credit in
            let movements = creditMovements.filter { $0.creditID == credit.id && $0.date < currentMonth }
            return total + credit.balance(with: movements)
        }

        return previousAccountBalance + previousSavingsTotal - previousCreditDebtTotal
    }

    private var analyticsNetWorthVariationRatio: Double? {
        guard let previousTotal = previousAnalyticsNetWorthTotal, abs(previousTotal) > 0.01 else { return nil }
        return (analyticsNetWorthTotal - previousTotal) / abs(previousTotal)
    }

    private var analyticsNetWorthTrendHelpMessage: String {
        guard let previousTotal = previousAnalyticsNetWorthTotal,
              let ratio = analyticsNetWorthVariationRatio
        else {
            return "Ainda não existe valor do mês anterior suficiente para calcular a variação."
        }

        let difference = analyticsNetWorthTotal - previousTotal
        return "Património atual: \(analyticsNetWorthTotal.currencyText)\nPatrimónio do mês anterior: \(previousTotal.currencyText)\nDiferença: \(difference.currencyText)\nPercentagem: \(difference.currencyText) ÷ \(abs(previousTotal).currencyText) = \(percentageText(abs(ratio), total: 1))"
    }

    private var largestSaving: SavingAccount? {
        analyticsSavingAccounts.max { first, second in
            first.balance(with: savingMovements) < second.balance(with: savingMovements)
        }
    }

    private var largestCredit: CreditAccount? {
        analyticsCreditAccounts.max { first, second in
            first.balance(with: creditMovements) < second.balance(with: creditMovements)
        }
    }

    private var lightweightEvolutionSignature: String {
        let transactionSignature = transactions
            .map { transaction in
                [
                    transaction.id.uuidString,
                    transaction.title,
                    transaction.displayName,
                    transaction.kind,
                    "\(transaction.day)",
                    "\(transaction.amount)",
                    transaction.monthStart.ISO8601Format(),
                    transaction.recurrenceType ?? "",
                    "\(transaction.recurrenceMonth)",
                    transaction.recurrenceEndMonthStart?.ISO8601Format() ?? "",
                    transaction.budgetAllocationType ?? "",
                    transaction.budgetMonthStart?.ISO8601Format() ?? ""
                ].joined(separator: "|")
            }
            .sorted()
            .joined(separator: ";")
        let paymentSignature = payments
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())|\($0.occurrenceDay ?? -1)|\($0.amountPaid ?? -1)" }
            .sorted()
            .joined(separator: ";")
        let exclusionSignature = exclusions
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())|\($0.occurrenceDay ?? -1)" }
            .sorted()
            .joined(separator: ";")
        let savingSignature = savingAccounts
            .map { "\($0.id.uuidString)|\($0.name)|\($0.initialAmount)|\($0.createdAt.ISO8601Format())|\($0.status)" }
            .sorted()
            .joined(separator: ";")
        let savingMovementSignature = savingMovements
            .map { "\($0.id.uuidString)|\($0.savingID.uuidString)|\($0.date.ISO8601Format())|\($0.type)|\($0.amount)" }
            .sorted()
            .joined(separator: ";")
        let creditSignature = creditAccounts
            .map { "\($0.id.uuidString)|\($0.name)|\($0.initialDebt)|\($0.createdAt.ISO8601Format())|\($0.status)" }
            .sorted()
            .joined(separator: ";")
        let creditMovementSignature = creditMovements
            .map { "\($0.id.uuidString)|\($0.creditID.uuidString)|\($0.date.ISO8601Format())|\($0.type)|\($0.amount)" }
            .sorted()
            .joined(separator: ";")

        return [
            transactionSignature,
            paymentSignature,
            exclusionSignature,
            savingSignature,
            savingMovementSignature,
            creditSignature,
            creditMovementSignature
        ].joined(separator: "#")
    }

    private func refreshLightweightEvolutionTableIfNeeded() {
        let signature = lightweightEvolutionSignature
        guard lightweightEvolutionSignatureSnapshot != signature || lightweightEvolutionTable.balance.isEmpty else { return }

        lightweightEvolutionTable = buildLightweightEvolutionTable()
        lightweightEvolutionSignatureSnapshot = signature
    }

    private func scheduleLightweightEvolutionTableRefreshIfNeeded() {
        guard !isLightweightEvolutionLoading else { return }
        let signature = lightweightEvolutionSignature
        if lightweightEvolutionSignatureSnapshot != signature {
            lightweightEvolutionTable = .empty
            lightweightEvolutionSignatureSnapshot = signature
        }

        let kind = selectedLightweightEvolutionKind
        guard lightweightEvolutionTable.points(for: kind).isEmpty else { return }

        isLightweightEvolutionLoading = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            let points = await buildLightweightEvolutionPoints(for: kind)
            lightweightEvolutionTable = lightweightEvolutionTable.replacing(points, for: kind)
            isLightweightEvolutionLoading = false

            if lightweightEvolutionTable.points(for: selectedLightweightEvolutionKind).isEmpty {
                scheduleLightweightEvolutionTableRefreshIfNeeded()
            }
        }
    }

    private func buildLightweightEvolutionPoints(for kind: LightweightEvolutionKind) async -> [LightweightEvolutionPoint] {
        switch kind {
        case .balance:
            return await lightweightBalanceEvolutionPoints()
        case .savings, .credits:
            return await lightweightAssetEvolutionPoints(for: kind)
        }
    }

    private func buildLightweightEvolutionTable() -> LightweightEvolutionTable {
        LightweightEvolutionTable(
            balance: lightweightEvolutionTable.balance,
            savings: lightweightEvolutionPoints(for: .savings),
            credits: lightweightEvolutionPoints(for: .credits)
        )
    }

    private func currentLightweightEvolutionValue(for kind: LightweightEvolutionKind) -> Double {
        switch kind {
        case .balance:
            inAccount
        case .savings:
            analyticsSavingsTotal
        case .credits:
            analyticsCreditDebtTotal
        }
    }

    private func lightweightEvolutionPoints(for kind: LightweightEvolutionKind) -> [LightweightEvolutionPoint] {
        let today = Calendar.current.startOfDay(for: Date())

        return (-60...90).compactMap { offset in
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: today) else { return nil }
            let value: Double

            switch kind {
            case .balance:
                value = projectedAccountBalance(until: day)
            case .savings:
                value = savingsBalance(until: day)
            case .credits:
                value = creditDebt(until: day)
            }

            let marker = lightweightEvolutionPreparedMarker(on: day, kind: kind)
            return LightweightEvolutionPoint(
                month: day,
                value: value,
                markerTitle: marker?.title,
                markerIcon: marker?.icon,
                markerTint: marker?.tint
            )
        }
    }

    private func lightweightAssetEvolutionPoints(for kind: LightweightEvolutionKind) async -> [LightweightEvolutionPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var points = [LightweightEvolutionPoint]()
        points.reserveCapacity(151)

        for offset in -60...90 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let value = kind == .savings ? savingsBalance(until: day) : creditDebt(until: day)
            points.append(
                LightweightEvolutionPoint(
                    month: day,
                    value: value,
                    markerTitle: nil,
                    markerIcon: nil,
                    markerTint: nil
                )
            )

            if abs(offset).isMultiple(of: 10) {
                await Task.yield()
            }
        }

        return points
    }

    private func lightweightBalanceEvolutionPoints() async -> [LightweightEvolutionPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var valuesByDay = [Date: Double]()
        valuesByDay[today] = inAccount

        var futureBalance = inAccount
        for offset in 1...90 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            futureBalance += lightweightAccountBalanceEffect(on: day)
            valuesByDay[day] = futureBalance

            if offset.isMultiple(of: 10) {
                await Task.yield()
            }
        }

        var pastBalance = inAccount
        for offset in stride(from: -1, through: -60, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day)
            else { continue }

            pastBalance -= lightweightAccountBalanceEffect(on: nextDay)
            valuesByDay[day] = pastBalance

            if abs(offset).isMultiple(of: 10) {
                await Task.yield()
            }
        }

        return (-60...90).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let value = valuesByDay[day]
            else { return nil }

            let marker = lightweightEvolutionPreparedMarker(on: day, kind: .balance)
            return LightweightEvolutionPoint(
                month: day,
                value: value,
                markerTitle: marker?.title,
                markerIcon: marker?.icon,
                markerTint: marker?.tint
            )
        }
    }

    private func lightweightAccountBalanceEffect(on day: Date) -> Double {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: day)
        let month = targetDay.monthStart
        let dayNumber = calendar.component(.day, from: targetDay)
        let today = calendar.startOfDay(for: Date())
        var total = 0.0

        for transaction in calculator.visibleTransactions(in: month) {
            let occurrenceDays = transaction.occurrenceDays(in: month, exclusions: exclusions)
            guard occurrenceDays.contains(dayNumber) else { continue }

            let occurrenceDay = transaction.recurrence == .weekly ? dayNumber : nil
            if transaction.kind == TransactionKind.income.rawValue {
                let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                guard scheduledAmount.isFinite else { continue }
                total += scheduledAmount
            } else if targetDay <= today {
                let paidAmount = calculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
                guard paidAmount.isFinite else { continue }
                total -= paidAmount
            } else {
                let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                guard scheduledAmount.isFinite else { continue }
                total -= scheduledAmount
            }
        }

        return total
    }

    private func projectedAccountBalance(until date: Date) -> Double {
        let targetDate = Calendar.current.startOfDay(for: date)
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min() else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())

        return MoneyCalculationService.months(from: firstMonth, through: targetDate.monthStart).reduce(0) { total, month in
            let monthTotal = calculator.visibleTransactions(in: month).reduce(0) { monthResult, transaction in
                let occurrenceTotal = transaction.occurrenceDays(in: month, exclusions: exclusions).reduce(0) { dayResult, day in
                    let occurrenceDate = Calendar.current.startOfDay(for: month.date(day: day))
                    guard occurrenceDate <= targetDate else { return dayResult }

                    let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                    if transaction.kind == TransactionKind.income.rawValue {
                        let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                        guard scheduledAmount.isFinite else { return dayResult }
                        return dayResult + scheduledAmount
                    }

                    if occurrenceDate <= today {
                        let paidAmount = calculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
                        guard paidAmount.isFinite else { return dayResult }
                        return dayResult - paidAmount
                    }

                    let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                    guard scheduledAmount.isFinite else { return dayResult }
                    return dayResult - scheduledAmount
                }

                return monthResult + occurrenceTotal
            }

            return total + monthTotal
        }
    }

    private func savingsBalance(until date: Date) -> Double {
        let targetDate = Calendar.current.startOfDay(for: date)
        return analyticsSavingAccounts.reduce(0) { total, saving in
            let initialAmount = Calendar.current.startOfDay(for: saving.createdAt) <= targetDate ? saving.initialAmount : 0
            let movementAmount = savingMovements
                .filter { $0.savingID == saving.id && Calendar.current.startOfDay(for: $0.date) <= targetDate }
                .reduce(0) { $0 + $1.balanceEffect }
            return total + max(initialAmount + movementAmount, 0)
        }
    }

    private func creditDebt(until date: Date) -> Double {
        let targetDate = Calendar.current.startOfDay(for: date)
        return analyticsCreditAccounts.reduce(0) { total, credit in
            let initialDebt = Calendar.current.startOfDay(for: credit.createdAt) <= targetDate ? credit.initialDebt : 0
            let movementAmount = creditMovements
                .filter { $0.creditID == credit.id && Calendar.current.startOfDay(for: $0.date) <= targetDate }
                .reduce(0) { $0 + $1.balanceEffect }
            return total + max(initialDebt + movementAmount, 0)
        }
    }

    private func sanitizedLightweightEvolutionPoints(_ points: [LightweightEvolutionPoint]) -> [LightweightEvolutionPoint] {
        var seenDays = Set<Date>()
        let calendar = Calendar.current

        return points.compactMap { point in
            guard point.value.isFinite else { return nil }

            let normalizedDay = calendar.startOfDay(for: point.month)
            guard seenDays.insert(normalizedDay).inserted else { return nil }

            return LightweightEvolutionPoint(
                month: normalizedDay,
                value: point.value,
                markerTitle: point.markerTitle,
                markerIcon: point.markerIcon,
                markerTint: point.markerTint
            )
        }
    }

    private func lightweightEvolutionPreparedMarker(on day: Date, kind: LightweightEvolutionKind) -> (title: String, icon: String, tint: Color)? {
        guard kind == .balance else { return nil }

        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: day)
        let dayNumber = calendar.component(.day, from: targetDay)
        let today = calendar.startOfDay(for: Date())
        var selectedTitle = ""
        var selectedIcon = "banknote"
        var selectedTint = AppPalette.savings
        var selectedAmount = 0.0
        let minimumMarkerAmount = 100.0

        for transaction in calculator.visibleTransactions(in: targetDay.monthStart) {
            guard !transaction.isWholeMonthExpense else { continue }

            let occurrenceDays = transaction.occurrenceDays(in: targetDay.monthStart, exclusions: exclusions)
            guard occurrenceDays.contains(dayNumber) else { continue }

            let occurrenceDay = transaction.recurrence == .weekly ? dayNumber : nil
            let title = transaction.displayName.isEmpty ? transaction.title : transaction.displayName
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let amount: Double

            if transaction.kind == TransactionKind.expense.rawValue && targetDay <= today {
                amount = abs(calculator.paidAmount(for: transaction, in: targetDay.monthStart, occurrenceDay: occurrenceDay))
            } else {
                amount = abs(transaction.scheduledAmount(in: targetDay.monthStart, occurrenceDay: occurrenceDay))
            }

            guard !cleanTitle.isEmpty, amount >= minimumMarkerAmount, amount > selectedAmount else { continue }

            if transaction.kind == TransactionKind.income.rawValue {
                selectedTitle = cleanTitle
                selectedIcon = "banknote"
                selectedTint = AppPalette.savings
            } else {
                selectedTitle = cleanTitle
                selectedIcon = ExpenseTypeIcon.name(for: cleanTitle)
                selectedTint = AppPalette.primary
            }

            selectedAmount = amount
        }

        return selectedAmount > 0 ? (selectedTitle, selectedIcon, selectedTint) : nil
    }

    private func displayedLightweightEvolutionValue(_ value: Double, for kind: LightweightEvolutionKind) -> String {
        kind == .credits ? (-value).currencyText : value.currencyText
    }

    private func displayedLightweightEvolutionRoundedValue(_ value: Double, for kind: LightweightEvolutionKind) -> String {
        let displayedValue = kind == .credits ? -value : value
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        return formatter.string(from: NSNumber(value: displayedValue)) ?? displayedValue.currencyText
    }

    private var selectedAnalyticsHistoryMonth: Date {
        Calendar.current.date(byAdding: .month, value: selectedAnalyticsHistoryMonthOffset, to: Date().monthStart) ?? Date().monthStart
    }

    private var analyticsHistoryDateBounds: (start: Date, endExclusive: Date) {
        if selectedAnalyticsHistoryFilterMode == .month {
            return (selectedAnalyticsHistoryMonth.monthStart, selectedAnalyticsHistoryMonth.nextMonthStart)
        }

        let firstDate = min(analyticsHistoryStartDate, analyticsHistoryEndDate)
        let lastDate = max(analyticsHistoryStartDate, analyticsHistoryEndDate)
        let start = Calendar.current.startOfDay(for: firstDate)
        let endStart = Calendar.current.startOfDay(for: lastDate)
        let endExclusive = Calendar.current.date(byAdding: .day, value: 1, to: endStart) ?? endStart.addingTimeInterval(86_400)
        return (start, endExclusive)
    }

    private var analyticsHistoryLines: [AnalyticsHistoryLine] {
        let bounds = analyticsHistoryDateBounds
        let auditLines = auditLogEntries.compactMap { entry -> AnalyticsHistoryLine? in
            guard entry.date >= bounds.start, entry.date < bounds.endExclusive else { return nil }
            let action = entry.auditAction
            let balanceText = AppStrings.currentLanguage == .portuguese
                ? "Saldo total na altura: \(entry.balanceAfter.currencyText)"
                : "Total balance at the time: \(entry.balanceAfter.currencyText)"
            let note = [entry.details, entry.note, balanceText]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            return AnalyticsHistoryLine(
                id: "audit-\(entry.id.uuidString)",
                date: entry.date,
                name: entry.title,
                type: action.title,
                note: note,
                amount: entry.amount,
                amountText: entry.amount.currencyText,
                amountColor: entry.amount >= 0 ? AppPalette.positive : AppPalette.primary,
                icon: action.iconName,
                tint: action.tint
            )
        }

        if !auditLines.isEmpty {
            return auditLines.sorted { first, second in
                if first.date != second.date { return first.date > second.date }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
        }

        let transactionByID = transactions.reduce(into: [UUID: MoneyTransaction]()) { result, transaction in
            result[transaction.id] = transaction
        }
        let creditByID = creditAccounts.reduce(into: [UUID: CreditAccount]()) { result, credit in
            result[credit.id] = credit
        }
        let savingByID = savingAccounts.reduce(into: [UUID: SavingAccount]()) { result, saving in
            result[saving.id] = saving
        }
        let accountByID = spendAccounts.reduce(into: [UUID: SpendAccount]()) { result, account in
            result[account.id] = account
        }

        let paymentLines = paymentHistory.compactMap { entry -> AnalyticsHistoryLine? in
            guard entry.paidAt >= bounds.start, entry.paidAt < bounds.endExclusive else { return nil }
            guard let transaction = transactionByID[entry.transactionID] else { return nil }
            let title = analyticsTransactionTitle(for: transaction)
            let type = transaction.kind == TransactionKind.income.rawValue
                ? AppStrings.text(.income)
                : transaction.displayName
            let tint = transaction.kind == TransactionKind.income.rawValue
                ? AppPalette.savings
                : (ExpenseCategory(rawValue: transaction.expenseCategory ?? "")?.color ?? AppPalette.primary)
            let amount = transaction.kind == TransactionKind.income.rawValue ? abs(entry.amount) : -abs(entry.amount)

            return AnalyticsHistoryLine(
                id: "payment-\(entry.id.uuidString)",
                date: entry.paidAt,
                name: title,
                type: "\(AppStrings.text(.currentAccount)) · \(type)",
                note: transaction.detailText(in: entry.monthStart),
                amount: amount,
                amountText: amount.currencyText,
                amountColor: amount >= 0 ? AppPalette.savings : AppPalette.primary,
                icon: transaction.kind == TransactionKind.income.rawValue ? "tray.and.arrow.down.fill" : ExpenseTypeIcon.name(for: transaction.displayName),
                tint: tint
            )
        }

        let creditLines = creditMovements.compactMap { movement -> AnalyticsHistoryLine? in
            guard movement.date >= bounds.start, movement.date < bounds.endExclusive else { return nil }
            let creditName = creditByID[movement.creditID]?.displayName ?? CreditStrings.text(.credit)

            return AnalyticsHistoryLine(
                id: "credit-\(movement.id.uuidString)",
                date: movement.date,
                name: creditName,
                type: "\(CreditStrings.text(.settingsTitle)) · \(movement.kind.title)",
                note: movement.note,
                amount: movement.balanceEffect,
                amountText: movement.signedAmountText,
                amountColor: movement.balanceEffect <= 0 ? AppPalette.positive : AppPalette.primary,
                icon: movement.kind.iconName,
                tint: movement.kind.tint
            )
        }

        let savingLines = savingMovements.compactMap { movement -> AnalyticsHistoryLine? in
            guard movement.date >= bounds.start, movement.date < bounds.endExclusive else { return nil }
            let savingName = savingByID[movement.savingID]?.displayName ?? SavingsStrings.text(.saving)

            return AnalyticsHistoryLine(
                id: "saving-\(movement.id.uuidString)",
                date: movement.date,
                name: savingName,
                type: "\(SavingsStrings.text(.settingsTitle)) · \(movement.kind.title)",
                note: movement.note,
                amount: movement.balanceEffect,
                amountText: movement.signedAmountText,
                amountColor: movement.balanceEffect >= 0 ? AppPalette.positive : AppPalette.primary,
                icon: movement.kind.iconName,
                tint: movement.kind.tint
            )
        }

        let accountLines = accountMovements.compactMap { movement -> AnalyticsHistoryLine? in
            guard movement.date >= bounds.start, movement.date < bounds.endExclusive else { return nil }
            guard movement.kind != .expensePayment else { return nil }

            let accountName = accountByID[movement.accountID]?.displayName ?? AppStrings.text(.accounts)
            var typeParts = [AppStrings.text(.accounts), movement.kind.title]
            if let relatedAccountID = movement.relatedAccountID,
               let relatedAccountName = accountByID[relatedAccountID]?.displayName {
                typeParts.append(relatedAccountName)
            }

            return AnalyticsHistoryLine(
                id: "account-\(movement.id.uuidString)",
                date: movement.date,
                name: accountName,
                type: typeParts.joined(separator: " · "),
                note: movement.note,
                amount: movement.amount,
                amountText: movement.signedAmountText,
                amountColor: movement.amount >= 0 ? AppPalette.positive : AppPalette.primary,
                icon: movement.kind.iconName,
                tint: movement.kind.tint
            )
        }

        return (paymentLines + creditLines + savingLines + accountLines)
            .sorted { first, second in
                if first.date != second.date { return first.date > second.date }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    private var analyticsHistoryTotal: Double {
        analyticsHistoryLines.reduce(0) { $0 + abs($1.amount) }
    }

    private func monthlyAmountList(points: [MonthlyBalancePoint], value: @escaping (MonthlyBalancePoint) -> Double, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let visiblePoints = points.filter { value($0) > 0 }
            if visiblePoints.isEmpty {
                analyticsEmptyRow(systemImage: systemImage)
            } else {
                ForEach(visiblePoints) { point in
                    AnalyticsRow(
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

    private var activeRecurringPlans: [MoneyTransaction] {
        transactions.filter(\.isActiveForSettingsList)
    }

    private var monthlyRecurringSavingsDetails: [SavingsPotentialMonthDetail] {
        let plans = activeRecurringPlans

        return currentYearMonths.map { month in
            let recurringIncome = plans
                .filter { $0.kind == TransactionKind.income.rawValue }
                .reduce(0.0) { total, transaction in
                    let receivedMonth = transaction.budgetAllocation == .nextMonth
                        ? month.previousMonthStart
                        : month
                    return total + simulatedRecurringAmount(for: transaction, in: receivedMonth)
                }
            let recurringExpenses = plans
                .filter { $0.kind == TransactionKind.expense.rawValue }
                .reduce(0.0) {
                    $0 + simulatedRecurringAmount(for: $1, in: month)
                }
            return SavingsPotentialMonthDetail(
                month: month,
                recurringIncome: recurringIncome,
                recurringExpenses: recurringExpenses
            )
        }
    }

    private func simulatedRecurringAmount(
        for transaction: MoneyTransaction,
        in month: Date
    ) -> Double {
        guard let recurrence = transaction.recurrence else { return 0 }

        switch recurrence {
        case .weekly:
            return transaction.amount * Double(transaction.weeklyOccurrenceDays(in: month).count)
        case .monthly:
            return transaction.amount
        case .quarterly, .semiannual, .annual:
            let anchorMonth = transaction.recurrenceMonth > 0
                ? transaction.recurrenceMonth
                : transaction.monthStart.monthNumber
            let monthDistance = (month.monthNumber - anchorMonth + 12) % 12
            return monthDistance.isMultiple(of: recurrence.intervalInMonths)
                ? transaction.amount
                : 0
        case .yearlyMonth:
            return month.monthNumber == transaction.recurrenceMonth
                ? transaction.amount
                : 0
        }
    }

    private var monthlyRecurringAnnualAverage: Double {
        let details = monthlyRecurringSavingsDetails
        guard !details.isEmpty else { return 0 }
        return details.reduce(0.0) { $0 + $1.remaining } / Double(details.count)
    }

    private var savingsPotentialCard: some View {
        let average = monthlyRecurringAnnualAverage
        let annualPotential = max(average, 0) * 12

        return SavingsPotentialCard(
            hasRecurringData: !activeRecurringPlans.isEmpty,
            averageRemaining: average,
            annualPotential: annualPotential
        ) {
            showsSavingsPotentialDetails = true
        }
        .sheet(isPresented: $showsSavingsPotentialDetails) {
            savingsPotentialDetailsSheet
        }
    }

    private var savingsPotentialDetailsSheet: some View {
        let details = monthlyRecurringSavingsDetails
        let totalIncome = details.reduce(0.0) { $0 + $1.income }
        let totalExpenses = details.reduce(0.0) { $0 + $1.expenses }
        let totalRemaining = details.reduce(0.0) { $0 + $1.remaining }
        let average = details.isEmpty ? 0 : totalRemaining / Double(details.count)
        let annualPotential = max(average, 0) * 12

        return SavingsPotentialDetailsView(
            details: details,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            totalRemaining: totalRemaining,
            averageRemaining: average,
            annualPotential: annualPotential
        ) {
            showsSavingsPotentialDetails = false
        }
    }

    private func percentageText(_ amount: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }

    private var settingsToolbarButton: some View {
        TopToolbarIconButton(
            systemImage: "gearshape",
            accessibilityLabel: AppStrings.text(.settings)
        ) {
            settingsInitialTab = .budget
            showsSettings = true
        }
    }

    private var compactFilterButton: some View {
        TopToolbarIconButton(
            systemImage: "line.3.horizontal.decrease",
            badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil,
            accessibilityLabel: AppStrings.text(.filters)
        ) {
            showsFilters = true
        }
    }

    private var phoneBottomAddButton: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showsQuickActions {
                phoneVerticalQuickActions
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            PhoneBottomActionButton(
                systemImage: showsQuickActions ? "xmark" : "plus",
                accessibilityLabel: AppStrings.text(.add)
            ) {
                selectedPhoneTab = .currentAccount
                selectMainTab(.currentAccount)
                withAnimation(.snappy) {
                    showsQuickActions.toggle()
                }
            }

            PhoneBottomActionButton(
                systemImage: "line.3.horizontal.decrease",
                badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil,
                accessibilityLabel: AppStrings.text(.filters)
            ) {
                selectedPhoneTab = .currentAccount
                selectMainTab(.currentAccount)
                showsQuickActions = false
                showsFilters = true
            }
        }
    }

    private var phoneVerticalQuickActions: some View {
        VStack(alignment: .trailing, spacing: 10) {
            PhoneVerticalQuickActionButton(
                title: AppStrings.text(.expense),
                imageName: "QuickActionDespesa"
            ) {
                editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
                showsQuickActions = false
            }

            PhoneVerticalQuickActionButton(
                title: AppStrings.text(.income),
                imageName: "QuickActionReceita"
            ) {
                editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
                showsQuickActions = false
            }

            if hasActiveSavings {
                PhoneVerticalQuickActionButton(
                    title: SavingsStrings.text(.saving),
                    imageName: "QuickActionPoupanca"
                ) {
                    openPresetExpense(title: AppStrings.text(.newSavingExpense), expenseName: savingExpenseName)
                }
            }

            if hasActiveCredits {
                PhoneVerticalQuickActionButton(
                    title: CreditStrings.text(.credit),
                    imageName: "QuickActionCredito"
                ) {
                    openCurrentAccountCreditMovement()
                }
            }

            PhoneVerticalQuickActionButton(
                title: AppStrings.text(.readReceipt),
                imageName: "QuickActionLerFatura"
            ) {
                openReceiptScanner()
            }
        }
    }

    private var compactQuickActionsButton: some View {
        Button {
            withAnimation(.snappy) {
                showsQuickActions.toggle()
            }
        } label: {
            Image(systemName: showsQuickActions ? "xmark" : "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.background)
                .frame(width: 34, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppStrings.text(.add))
    }

    private func selectMainTab(_ tab: MainTab) {
        selectedTab = tab
        if tab != .currentAccount {
            showsQuickActions = false
        }
        if tab != .management {
            showsRecurringQuickActions = false
        }
    }

    private func presentMonthRemainingBreakdown(
        _ calculation: MonthRemainingCalculation?
    ) {
        guard let calculation else { return }
        monthRemainingBreakdownRequest = MonthRemainingBreakdownRequest(
            month: selectedMonth,
            calculation: calculation
        )
    }

    private func openAccountsManagement() {
        selectedManagementSidebarTab = .accounts
        selectedPhoneTab = .management
        selectMainTab(.management)
        if !usesSidebarNavigation {
            showsPhoneAccountsManagement = true
        }
    }

    private var summaryBar: some View {
        CurrentAccountLiveSummaryBar(
            month: selectedMonth,
            usesSidebarNavigation: usesSidebarNavigation,
            showsBalanceCard: showsCurrentAccountBalanceCard,
            showsPlanningCards: showsCurrentAccountPlanningCards,
            onOpenAccounts: openAccountsManagement,
            onOpenUnpaidExpenses: { showsUnpaidExpensesBreakdown = true },
            onOpenMonthRemaining: { calculation in
                presentMonthRemainingBreakdown(calculation)
            }
        )
    }

    private var quickActionsBar: some View {
        PhoneQuickActionsBar(
            hasSavings: hasActiveSavings,
            hasCredits: hasActiveCredits,
            onSaving: {
                openPresetExpense(
                    title: AppStrings.text(.newSavingExpense),
                    expenseName: savingExpenseName
                )
            },
            onCredit: openCurrentAccountCreditMovement,
            onIncome: {
                editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
                showsQuickActions = false
            },
            onExpense: {
                editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
                showsQuickActions = false
            },
            onReceipt: openReceiptScanner
        )
    }

    private var recurringQuickActionsBar: some View {
        RecurringQuickActionsBar(
            onExpense: {
                selectedManagementSidebarTab = .recurringExpenses
                editorRequest = TransactionEditorRequest(
                    mode: .monthlyExpense,
                    month: Date().monthStart
                )
                showsRecurringQuickActions = false
            },
            onIncome: {
                selectedManagementSidebarTab = .recurringIncome
                editorRequest = TransactionEditorRequest(
                    mode: .salary,
                    month: Date().monthStart
                )
                showsRecurringQuickActions = false
            }
        )
    }

    private var hasActiveSavings: Bool {
        savingAccounts.contains { $0.savingStatus == .active }
    }

    private var hasActiveCredits: Bool {
        creditAccounts.contains { $0.creditStatus == .active }
    }

    private var recurringSavingQuickActionButton: some View {
        PhoneVerticalQuickActionButton(
            title: SavingsStrings.text(.saving),
            imageName: "QuickActionPoupanca"
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newRecurringSavingExpense), expenseName: savingExpenseName)
        }
    }

    private var recurringCreditQuickActionButton: some View {
        PhoneVerticalQuickActionButton(
            title: CreditStrings.text(.credit),
            imageName: "QuickActionCredito"
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newRecurringCreditPaymentExpense), expenseName: creditPaymentExpenseName)
        }
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

    private func openCurrentAccountCreditMovement() {
        currentAccountCreditMovementRequest = CurrentAccountCreditMovementRequest(month: selectedMonth)
        showsQuickActions = false
    }

    private func openReceiptScanner() {
        selectMainTab(.currentAccount)
        showsQuickActions = false
        showsReceiptScanner = true
    }

    private func handleReceiptScanResult(_ result: ReceiptScanResult) {
        showsReceiptScanner = false
        let transactionDate = result.date ?? Date()
        let transactionMonth = transactionDate.monthStart
        editorRequest = TransactionEditorRequest(
            mode: .expense,
            month: transactionMonth,
            titleOverride: "Despesa por fatura",
            initialExpenseCategory: result.category,
            initialExpenseName: result.expenseName,
            initialTitle: result.title,
            initialAmount: result.amount,
            initialDate: transactionDate,
            startsMarkedAsPaid: true
        )

        if result.amount == nil {
            expenseNotice = ExpenseNotice(
                title: AppStrings.text(.receiptReadTitle),
                message: AppStrings.text(.receiptReadMissingTotalMessage)
            )
        }
    }

    private func handleReceiptScanFailure(_ message: String) {
        showsReceiptScanner = false
        expenseNotice = ExpenseNotice(
            title: AppStrings.text(.receiptReadFailureTitle),
            message: message
        )
    }

    private func openPresetRecurringExpense(title: String, expenseName: String) {
        selectedManagementSidebarTab = .recurringExpenses
        editorRequest = TransactionEditorRequest(
            mode: .monthlyExpense,
            month: Date().monthStart,
            titleOverride: title,
            initialExpenseCategory: .savingsAndDebt,
            initialExpenseName: expenseName
        )
        showsRecurringQuickActions = false
    }

    @MainActor
    private func waitUntilOverdueNoticeIsDismissed() async {
        while (!didFinishStartupMaintenance || overdueExpenseNotice != nil), !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(150))
        }
    }

    @MainActor
    private func handleStartupMaintenance() async {
        guard !didRunStartupMaintenance else { return }
        didRunStartupMaintenance = true

        await Task.yield()
        try? await Task.sleep(nanoseconds: 350_000_000)
        handleAppear()
        didFinishStartupMaintenance = true
    }

    @MainActor
    private func refreshDueAutomaticMovements() async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(150))
        await waitUntilOverdueNoticeIsDismissed()
        try? await Task.sleep(for: .milliseconds(1_200))
        guard !Task.isCancelled else { return }
        syncDueRecurringIncomeAccountMovements()
        autoMarkDueRecurringExpensesAsPaid()
    }

    @MainActor
    private func monitorCalendarDayChanges() async {
        for await _ in NotificationCenter.default.notifications(named: .NSCalendarDayChanged) {
            guard !Task.isCancelled else { return }
            await refreshDueAutomaticMovements()
        }
    }

    private func handleAppear() {
        migrateSpendAccountsIfNeeded()
        loadStoredCurrentAccountFilters()
        syncDueRecurringIncomeAccountMovements()
        autoMarkDueRecurringExpensesAsPaid()
        repairLinkedSavingDepositsFromPayments()
        checkOverdueExpenses()
    }

    private func migrateSpendAccountsIfNeeded() {
        var didChangeAccounts = false

        if spendAccounts.isEmpty {
            let primaryAccount = SpendAccount(
                name: AppStrings.text(.currentAccount),
                iconName: "wallet.pass.fill",
                colorName: SpendAccountColor.blue.rawValue,
                initialBalance: accountSummary.availableBalance,
                isPrimary: true
            )
            modelContext.insert(primaryAccount)
            transactions.forEach { $0.accountID = primaryAccount.id }
            paymentHistory.forEach { $0.accountID = primaryAccount.id }
            try? modelContext.save()
            return
        }

        let primaryAccounts = spendAccounts.filter(\.isPrimary)
        if primaryAccounts.isEmpty, let firstAccount = spendAccounts.first {
            firstAccount.isPrimary = true
            didChangeAccounts = true
        } else if let firstPrimary = primaryAccounts.first {
            spendAccounts
                .filter { $0.id != firstPrimary.id && $0.isPrimary }
                .forEach {
                    $0.isPrimary = false
                    didChangeAccounts = true
                }
        }

        guard let primaryAccount = spendAccounts.first(where: \.isPrimary) ?? spendAccounts.first else { return }
        let accountIDs = Set(spendAccounts.map(\.id))
        transactions
            .filter { $0.accountID.map { !accountIDs.contains($0) } ?? true }
            .forEach {
                $0.accountID = primaryAccount.id
                didChangeAccounts = true
            }
        paymentHistory
            .filter { $0.accountID.map { !accountIDs.contains($0) } ?? true }
            .forEach {
                $0.accountID = primaryAccount.id
                didChangeAccounts = true
            }

        if didChangeAccounts {
            try? modelContext.save()
        }
    }

    private func syncDueRecurringIncomeAccountMovements(now: Date = Date()) {
        let calculator = MoneyCalculationService(
            transactions: Array(transactions),
            payments: Array(payments),
            exclusions: Array(exclusions)
        )
        let accountsByID = Dictionary(uniqueKeysWithValues: spendAccounts.map { ($0.id, $0) })
        let calendar = Calendar.current
        var existingOccurrenceKeys = Set(
            accountMovements
                .filter { $0.kind == .income && $0.transactionID != nil }
                .compactMap { movement -> String? in
                    guard let transactionID = movement.transactionID else { return nil }
                    return "\(transactionID.uuidString)|\(calendar.startOfDay(for: movement.date).timeIntervalSinceReferenceDate)"
                }
        )
        var didCreateMovement = false

        spendAccounts.forEach { account in
            calculator
                .recurringIncomeOccurrencesDue(
                    onOrAfter: calendar.startOfDay(for: account.createdAt),
                    through: now
                )
                .filter { $0.transaction.accountID == account.id }
                .forEach { occurrence in
                    guard accountsByID[account.id] != nil else { return }
                    let occurrenceKey = "\(occurrence.transaction.id.uuidString)|\(calendar.startOfDay(for: occurrence.receivedDate).timeIntervalSinceReferenceDate)"
                    guard !existingOccurrenceKeys.contains(occurrenceKey) else { return }

                    modelContext.insert(AccountMovement(
                        accountID: account.id,
                        transactionID: occurrence.transaction.id,
                        date: occurrence.receivedDate,
                        type: AccountMovementKind.income.rawValue,
                        amount: occurrence.amount,
                        note: occurrence.transaction.displayName
                    ))
                    existingOccurrenceKeys.insert(occurrenceKey)
                    didCreateMovement = true
                }
        }

        transactions
            .filter {
                $0.kind == TransactionKind.income.rawValue
                    && !$0.isRecurring
                    && $0.autoMarkPaidOnDay
            }
            .forEach { transaction in
                guard let accountID = transaction.accountID,
                      let account = accountsByID[accountID]
                else { return }

                let receivedDate = transaction.receivedDate(in: transaction.monthStart)
                guard receivedDate > account.createdAt, receivedDate <= now else { return }

                let occurrenceKey = "\(transaction.id.uuidString)|\(calendar.startOfDay(for: receivedDate).timeIntervalSinceReferenceDate)"
                guard !existingOccurrenceKeys.contains(occurrenceKey) else {
                    transaction.autoMarkPaidOnDay = false
                    return
                }

                modelContext.insert(AccountMovement(
                    accountID: accountID,
                    transactionID: transaction.id,
                    date: receivedDate,
                    type: AccountMovementKind.income.rawValue,
                    amount: transaction.amount,
                    note: transaction.displayName
                ))
                transaction.autoMarkPaidOnDay = false
                existingOccurrenceKeys.insert(occurrenceKey)
                didCreateMovement = true
            }

        if didCreateMovement {
            try? modelContext.save()
        }
    }

    private func autoMarkDueRecurringExpensesAsPaid(now: Date = Date()) {
        let transactionSnapshot = Array(transactions)
        let paymentSnapshot = Array(payments)
        let exclusionSnapshot = Array(exclusions)
        let snapshotCalculator = MoneyCalculationService(
            transactions: transactionSnapshot,
            payments: paymentSnapshot,
            exclusions: exclusionSnapshot
        )
        guard let firstMonth = transactionSnapshot.map(\.monthStart.monthStart).min() else { return }
        let currentMonth = now.monthStart
        let todayDay = Calendar.current.component(.day, from: now)
        var paymentsToCreate: [(transaction: MoneyTransaction, month: Date, occurrenceDay: Int?, amount: Double, paidAt: Date)] = []

        months(from: firstMonth, through: currentMonth).forEach { month in
            let maxDay = Calendar.current.isDate(month, equalTo: currentMonth, toGranularity: .month)
                ? todayDay
                : month.daysInMonth

            transactionSnapshot
                .visible(in: month, payments: paymentSnapshot, exclusions: exclusionSnapshot)
                .filter { transaction in
                    transaction.kind == TransactionKind.expense.rawValue
                        && transaction.isRecurring
                        && transaction.autoMarkPaidOnDay
                        && !transaction.isWholeMonthExpense
                }
                .forEach { transaction in
                    if transaction.recurrence == .weekly {
                        transaction
                            .occurrenceDays(in: month, exclusions: exclusionSnapshot)
                            .filter { occurrenceDay in
                                occurrenceDay <= maxDay
                                    && snapshotCalculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay) < transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                            }
                            .forEach { occurrenceDay in
                                let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                                let remainingAmount = max(scheduledAmount - snapshotCalculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay), 0)
                                guard remainingAmount > 0 else { return }
                                paymentsToCreate.append((
                                    transaction: transaction,
                                    month: month,
                                    occurrenceDay: occurrenceDay,
                                    amount: remainingAmount,
                                    paidAt: month.date(day: occurrenceDay)
                                ))
                            }
                    } else {
                        let dueDay = transaction.effectiveDay(in: month)
                        guard dueDay <= maxDay && !snapshotCalculator.isPaid(transaction, in: month) else { return }
                        let scheduledAmount = transaction.scheduledAmount(in: month)
                        let remainingAmount = max(scheduledAmount - snapshotCalculator.paidAmount(for: transaction, in: month), 0)
                        guard remainingAmount > 0 else { return }
                        paymentsToCreate.append((
                            transaction: transaction,
                            month: month,
                            occurrenceDay: nil,
                            amount: remainingAmount,
                            paidAt: month.date(day: dueDay)
                        ))
                    }
                }
            }

        paymentsToCreate.forEach { payment in
            addPaymentAmount(
                payment.transaction,
                in: payment.month,
                occurrenceDay: payment.occurrenceDay,
                amount: payment.amount,
                paidAt: payment.paidAt
            )
        }
    }

    private func repairLinkedSavingDepositsFromPayments() {
        let linkedSavingTransactionIDs = Set(
            transactions
                .filter { $0.kind == TransactionKind.expense.rawValue && $0.linkedSavingID != nil }
                .map(\.id)
        )
        guard !linkedSavingTransactionIDs.isEmpty else { return }

        payments
            .filter { linkedSavingTransactionIDs.contains($0.transactionID) }
            .forEach { payment in
                guard let transaction = transactions.first(where: { $0.id == payment.transactionID }),
                      transaction.linkedSavingID != nil
                else { return }

                let occurrenceDay = transaction.recurrence == .weekly ? payment.occurrenceDay : nil
                let scheduledAmount = transaction.scheduledAmount(in: payment.monthStart, occurrenceDay: occurrenceDay)
                let paidAmount = payment.amountPaid ?? scheduledAmount
                guard paidAmount > 0 else { return }

                syncLinkedSavingDeposit(
                    for: transaction,
                    in: payment.monthStart,
                    occurrenceDay: occurrenceDay,
                    paidAmount: paidAmount
                )
            }
    }

    private func loadStoredCurrentAccountFilters() {
        guard !didLoadStoredFilters else { return }
        didLoadStoredFilters = true

        paymentFilter = CurrentAccountPaymentFilter(rawValue: storedPaymentFilter) ?? .all
        incomeFilter = CurrentAccountIncomeFilter(rawValue: storedIncomeFilter) ?? .all
        filteredCategories = Set(storedFilteredCategories
            .split(separator: ",")
            .compactMap { ExpenseCategory(rawValue: String($0)) })
        filteredExpenseType = storedFilteredExpenseType
        freeTextFilter = storedFreeTextFilter
        sortOrder = CurrentAccountSortOrder(rawValue: storedSortOrder) ?? .currentPaymentStatusOrder
    }

    private func persistCurrentAccountFilters() {
        storedPaymentFilter = paymentFilter.rawValue
        storedIncomeFilter = incomeFilter.rawValue
        storedFilteredCategories = filteredCategories
            .map(\.rawValue)
            .sorted()
            .joined(separator: ",")
        storedFilteredExpenseType = filteredExpenseType
        storedFreeTextFilter = freeTextFilter
        storedSortOrder = sortOrder.rawValue
    }

    private func refreshExpensePaymentNotifications() async {
        await waitUntilOverdueNoticeIsDismissed()
        try? await Task.sleep(for: .milliseconds(2_000))
        guard !Task.isCancelled else { return }

        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let existingReminderIDs = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix("spendwise-expense-due-") }
        center.removePendingNotificationRequests(withIdentifiers: existingReminderIDs)

        guard notificationsEnabled else { return }

        let reminders = upcomingExpensePaymentReminders()
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
                    .flatMap { reminders(for: $0, in: month, now: now) }
            }
            .filter { $0.fireDate > now }
            .sorted { $0.fireDate < $1.fireDate }
    }

    private func reminders(for transaction: MoneyTransaction, in month: Date, now: Date) -> [ExpensePaymentReminder] {
        guard !transaction.isWholeMonthExpense else { return [] }

        let calendar = Calendar.current
        let freeText = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let type = transaction.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryText = freeText.isEmpty ? type : freeText
        let dueDays = transaction.recurrence == .weekly
            ? transaction.occurrenceDays(in: month, exclusions: exclusions)
            : [transaction.effectiveDay(in: month)]

        return dueDays.compactMap { dueDay in
            if transaction.recurrence == .weekly,
               paidAmount(for: transaction, in: month, occurrenceDay: dueDay)
                    >= transaction.scheduledAmount(in: month, occurrenceDay: dueDay) {
                return nil
            }

            guard let dueDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: month.date(day: dueDay)),
                  let reminderDay = calendar.date(byAdding: .day, value: -1, to: dueDate) else {
                return nil
            }

            var fireDate = reminderDay
            if fireDate <= now, calendar.isDate(fireDate, inSameDayAs: now), dueDate > now {
                fireDate = now.addingTimeInterval(60)
            }
            guard fireDate > now else { return nil }

            let body: String
            if freeText.isEmpty || type.isEmpty || freeText == type {
                body = String(format: AppStrings.text(.expenseDueTomorrowBody), primaryText, dueDay)
            } else {
                body = String(format: AppStrings.text(.expenseDueTomorrowBodyWithType), primaryText, dueDay, type)
            }

            return ExpensePaymentReminder(
                identifier: "spendwise-expense-due-\(transaction.id.uuidString)-\(month.notificationIdentifierDate)-\(dueDay)",
                title: AppStrings.text(.expenseDueTomorrowTitle),
                body: body,
                fireDate: fireDate
            )
        }
    }

    private func checkOverdueExpenses() {
        guard launchPaymentReminderEnabled else { return }
        guard !didCheckOverdueExpenses else { return }
        didCheckOverdueExpenses = true

        let suppressedDate = Date(timeIntervalSinceReferenceDate: overdueExpenseNoticeSuppressedAt)
        guard overdueExpenseNoticeSuppressedAt == 0 || !Calendar.current.isDateInToday(suppressedDate) else {
            return
        }

        let todayDay = Calendar.current.component(.day, from: Date())
        let currentOverdueExpenses = unpaidExpenses(in: currentMonth, fromDay: 1, throughDay: todayDay - 1)
        let todayUnpaidExpenses = unpaidExpenses(in: currentMonth, fromDay: todayDay, throughDay: todayDay)
        var sections: [String] = []

        let previousMonthsWithUnpaidExpenses = previousMonthsWithUnpaidExpenses()
        if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)?.monthStart,
           let previousMonthExpenses = previousMonthsWithUnpaidExpenses.first(where: {
               Calendar.current.isDate($0.month, equalTo: previousMonth, toGranularity: .month)
           })?.expenses,
           !previousMonthExpenses.isEmpty {
            sections.append(expenseNoticeSection(
                prefix: AppStrings.text(.previousMonthUnpaidExpensesMessagePrefix),
                expenses: previousMonthExpenses
            ))
        }

        previousMonthsWithUnpaidExpenses
            .filter { month, _ in
                guard let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)?.monthStart else {
                    return true
                }
                return !Calendar.current.isDate(month, equalTo: previousMonth, toGranularity: .month)
            }
            .forEach { month, expenses in
                sections.append(expenseNoticeSection(
                    prefix: "\(AppStrings.text(.pastMonthsUnpaidExpensesMessagePrefix)) \(month.monthTitle)",
                    expenses: expenses
                ))
            }

        if !currentOverdueExpenses.isEmpty {
            sections.append(expenseNoticeSection(
                prefix: AppStrings.text(.overdueExpensesMessagePrefix),
                expenses: currentOverdueExpenses
            ))
        }

        if !todayUnpaidExpenses.isEmpty {
            sections.append(expenseNoticeSection(
                prefix: AppStrings.text(.dueTodayExpensesMessagePrefix),
                expenses: todayUnpaidExpenses
            ))
        }

        guard !sections.isEmpty else { return }

        overdueExpenseNotice = ExpenseNotice(
            title: AppStrings.text(.overdueExpensesTitle),
            message: sections.joined(separator: "\n\n")
        )
    }

    private func previousMonthsWithUnpaidExpenses() -> [(month: Date, expenses: [ExpenseNoticeItem])] {
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

    private func unpaidExpenses(in month: Date, throughDay maxDay: Int) -> [ExpenseNoticeItem] {
        unpaidExpenses(in: month, fromDay: 1, throughDay: maxDay)
    }

    private func unpaidExpenses(in month: Date, fromDay minDay: Int, throughDay maxDay: Int) -> [ExpenseNoticeItem] {
        guard minDay <= maxDay else { return [] }

        return transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { $0.kind == TransactionKind.expense.rawValue && !$0.isWholeMonthExpense }
            .flatMap { transaction -> [ExpenseNoticeItem] in
                transaction.occurrenceDays(in: month, exclusions: exclusions).compactMap { day in
                    let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                    let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                    let paidAmount = paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
                    let remainingAmount = max(scheduledAmount - paidAmount, 0)

                    guard day >= minDay, day <= maxDay, remainingAmount > 0.005 else { return nil }
                    return ExpenseNoticeItem(transaction: transaction, month: month, occurrenceDay: occurrenceDay)
                }
            }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return unpaidExpenseTitle(for: first.transaction).localizedCaseInsensitiveCompare(unpaidExpenseTitle(for: second.transaction)) == .orderedAscending
            }
    }

    private func expenseNoticeSection(prefix: String, expenses: [ExpenseNoticeItem]) -> String {
        let lines = expenses.map { item in
            let scheduledAmount = item.transaction.scheduledAmount(in: item.month, occurrenceDay: item.occurrenceDay)
            let remainingAmount = max(scheduledAmount - paidAmount(for: item.transaction, in: item.month, occurrenceDay: item.occurrenceDay), 0)
            return "\(unpaidExpenseTitle(for: item.transaction)) - \(AppStrings.text(.day)) \(item.day) - falta \(remainingAmount.currencyText)"
        }

        return ([prefix] + lines).joined(separator: "\n")
    }

    private func months(from startMonth: Date, through endMonth: Date) -> [Date] {
        MoneyCalculationService.months(from: startMonth, through: endMonth)
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        calculator.isPaid(transaction, in: month)
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Bool {
        paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay) >= transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
    }

    private func paidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        calculator.paidAmount(for: transaction, in: month)
    }

    private func paidAmount(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Double {
        calculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
    }

    private func paymentHistoryEntries(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) -> [PaymentHistoryEntry] {
        paymentHistory
            .filter { paymentHistoryEntry($0, matches: transaction, in: month, occurrenceDay: occurrenceDay) }
            .sorted { $0.paidAt > $1.paidAt }
    }

    private func hasPaymentHistory(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) -> Bool {
        paymentHistory.contains {
            paymentHistoryEntry($0, matches: transaction, in: month, occurrenceDay: occurrenceDay)
        }
    }

    private func addPaymentAmount(_ transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil, amount: Double, note: String? = nil, accountID selectedAccountID: UUID? = nil, paidAt: Date = Date()) {
        let paymentAmount = max(amount, 0)
        guard paymentAmount > 0 else { return }

        let monthStart = month.monthStart
        let normalizedOccurrenceDay = normalizedPaymentOccurrenceDay(for: transaction, occurrenceDay: occurrenceDay)
        let scheduledAmount = transaction.scheduledAmount(in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let matchingPayments = paymentRecords(for: transaction, in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let storedPaid = matchingPayments.reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
        let newPaidAmount = storedPaid + paymentAmount
        let appliedPaymentAmount = paymentAmount

        if let existingPayment = matchingPayments.first {
            existingPayment.amountPaid = newPaidAmount
            existingPayment.occurrenceDay = normalizedOccurrenceDay
            matchingPayments.dropFirst().forEach { modelContext.delete($0) }
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: monthStart, amountPaid: newPaidAmount, occurrenceDay: normalizedOccurrenceDay))
        }

        let accountID = selectedAccountID ?? transaction.accountID ?? primarySpendAccount?.id
        transaction.accountID = accountID
        let historyEntry = PaymentHistoryEntry(
            transactionID: transaction.id,
            monthStart: monthStart,
            occurrenceDay: normalizedOccurrenceDay,
            amount: appliedPaymentAmount,
            paidAt: paidAt,
            note: note,
            accountID: accountID
        )
        modelContext.insert(historyEntry)
        if let accountID {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                transactionID: transaction.id,
                paymentHistoryID: historyEntry.id,
                date: paidAt,
                type: AccountMovementKind.expensePayment.rawValue,
                amount: -appliedPaymentAmount,
                note: note ?? transaction.displayName
            ))
        }
        let accountName = accountID.flatMap { id in spendAccounts.first(where: { $0.id == id })?.displayName }
        insertAuditLog(
            action: .expensePaymentCreated,
            title: transaction.displayName,
            details: accountName.map { "Conta: \($0)" } ?? "",
            note: note ?? "",
            amount: -appliedPaymentAmount,
            balanceAfter: auditBalanceAfter(delta: -appliedPaymentAmount),
            accountID: accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            date: paidAt
        )
        syncLinkedCreditPayment(for: transaction, in: month, occurrenceDay: normalizedOccurrenceDay, paidAmount: newPaidAmount)
        syncLinkedSavingDeposit(for: transaction, in: month, occurrenceDay: normalizedOccurrenceDay, paidAmount: newPaidAmount)
        SaveResultNoticeCenter.shared.show(.saved(
            AppStrings.currentLanguage == .portuguese
                ? "Pagamento de \(appliedPaymentAmount.currencyText) registado."
                : "Payment of \(appliedPaymentAmount.currencyText) recorded."
        ))
    }

    private func deletePaymentHistoryEntry(_ entry: PaymentHistoryEntry, for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) {
        guard entry.transactionID == transaction.id else { return }

        let monthStart = month.monthStart
        guard Calendar.current.isDate(entry.monthStart, equalTo: monthStart, toGranularity: .month) else { return }
        let normalizedOccurrenceDay = normalizedPaymentOccurrenceDay(for: transaction, occurrenceDay: occurrenceDay)
        if transaction.recurrence == .weekly {
            guard entry.occurrenceDay == normalizedOccurrenceDay else { return }
        }

        let matchingPayments = paymentRecords(for: transaction, in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let scheduledAmount = transaction.scheduledAmount(in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let currentPaidAmount = matchingPayments.reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
        let newPaidAmount = max(currentPaidAmount - entry.amount, 0)
        let accountName = entry.accountID.flatMap { id in spendAccounts.first(where: { $0.id == id })?.displayName }

        accountMovements
            .filter { $0.paymentHistoryID == entry.id }
            .forEach(modelContext.delete)
        modelContext.delete(entry)
        insertAuditLog(
            action: .expensePaymentDeleted,
            title: transaction.displayName,
            details: accountName.map { "Conta: \($0)" } ?? "",
            note: entry.note ?? "",
            amount: entry.amount,
            balanceAfter: auditBalanceAfter(delta: entry.amount),
            accountID: entry.accountID,
            transactionID: transaction.id,
            paymentHistoryID: entry.id
        )

        if let existingPayment = matchingPayments.first {
            if newPaidAmount <= 0 {
                matchingPayments.forEach { modelContext.delete($0) }
            } else {
                existingPayment.amountPaid = newPaidAmount
                existingPayment.occurrenceDay = normalizedOccurrenceDay
                matchingPayments.dropFirst().forEach { modelContext.delete($0) }
            }
        }

        syncLinkedCreditPayment(for: transaction, in: monthStart, occurrenceDay: normalizedOccurrenceDay, paidAmount: newPaidAmount)
        syncLinkedSavingDeposit(for: transaction, in: monthStart, occurrenceDay: normalizedOccurrenceDay, paidAmount: newPaidAmount)
    }

    private func normalizedPaymentOccurrenceDay(for transaction: MoneyTransaction, occurrenceDay: Int?) -> Int? {
        transaction.recurrence == .weekly ? occurrenceDay : nil
    }

    private func paymentRecords(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> [ExpensePayment] {
        payments.filter { payment in
            payment.transactionID == transaction.id
                && Calendar.current.isDate(payment.monthStart, equalTo: month.monthStart, toGranularity: .month)
                && (transaction.recurrence != .weekly || payment.occurrenceDay == occurrenceDay)
        }
    }

    private func paymentHistoryEntry(_ entry: PaymentHistoryEntry, matches transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Bool {
        entry.transactionID == transaction.id
            && Calendar.current.isDate(entry.monthStart, equalTo: month.monthStart, toGranularity: .month)
            && (transaction.recurrence != .weekly || entry.occurrenceDay == occurrenceDay)
    }

    private func syncLinkedCreditPayment(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?, paidAmount: Double) {
        guard let linkedCreditID = transaction.linkedCreditID else { return }
        let monthStart = month.monthStart
        let movement = linkedCreditMovement(for: transaction, creditID: linkedCreditID, month: monthStart, occurrenceDay: occurrenceDay)

        if paidAmount <= 0 {
            if let movement {
                modelContext.delete(movement)
            }
            if !transaction.isRecurring {
                transaction.linkedCreditMovementID = nil
            }
            return
        }

        let movementDate = linkedMovementDate(for: transaction, in: monthStart, occurrenceDay: occurrenceDay)
        let note = linkedMovementNote(for: transaction)

        if let movement {
            movement.creditID = linkedCreditID
            movement.date = movementDate
            movement.type = CreditMovementKind.payment.rawValue
            movement.amount = paidAmount
            movement.note = note
            movement.linkedTransactionID = transaction.id
            movement.linkedTransactionMonthStart = monthStart
            movement.linkedTransactionOccurrenceDay = occurrenceDay
        } else {
            let movement = CreditMovement(
                creditID: linkedCreditID,
                date: movementDate,
                type: CreditMovementKind.payment.rawValue,
                amount: paidAmount,
                note: note,
                linkedTransactionID: transaction.id,
                linkedTransactionMonthStart: monthStart,
                linkedTransactionOccurrenceDay: occurrenceDay
            )
            modelContext.insert(movement)
            if !transaction.isRecurring {
                transaction.linkedCreditMovementID = movement.id
            }
        }
    }

    private func linkedCreditMovement(for transaction: MoneyTransaction, creditID: UUID, month: Date, occurrenceDay: Int?) -> CreditMovement? {
        if let movement = creditMovements.first(where: {
            $0.linkedTransactionID == transaction.id
                && Calendar.current.isDate($0.linkedTransactionMonthStart ?? .distantPast, equalTo: month.monthStart, toGranularity: .month)
                && $0.linkedTransactionOccurrenceDay == occurrenceDay
        }) {
            return movement
        }

        if !transaction.isRecurring,
           let linkedCreditMovementID = transaction.linkedCreditMovementID,
           let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
            return movement
        }

        if let linkedCreditMovementID = transaction.linkedCreditMovementID,
           let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }),
           Calendar.current.isDate(movement.date, equalTo: linkedMovementDate(for: transaction, in: month, occurrenceDay: occurrenceDay), toGranularity: .day) {
            return movement
        }

        let movementDate = linkedMovementDate(for: transaction, in: month, occurrenceDay: occurrenceDay)
        let note = linkedMovementNote(for: transaction)
        return creditMovements.first {
            $0.creditID == creditID
                && $0.kind == .payment
                && Calendar.current.isDate($0.date, equalTo: movementDate, toGranularity: .day)
                && $0.note == note
        }
    }

    private func syncLinkedSavingDeposit(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?, paidAmount: Double) {
        guard let linkedSavingID = transaction.linkedSavingID else { return }
        let monthStart = month.monthStart
        let movement = linkedSavingMovement(for: transaction, savingID: linkedSavingID, month: monthStart, occurrenceDay: occurrenceDay)

        if paidAmount <= 0 {
            if let movement {
                modelContext.delete(movement)
            }
            if !transaction.isRecurring {
                transaction.linkedSavingMovementID = nil
            }
            return
        }

        let movementDate = linkedMovementDate(for: transaction, in: monthStart, occurrenceDay: occurrenceDay)
        let note = linkedMovementNote(for: transaction)

        if let movement {
            movement.savingID = linkedSavingID
            movement.date = movementDate
            movement.type = SavingMovementKind.deposit.rawValue
            movement.amount = paidAmount
            movement.note = note
            movement.linkedTransactionID = transaction.id
            movement.linkedTransactionMonthStart = monthStart
            movement.linkedTransactionOccurrenceDay = occurrenceDay
        } else {
            let movement = SavingMovement(
                savingID: linkedSavingID,
                date: movementDate,
                type: SavingMovementKind.deposit.rawValue,
                amount: paidAmount,
                note: note,
                linkedTransactionID: transaction.id,
                linkedTransactionMonthStart: monthStart,
                linkedTransactionOccurrenceDay: occurrenceDay
            )
            modelContext.insert(movement)
            if !transaction.isRecurring {
                transaction.linkedSavingMovementID = movement.id
            }
        }
    }

    private func linkedSavingMovement(for transaction: MoneyTransaction, savingID: UUID, month: Date, occurrenceDay: Int?) -> SavingMovement? {
        if let movement = savingMovements.first(where: {
            $0.linkedTransactionID == transaction.id
                && Calendar.current.isDate($0.linkedTransactionMonthStart ?? .distantPast, equalTo: month.monthStart, toGranularity: .month)
                && $0.linkedTransactionOccurrenceDay == occurrenceDay
        }) {
            return movement
        }

        if !transaction.isRecurring,
           let linkedSavingMovementID = transaction.linkedSavingMovementID,
           let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
            return movement
        }

        if let linkedSavingMovementID = transaction.linkedSavingMovementID,
           let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }),
           Calendar.current.isDate(movement.date, equalTo: linkedMovementDate(for: transaction, in: month, occurrenceDay: occurrenceDay), toGranularity: .day) {
            return movement
        }

        let movementDate = linkedMovementDate(for: transaction, in: month, occurrenceDay: occurrenceDay)
        let note = linkedMovementNote(for: transaction)
        return savingMovements.first {
            $0.savingID == savingID
                && $0.kind == .deposit
                && Calendar.current.isDate($0.date, equalTo: movementDate, toGranularity: .day)
                && $0.note == note
        }
    }

    private func linkedMovementDate(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Date {
        month.monthStart.date(day: occurrenceDay ?? transaction.effectiveDay(in: month))
    }

    private func linkedMovementNote(for transaction: MoneyTransaction) -> String {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? transaction.displayName : trimmedTitle
    }

    private func closeBudgetWithConsumedValue(
        _ transaction: MoneyTransaction,
        in month: Date,
        occurrenceDay: Int?,
        consumedValue: Double,
        additionalPaymentAmount: Double = 0,
        note: String? = nil,
        accountID: UUID? = nil
    ) {
        guard transaction.kind == TransactionKind.expense.rawValue else { return }
        let consumedAmount = max(consumedValue, 0)
        guard consumedAmount > 0 else { return }

        let monthStart = month.monthStart
        let normalizedOccurrenceDay = normalizedPaymentOccurrenceDay(for: transaction, occurrenceDay: occurrenceDay)
        let previousBudget = transaction.scheduledAmount(in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        guard consumedAmount < previousBudget else { return }

        if transaction.isRecurring {
            closeRecurringBudgetWithConsumedValue(
                transaction,
                in: monthStart,
                occurrenceDay: normalizedOccurrenceDay,
                consumedAmount: consumedAmount,
                previousBudget: previousBudget,
                additionalPaymentAmount: additionalPaymentAmount,
                note: note,
                accountID: accountID
            )
        } else {
            if additionalPaymentAmount > 0 {
                addPaymentAmount(
                    transaction,
                    in: monthStart,
                    occurrenceDay: normalizedOccurrenceDay,
                    amount: additionalPaymentAmount,
                    note: note,
                    accountID: accountID
                )
            }
            transaction.amount = consumedAmount
            syncLinkedCreditPayment(for: transaction, in: monthStart, occurrenceDay: nil, paidAmount: consumedAmount)
            syncLinkedSavingDeposit(for: transaction, in: monthStart, occurrenceDay: nil, paidAmount: consumedAmount)
            insertBudgetClosedAuditLog(for: transaction, month: monthStart, previousBudget: previousBudget, consumedAmount: consumedAmount)
        }
        SaveResultNoticeCenter.shared.show(.saved(
            AppStrings.currentLanguage == .portuguese
                ? "Planeamento concluído com o valor utilizado."
                : "Planning completed with the used amount."
        ))
    }

    private func closeRecurringBudgetWithConsumedValue(
        _ transaction: MoneyTransaction,
        in month: Date,
        occurrenceDay: Int?,
        consumedAmount: Double,
        previousBudget: Double,
        additionalPaymentAmount: Double = 0,
        note: String? = nil,
        accountID: UUID? = nil
    ) {
        let closedTransaction = MoneyTransaction(
            title: transaction.title,
            day: occurrenceDay ?? transaction.effectiveDay(in: month),
            monthStart: month.monthStart,
            amount: consumedAmount,
            kind: TransactionKind.expense.rawValue,
            repeatsEveryMonth: false,
            expenseCategory: transaction.expenseCategory,
            expenseName: transaction.expenseName,
            linkedCreditID: transaction.linkedCreditID,
            linkedSavingID: transaction.linkedSavingID,
            accountID: transaction.accountID
        )
        modelContext.insert(closedTransaction)

        let paidBeforeAdditionalPayment = max(consumedAmount - additionalPaymentAmount, 0)
        let matchingPayments = paymentRecords(for: transaction, in: month, occurrenceDay: occurrenceDay)
        matchingPayments.forEach { payment in
            payment.transactionID = closedTransaction.id
            payment.monthStart = month.monthStart
            payment.amountPaid = paidBeforeAdditionalPayment
            payment.occurrenceDay = nil
        }
        matchingPayments.dropFirst().forEach(modelContext.delete)

        let matchingHistoryEntries = paymentHistory.filter {
            paymentHistoryEntry($0, matches: transaction, in: month, occurrenceDay: occurrenceDay)
        }
        let matchingHistoryIDs = Set(matchingHistoryEntries.map(\.id))
        matchingHistoryEntries.forEach { entry in
            entry.transactionID = closedTransaction.id
            entry.monthStart = month.monthStart
            entry.occurrenceDay = nil
        }
        accountMovements
            .filter { movement in
                guard let paymentHistoryID = movement.paymentHistoryID else { return false }
                return matchingHistoryIDs.contains(paymentHistoryID)
            }
            .forEach { $0.transactionID = closedTransaction.id }

        if let linkedCreditID = transaction.linkedCreditID,
           let movement = linkedCreditMovement(for: transaction, creditID: linkedCreditID, month: month, occurrenceDay: occurrenceDay) {
            movement.linkedTransactionID = closedTransaction.id
            movement.linkedTransactionMonthStart = month.monthStart
            movement.linkedTransactionOccurrenceDay = nil
            movement.amount = consumedAmount
            closedTransaction.linkedCreditMovementID = movement.id
        }
        if let linkedSavingID = transaction.linkedSavingID,
           let movement = linkedSavingMovement(for: transaction, savingID: linkedSavingID, month: month, occurrenceDay: occurrenceDay) {
            movement.linkedTransactionID = closedTransaction.id
            movement.linkedTransactionMonthStart = month.monthStart
            movement.linkedTransactionOccurrenceDay = nil
            movement.amount = consumedAmount
            closedTransaction.linkedSavingMovementID = movement.id
        }

        if additionalPaymentAmount > 0 {
            addPaymentAmount(
                closedTransaction,
                in: month,
                amount: additionalPaymentAmount,
                note: note,
                accountID: accountID
            )
        }

        addExclusion(for: transaction, in: month, occurrenceDay: occurrenceDay)
        insertBudgetClosedAuditLog(for: closedTransaction, month: month, previousBudget: previousBudget, consumedAmount: consumedAmount)
    }

    private func insertBudgetClosedAuditLog(for transaction: MoneyTransaction, month: Date, previousBudget: Double, consumedAmount: Double) {
        let isPortuguese = AppStrings.currentLanguage == .portuguese
        let details = isPortuguese
            ? "Orçamento fechado com o valor consumido: \(previousBudget.currencyText) -> \(consumedAmount.currencyText)"
            : "Budget closed with consumed value: \(previousBudget.currencyText) -> \(consumedAmount.currencyText)"
        insertAuditLog(
            action: .expenseUpdated,
            title: transaction.displayName,
            details: details,
            accountID: transaction.accountID,
            transactionID: transaction.id,
            date: Date()
        )
    }

    private func deleteTransaction(_ transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) {
        if transaction.isRecurring {
            let normalizedOccurrenceDay = transaction.recurrence == .weekly ? occurrenceDay : nil
            let matchingHistoryEntries = paymentHistory.filter {
                $0.matches(transactionID: transaction.id, month: month, occurrenceDay: normalizedOccurrenceDay)
            }
            let removedMovements = accountMovements.filter { movement in
                guard movement.transactionID == transaction.id else { return false }

                if movement.kind == .income {
                    return Calendar.current.isDate(movement.date, equalTo: month.monthStart, toGranularity: .month)
                }

                guard let paymentHistoryID = movement.paymentHistoryID else { return false }
                return matchingHistoryEntries.contains { $0.id == paymentHistoryID }
            }
            let returnedBalance = -removedMovements.reduce(0) { $0 + $1.amount }
            insertAuditLog(
                action: transaction.kind == TransactionKind.income.rawValue ? .incomeDeleted : .expenseDeleted,
                title: analyticsTransactionTitle(for: transaction),
                details: transaction.detailText(in: month.monthStart),
                amount: returnedBalance,
                balanceAfter: auditBalanceAfter(delta: returnedBalance),
                accountID: transaction.accountID,
                transactionID: transaction.id
            )
            accountMovements
                .filter { movement in
                    guard movement.transactionID == transaction.id else { return false }

                    if movement.kind == .income {
                        return Calendar.current.isDate(movement.date, equalTo: month.monthStart, toGranularity: .month)
                    }

                    guard let paymentHistoryID = movement.paymentHistoryID else { return false }
                    return matchingHistoryEntries.contains { $0.id == paymentHistoryID }
                }
                .forEach(modelContext.delete)
            syncLinkedCreditPayment(for: transaction, in: month, occurrenceDay: normalizedOccurrenceDay, paidAmount: 0)
            syncLinkedSavingDeposit(for: transaction, in: month, occurrenceDay: normalizedOccurrenceDay, paidAmount: 0)
            addExclusion(for: transaction, in: month, occurrenceDay: transaction.recurrence == .weekly ? occurrenceDay : nil)
            payments
                .filter { $0.matches(transactionID: transaction.id, month: month, occurrenceDay: transaction.recurrence == .weekly ? occurrenceDay : nil) }
                .forEach(modelContext.delete)
            matchingHistoryEntries.forEach(modelContext.delete)
        } else {
            let removedMovements = accountMovements.filter { $0.transactionID == transaction.id }
            let returnedBalance = -removedMovements.reduce(0) { $0 + $1.amount }
            insertAuditLog(
                action: transaction.kind == TransactionKind.income.rawValue ? .incomeDeleted : .expenseDeleted,
                title: analyticsTransactionTitle(for: transaction),
                details: transaction.detailText(in: transaction.monthStart),
                amount: returnedBalance,
                balanceAfter: auditBalanceAfter(delta: returnedBalance),
                accountID: transaction.accountID,
                transactionID: transaction.id
            )
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
            accountMovements
                .filter { $0.transactionID == transaction.id }
                .forEach(modelContext.delete)
            modelContext.delete(transaction)
        }
    }

    private func addExclusion(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) {
        guard !exclusions.contains(where: { $0.matches(transactionID: transaction.id, month: month, occurrenceDay: occurrenceDay) }) else {
            return
        }

        modelContext.insert(RecurrenceExclusion(transactionID: transaction.id, monthStart: month.monthStart, occurrenceDay: occurrenceDay))
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
    @Binding var incomeFilter: CurrentAccountIncomeFilter
    @Binding var filteredCategories: Set<ExpenseCategory>
    @Binding var filteredExpenseType: String
    @Binding var freeTextFilter: String
    @Binding var filtersAffectSummaryCards: Bool
    @Binding var sortOrder: CurrentAccountSortOrder

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

                Section(AppStrings.text(.income)) {
                    Picker(AppStrings.text(.income), selection: $incomeFilter) {
                        ForEach(CurrentAccountIncomeFilter.allCases) { filter in
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

                Section {
                    Button {
                        filtersAffectSummaryCards.toggle()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: filtersAffectSummaryCards ? "checkmark.square.fill" : "square")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(filtersAffectSummaryCards ? AppPalette.primary : AppPalette.mutedText)
                                .frame(width: 26, height: 26)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(AppStrings.text(.applyFiltersToSummaryCards))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AppPalette.background)

                                Text(AppStrings.text(.applyFiltersToSummaryCardsDescription))
                                    .font(.footnote)
                                    .foregroundStyle(AppPalette.mutedText)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(filtersAffectSummaryCards ? AppStrings.text(.yes) : AppStrings.text(.no))
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    ForEach(CurrentAccountSortOrder.allCases) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: order.systemImage)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(sortOrder == order ? AppPalette.primary : AppPalette.mutedText)
                                    .frame(width: 24)

                                Text(order.title)
                                    .foregroundStyle(AppPalette.background)

                                Spacer(minLength: 8)

                                if sortOrder == order {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppPalette.primary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if sortOrder != .currentPaymentStatusOrder {
                        Button {
                            sortOrder = .currentPaymentStatusOrder
                        } label: {
                            Label(
                                AppStrings.currentLanguage == .portuguese ? "Repor predefinição" : "Restore default",
                                systemImage: "arrow.counterclockwise"
                            )
                            .foregroundStyle(AppPalette.primary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(AppStrings.currentLanguage == .portuguese ? "Ordenação da lista" : "List ordering")
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                        .textCase(nil)
                        .padding(.top, 16)
                } footer: {
                    Text(AppStrings.currentLanguage == .portuguese
                         ? "A ordenação só altera a apresentação da lista e não modifica os filtros nem os cálculos."
                         : "Ordering only changes how the list is displayed. It does not change filters or calculations.")
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

private struct MonthRemainingBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss

    let month: Date
    let calculation: MonthRemainingCalculation

    var body: some View {
        NavigationStack {
            List {
                Section {
                    calculationRow(
                        title: AppStrings.text(.calculationBase),
                        symbol: nil,
                        value: calculation.base,
                        color: AppPalette.background
                    )
                    calculationRow(
                        title: AppStrings.text(.calculationExpectedIncome),
                        symbol: "+",
                        value: calculation.income,
                        color: AppPalette.positive
                    )
                    calculationRow(
                        title: AppStrings.text(.calculationUnpaidExpenses),
                        symbol: "−",
                        value: calculation.unpaidExpenses,
                        color: AppPalette.primary
                    )
                } header: {
                    Text(month.monthTitle)
                } footer: {
                    Text(AppStrings.text(.monthRemainingCalculationExplanation))
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                }

                Section {
                    calculationRow(
                        title: AppStrings.text(.calculationResult),
                        symbol: "=",
                        value: calculation.result,
                        color: calculation.result < 0 ? AppPalette.primary : AppPalette.positive,
                        isResult: true
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .navigationTitle(AppStrings.text(.monthRemainingCalculationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func calculationRow(
        title: String,
        symbol: String?,
        value: Double,
        color: Color,
        isResult: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Text(symbol ?? "")
                .font(.headline.bold())
                .foregroundStyle(color)
                .frame(width: 18)

            Text(title)
                .font(isResult ? .headline : .subheadline)
                .foregroundStyle(AppPalette.background)

            Spacer(minLength: 8)

            Text(value.currencyText)
                .font(isResult ? .headline.bold() : .subheadline.bold())
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .listRowBackground(AppPalette.surface)
    }
}

private struct UnpaidExpenseLine: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let day: Int
    let scheduledAmount: Double
    let paidAmount: Double
    let remainingAmount: Double
    let isWeekly: Bool
}

private struct UnpaidExpensesBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss

    let month: Date
    let lines: [UnpaidExpenseLine]
    let total: Double

    var body: some View {
        NavigationStack {
            Group {
                if lines.isEmpty {
                    ContentUnavailableView(
                        "Sem despesas por pagar",
                        systemImage: "checkmark.circle",
                        description: Text(AppStrings.text(.noBreakdownRecords))
                    )
                    .foregroundStyle(AppPalette.background)
                } else {
                    List {
                        Section {
                            ForEach(lines) { line in
                                unpaidExpenseRow(line)
                            }
                        } footer: {
                            Text(String(format: AppStrings.text(.detailedTotal), total.currencyText))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.background)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(AppPalette.appBackground)
                }
            }
            .background(AppPalette.appBackground)
            .navigationTitle(AppStrings.text(.payable))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func unpaidExpenseRow(_ line: UnpaidExpenseLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(line.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(2)

                    Text(line.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                }

                Spacer(minLength: 8)

                Text(line.remainingAmount.currencyText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.primary)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                unpaidAmountChip(title: AppStrings.text(.expected), value: line.scheduledAmount)
                unpaidAmountChip(title: AppStrings.text(.paid), value: line.paidAmount)
                if line.isWeekly {
                    Text(AppStrings.text(.weeklyRecurrence))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppPalette.separator.opacity(0.65), in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(AppPalette.surface)
    }

    private func unpaidAmountChip(title: String, value: Double) -> some View {
        Text("\(title): \(value.currencyText)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppPalette.mutedText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppPalette.separator.opacity(0.65), in: Capsule())
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
