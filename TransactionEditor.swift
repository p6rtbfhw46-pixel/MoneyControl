//
//  TransactionEditor.swift
//  MoneyControl
//

import SwiftData
import SwiftUI

private enum TransactionIncomeType: CaseIterable, Identifiable {
    case salary
    case investments
    case earnings
    case pension
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .salary:
            "Salário"
        case .investments:
            "Investimentos"
        case .earnings:
            "Rendimentos"
        case .pension:
            "Pensão"
        case .other:
            "Outros"
        }
    }

    var iconName: String {
        switch self {
        case .salary:
            "briefcase.fill"
        case .investments:
            "chart.line.uptrend.xyaxis"
        case .earnings:
            "banknote.fill"
        case .pension:
            "person.crop.circle.badge.checkmark"
        case .other:
            "ellipsis.circle.fill"
        }
    }

    static func matching(_ title: String) -> TransactionIncomeType? {
        allCases.first { $0.title.compare(title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }
}

private struct SavingProgressCurtain: View {
    let updatesRecurringPlanning: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(AppPalette.background)

                Text("A guardar…")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Text(updatesRecurringPlanning ? "A atualizar os planeamentos recorrentes." : "A concluir a gravação.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
        .zIndex(4000)
    }
}

struct TransactionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""

    let request: TransactionEditorRequest
    let onSaved: (SaveResultNotice) -> Void

    @State private var title = ""
    @State private var selectedIncomeType: TransactionIncomeType = .salary
    @State private var incomeDescription = ""
    @State private var day = 1
    @State private var hasSelectedDay = true
    @State private var amountValue = 0.0
    @State private var expenseCategory: ExpenseCategory?
    @State private var expenseName = ""
    @State private var selectedRecurrenceType: RecurrenceType = .monthly
    @State private var recurrenceMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedIncomeWeekday = Calendar.current.component(.weekday, from: Date())
    @State private var hasEndDate = false
    @State private var endMonth = Calendar.current.component(.month, from: Date())
    @State private var endYear = Calendar.current.component(.year, from: Date())
    @State private var showsDayPicker = false
    @State private var validationMessage: String?
    @State private var markExpenseAsPaid = false
    @State private var didLoad = false
    @State private var showsSingleMonthRecurringEditInfo = false
    @State private var hasConfirmedSingleMonthRecurringEditInfo = false
    @State private var showsValueBelowPaidConfirmation = false
    @State private var showsCloseBudgetConfirmation = false
    @State private var hasConfirmedValueBelowPaid = false
    @State private var showsValueAbovePaidConfirmation = false
    @State private var hasConfirmedValueAbovePaid = false
    @State private var hasDeclinedValueAbovePaid = false
    @State private var selectedCreditID: UUID?
    @State private var selectedSavingID: UUID?
    @State private var selectedAccountID: UUID?
    @State private var selectedTransactionDate = Date()
    @State private var budgetAllocation: BudgetAllocation = .currentMonth
    @State private var autoMarkPaidOnDay = false
    @State private var customBudgetMonth = Calendar.current.component(.month, from: Date())
    @State private var customBudgetYear = Calendar.current.component(.year, from: Date())
    @State private var showsRecurrenceSettings = false
    @State private var showsInlineDayPicker = false
    @State private var isClassificationSectionExpanded = true
    @State private var customIconBrandName: String?
    @State private var customIconBrandDomain: String?
    @State private var customIconURL: String?
    @State private var isSaving = false

    init(
        request: TransactionEditorRequest,
        onSaved: @escaping (SaveResultNotice) -> Void = { _ in }
    ) {
        self.request = request
        self.onSaved = onSaved
    }

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
    private var canMarkExpenseAsPaid: Bool {
        mode == .expense && editedTransaction == nil
    }
    private var activeCreditAccounts: [CreditAccount] {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    private var shouldShowCreditPicker: Bool {
        mode.needsExpenseClassification
            && expenseCategory == .savingsAndDebt
            && isDebtAmortizationExpense
            && !activeCreditAccounts.isEmpty
    }
    private var activeSavingAccounts: [SavingAccount] {
        savingAccounts
            .filter { $0.savingStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    private var shouldShowSavingPicker: Bool {
        mode.needsExpenseClassification
            && expenseCategory == .savingsAndDebt
            && isSavingExpense
            && !activeSavingAccounts.isEmpty
    }
    private var orderedSpendAccounts: [SpendAccount] {
        spendAccounts.sorted { lhs, rhs in
            if lhs.isPrimary != rhs.isPrimary {
                return lhs.isPrimary
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
    private var defaultSpendAccountID: UUID? {
        spendAccounts.first(where: \.isPrimary)?.id ?? spendAccounts.first?.id
    }
    private var resolvedSpendAccountID: UUID? {
        validSpendAccountID(selectedAccountID) ?? defaultSpendAccountID
    }
    private var shouldShowAccountPicker: Bool {
        !orderedSpendAccounts.isEmpty && (mode.needsExpenseClassification || isIncomeMode)
    }

    private var totalAvailableBalanceForAudit: Double {
        spendAccounts.reduce(0) { $0 + $1.balance(with: accountMovements) }
    }

    private func insertAuditLog(
        action: AuditLogAction,
        title: String,
        details: String = "",
        note: String = "",
        amount: Double = 0,
        balanceAfter: Double? = nil,
        accountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        date: Date = Date()
    ) {
        modelContext.insert(AuditLogEntry(
            date: date,
            action: action.rawValue,
            title: title,
            details: details,
            note: note,
            amount: amount,
            balanceAfter: balanceAfter ?? totalAvailableBalanceForAudit,
            accountID: accountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID
        ))
    }
    private var isDebtAmortizationExpense: Bool {
        let normalizedName = normalizedExpenseName
        return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
    }
    private var isSavingExpense: Bool {
        let normalizedName = normalizedExpenseName
        return normalizedName.contains("poup") || normalizedName.contains("saving")
    }
    private var normalizedExpenseName: String {
        expenseName
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
    private var paidAmountForEditedMonth: Double {
        guard mode.needsExpenseClassification, let editedTransaction else { return 0 }
        return payments
            .first { $0.transactionID == editedTransaction.id && Calendar.current.isDate($0.monthStart, equalTo: request.month, toGranularity: .month) }
            .flatMap(\.amountPaid) ?? 0
    }
    private var isEditedExpenseFullyPaid: Bool {
        guard mode.needsExpenseClassification, let editedTransaction else { return false }
        return paidAmountForEditedMonth >= editedTransaction.amount
    }
    private var canCloseBudgetWithConsumedValue: Bool {
        guard mode.needsExpenseClassification,
              editedTransaction != nil,
              paidAmountForEditedMonth > 0,
              paidAmountForEditedMonth < amountValue
        else { return false }

        return request.editScope == .normal || request.editScope == .singleMonth
    }
    private var closeBudgetConfirmationMessage: String {
        let isPortuguese = AppStrings.currentLanguage == .portuguese
        if isPortuguese {
            return "Este orçamento vai ser editado apenas neste registo. O valor orçamentado era \(amountValue.currencyText) e vai passar para \(paidAmountForEditedMonth.currencyText), que já está pago. Depois disto, o orçamento fica fechado como pago."
        }

        return "This budget will be edited only for this entry. The budgeted value was \(amountValue.currencyText) and will become \(paidAmountForEditedMonth.currencyText), which is already paid. After this, the budget is closed as paid."
    }
    private var canMoveEditedExpenseDate: Bool {
        mode.needsExpenseClassification && editedTransaction != nil && (mode == .expense || request.editScope == .singleMonth)
    }
    private var isIncomeMode: Bool {
        mode == .income || mode == .salary
    }
    private var isPresetSavingExpenseRequest: Bool {
        guard mode.needsExpenseClassification,
              request.initialExpenseCategory == .savingsAndDebt,
              let initialExpenseName = request.initialExpenseName
        else { return false }

        let normalizedName = initialExpenseName
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        return normalizedName.contains("poup") || normalizedName.contains("saving")
    }
    private var canUseIncomeReceivedDatePicker: Bool {
        mode == .income
    }
    private var shouldShowBudgetAllocation: Bool {
        mode == .salary && !isSingleMonthRecurringEdit
    }
    private var selectedIncomeReceivedMonthStart: Date {
        canUseIncomeReceivedDatePicker ? selectedTransactionDate.monthStart : request.month.monthStart
    }
    private var selectedIncomeReceivedDay: Int {
        canUseIncomeReceivedDatePicker ? Calendar.current.component(.day, from: selectedTransactionDate) : day
    }
    private var selectedCustomBudgetMonthStart: Date {
        Date.monthStart(month: customBudgetMonth, year: customBudgetYear)
    }
    private var selectedBudgetMonthStart: Date {
        switch budgetAllocation {
        case .currentMonth:
            selectedIncomeReceivedMonthStart
        case .nextMonth:
            selectedIncomeReceivedMonthStart.nextMonthStart
        case .custom:
            selectedCustomBudgetMonthStart
        }
    }
    private var shouldShowRecurrenceMonthHint: Bool {
        (mode == .monthlyExpense || mode == .salary)
            && selectedRecurrenceType != .monthly
            && selectedRecurrenceType != .weekly
            && !isSingleMonthRecurringEdit
    }
    private var shouldShowAutoMarkPaidToggle: Bool {
        mode.needsExpenseClassification
            && (mode == .monthlyExpense || mode == .periodicExpense)
            && hasSelectedDay
            && selectedRecurrenceDay > 0
            && !isSingleMonthRecurringEdit
    }
    private var recurrenceActivationDate: Date {
        Date.firstRecurringOccurrenceDate(
            recurrence: selectedRecurrenceType,
            recurrenceMonth: recurrenceMonth,
            day: selectedRecurrenceDay,
            onOrAfter: request.month
        )
    }
    private var periodicExpenseActivationDate: Date {
        Date.firstRecurringOccurrenceDate(
            recurrence: .yearlyMonth,
            recurrenceMonth: recurrenceMonth,
            day: selectedRecurrenceDay,
            onOrAfter: request.month
        )
    }
    private var selectedRecurrenceDay: Int {
        if selectedRecurrenceType == .weekly {
            return selectedIncomeWeekday
        }
        if isIncomeMode {
            return selectedIncomeReceivedDay
        }
        return day
    }
    private var recurrenceOptions: [RecurrenceType] {
        mode == .salary ? RecurrenceType.incomeSelectableCases : RecurrenceType.selectableCases
    }
    private var currentMonthDay: Int {
        min(Calendar.current.component(.day, from: Date()), request.month.daysInMonth)
    }
    private var isRequestMonthCurrent: Bool {
        Calendar.current.isDate(request.month, equalTo: Date(), toGranularity: .month)
    }
    private var selectedExpenseMonthStart: Date {
        usesExpenseDayCardPicker ? request.month.monthStart : (canMoveEditedExpenseDate ? selectedTransactionDate.monthStart : request.month.monthStart)
    }
    private var selectedExpenseDay: Int {
        usesExpenseDayCardPicker ? day : (canMoveEditedExpenseDate ? Calendar.current.component(.day, from: selectedTransactionDate) : day)
    }
    private var usesExpenseDayCardPicker: Bool {
        mode.needsExpenseClassification
            && (mode != .monthlyExpense || isSingleMonthRecurringEdit)
            && !(mode == .salary && selectedRecurrenceType == .weekly)
    }
    private var resolvedIncomeTitle: String {
        selectedIncomeType == .other ? title : selectedIncomeType.title
    }
    private var expenseCategoryBinding: Binding<ExpenseCategory?> {
        Binding(
            get: { expenseCategory },
            set: { newCategory in
                if expenseCategory != newCategory {
                    expenseName = ""
                    selectedCreditID = nil
                    selectedSavingID = nil
                }
                expenseCategory = newCategory
            }
        )
    }
    private var incomeTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(TransactionIncomeType.allCases) { type in
                        selectorCard(
                            title: type.title,
                            systemImage: type.iconName,
                            isSelected: selectedIncomeType == type
                        ) {
                            selectedIncomeType = type
                            if type != .other {
                                title = type.title
                            } else {
                                title = ""
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            if selectedIncomeType == .other {
                TextField(AppStrings.text(.name), text: $title, prompt: Text(AppStrings.text(.incomeNamePrompt)).foregroundStyle(AppPalette.background.opacity(0.65)))
                    .foregroundStyle(AppPalette.background)
                    .tint(AppPalette.primary)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var incomeDescriptionField: some View {
        TextField("Descrição", text: $incomeDescription, prompt: Text("Descrição").foregroundStyle(AppPalette.background.opacity(0.65)))
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.primary)
            .textInputAutocapitalization(.sentences)
            .padding(12)
            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var recurrenceCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.text(.periodicity), systemImage: "arrow.triangle.2.circlepath")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recurrenceOptions) { recurrence in
                        selectorCard(
                            title: recurrence.title,
                            systemImage: recurrenceIconName(for: recurrence),
                            isSelected: selectedRecurrenceType == recurrence
                        ) {
                            selectedRecurrenceType = recurrence
                            if recurrence == .weekly {
                                hasSelectedDay = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var recurrenceMonthCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.text(.month), systemImage: "calendar")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...12, id: \.self) { month in
                        selectorCard(
                            title: Date.monthName(forMonthNumber: month),
                            systemImage: "calendar",
                            isSelected: recurrenceMonth == month
                        ) {
                            recurrenceMonth = month
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var weekdayCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Dia da semana", systemImage: "calendar.badge.clock")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...7, id: \.self) { weekday in
                        selectorCard(
                            title: weekdayName(for: weekday),
                            systemImage: "calendar",
                            isSelected: selectedIncomeWeekday == weekday
                        ) {
                            selectedIncomeWeekday = weekday
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var dayCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(dateFieldTitle, systemImage: "calendar")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    selectorCard(
                        title: AppStrings.text(.noSpecificDay),
                        systemImage: "calendar.badge.minus",
                        isSelected: hasSelectedDay && day == 0
                    ) {
                        hasSelectedDay = true
                        day = 0
                        autoMarkPaidOnDay = false
                    }

                    selectorCard(
                        title: isRequestMonthCurrent ? "Hoje" : nil,
                        systemImage: "calendar",
                        isSelected: hasSelectedDay && day == currentMonthDay,
                        iconText: "\(currentMonthDay)"
                    ) {
                        hasSelectedDay = true
                        day = currentMonthDay
                    }

                    selectorCard(
                        title: "Outro dia",
                        systemImage: "calendar.badge.plus",
                        isSelected: hasSelectedDay && day > 0 && day != currentMonthDay,
                        iconText: hasSelectedDay && day > 0 && day != currentMonthDay ? "\(day)" : nil
                    ) {
                        withAnimation(.snappy) {
                            showsInlineDayPicker.toggle()
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            if showsInlineDayPicker {
                inlineDayPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var incomeReceivedDayCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(dateFieldTitle, systemImage: "calendar.badge.clock")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                selectorCard(
                    title: "Hoje",
                    systemImage: "calendar",
                    isSelected: day == currentMonthDay,
                    fixedWidth: false,
                    iconText: "\(currentMonthDay)"
                ) {
                    day = currentMonthDay
                    hasSelectedDay = true
                    showsInlineDayPicker = false
                }

                selectorCard(
                    title: "Outro dia",
                    systemImage: "calendar.badge.plus",
                    isSelected: day > 0 && day != currentMonthDay,
                    fixedWidth: false,
                    iconText: day > 0 && day != currentMonthDay ? "\(day)" : nil
                ) {
                    withAnimation(.snappy) {
                        showsInlineDayPicker.toggle()
                    }
                }
            }

            if showsInlineDayPicker {
                inlineDayPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var inlineDayPicker: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...request.month.daysInMonth, id: \.self) { pickerDay in
                Button {
                    day = pickerDay
                    hasSelectedDay = true
                    withAnimation(.snappy) {
                        showsInlineDayPicker = false
                    }
                } label: {
                    Text("\(pickerDay)")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .foregroundStyle(day == pickerDay ? AppPalette.surface : AppPalette.background)
                        .background(day == pickerDay ? AppPalette.background : AppPalette.surface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppPalette.background.opacity(0.16), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var budgetAllocationCardPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.text(.budgetAllocationCurrentMonth), systemImage: "calendar")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                selectorCard(
                    title: "Mês atual",
                    systemImage: "calendar",
                    isSelected: budgetAllocation == .currentMonth,
                    fixedWidth: false
                ) {
                    budgetAllocation = .currentMonth
                }

                selectorCard(
                    title: "Próximo mês",
                    systemImage: "calendar.badge.plus",
                    isSelected: budgetAllocation == .nextMonth,
                    fixedWidth: false
                ) {
                    budgetAllocation = .nextMonth
                }
            }

            Text(budgetAllocationDescription)
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.background.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
        }
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.surface)
                .frame(width: 30, height: 30)
                .background(AppPalette.background, in: Circle())

            Text(title)
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)
        }
    }

    private func selectorCard(
        title: String?,
        systemImage: String,
        isSelected: Bool,
        fixedWidth: Bool = true,
        iconText: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        if let iconText {
                            Text(iconText)
                                .font(.title3.bold())
                                .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.background)
                        } else {
                            Image(systemName: systemImage)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.background)
                        }
                    }
                    .frame(width: 46, height: 46)
                    .background(isSelected ? AppPalette.positive.opacity(0.12) : AppPalette.appBackground, in: Circle())

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.surface)
                            .frame(width: 22, height: 22)
                            .background(AppPalette.positive, in: Circle())
                            .offset(x: 8, y: -8)
                    }
                }

                if let title {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.background)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(minWidth: fixedWidth ? 112 : 0, maxWidth: fixedWidth ? 112 : .infinity, minHeight: 104)
            .background(isSelected ? AppPalette.positive.opacity(0.08) : AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppPalette.positive.opacity(0.55) : AppPalette.separator, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func recurrenceIconName(for recurrence: RecurrenceType) -> String {
        switch recurrence {
        case .weekly:
            "calendar.badge.clock"
        case .monthly:
            "calendar.badge.clock"
        case .quarterly:
            "calendar"
        case .semiannual:
            "calendar"
        case .annual, .yearlyMonth:
            "calendar.circle"
        }
    }

    private var recurrenceSummaryText: String {
        if isSingleMonthRecurringEdit {
            return singleMonthRecurringEditMessage
        }

        if mode == .periodicExpense {
            return "\(AppStrings.text(.annualRecurrence)) - \(Date.monthName(forMonthNumber: recurrenceMonth))"
        }

        var parts = [selectedRecurrenceType.title]

        if selectedRecurrenceType == .weekly {
            parts.append(weekdayName(for: selectedIncomeWeekday))
        } else if shouldShowRecurrenceMonthHint {
            parts.append(Date.monthName(forMonthNumber: recurrenceMonth))
        }

        if (mode == .monthlyExpense || mode == .salary) && selectedRecurrenceType != .weekly && hasSelectedDay {
            parts.append(daySelectionText)
        }

        if mode == .monthlyExpense && hasEndDate {
            parts.append("\(AppStrings.text(.endDate)) \(selectedEndMonthStart.monthTitle)")
        }

        return parts.joined(separator: " - ")
    }

    private var recurrenceNavigationRow: some View {
        Group {
            if isSingleMonthRecurringEdit {
                recurrenceSummaryRow(showsDisclosure: false)
            } else {
                Button {
                    showsRecurrenceSettings = true
                } label: {
                    recurrenceSummaryRow(showsDisclosure: true)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
    }

    private func recurrenceSummaryRow(showsDisclosure: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.text(.recurrence))
                    .foregroundStyle(AppPalette.background)

                Text(recurrenceSummaryText)
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var recurrenceSettingsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isSingleMonthRecurringEdit {
                    recurrenceSettingsOnlyMessage
                } else if mode == .periodicExpense {
                    recurrenceMonthCardPicker
                } else {
                    recurrenceCardPicker

                    if mode == .salary && selectedRecurrenceType != .weekly {
                        incomeReceivedDayCardPicker
                    }

                    if (mode == .salary || mode == .monthlyExpense) && selectedRecurrenceType == .weekly {
                        weekdayCardPicker
                    }

                    if shouldShowRecurrenceMonthHint {
                        recurrenceMonthCardPicker
                    }

                    if mode == .monthlyExpense && selectedRecurrenceType != .weekly {
                        dayCardPicker
                    }

                    if mode == .monthlyExpense && shouldShowAutoMarkPaidToggle {
                        Toggle(AppStrings.text(.autoMarkPaidOnDay), isOn: $autoMarkPaidOnDay)
                            .tint(AppPalette.primary)
                            .padding(14)
                            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                    }

                    if mode == .monthlyExpense {
                        VStack(alignment: .leading, spacing: 12) {
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
                            }
                        }
                        .padding(14)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
        }
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.recurrence))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var editorFormContent: some View {
        if isPresetSavingExpenseRequest {
            presetSavingExpenseInfoSection
            classificationSection
            recurrenceSections
            detailsSection
        } else {
            closeBudgetSection
            detailsSection
            classificationSection
            recurrenceSections
        }
        BrandIconPickerSection(
            selectedBrandName: $customIconBrandName,
            selectedBrandDomain: $customIconBrandDomain,
            selectedBrandIconURL: $customIconURL,
            suggestedSearchText: brandIconSearchSuggestion
        )
    }

    private var brandIconSearchSuggestion: String {
        let trimmedIncomeDescription = incomeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if isIncomeMode, !trimmedIncomeDescription.isEmpty {
            return trimmedIncomeDescription
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ViewBuilder
    private var presetSavingExpenseInfoSection: some View {
        Section {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.savings)
                    .padding(.top, 2)

                Text(AppStrings.text(.newSavingExpenseInfo))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppPalette.savings.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppPalette.savings.opacity(0.22), lineWidth: 1)
            }
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var closeBudgetSection: some View {
        if canCloseBudgetWithConsumedValue {
            Section {
                Button {
                    showsCloseBudgetConfirmation = true
                } label: {
                    Label(AppStrings.text(.closeBudgetWithConsumedValue), systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppPalette.mediumBlue.opacity(0.35), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            } footer: {
                Text("\(paidAmountForEditedMonth.currencyText) já pagos de \(amountValue.currencyText).")
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var classificationSection: some View {
        if mode.needsExpenseClassification {
            Section {
                Button {
                    withAnimation(.snappy) {
                        isClassificationSectionExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(AppStrings.text(.classification))
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)

                        Spacer()

                        if !expenseName.isEmpty, !isClassificationSectionExpanded {
                            Text(expenseName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(expenseCategory?.color ?? AppPalette.background)
                                .lineLimit(1)
                        }

                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.mutedText)
                            .rotationEffect(.degrees(isClassificationSectionExpanded ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isClassificationSectionExpanded {
                    HStack(spacing: 10) {
                        Text(AppStrings.text(.category503020))
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)

                        HelpIconButton(
                            title: AppStrings.text(.rule503020Title),
                            message: AppStrings.text(.rule503020Help),
                            arrowEdge: .bottom
                        )

                        Spacer()
                    }

                    ExpenseCategorySegmentedPicker(selection: expenseCategoryBinding)

                    if let expenseCategory {
                        ExpenseTypeHorizontalPicker(
                            title: AppStrings.text(.expenseType),
                            names: expenseCategory.names,
                            tint: expenseCategory.color,
                            selection: $expenseName
                        )
                    } else {
                        ExpenseTypeHorizontalPicker(
                            title: AppStrings.text(.expenseType),
                            names: ExpenseCategory.needs.names,
                            tint: ExpenseCategory.needs.color,
                            selection: $expenseName
                        )
                        .onAppear {
                            expenseCategory = .needs
                        }
                    }

                    linkedCreditPicker
                }
            }
            .listRowBackground(AppPalette.surface)
        }
    }

    @ViewBuilder
    private var linkedCreditPicker: some View {
        if shouldShowCreditPicker {
            HStack(spacing: 10) {
                Picker(CreditStrings.text(.credit), selection: normalizedSelectedCreditID) {
                    Text(CreditStrings.text(.selectCredit)).tag(nil as UUID?)
                    ForEach(activeCreditAccounts) { credit in
                        Text(credit.displayName).tag(credit.id as UUID?)
                    }
                }
                .tint(AppPalette.background)

                HelpIconButton(
                    title: AppStrings.text(.linkedTrackingOptionalHelpTitle),
                    message: AppStrings.text(.linkedTrackingOptionalHelpMessage)
                )
            }
        }
    }

    @ViewBuilder
    private var linkedSavingPicker: some View {
        if shouldShowSavingPicker {
            HStack(spacing: 10) {
                Picker(SavingsStrings.text(.saving), selection: normalizedSelectedSavingID) {
                    Text(SavingsStrings.text(.selectSaving)).tag(nil as UUID?)
                    ForEach(activeSavingAccounts) { saving in
                        Text(saving.displayName).tag(saving.id as UUID?)
                    }
                }
                .tint(AppPalette.background)

                HelpIconButton(
                    title: AppStrings.text(.linkedTrackingOptionalHelpTitle),
                    message: AppStrings.text(.linkedTrackingOptionalHelpMessage)
                )
            }
        }
    }

    @ViewBuilder
    private var linkedSpendAccountPicker: some View {
        if shouldShowAccountPicker {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(AppStrings.text(.account), systemImage: "wallet.pass.fill")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(orderedSpendAccounts) { account in
                            spendAccountCard(account)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private func spendAccountCard(_ account: SpendAccount) -> some View {
        let isSelected = resolvedSpendAccountID == account.id
        let balance = account.balance(with: accountMovements)

        return Button {
            selectedAccountID = account.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: account.accountIcon.systemName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.surface : account.tint)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
                        .lineLimit(1)
                    Text(balance.currencyText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isSelected ? AppPalette.surface.opacity(0.88) : AppPalette.mutedText)
                        .lineLimit(1)
                }
            }
            .frame(width: 180, height: 72, alignment: .leading)
            .padding(.horizontal, 12)
            .background(isSelected ? AppPalette.background : AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppPalette.background : AppPalette.separator, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var normalizedSelectedAccountID: Binding<UUID?> {
        Binding(
            get: { resolvedSpendAccountID },
            set: { selectedAccountID = $0 }
        )
    }

    private var normalizedSelectedCreditID: Binding<UUID?> {
        Binding(
            get: { validCreditID(selectedCreditID) },
            set: { selectedCreditID = $0 }
        )
    }

    private var normalizedSelectedSavingID: Binding<UUID?> {
        Binding(
            get: { validSavingID(selectedSavingID) },
            set: { selectedSavingID = $0 }
        )
    }

    private func validSpendAccountID(_ id: UUID?) -> UUID? {
        guard let id, spendAccounts.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    private func validCreditID(_ id: UUID?) -> UUID? {
        guard let id, activeCreditAccounts.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    private func validSavingID(_ id: UUID?) -> UUID? {
        guard let id, activeSavingAccounts.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    @ViewBuilder
    private var recurrenceSections: some View {
        if mode == .monthlyExpense {
            Section(AppStrings.text(.recurrence)) {
                recurrenceNavigationRow
            }
            .listRowBackground(AppPalette.surface)
        }

        if mode == .periodicExpense {
            Section(AppStrings.text(.recurrence)) {
                recurrenceNavigationRow
            }
            .listRowBackground(AppPalette.surface)
        }
    }

    private var detailsSection: some View {
        Section {
            detailsFields
        }
        .listRowBackground(AppPalette.surface)
    }

    @ViewBuilder
    private var detailsFields: some View {
        if isIncomeMode && !isSingleMonthRecurringEdit {
            incomeTypePicker
        } else {
            titleField
        }

        MoneyAmountPicker(
            title: AppStrings.text(.value),
            amount: $amountValue,
            maximumAmount: 1_000_000,
            onConfirm: save
        )

        if mode == .salary {
            recurrenceNavigationRow
        }

        if usesExpenseDayCardPicker {
            dayCardPicker
        } else if mode != .monthlyExpense && mode != .salary {
            Button {
                showsDayPicker = true
            } label: {
                HStack {
                    Text(dateFieldTitle)
                    Spacer()
                    Text(daySelectionText)
                        .foregroundStyle(AppPalette.mutedText)
                }
            }
            .foregroundStyle(AppPalette.background)
        }

        if mode != .monthlyExpense && shouldShowAutoMarkPaidToggle {
            Toggle(AppStrings.text(.autoMarkPaidOnDay), isOn: $autoMarkPaidOnDay)
                .tint(AppPalette.primary)
        }

        linkedSpendAccountPicker
        linkedSavingPicker

        if shouldShowBudgetAllocation {
            budgetAllocationCardPicker
        }

        if isIncomeMode {
            incomeDescriptionField
        }

        paymentStatusRow
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mode.needsExpenseClassification ? AppStrings.text(.freeText) : AppStrings.text(.name))
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            TextField(
                "",
                text: $title,
                prompt: Text(mode.needsExpenseClassification ? AppStrings.text(.freeText) : AppStrings.text(.name))
                    .foregroundStyle(AppPalette.background.opacity(0.65))
            )
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.primary)
            .padding(12)
            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppPalette.separator, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var paymentStatusRow: some View {
        if canMarkExpenseAsPaid {
            HStack(spacing: 12) {
                sectionLabel(markExpenseAsPaid ? AppStrings.text(.paidExpense) : AppStrings.text(.unpaidExpense), systemImage: "doc.text.fill")

                Spacer()

                Toggle("", isOn: $markExpenseAsPaid)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(AppPalette.primary)
                    .fixedSize()

                HelpIconButton(
                    title: AppStrings.text(.paidToggleHelpTitle),
                    message: AppStrings.text(.paidToggleHelpMessage)
                )
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(request.titleOverride ?? mode.navigationTitle(isEditing: editedTransaction != nil))
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, validationMessage == nil ? 4 : 2)

                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Form {
                    editorFormContent
                }
                .scrollContentBackground(.hidden)
                .background(AppPalette.appBackground)
            }
            .animation(.snappy, value: validationMessage)
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.background)
            .background(AppPalette.appBackground)
            .navigationTitle("")
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
                if canUseIncomeReceivedDatePicker {
                    TransactionDatePicker(selectedDate: $selectedTransactionDate, title: dateFieldTitle)
                } else {
                    DayPicker(
                        month: mode == .periodicExpense ? pickerMonth : request.month,
                        selectedDay: $day,
                        allowsWholeMonthExpense: mode == .expense || mode == .monthlyExpense,
                        isWholeMonthExpenseSelected: hasSelectedDay && day == 0,
                        onSelection: { selectedDay in
                            hasSelectedDay = true
                            if selectedDay <= 0 {
                                autoMarkPaidOnDay = false
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showsRecurrenceSettings) {
                NavigationStack {
                    recurrenceSettingsPage
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(AppStrings.text(.ok)) {
                                    showsRecurrenceSettings = false
                                }
                            }
                        }
                }
            }
            .confirmationNotice(
                isPresented: $showsSingleMonthRecurringEditInfo,
                title: "Editar apenas este mês",
                message: singleMonthRecurringEditMessage
            ) {
                hasConfirmedSingleMonthRecurringEditInfo = true
                save()
            }
            .confirmationNotice(
                isPresented: $showsCloseBudgetConfirmation,
                title: "Fechar orçamento?",
                message: closeBudgetConfirmationMessage,
                onConfirm: closeBudgetWithConsumedValue
            )
            .confirmationNotice(
                isPresented: $showsValueBelowPaidConfirmation,
                title: AppStrings.text(.valueBelowPaidTitle),
                message: AppStrings.text(.valueBelowPaidMessage)
            ) {
                hasConfirmedValueBelowPaid = true
                amountValue = paidAmountForEditedMonth
                save()
            }
            .alert(AppStrings.text(.valueAbovePaidTitle), isPresented: $showsValueAbovePaidConfirmation) {
                Button(AppStrings.text(.no)) {
                    hasDeclinedValueAbovePaid = true
                    save()
                }
                Button(AppStrings.text(.yes)) {
                    hasConfirmedValueAbovePaid = true
                    save()
                }
            } message: {
                Text(AppStrings.text(.valueAbovePaidMessage))
            }
            .overlay {
                if isSaving {
                    SavingProgressCurtain(
                        updatesRecurringPlanning: editedTransaction?.isRecurring == true || mode == .monthlyExpense || mode == .periodicExpense || mode == .salary
                    )
                }
            }
            .onAppear(perform: loadInitialValues)
            .id(selectedCurrencyCode)
        }
    }

    private var parsedValue: Double? {
        amountValue > 0 ? amountValue : nil
    }

    private var daySelectionText: String {
        if canMoveEditedExpenseDate || canUseIncomeReceivedDatePicker {
            let formatter = DateFormatter()
            formatter.locale = SpendWiseRegionalFormat.locale
            formatter.calendar = SpendWiseRegionalFormat.calendar
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: selectedTransactionDate)
        }
        if !hasSelectedDay {
            return AppStrings.text(.select)
        }
        if mode.needsExpenseClassification && day <= 0 {
            return AppStrings.text(.noSpecificDay)
        }
        return "\(day)"
    }

    private var requiresExplicitDaySelection: Bool {
        guard mode.needsExpenseClassification else { return false }
        if mode == .monthlyExpense || mode == .periodicExpense {
            return true
        }
        return editedTransaction == nil && !isRequestMonthCurrent
    }

    private var explicitDayValidationMessage: String {
        let month = request.month.formatted(
            .dateTime
                .locale(Locale(identifier: AppStrings.currentLocaleIdentifier))
                .month(.wide)
                .year()
        )
        if AppStrings.currentLanguage == .portuguese {
            return "Selecione o dia do agendamento para \(month)."
        }
        return "Select the schedule day for \(month)."
    }

    private var dateFieldTitle: String {
        guard !isIncomeMode else { return AppStrings.text(.receivedDate) }

        let selectedMonth = mode == .periodicExpense ? pickerMonth : request.month
        let monthNumber = Calendar.current.component(.month, from: selectedMonth)
        let monthName = Date.monthName(forMonthNumber: monthNumber)
        return "\(AppStrings.text(.day)) - \(monthName)"
    }

    private var budgetAllocationDescription: String {
        switch budgetAllocation {
        case .currentMonth:
            AppStrings.text(.budgetAllocationCurrentMonthDescription)
        case .nextMonth:
            AppStrings.text(.budgetAllocationNextMonthDescription)
        case .custom:
            AppStrings.text(.budgetAllocationCustomMonthDescription)
        }
    }

    private var singleMonthRecurringEditMessage: String {
        mode == .salary ? AppStrings.text(.recurringIncomeSettingsOnlyMessage) : AppStrings.text(.recurrenceSettingsOnlyMessage)
    }

    private var recurrenceSettingsOnlyMessage: some View {
        Text(singleMonthRecurringEditMessage)
            .font(.subheadline)
            .foregroundStyle(AppPalette.mutedText)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 4)
    }

    private func showValidation(_ message: String) {
        validationMessage = message
    }

    private func closeBudgetWithConsumedValue() {
        guard canCloseBudgetWithConsumedValue else { return }
        hasConfirmedValueBelowPaid = true
        hasConfirmedSingleMonthRecurringEditInfo = true
        amountValue = paidAmountForEditedMonth
        save()
    }

    private func loadInitialValues() {
        guard !didLoad else { return }
        didLoad = true

        guard let transaction = editedTransaction else {
            isClassificationSectionExpanded = true
            selectedAccountID = defaultSpendAccountID
            recurrenceMonth = Calendar.current.component(.month, from: request.month)
            if requiresExplicitDaySelection {
                day = currentMonthDay
                hasSelectedDay = isRequestMonthCurrent
            } else {
                day = min(Calendar.current.component(.day, from: Date()), request.month.daysInMonth)
                hasSelectedDay = true
            }
            selectedTransactionDate = request.month.date(day: max(day, 1))
            autoMarkPaidOnDay = false
            selectedIncomeWeekday = Calendar.current.component(.weekday, from: Date())
            customBudgetMonth = Calendar.current.component(.month, from: request.month)
            customBudgetYear = Calendar.current.component(.year, from: request.month)
            expenseCategory = request.initialExpenseCategory ?? (mode.needsExpenseClassification ? .needs : nil)
            expenseName = request.initialExpenseName ?? ""
            if let initialTitle = request.initialTitle {
                title = initialTitle
                updateIncomeTypeSelection(for: initialTitle)
            }
            if let initialAmount = request.initialAmount {
                amountValue = initialAmount
            }
            if let initialDate = request.initialDate {
                selectedTransactionDate = initialDate
                day = min(Calendar.current.component(.day, from: initialDate), request.month.daysInMonth)
                hasSelectedDay = true
            }
            markExpenseAsPaid = request.startsMarkedAsPaid && canMarkExpenseAsPaid
            return
        }

        isClassificationSectionExpanded = false
        title = transaction.title
        updateIncomeTypeSelection(for: transaction.title)
        incomeDescription = transaction.incomeDescription ?? ""
        if let recurrence = transaction.recurrence {
            selectedRecurrenceType = recurrence == .yearlyMonth ? .annual : recurrence
        }
        let initialMonth = request.editScope == .singleMonth ? request.month.monthStart : transaction.monthStart.monthStart
        day = transaction.day <= 0 ? 0 : min(transaction.day, initialMonth.daysInMonth)
        if selectedRecurrenceType == .weekly {
            selectedIncomeWeekday = min(max(transaction.day, 1), 7)
        }
        hasSelectedDay = true
        selectedTransactionDate = initialMonth.date(day: max(day, 1))
        autoMarkPaidOnDay = transaction.autoMarkPaidOnDay && day > 0
        amountValue = transaction.amount
        expenseCategory = ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
        expenseName = transaction.expenseName ?? ""
        selectedCreditID = transaction.linkedCreditID
        selectedSavingID = transaction.linkedSavingID
        selectedAccountID = transaction.accountID ?? defaultSpendAccountID
        customIconBrandName = transaction.customIconBrandName
        customIconBrandDomain = transaction.customIconBrandDomain
        customIconURL = transaction.customIconURL
        recurrenceMonth = transaction.recurrenceMonth > 0 ? transaction.recurrenceMonth : Calendar.current.component(.month, from: transaction.monthStart)
        budgetAllocation = mode == .salary && transaction.budgetAllocation == .custom ? .currentMonth : transaction.budgetAllocation
        let budgetMonth = transaction.budgetMonth(forReceivedMonth: initialMonth)
        customBudgetMonth = Calendar.current.component(.month, from: budgetMonth)
        customBudgetYear = Calendar.current.component(.year, from: budgetMonth)

        if let endMonthStart = transaction.recurrenceEndMonthStart?.previousMonthStart {
            hasEndDate = true
            endMonth = Calendar.current.component(.month, from: endMonthStart)
            endYear = Calendar.current.component(.year, from: endMonthStart)
        }
    }

    private func updateIncomeTypeSelection(for value: String) {
        guard isIncomeMode else { return }

        if let matchingType = TransactionIncomeType.matching(value) {
            selectedIncomeType = matchingType
            title = matchingType.title
        } else {
            selectedIncomeType = .other
            title = value
        }
    }

    private func save() {
        validationMessage = nil

        if mode.needsExpenseClassification {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                showValidation(AppStrings.text(.fillFreeText))
                return
            }

            guard let parsedValue else {
                showValidation(AppStrings.text(.fillValue))
                return
            }

            guard !requiresExplicitDaySelection || hasSelectedDay else {
                showValidation(explicitDayValidationMessage)
                return
            }

            guard let expenseCategory else {
                showValidation(AppStrings.text(.selectExpenseType))
                return
            }

            guard !expenseName.isEmpty else {
                showValidation(AppStrings.text(.selectExpenseName))
                return
            }

            if paidAmountForEditedMonth > parsedValue && !hasConfirmedValueBelowPaid {
                showsValueBelowPaidConfirmation = true
                return
            }

            if isEditedExpenseFullyPaid,
               let editedTransaction,
               parsedValue > editedTransaction.amount,
               !hasConfirmedValueAbovePaid,
               !hasDeclinedValueAbovePaid {
                showsValueAbovePaidConfirmation = true
                return
            }

            if isSingleMonthRecurringEdit && !hasConfirmedSingleMonthRecurringEditInfo {
                showsSingleMonthRecurringEditInfo = true
                return
            }

            performSave {
                saveExpense(value: max(parsedValue, paidAmountForEditedMonth), category: expenseCategory, title: trimmedTitle)
            }
        } else {
            let rawTitle = isIncomeMode ? resolvedIncomeTitle : title
            let trimmedTitle = rawTitle.trimmingCharacters(in: .whitespaces)
            guard !trimmedTitle.isEmpty else {
                showValidation(AppStrings.text(.fillName))
                return
            }

            guard let parsedValue else {
                showValidation(AppStrings.text(.fillValue))
                return
            }

            if isSingleMonthRecurringEdit && !hasConfirmedSingleMonthRecurringEditInfo {
                showsSingleMonthRecurringEditInfo = true
                return
            }

            performSave {
                saveIncome(
                    value: parsedValue,
                    title: trimmedTitle,
                    description: incomeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }
    }

    private func performSave(_ update: @escaping @MainActor () -> Void) {
        guard !isSaving else { return }
        isSaving = true

        Task { @MainActor in
            // Give SwiftUI one render pass so the progress curtain is visible
            // before recurring schedules are regenerated synchronously.
            try? await Task.sleep(for: .milliseconds(60))
            update()

            do {
                try modelContext.save()
                let notice = SaveResultNotice.saved(saveSuccessMessage)
                onSaved(notice)
                dismiss()
            } catch {
                isSaving = false
                validationMessage = error.localizedDescription
            }
        }
    }

    private var saveSuccessMessage: String {
        let isNewRecord = editedTransaction == nil || request.editScope != .normal
        if isIncomeMode {
            return AppStrings.text(isNewRecord ? .incomeCreatedMessage : .incomeUpdatedMessage)
        } else {
            return AppStrings.text(isNewRecord ? .budgetExpenseCreatedMessage : .budgetExpenseUpdatedMessage)
        }
    }

    private func saveExpense(value: Double, category: ExpenseCategory, title: String) {
        let isNewTransaction = editedTransaction == nil || request.editScope != .normal
        let transaction = targetTransaction()
        let originalMonthStart = transaction.monthStart.monthStart
        let originalAccountID = transaction.accountID
        transaction.title = title
        transaction.day = mode == .monthlyExpense && selectedRecurrenceType == .weekly
            ? selectedIncomeWeekday
            : (canMoveEditedExpenseDate ? selectedExpenseDay : (request.editScope == .singleMonth ? min(day, request.month.daysInMonth) : day))
        transaction.amount = value
        transaction.kind = TransactionKind.expense.rawValue
        transaction.expenseCategory = category.rawValue
        transaction.expenseName = expenseName
        transaction.accountID = resolvedSpendAccountID
        transaction.autoMarkPaidOnDay = shouldShowAutoMarkPaidToggle && autoMarkPaidOnDay
        transaction.customIconBrandName = customIconBrandName
        transaction.customIconBrandDomain = customIconBrandDomain
        transaction.customIconURL = customIconURL

        if request.editScope == .singleMonth {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = nil
            transaction.recurrenceMonth = 0
            transaction.recurrenceEndMonthStart = nil
            transaction.monthStart = selectedExpenseMonthStart
        } else {
            switch mode {
            case .monthlyExpense:
                transaction.repeatsEveryMonth = selectedRecurrenceType == .monthly
                transaction.recurrenceType = selectedRecurrenceType.rawValue
                transaction.recurrenceMonth = (selectedRecurrenceType == .monthly || selectedRecurrenceType == .weekly) ? 0 : recurrenceMonth
                transaction.recurrenceEndMonthStart = hasEndDate ? selectedEndMonthStart.nextMonthStart : nil
                transaction.monthStart = recurrenceActivationDate
            case .periodicExpense:
                transaction.repeatsEveryMonth = false
                transaction.recurrenceType = RecurrenceType.yearlyMonth.rawValue
                transaction.recurrenceMonth = recurrenceMonth
                transaction.recurrenceEndMonthStart = nil
                transaction.monthStart = periodicExpenseActivationDate
            case .expense:
                transaction.repeatsEveryMonth = false
                transaction.recurrenceType = nil
                transaction.recurrenceMonth = 0
                transaction.recurrenceEndMonthStart = nil
                transaction.monthStart = canMoveEditedExpenseDate ? selectedExpenseMonthStart : request.month.monthStart
            case .income, .salary:
                break
            }
        }

        finishSaving(
            transaction,
            originalMonthStart: originalMonthStart,
            fullyPaidAmountAfterTransfer: hasConfirmedValueAbovePaid ? value : nil
        )
        syncEditedExpensePaymentAccountIfNeeded(
            transaction,
            originalAccountID: originalAccountID
        )
        markAsFullyPaidIfNeeded(transaction, value: value)
        keepEditedPaidExpenseFullyPaidIfNeeded(transaction, value: value)
        syncLinkedCreditPaymentIfNeeded(transaction, value: value)
        syncLinkedSavingDepositIfNeeded(transaction, value: value)
        insertAuditLog(
            action: isNewTransaction ? .expenseCreated : .expenseUpdated,
            title: transaction.displayName,
            details: transaction.detailText(in: transaction.monthStart),
            accountID: transaction.accountID,
            transactionID: transaction.id
        )
    }

    private func saveIncome(value: Double, title: String, description: String) {
        let isNewTransaction = editedTransaction == nil || request.editScope != .normal
        let balanceBefore = totalAvailableBalanceForAudit
        let previousMovementAmount = editedTransaction.flatMap { edited in
            accountMovements.first { $0.transactionID == edited.id && $0.kind == .income }?.amount
        } ?? 0
        let transaction = targetTransaction()
        transaction.title = title
        transaction.incomeDescription = description.isEmpty ? nil : description
        transaction.day = mode == .salary && selectedRecurrenceType == .weekly ? selectedIncomeWeekday : selectedIncomeReceivedDay
        transaction.amount = value
        transaction.kind = TransactionKind.income.rawValue
        transaction.expenseCategory = nil
        transaction.expenseName = nil
        transaction.accountID = resolvedSpendAccountID
        transaction.autoMarkPaidOnDay = false
        transaction.customIconBrandName = customIconBrandName
        transaction.customIconBrandDomain = customIconBrandDomain
        transaction.customIconURL = customIconURL

        if mode == .salary && request.editScope != .singleMonth {
            transaction.repeatsEveryMonth = selectedRecurrenceType == .monthly
            transaction.recurrenceType = selectedRecurrenceType.rawValue
            transaction.budgetAllocation = budgetAllocation == .custom ? .currentMonth : budgetAllocation
        } else {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = nil
            transaction.budgetAllocation = budgetAllocation
        }

        transaction.recurrenceMonth = (mode == .salary && selectedRecurrenceType != .monthly && selectedRecurrenceType != .weekly)
            ? recurrenceMonth
            : 0
        transaction.monthStart = mode == .income
            ? selectedIncomeReceivedMonthStart
            : recurrenceActivationDate
        transaction.budgetMonthStart = transaction.budgetMonth(forReceivedMonth: transaction.monthStart)
        if !transaction.isRecurring {
            let receivedDay = Calendar.current.startOfDay(for: transaction.receivedDate(in: transaction.monthStart))
            transaction.autoMarkPaidOnDay = receivedDay > Calendar.current.startOfDay(for: Date())
        }
        finishSaving(transaction)
        syncIncomeAccountMovementIfNeeded(transaction, value: value)
        let balanceDelta = transaction.recurrence == nil ? value - previousMovementAmount : 0
        insertAuditLog(
            action: isNewTransaction ? .incomeCreated : .incomeUpdated,
            title: transaction.displayName,
            details: transaction.detailText(in: transaction.monthStart),
            amount: balanceDelta,
            balanceAfter: balanceBefore + balanceDelta,
            accountID: transaction.accountID,
            transactionID: transaction.id,
            date: transaction.recurrence == nil ? accountMovementDate(on: transaction.receivedDate(in: transaction.monthStart), preservingTimeFrom: Date()) : Date()
        )
    }

    private func weekdayName(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        return formatter.weekdaySymbols[min(max(weekday, 1), 7) - 1]
    }

    private func targetTransaction() -> MoneyTransaction {
        if let editedTransaction, request.editScope == .normal {
            return editedTransaction
        }

        return MoneyTransaction(
            title: "",
            day: day,
            monthStart: canMoveEditedExpenseDate ? selectedExpenseMonthStart : request.month.monthStart,
            amount: 0,
            kind: mode.needsExpenseClassification ? TransactionKind.expense.rawValue : TransactionKind.income.rawValue
        )
    }

    private func finishSaving(
        _ transaction: MoneyTransaction,
        originalMonthStart: Date? = nil,
        fullyPaidAmountAfterTransfer: Double? = nil
    ) {
        switch request.editScope {
        case .normal:
            if editedTransaction == nil {
                modelContext.insert(transaction)
            } else if let originalMonthStart, !Calendar.current.isDate(originalMonthStart, equalTo: transaction.monthStart, toGranularity: .month) {
                movePaymentsAndHistory(for: transaction, from: originalMonthStart, to: transaction.monthStart)
            }
        case .singleMonth:
            if let editedTransaction {
                let paymentToTransfer = payment(for: editedTransaction, in: request.month)
                let historyToTransfer = paymentHistoryEntries(for: editedTransaction, in: request.month)
                addExclusion(for: editedTransaction, in: request.month)
                deletePayments(for: editedTransaction, from: request.month, onlySameMonth: true)
                deletePaymentHistory(for: editedTransaction, from: request.month, onlySameMonth: true)
                transferPayment(
                    paymentToTransfer,
                    history: historyToTransfer,
                    to: transaction,
                    in: transaction.monthStart,
                    fullyPaidAmount: fullyPaidAmountAfterTransfer
                )
            }
            modelContext.insert(transaction)
        case .futureMonths:
            if let editedTransaction {
                editedTransaction.recurrenceEndMonthStart = request.month.monthStart
                deletePayments(for: editedTransaction, from: request.month, onlySameMonth: false)
                deletePaymentHistory(for: editedTransaction, from: request.month, onlySameMonth: false)
            }
            modelContext.insert(transaction)
        }
    }

    private func markAsFullyPaidIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        guard canMarkExpenseAsPaid, markExpenseAsPaid else { return }

        let paymentMonth = transaction.monthStart.monthStart
        let accountID = transaction.accountID ?? resolvedSpendAccountID
        transaction.accountID = accountID
        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: paymentMonth, toGranularity: .month) }) {
            payment.amountPaid = value
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: paymentMonth, amountPaid: value))
        }
        let historyEntry = PaymentHistoryEntry(transactionID: transaction.id, monthStart: paymentMonth, amount: value, accountID: accountID)
        modelContext.insert(historyEntry)
        insertExpenseAccountMovement(for: transaction, historyEntry: historyEntry, amount: value)
        insertAuditLog(
            action: .expensePaymentCreated,
            title: transaction.displayName,
            details: transaction.detailText(in: paymentMonth),
            amount: -value,
            balanceAfter: totalAvailableBalanceForAudit - value,
            accountID: accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            date: historyEntry.paidAt
        )
    }

    private func keepEditedPaidExpenseFullyPaidIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        guard hasConfirmedValueAbovePaid, request.editScope != .singleMonth else { return }

        let paymentMonth = transaction.monthStart.monthStart
        let currentPaid = payment(for: transaction, in: paymentMonth)?.amountPaid ?? paidAmountForEditedMonth
        let additionalPaidAmount = value - currentPaid
        guard additionalPaidAmount > 0 else { return }

        if let payment = payment(for: transaction, in: paymentMonth) {
            payment.amountPaid = value
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: paymentMonth, amountPaid: value))
        }
        let accountID = transaction.accountID ?? resolvedSpendAccountID
        transaction.accountID = accountID
        let historyEntry = PaymentHistoryEntry(transactionID: transaction.id, monthStart: paymentMonth, amount: additionalPaidAmount, accountID: accountID)
        modelContext.insert(historyEntry)
        insertExpenseAccountMovement(for: transaction, historyEntry: historyEntry, amount: additionalPaidAmount)
        insertAuditLog(
            action: .expensePaymentCreated,
            title: transaction.displayName,
            details: transaction.detailText(in: paymentMonth),
            amount: -additionalPaidAmount,
            balanceAfter: totalAvailableBalanceForAudit - additionalPaidAmount,
            accountID: accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            date: historyEntry.paidAt
        )
    }

    private func syncIncomeAccountMovementIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        guard transaction.kind == TransactionKind.income.rawValue,
              let accountID = transaction.accountID
        else {
            deleteIncomeAccountMovementIfNeeded(for: transaction)
            return
        }

        if transaction.isRecurring {
            syncDueRecurringIncomeAccountMovements(for: transaction, accountID: accountID)
            return
        }

        let incomeDate = transaction.receivedDate(in: transaction.monthStart)
        guard Calendar.current.startOfDay(for: incomeDate) <= Calendar.current.startOfDay(for: Date()) else {
            deleteIncomeAccountMovementIfNeeded(for: transaction)
            return
        }

        let note = transaction.displayName
        if let movement = accountMovements.first(where: { $0.transactionID == transaction.id && $0.kind == .income }) {
            movement.accountID = accountID
            movement.date = accountMovementDate(on: incomeDate, preservingTimeFrom: movement.date)
            movement.amount = value
            movement.note = note
        } else {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                transactionID: transaction.id,
                date: accountMovementDate(on: incomeDate, preservingTimeFrom: Date()),
                type: AccountMovementKind.income.rawValue,
                amount: value,
                note: note
            ))
        }
        transaction.autoMarkPaidOnDay = false
    }

    private func syncDueRecurringIncomeAccountMovements(for transaction: MoneyTransaction, accountID: UUID) {
        guard let account = spendAccounts.first(where: { $0.id == accountID }) else { return }

        let now = Date()
        let calendar = Calendar.current
        let calculator = MoneyCalculationService(
            transactions: [transaction],
            payments: [],
            exclusions: exclusions
        )
        var existingOccurrenceKeys = Set(
            accountMovements
                .filter { $0.transactionID == transaction.id && $0.kind == .income }
                .map { calendar.startOfDay(for: $0.date) }
        )

        calculator
            .recurringIncomeOccurrencesDue(
                onOrAfter: calendar.startOfDay(for: account.createdAt),
                through: now
            )
            .forEach { occurrence in
                let occurrenceDate = calendar.startOfDay(for: occurrence.receivedDate)
                guard !existingOccurrenceKeys.contains(occurrenceDate) else { return }

                modelContext.insert(AccountMovement(
                    accountID: accountID,
                    transactionID: transaction.id,
                    date: occurrence.receivedDate,
                    type: AccountMovementKind.income.rawValue,
                    amount: occurrence.amount,
                    note: transaction.displayName
                ))
                existingOccurrenceKeys.insert(occurrenceDate)
            }
    }

    private func accountMovementDate(on date: Date, preservingTimeFrom sourceDate: Date) -> Date {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute, .second], from: sourceDate)
        return calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: date
        ) ?? date
    }

    private func deleteIncomeAccountMovementIfNeeded(for transaction: MoneyTransaction) {
        accountMovements
            .filter { $0.transactionID == transaction.id && $0.kind == .income }
            .forEach(modelContext.delete)
    }

    private func insertExpenseAccountMovement(for transaction: MoneyTransaction, historyEntry: PaymentHistoryEntry, amount: Double) {
        guard let accountID = historyEntry.accountID ?? transaction.accountID else { return }
        modelContext.insert(AccountMovement(
            accountID: accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            date: historyEntry.paidAt,
            type: AccountMovementKind.expensePayment.rawValue,
            amount: -amount,
            note: historyEntry.note ?? transaction.displayName
        ))
    }

    private func syncEditedExpensePaymentAccountIfNeeded(
        _ transaction: MoneyTransaction,
        originalAccountID: UUID?
    ) {
        guard request.editScope == .normal,
              editedTransaction != nil,
              let accountID = transaction.accountID,
              originalAccountID != accountID
        else { return }

        let editedMonth = transaction.monthStart.monthStart
        let entries = paymentHistory.filter {
            $0.transactionID == transaction.id
                && Calendar.current.isDate($0.monthStart, equalTo: editedMonth, toGranularity: .month)
        }

        entries.forEach { entry in
            entry.accountID = accountID
            accountMovements
                .filter { $0.paymentHistoryID == entry.id && $0.kind == .expensePayment }
                .forEach { $0.accountID = accountID }
        }
    }

    private func syncLinkedCreditPaymentIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        let shouldLinkPayment = mode.needsExpenseClassification && isDebtAmortizationExpense && selectedCreditID != nil

        guard shouldLinkPayment, let selectedCreditID else {
            deleteLinkedCreditMovementIfNeeded(for: transaction)
            transaction.linkedCreditID = nil
            transaction.linkedCreditMovementID = nil
            return
        }

        transaction.linkedCreditID = selectedCreditID

        let paidAmount = paidAmountForLinkedMovement(transaction, value: value)

        guard paidAmount > 0 else {
            deleteLinkedCreditMovementIfNeeded(for: transaction)
            transaction.linkedCreditMovementID = nil
            return
        }

        let paymentDate = transaction.monthStart.date(day: transaction.day)
        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let movementID = transaction.linkedCreditMovementID,
           let movement = creditMovements.first(where: { $0.id == movementID }) {
            movement.creditID = selectedCreditID
            movement.date = paymentDate
            movement.type = CreditMovementKind.payment.rawValue
            movement.amount = paidAmount
            movement.note = note
            movement.linkedTransactionID = transaction.id
            movement.linkedTransactionMonthStart = transaction.monthStart.monthStart
            movement.linkedTransactionOccurrenceDay = transaction.recurrence == .weekly ? transaction.day : nil
        } else {
            let movement = CreditMovement(
                creditID: selectedCreditID,
                date: paymentDate,
                type: CreditMovementKind.payment.rawValue,
                amount: paidAmount,
                note: note,
                linkedTransactionID: transaction.id,
                linkedTransactionMonthStart: transaction.monthStart.monthStart,
                linkedTransactionOccurrenceDay: transaction.recurrence == .weekly ? transaction.day : nil
            )
            modelContext.insert(movement)
            transaction.linkedCreditMovementID = movement.id
        }
    }

    private func deleteLinkedCreditMovementIfNeeded(for transaction: MoneyTransaction) {
        guard let movementID = transaction.linkedCreditMovementID,
              let movement = creditMovements.first(where: { $0.id == movementID })
        else { return }
        modelContext.delete(movement)
    }

    private func paidAmountForLinkedMovement(_ transaction: MoneyTransaction, value: Double) -> Double {
        if canMarkExpenseAsPaid && markExpenseAsPaid {
            return value
        }

        if hasConfirmedValueAbovePaid {
            return value
        }

        let paymentMonth = transaction.monthStart.monthStart
        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: paymentMonth, toGranularity: .month) }) {
            return min(payment.amountPaid ?? value, value)
        }

        if request.editScope == .singleMonth, let editedTransaction, let transferredPayment = payment(for: editedTransaction, in: request.month) {
            return min(transferredPayment.amountPaid ?? value, value)
        }

        return 0
    }

    private func syncLinkedSavingDepositIfNeeded(_ transaction: MoneyTransaction, value: Double) {
        let shouldLinkDeposit = mode.needsExpenseClassification && isSavingExpense && selectedSavingID != nil

        guard shouldLinkDeposit, let selectedSavingID else {
            deleteLinkedSavingMovementIfNeeded(for: transaction)
            transaction.linkedSavingID = nil
            transaction.linkedSavingMovementID = nil
            return
        }

        transaction.linkedSavingID = selectedSavingID

        let paidAmount = paidAmountForLinkedMovement(transaction, value: value)

        guard paidAmount > 0 else {
            deleteLinkedSavingMovementIfNeeded(for: transaction)
            transaction.linkedSavingMovementID = nil
            return
        }

        let depositDate = transaction.monthStart.date(day: transaction.day)
        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let movementID = transaction.linkedSavingMovementID,
           let movement = savingMovements.first(where: { $0.id == movementID }) {
            movement.savingID = selectedSavingID
            movement.date = depositDate
            movement.type = SavingMovementKind.deposit.rawValue
            movement.amount = paidAmount
            movement.note = note
            movement.linkedTransactionID = transaction.id
            movement.linkedTransactionMonthStart = transaction.monthStart.monthStart
            movement.linkedTransactionOccurrenceDay = transaction.recurrence == .weekly ? transaction.day : nil
        } else {
            let movement = SavingMovement(
                savingID: selectedSavingID,
                date: depositDate,
                type: SavingMovementKind.deposit.rawValue,
                amount: paidAmount,
                note: note,
                linkedTransactionID: transaction.id,
                linkedTransactionMonthStart: transaction.monthStart.monthStart,
                linkedTransactionOccurrenceDay: transaction.recurrence == .weekly ? transaction.day : nil
            )
            modelContext.insert(movement)
            transaction.linkedSavingMovementID = movement.id
        }
    }

    private func deleteLinkedSavingMovementIfNeeded(for transaction: MoneyTransaction) {
        guard let movementID = transaction.linkedSavingMovementID,
              let movement = savingMovements.first(where: { $0.id == movementID })
        else { return }
        modelContext.delete(movement)
    }

    private func payment(for transaction: MoneyTransaction, in month: Date) -> ExpensePayment? {
        payments.first { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
    }

    private func paymentHistoryEntries(for transaction: MoneyTransaction, in month: Date) -> [PaymentHistoryEntry] {
        paymentHistory.filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
    }

    private func transferPayment(
        _ payment: ExpensePayment?,
        history: [PaymentHistoryEntry],
        to transaction: MoneyTransaction,
        in month: Date,
        fullyPaidAmount: Double? = nil
    ) {
        let transferredAmount = payment?.amountPaid ?? 0
        let amountToStore = max(transferredAmount, fullyPaidAmount ?? transferredAmount)
        if amountToStore > 0 {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: month.monthStart, amountPaid: amountToStore))
        }

        history.forEach { entry in
            let accountID = transaction.accountID ?? entry.accountID ?? resolvedSpendAccountID
            transaction.accountID = accountID
            let newEntry = PaymentHistoryEntry(
                transactionID: transaction.id,
                monthStart: month.monthStart,
                amount: entry.amount,
                paidAt: entry.paidAt,
                note: entry.note,
                accountID: accountID
            )
            newEntry.id = entry.id
            modelContext.insert(newEntry)
            insertExpenseAccountMovement(for: transaction, historyEntry: newEntry, amount: entry.amount)
        }

        let additionalPaidAmount = amountToStore - transferredAmount
        if additionalPaidAmount > 0 {
            let accountID = transaction.accountID ?? resolvedSpendAccountID
            transaction.accountID = accountID
            let historyEntry = PaymentHistoryEntry(
                transactionID: transaction.id,
                monthStart: month.monthStart,
                amount: additionalPaidAmount,
                accountID: accountID
            )
            modelContext.insert(historyEntry)
            insertExpenseAccountMovement(for: transaction, historyEntry: historyEntry, amount: additionalPaidAmount)
        }
    }

    private func movePaymentsAndHistory(for transaction: MoneyTransaction, from oldMonth: Date, to newMonth: Date) {
        payments
            .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: oldMonth, toGranularity: .month) }
            .forEach { $0.monthStart = newMonth.monthStart }

        let movedHistoryEntries = paymentHistory
            .filter { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: oldMonth, toGranularity: .month) }
        let movedHistoryIDs = Set(movedHistoryEntries.map(\.id))
        let movedPaymentDate = newMonth.monthStart.date(day: transaction.effectiveDay(in: newMonth))

        movedHistoryEntries.forEach { $0.monthStart = newMonth.monthStart }
        accountMovements
            .filter { movement in
                guard let paymentHistoryID = movement.paymentHistoryID else { return false }
                return movedHistoryIDs.contains(paymentHistoryID)
            }
            .forEach { movement in
                movement.date = accountMovementDate(on: movedPaymentDate, preservingTimeFrom: movement.date)
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

    private func deletePaymentHistory(for transaction: MoneyTransaction, from month: Date, onlySameMonth: Bool) {
        paymentHistory
            .filter { entry in
                entry.transactionID == transaction.id && (onlySameMonth
                    ? Calendar.current.isDate(entry.monthStart, equalTo: month, toGranularity: .month)
                    : entry.monthStart >= month.monthStart)
            }
            .forEach { entry in
                accountMovements
                    .filter { $0.paymentHistoryID == entry.id }
                    .forEach(modelContext.delete)
                modelContext.delete(entry)
            }
    }
}

struct DayPicker: View {
    @Environment(\.dismiss) private var dismiss
    let month: Date
    @Binding var selectedDay: Int
    var allowsWholeMonthExpense = false
    var isWholeMonthExpenseSelected = false
    var onSelection: ((Int) -> Void)? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(1...month.daysInMonth, id: \.self) { day in
                        Button {
                            selectedDay = day
                            onSelection?(day)
                            dismiss()
                        } label: {
                            Text("\(day)")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 42)
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

                if allowsWholeMonthExpense {
                    Button {
                        selectedDay = 0
                        onSelection?(0)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isWholeMonthExpenseSelected ? "checkmark.square.fill" : "square")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(isWholeMonthExpenseSelected ? AppPalette.primary : AppPalette.mutedText)
                                .frame(width: 28, height: 28)

                            Text(AppStrings.text(.noSpecificDay))
                                .font(.headline)
                                .foregroundStyle(AppPalette.background)

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12).stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }

                Spacer(minLength: 0)
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .environment(\.locale, SpendWiseRegionalFormat.locale)
            .environment(\.calendar, SpendWiseRegionalFormat.calendar)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(AppPalette.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
            }
        }
        .presentationDetents([.height(allowsWholeMonthExpense ? 490 : 420)])
        .presentationDragIndicator(.visible)
    }
}

struct TransactionDatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    var title = AppStrings.text(.day)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(title, selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppPalette.primary)
                    .padding(.horizontal)
                    .padding(.top, 0)
                    .environment(\.locale, SpendWiseRegionalFormat.locale)
                    .environment(\.calendar, SpendWiseRegionalFormat.calendar)

                Spacer(minLength: 0)
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .environment(\.locale, SpendWiseRegionalFormat.locale)
            .environment(\.calendar, SpendWiseRegionalFormat.calendar)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
    }
}

private struct ExpenseCategorySegmentedPicker: View {
    @Binding var selection: ExpenseCategory?

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(ExpenseCategory.allCases) { category in
                    Button {
                        select(category)
                    } label: {
                        Text(category.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(1)
                            .allowsTightening(true)
                            .padding(.horizontal, 6)
                            .foregroundStyle(selection == category ? AppPalette.surface : AppPalette.background)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background {
                                if selection == category {
                                    selectedSegmentBackground(for: category)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == category ? .isSelected : [])
                }
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        selectCategory(at: value.location.x, width: proxy.size.width)
                    }
            )
            .padding(4)
            .segmentContainerBackground()
        }
        .frame(height: 52)
    }

    @ViewBuilder
    private func selectedSegmentBackground(for category: ExpenseCategory) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Capsule()
                .fill(category.color.opacity(0.78))
                .glassEffect(.regular.tint(category.color).interactive(), in: Capsule())
        } else {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [category.color.opacity(0.92), category.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Capsule()
                        .stroke(AppPalette.surface.opacity(0.55), lineWidth: 1)
                }
                .shadow(color: category.color.opacity(0.25), radius: 6, y: 2)
        }
    }

    private func select(_ category: ExpenseCategory) {
        withAnimation(.snappy(duration: 0.18)) {
            selection = category
        }
    }

    private func selectCategory(at locationX: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let segmentWidth = width / CGFloat(ExpenseCategory.allCases.count)
        let rawIndex = Int((locationX / segmentWidth).rounded(.down))
        let index = min(max(rawIndex, 0), ExpenseCategory.allCases.count - 1)
        let category = ExpenseCategory.allCases[index]

        guard selection != category else { return }
        select(category)
    }
}

private extension View {
    @ViewBuilder
    func segmentContainerBackground() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .glassEffect(.regular.interactive(), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AppPalette.surface.opacity(0.55), lineWidth: 1)
                }
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AppPalette.surface.opacity(0.75), lineWidth: 1)
                }
                .shadow(color: AppPalette.background.opacity(0.06), radius: 8, y: 3)
        }
    }
}

private enum SpendWiseRegionalFormat {
    static var locale: Locale {
        Locale(identifier: AppStrings.currentLocaleIdentifier)
    }

    static var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = locale
        return calendar
    }
}

private extension Date {
    var regionMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = SpendWiseRegionalFormat.locale
        formatter.calendar = SpendWiseRegionalFormat.calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        let title = formatter.string(from: self)
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}
