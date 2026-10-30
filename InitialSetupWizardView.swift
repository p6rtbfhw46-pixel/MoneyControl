//
//  InitialSetupWizardView.swift
//  MoneyControl
//

import Charts
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct InitialSetupWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
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
    @Query private var planningItemTypes: [PlanningItemType]
    @Query private var planningItems: [PlanningItem]
    @Query private var planningMovements: [PlanningMovement]

    let onFinish: () -> Void

    @State private var step = 0
    @State private var direction = 1
    @State private var validationMessage: String?
    @State private var incomeDraft = SetupIncomeDraft()
    @State private var expenseDraft = SetupExpenseDraft()
    @State private var incomes: [SetupIncomeDraft] = []
    @State private var expenses: [SetupExpenseDraft] = []
    @State private var budgetDrafts = SetupBudgetCategoryDraft.defaults
    @State private var manualBudgetDraft: SetupBudgetCategoryDraft?
    @State private var createdBudgetExpenses: [SetupExpenseDraft] = []
    @State private var showsManualBudgetAmountEditor = false
    @State private var showsIncomeRecurringDetails = false
    @State private var showsIncomeDayPicker = false
    @State private var showsExpenseDayPicker = false
    @State private var showsExpenseRecurrenceEditor = false
    @State private var isImportingBackup = false
    @State private var pendingEncryptedBackup: EncryptedSpendWiseBackup?
    @State private var importPassword = ""
    @State private var showsImportPasswordPrompt = false
    @State private var backupNotice: BackupNotice?

    private let stepCount = 5
    private let incomeStepBottomID = "incomeStepBottom"

    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var availableBalance: Double {
        totalIncome - totalExpenses
    }

    private var totalBudgetDraftAmount: Double {
        budgetDrafts.reduce(0) { $0 + $1.amount }
    }

    private var budgetRemaining: Double {
        max(totalIncome - totalBudgetDraftAmount, 0)
    }

    private var totalBudgetCreatedAmount: Double {
        createdBudgetExpenses.reduce(0) { $0 + $1.amount }
    }

    private var createdBudgetRemaining: Double {
        max(totalIncome - totalBudgetCreatedAmount, 0)
    }

    private var expenseCategoryTotals: [SetupCategoryTotal] {
        ExpenseCategory.allCases.map { category in
            SetupCategoryTotal(
                category: category,
                amount: expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            )
        }
    }

    private var bodyAnalysis: String {
        guard totalIncome > 0 else {
            return AppStrings.text(.budgetAnalysisNoIncome)
        }

        let needsRatio = categoryRatio(.needs)
        let wantsRatio = categoryRatio(.wants)
        let savingsRatio = categoryRatio(.savingsAndDebt)

        if needsRatio > 0.50 {
            return AppStrings.text(.budgetAnalysisNeedsHigh)
        }

        if savingsRatio < 0.20 {
            return AppStrings.text(.budgetAnalysisSavingsLow)
        }

        if wantsRatio <= 0.30 && needsRatio <= 0.50 && savingsRatio >= 0.20 {
            return AppStrings.text(.budgetAnalysisExcellent)
        }

        return AppStrings.text(.budgetAnalysisHealthy)
    }

    var body: some View {
        ZStack {
            AppPalette.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, validationMessage == nil ? 10 : 6)

                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ZStack {
                    currentStepView
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: direction >= 0 ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: direction >= 0 ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
                .animation(.snappy, value: step)
                .animation(.snappy, value: validationMessage)

                footer
                    .padding(.horizontal, 20)
                    .padding(.bottom, step == stepCount - 1 ? 22 : 14)
                    .background(AppPalette.appBackground)
            }
        }
        .preferredColorScheme(.light)
        .id(selectedCurrencyCode)
        .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [.json]) { result in
            handleBackupImportResult(result)
        }
        .alert("Backup encriptado", isPresented: $showsImportPasswordPrompt) {
            SecureField("Palavra-passe", text: $importPassword)
            Button(AppStrings.text(.cancel), role: .cancel) {
                pendingEncryptedBackup = nil
                importPassword = ""
            }
            Button(AppStrings.text(.importBackup)) {
                decryptAndImportPendingBackup()
            }
        } message: {
            Text("Introduza a palavra-passe usada ao exportar este backup.")
        }
        .alert(backupNotice?.title ?? "", isPresented: Binding(
            get: { backupNotice != nil },
            set: { if !$0 { backupNotice = nil } }
        )) {
            Button(AppStrings.text(.ok)) { backupNotice = nil }
        } message: {
            Text(backupNotice?.message ?? "")
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(step + 1)/\(stepCount)")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text(AppStrings.text(.setupProgressTitle))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.mutedText)
            }

            GeometryReader { proxy in
                let progress = CGFloat(stepCount > 0 ? Double(step + 1) / Double(stepCount) : 0)
                let clampedProgress = min(max(progress.isFinite ? progress : 0, 0), 1)
                let safeWidth = max(proxy.size.width, 0)
                ZStack(alignment: .leading) {
                    Capsule().fill(AppPalette.separator)
                    Capsule()
                        .fill(AppPalette.primary)
                        .frame(width: safeWidth * clampedProgress)
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 0:
            incomeStep
        case 1:
            monthlyBudgetStep
        case 2:
            budgetSummaryStep
        case 3:
            expenseStep
        default:
            summaryStep
        }
    }

    private var incomeStep: some View {
        ScrollViewReader { scrollProxy in
            VStack(spacing: 0) {
                wizardScroll {
                    stepTitle(
                        title: AppStrings.text(.setupWelcomeTitle),
                        subtitle: AppStrings.text(.setupWelcomeSubtitle)
                    )

                    inputCard(title: AppStrings.text(.setupIncomeCardTitle), systemImage: "banknote.fill", tint: AppPalette.positive) {
                        Text("Pode adicionar um valor inicial ou configurar um rendimento recorrente.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.mutedText)
                            .fixedSize(horizontal: false, vertical: true)

                        MoneyAmountPicker(title: AppStrings.text(.value), amount: $incomeDraft.amount, maximumAmount: 1_000_000) {
                            addIncomeAndScroll(scrollProxy)
                        }

                        Toggle("Rendimento Recorrente", isOn: $incomeDraft.isRecurring)
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)
                            .tint(AppPalette.positive)
                            .padding(12)
                            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: incomeDraft.isRecurring) { _, isRecurring in
                                withAnimation(.snappy) {
                                    showsIncomeRecurringDetails = isRecurring
                                }
                            }

                        if incomeDraft.isRecurring {
                            incomeRecurringSummaryCard
                        }
                    }

                    draftList(title: AppStrings.text(.addedIncomes), drafts: incomes.map { $0.listText }, emptyText: AppStrings.text(.noAddedIncomes)) { index in
                        incomes.remove(at: index)
                    }

                    noteCard(AppStrings.text(.setupIncomeNote))
                        .id(incomeStepBottomID)

                    backupImportCard
                }

                fixedWizardActionButton(
                    title: AppStrings.text(.add),
                    systemImage: "plus.circle.fill",
                    tint: AppPalette.background
                ) {
                    addIncomeAndScroll(scrollProxy)
                }
            }
        }
        .fullScreenCover(isPresented: $showsIncomeRecurringDetails) {
            NavigationStack {
                ScrollView {
                    incomeRecurringDetailsArea
                        .padding(20)
                }
                .background(AppPalette.appBackground)
                .navigationTitle("Rendimento recorrente")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(AppStrings.text(.ok)) {
                            showsIncomeRecurringDetails = false
                        }
                    }
                }
            }
        }
    }

    private var backupImportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "externaldrive.badge.icloud")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 38, height: 38)
                    .background(AppPalette.background, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Já tem um backup?")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)

                    Text("Pode importar um ficheiro de backup da SpendWise e continuar com os seus dados anteriores.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                isImportingBackup = true
            } label: {
                Label(AppStrings.text(.importBackup), systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }

    private var incomeTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SetupIncomeType.allCases) { type in
                    Button {
                        incomeDraft.selectedType = type
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.iconName)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(incomeDraft.selectedType == type ? AppPalette.surface : AppPalette.background)
                                .frame(width: 46, height: 46)
                                .background(
                                    incomeDraft.selectedType == type
                                        ? AppPalette.background
                                        : AppPalette.background.opacity(0.10),
                                    in: Circle()
                                )

                            Text(type.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.background)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 82)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(
                            incomeDraft.selectedType == type
                                ? AppPalette.mintSurface
                                : AppPalette.appBackground,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var incomeRecurringSummaryCard: some View {
        Button {
            showsIncomeRecurringDetails = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 32, height: 32)
                        .background(AppPalette.background, in: Circle())

                    Text(AppStrings.text(.recurrence))
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.primary)
                        .frame(width: 34, height: 34)
                        .background(AppPalette.primary.opacity(0.12), in: Circle())
                }

                Text(incomeDraft.listText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(AppPalette.background.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var incomeRecurringDetailsArea: some View {
        VStack(alignment: .leading, spacing: 14) {
            incomeTypePicker

            if incomeDraft.selectedType == .other {
                TextField(AppStrings.text(.name), text: $incomeDraft.customName, prompt: Text(AppStrings.text(.incomeNamePrompt)).foregroundStyle(AppPalette.secondaryText))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppPalette.background)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
            }

            TextField("Descrição", text: $incomeDraft.description, prompt: Text("Descrição").foregroundStyle(AppPalette.secondaryText))
                .textFieldStyle(.plain)
                .foregroundStyle(AppPalette.background)
                .textInputAutocapitalization(.sentences)
                .padding(12)
                .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))

            incomeRecurrencePicker

            if incomeDraft.recurrenceType != .weekly {
                incomeReceivedDayPicker
            }

            incomeBudgetAllocationPicker
        }
    }

    private var incomeRecurrencePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "repeat.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.background, in: Circle())

                Text(AppStrings.text(.recurrence))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RecurrenceType.incomeSelectableCases) { recurrence in
                        incomeOptionCard(
                            title: recurrence.title,
                            systemImage: recurrenceIconName(for: recurrence),
                            isSelected: incomeDraft.recurrenceType == recurrence
                        ) {
                            incomeDraft.recurrenceType = recurrence
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if incomeDraft.recurrenceType == .weekly {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(1...7, id: \.self) { weekday in
                            incomeOptionCard(
                                title: weekdayName(for: weekday),
                                systemImage: "calendar",
                                isSelected: incomeDraft.weekday == weekday
                            ) {
                                incomeDraft.weekday = weekday
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if incomeDraft.recurrenceType != .monthly && incomeDraft.recurrenceType != .weekly {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(1...12, id: \.self) { month in
                            incomeOptionCard(
                                title: Date.monthName(forMonthNumber: month),
                                systemImage: "calendar",
                                isSelected: incomeDraft.recurrenceMonth == month
                            ) {
                                incomeDraft.recurrenceMonth = month
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(AppPalette.background.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
        }
    }

    private var incomeReceivedDayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.background, in: Circle())

                Text("Dia em que é recebido")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }

            LazyVGrid(columns: incomeOptionGridColumns, spacing: 10) {
                incomeOptionCard(
                    title: "Hoje",
                    systemImage: "calendar",
                    isSelected: incomeDraft.day == currentIncomeDay,
                    fixedWidth: false,
                    iconText: "\(currentIncomeDay)"
                ) {
                    incomeDraft.day = currentIncomeDay
                    showsIncomeDayPicker = false
                }

                incomeOptionCard(
                    title: "Outro dia",
                    systemImage: "calendar.badge.plus",
                    isSelected: incomeDraft.day > 0 && incomeDraft.day != currentIncomeDay,
                    fixedWidth: false,
                    iconText: incomeDraft.day > 0 && incomeDraft.day != currentIncomeDay ? "\(incomeDraft.day)" : nil
                ) {
                    withAnimation(.snappy) {
                        showsIncomeDayPicker.toggle()
                    }
                }
            }

            if showsIncomeDayPicker {
                inlineIncomeDayPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text(incomeDayDescription)
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

    private var inlineIncomeDayPicker: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...Date().monthStart.daysInMonth, id: \.self) { day in
                Button {
                    incomeDraft.day = day
                    withAnimation(.snappy) {
                        showsIncomeDayPicker = false
                    }
                } label: {
                    Text("\(day)")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .foregroundStyle(incomeDraft.day == day ? AppPalette.surface : AppPalette.background)
                        .background(incomeDraft.day == day ? AppPalette.background : AppPalette.surface, in: RoundedRectangle(cornerRadius: 8))
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

    private var incomeBudgetAllocationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.background, in: Circle())

                Text("Mês em que é recebido")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }

            LazyVGrid(columns: incomeOptionGridColumns, spacing: 10) {
                incomeOptionCard(
                    title: "Mês atual",
                    systemImage: "calendar",
                    isSelected: incomeDraft.budgetAllocation == .currentMonth,
                    fixedWidth: false
                ) {
                    incomeDraft.budgetAllocation = .currentMonth
                }

                incomeOptionCard(
                    title: "Próximo mês",
                    systemImage: "calendar.badge.plus",
                    isSelected: incomeDraft.budgetAllocation == .nextMonth,
                    fixedWidth: false
                ) {
                    incomeDraft.budgetAllocation = .nextMonth
                }
            }

            Text(incomeBudgetAllocationDescription)
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

    private var expensePaymentDayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.background, in: Circle())

                Text("Dia em que é paga")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }

            LazyVGrid(columns: incomeOptionGridColumns, spacing: 10) {
                incomeOptionCard(
                    title: AppStrings.text(.noSpecificDay),
                    systemImage: "calendar.badge.minus",
                    isSelected: expenseDraft.day == 0,
                    fixedWidth: false
                ) {
                    expenseDraft.day = 0
                    showsExpenseDayPicker = false
                }

                incomeOptionCard(
                    title: "Hoje",
                    systemImage: "calendar",
                    isSelected: expenseDraft.day == currentIncomeDay,
                    fixedWidth: false,
                    iconText: "\(currentIncomeDay)"
                ) {
                    expenseDraft.day = currentIncomeDay
                    showsExpenseDayPicker = false
                }

                incomeOptionCard(
                    title: "Outro dia",
                    systemImage: "calendar.badge.plus",
                    isSelected: expenseDraft.day > 0 && expenseDraft.day != currentIncomeDay,
                    fixedWidth: false,
                    iconText: expenseDraft.day > 0 && expenseDraft.day != currentIncomeDay ? "\(expenseDraft.day)" : nil
                ) {
                    withAnimation(.snappy) {
                        showsExpenseDayPicker.toggle()
                    }
                }
            }

            if showsExpenseDayPicker {
                inlineExpenseDayPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text(expenseDayDescription)
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

    private var incomeOptionGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    }

    private var inlineExpenseDayPicker: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...Date().monthStart.daysInMonth, id: \.self) { day in
                Button {
                    expenseDraft.day = day
                    withAnimation(.snappy) {
                        showsExpenseDayPicker = false
                    }
                } label: {
                    Text("\(day)")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .foregroundStyle(expenseDraft.day == day ? AppPalette.surface : AppPalette.background)
                        .background(expenseDraft.day == day ? AppPalette.background : AppPalette.surface, in: RoundedRectangle(cornerRadius: 8))
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

    private func incomeOptionCard(
        title: String,
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

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.background)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
            }
            .frame(minWidth: fixedWidth ? 104 : 0, maxWidth: fixedWidth ? 104 : .infinity, minHeight: 104)
            .background(isSelected ? AppPalette.positive.opacity(0.08) : AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppPalette.positive.opacity(0.55) : AppPalette.separator, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var currentIncomeDay: Int {
        min(Calendar.current.component(.day, from: Date()), Date().monthStart.daysInMonth)
    }

    private var incomeDayDescription: String {
        if incomeDraft.day == 0 {
            return "Seleciona o dia em que o rendimento ficará disponível."
        }

        return "Neste dia o rendimento ficará disponível."
    }

    private var expenseDayDescription: String {
        if expenseDraft.day == 0 {
            return "Flexível nenhum dia para esta despesa."
        }

        return "Neste dia a despesa ficará prevista."
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

    private var monthlyBudgetStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                stepTitle(
                    title: "Orçamento mensal por categorias",
                    subtitle: "Defina rapidamente quanto pretende reservar todos os meses."
                )

                budgetAvailabilityCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .background(AppPalette.appBackground)
            .zIndex(1)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quanto pretende reservar por mês para estas áreas?")
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Defina quanto pretende gastar mensalmente em cada categoria. Estes valores serão repetidos automaticamente todos os meses, mas poderá alterá-los, adicionar novas categorias ou ajustar o orçamento mais tarde.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.bodyText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)

                    VStack(spacing: 12) {
                        ForEach($budgetDrafts) { $draft in
                            budgetSliderRow(draft: $draft)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $showsManualBudgetAmountEditor) {
            NavigationStack {
                if let budgetDraft = manualBudgetDraft,
                   let index = budgetDrafts.firstIndex(where: { $0.id == budgetDraft.id }) {
                    Form {
                        MoneyAmountPicker(
                            title: budgetDraft.title,
                            amount: Binding(
                                get: { budgetDrafts[index].amount },
                                set: { updateBudgetDraftAmount(for: budgetDraft.id, to: $0) }
                            ),
                            maximumAmount: totalIncome
                        )
                    }
                    .navigationTitle(budgetDraft.title)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") {
                                showsManualBudgetAmountEditor = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.height(260)])
        }
    }

    private func budgetSliderRow(draft: Binding<SetupBudgetCategoryDraft>) -> some View {
        let currentDraft = draft.wrappedValue
        let maximum = sliderMaximum(for: currentDraft)
        let value = Binding<Double>(
            get: { draft.wrappedValue.amount },
            set: { updateBudgetDraftAmount(for: currentDraft.id, to: $0) }
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: currentDraft.iconName)
                    .font(.headline)
                    .foregroundStyle(currentDraft.tint)
                    .frame(width: 38, height: 38)
                    .background(currentDraft.tint.opacity(0.16), in: Circle())

                Text(currentDraft.title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Button {
                    manualBudgetDraft = currentDraft
                    showsManualBudgetAmountEditor = true
                } label: {
                    Text(currentDraft.amount.currencyText)
                        .font(.headline.bold())
                        .foregroundStyle(currentDraft.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(currentDraft.tint.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Slider(value: value, in: 0...max(maximum, 1), step: 10)
                .tint(currentDraft.tint)
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }

    private var budgetAvailabilityCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "banknote.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.positive)
                    .frame(width: 38, height: 38)
                    .background(AppPalette.positive.opacity(0.16), in: Circle())

                Text("Rendimento mensal")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text(totalIncome.currencyText)
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.positive)
            }

            Divider()

            HStack(spacing: 12) {
                Image(systemName: "equal.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 38, height: 38)
                    .background(AppPalette.background.opacity(0.12), in: Circle())

                Text("Restante disponível")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text(budgetRemaining.currencyText)
                    .font(.title2.bold())
                    .foregroundStyle(budgetRemaining > 0 ? AppPalette.background : AppPalette.primary)
                    .contentTransition(.numericText())
            }

            GeometryReader { proxy in
                let ratio = CGFloat(totalIncome > 0 ? budgetRemaining / totalIncome : 0)
                let clampedRatio = min(max(ratio.isFinite ? ratio : 0, 0), 1)
                let safeWidth = max(proxy.size.width, 0)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppPalette.separator)

                    Capsule()
                        .fill(AppPalette.background)
                        .frame(width: safeWidth * clampedRatio)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }

    private var budgetSummaryStep: some View {
        wizardScroll {
            stepTitle(
                title: "O seu orçamento mensal",
                subtitle: "Criámos estas despesas mensais com base nos valores que definiu."
            )

            inputCard(title: "Despesas criadas", systemImage: "checklist.checked", tint: AppPalette.primary) {
                if createdBudgetExpenses.isEmpty {
                    Text("Não foram criadas despesas automáticas porque todos os valores estão a 0 €.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        ForEach(createdBudgetExpenses) { expense in
                            HStack(spacing: 12) {
                                Image(systemName: expense.typeIconName)
                                    .font(.headline)
                                    .foregroundStyle(expense.category.color)
                                    .frame(width: 38, height: 38)
                                    .background(expense.category.color.opacity(0.16), in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(expense.displayTitle)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppPalette.background)

                                    Text("Mensal")
                                        .font(.caption.bold())
                                        .foregroundStyle(AppPalette.mediumBlue)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Text("\(expense.amount.currencyText)/mês")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppPalette.primary)
                            }
                            .padding(12)
                            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }

            VStack(spacing: 10) {
                summaryRow("Total orçamentado", totalBudgetCreatedAmount.currencyText, AppPalette.primary)
                summaryRow("Restante disponível", createdBudgetRemaining.currencyText, AppPalette.background)
            }
            .padding(16)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)

            noteCard("Pode adicionar mais despesas agora ou continuar. Poderá alterar estes valores, adicionar novas despesas ou criar outras categorias mais tarde.")

            Button {
                direction = 1
                step = 3
            } label: {
                Label("Adicionar outra despesa", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(AppPalette.primary, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private var expenseStep: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                if horizontalSizeClass == .regular && proxy.size.width > proxy.size.height {
                    wizardScroll {
                        stepTitle(
                            title: AppStrings.text(.setupExpensesTitle),
                            subtitle: AppStrings.text(.setupExpensesSubtitle)
                        )

                        HStack(alignment: .top, spacing: 16) {
                            expenseInputCard
                                .frame(maxWidth: .infinity, alignment: .top)

                            expenseDraftList
                                .frame(maxWidth: .infinity, alignment: .top)
                        }

                        noteCard(AppStrings.text(.setupExpensesNote))
                    }
                } else {
                    wizardScroll {
                        stepTitle(
                            title: AppStrings.text(.setupExpensesTitle),
                            subtitle: AppStrings.text(.setupExpensesSubtitle)
                        )

                        expenseInputCard

                        expenseDraftList

                        noteCard(AppStrings.text(.setupExpensesNote))
                    }
                }
            }

            fixedWizardActionButton(
                title: AppStrings.text(.addExpense),
                systemImage: "plus.circle.fill",
                tint: AppPalette.primary
            ) {
                addExpense()
            }
        }
        .fullScreenCover(isPresented: $showsExpenseRecurrenceEditor) {
            NavigationStack {
                ScrollView {
                    expenseRecurrenceEditorContent
                        .padding(20)
                }
                .background(AppPalette.appBackground)
                .navigationTitle(AppStrings.text(.recurrence))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(AppStrings.text(.ok)) {
                            showsExpenseRecurrenceEditor = false
                        }
                    }
                }
            }
        }
    }

    private var expenseInputCard: some View {
        inputCard(title: AppStrings.text(.setupExpenseCardTitle), systemImage: "creditcard.fill", tint: AppPalette.primary) {
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

                SetupExpenseCategoryPicker(selection: $expenseDraft.category)

                ExpenseTypeHorizontalPicker(
                    title: AppStrings.text(.expenseType),
                    names: expenseDraft.category.names,
                    tint: expenseDraft.category.color,
                    selection: $expenseDraft.expenseName
                )

                TextField(AppStrings.text(.name), text: $expenseDraft.name, prompt: Text(AppStrings.text(.freeText)).foregroundStyle(AppPalette.secondaryText))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppPalette.background)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))

                expenseRecurrenceSummaryCard

                MoneyAmountPicker(title: AppStrings.text(.value), amount: $expenseDraft.amount, maximumAmount: 1_000_000)

            }
            .id(expenseDraft.id)
    }

    private var expenseRecurrenceSummaryCard: some View {
        Button {
            showsExpenseRecurrenceEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 32, height: 32)
                        .background(AppPalette.background, in: Circle())

                    Text(AppStrings.text(.recurrence))
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.primary)
                        .frame(width: 34, height: 34)
                        .background(AppPalette.primary.opacity(0.12), in: Circle())
                }

                Text(expenseDraft.recurrenceSummaryText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(AppPalette.background.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var expenseRecurrenceEditorContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            expenseRecurrencePicker

            if expenseDraft.recurrenceType != .weekly {
                expensePaymentDayPicker
            }
        }
    }

    private var expenseRecurrencePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "repeat.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 32, height: 32)
                    .background(AppPalette.background, in: Circle())

                Text(AppStrings.text(.recurrence))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RecurrenceType.selectableCases) { recurrence in
                        incomeOptionCard(
                            title: recurrence.title,
                            systemImage: recurrenceIconName(for: recurrence),
                            isSelected: expenseDraft.recurrenceType == recurrence
                        ) {
                            expenseDraft.recurrenceType = recurrence
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if expenseDraft.recurrenceType == .weekly {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(1...7, id: \.self) { weekday in
                            incomeOptionCard(
                                title: weekdayName(for: weekday),
                                systemImage: "calendar",
                                isSelected: expenseDraft.weekday == weekday
                            ) {
                                expenseDraft.weekday = weekday
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if expenseDraft.recurrenceType != .monthly && expenseDraft.recurrenceType != .weekly {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(1...12, id: \.self) { month in
                            incomeOptionCard(
                                title: Date.monthName(forMonthNumber: month),
                                systemImage: "calendar",
                                isSelected: expenseDraft.recurrenceMonth == month
                            ) {
                                expenseDraft.recurrenceMonth = month
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(AppPalette.background.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppPalette.background.opacity(0.18), lineWidth: 1)
        }
    }

    private var sortedExpenses: [SetupExpenseDraft] {
        expenses.sorted {
            if $0.day != $1.day {
                return $0.day < $1.day
            }

            return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
        }
    }

    private var summaryStep: some View {
        wizardScroll {
            stepTitle(
                title: AppStrings.text(.setupSummaryTitle),
                subtitle: AppStrings.text(.setupSummarySubtitle)
            )

            VStack(spacing: 10) {
                summaryRow(AppStrings.text(.receives), totalIncome.currencyText, AppPalette.positive)
                summaryRow(AppStrings.text(.fixedExpenses), totalExpenses.currencyText, AppPalette.primary)
                summaryRow(AppStrings.text(.setupAvailableThisMonth), availableBalance.currencyText, AppPalette.background)
            }
            .padding(16)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)

            noteCard(AppStrings.text(.setupFinalNote))

            inputCard(title: AppStrings.text(.visualSummary), systemImage: "chart.pie.fill", tint: AppPalette.secondary) {
                Chart {
                    BarMark(x: .value(AppStrings.text(.expenseType), AppStrings.text(.chartIncome)), y: .value(AppStrings.text(.value), totalIncome))
                        .foregroundStyle(AppPalette.positive)
                    BarMark(x: .value(AppStrings.text(.expenseType), AppStrings.text(.chartExpenses)), y: .value(AppStrings.text(.value), totalExpenses))
                        .foregroundStyle(AppPalette.primary)
                    BarMark(x: .value(AppStrings.text(.expenseType), AppStrings.text(.chartBalance)), y: .value(AppStrings.text(.value), max(availableBalance, 0)))
                        .foregroundStyle(AppPalette.background)
                }
                .frame(height: 170)
                .chartYAxis { AxisMarks(position: .leading) }

                if totalExpenses > 0 {
                    Chart(expenseCategoryTotals.filter { $0.amount > 0 }) { point in
                        SectorMark(angle: .value("Valor", point.amount), innerRadius: .ratio(0.58), angularInset: 1.5)
                            .foregroundStyle(point.category.color)
                            .cornerRadius(4)
                    }
                    .frame(height: 170)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(expenseCategoryTotals) { point in
                            HStack(spacing: 8) {
                                Circle().fill(point.category.color).frame(width: 10, height: 10)
                                Text("\(point.category.title): \(percentageText(point.amount, total: totalExpenses))")
                                    .font(.caption)
                                    .foregroundStyle(AppPalette.mutedText)
                            }
                        }
                    }
                }
            }

            inputCard(title: AppStrings.text(.automaticAnalysis), systemImage: "lightbulb.fill", tint: AppPalette.accent) {
                Text(bodyAnalysis)
                    .font(.body)
                    .foregroundStyle(AppPalette.bodyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    goBack()
                } label: {
                    Label(AppStrings.text(.back), systemImage: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16).stroke(AppPalette.separator, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(step == 0)
                .opacity(step == 0 ? 0.35 : 1)

                Button {
                    goForward()
                } label: {
                    Text(step == stepCount - 1 ? AppStrings.text(.startUsingSpendWise) : AppStrings.text(.next))
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(step == stepCount - 1 ? AppPalette.background : AppPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func wizardScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
    }

    private func fixedWizardActionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.surface)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(tint, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(AppPalette.appBackground)
    }

    private func weekdayName(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        return formatter.weekdaySymbols[min(max(weekday, 1), 7) - 1]
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func stepTitle(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(AppPalette.background)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(AppPalette.bodyText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inputCard<Content: View>(title: String, systemImage: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.16), in: Circle())

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
            }

            content()
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }

    private func draftList(title: String, drafts: [String], emptyText: String, onDelete: @escaping (Int) -> Void) -> some View {
        inputCard(title: title, systemImage: "list.bullet.rectangle", tint: AppPalette.secondary) {
            if drafts.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(drafts.enumerated()), id: \.offset) { index, text in
                        HStack(spacing: 10) {
                            Text(text)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.bodyText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                onDelete(index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(AppPalette.primary)
                                    .frame(width: 34, height: 34)
                                    .background(AppPalette.paleOrange, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var expenseDraftList: some View {
        inputCard(title: AppStrings.text(.addedExpenses), systemImage: "list.bullet.rectangle", tint: AppPalette.secondary) {
            if expenses.isEmpty {
                Text(AppStrings.text(.noAddedExpenses))
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(sortedExpenses) { expense in
                        HStack(spacing: 10) {
                            Image(systemName: expense.typeIconName)
                                .font(.headline)
                                .foregroundStyle(AppPalette.background)
                                .frame(width: 38, height: 38)
                                .background(AppPalette.secondary.opacity(0.25), in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(expense.displayTitle)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppPalette.background)
                                    .lineLimit(1)

                                HStack(spacing: 0) {
                                    if expense.recurrenceType == .weekly {
                                        Text(expense.recurrenceSummary)
                                            .font(.caption.bold())
                                    } else if expense.day <= 0 {
                                        Text(AppStrings.text(.monthExpense))
                                            .font(.caption.bold())
                                    } else {
                                        Text("\(AppStrings.text(.day)) ")
                                            .font(.caption)
                                        Text("\(expense.day)")
                                            .font(.caption.bold())
                                        Text(" - \(expense.recurrenceSummary)")
                                            .font(.caption)
                                    }
                                }
                                .foregroundStyle(AppPalette.mediumBlue)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(expense.amount.currencyText)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppPalette.primary)

                            Button {
                                expenses.removeAll { $0.id == expense.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(AppPalette.primary)
                                    .frame(width: 34, height: 34)
                                    .background(AppPalette.paleOrange, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func noteCard(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(AppPalette.mutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppPalette.mintSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }

    private func summaryRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppPalette.bodyText)
            Spacer()
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(color)
        }
    }

    @discardableResult
    private func addIncome() -> Bool {
        validationMessage = nil
        let name = incomeDraft.resolvedName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            validationMessage = AppStrings.text(.incomeNameRequired)
            return false
        }

        guard incomeDraft.amount > 0 else {
            validationMessage = AppStrings.text(.incomeValueRequired)
            return false
        }

        if incomeDraft.selectedType == .other {
            incomeDraft.customName = name
        }
        incomeDraft.description = incomeDraft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        incomes.append(incomeDraft)
        incomeDraft = SetupIncomeDraft()
        showsIncomeRecurringDetails = false
        return true
    }

    private func addIncomeAndScroll(_ scrollProxy: ScrollViewProxy) {
        guard addIncome() else { return }

        dismissKeyboard()

        Task { @MainActor in
            withAnimation(.snappy) {
                scrollProxy.scrollTo(incomeStepBottomID, anchor: .bottom)
            }
        }
    }

    private func addExpense() {
        validationMessage = nil

        guard !expenseDraft.expenseName.isEmpty else {
            validationMessage = AppStrings.text(.selectExpenseName)
            return
        }

        guard expenseDraft.category.names.contains(expenseDraft.expenseName) else {
            validationMessage = AppStrings.text(.selectExpenseName)
            return
        }

        let name = expenseDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            validationMessage = AppStrings.text(.fillFreeText)
            return
        }

        guard expenseDraft.amount > 0 else {
            validationMessage = AppStrings.text(.fillValue)
            return
        }

        expenseDraft.name = name
        expenses.append(expenseDraft)
        expenseDraft = SetupExpenseDraft()
    }

    private func goBack() {
        guard step > 0 else { return }
        validationMessage = nil
        direction = -1
        step -= 1
    }

    private func goForward() {
        validationMessage = nil

        if step == 0 {
            if incomeDraft.hasRequiredValues {
                addIncome()
            }
            guard !incomes.isEmpty else {
                validationMessage = AppStrings.text(.addIncomeToContinue)
                return
            }
        }

        if step == 1 {
            createBudgetExpensesFromDrafts()
        }

        if step == 3 {
            if expenseDraft.hasRequiredValues {
                addExpense()
            }
        }

        if step == 2 {
            direction = 1
            step = stepCount - 1
        } else if step < stepCount - 1 {
            direction = 1
            step += 1
        } else {
            saveSetup()
            onFinish()
        }
    }

    private func createBudgetExpensesFromDrafts() {
        let generatedExpenses = budgetDrafts
            .filter { $0.amount > 0 }
            .map { draft in
                SetupExpenseDraft(
                    category: draft.category,
                    expenseName: draft.expenseName,
                    name: draft.title,
                    amount: draft.amount,
                    day: 0,
                    recurrenceType: .monthly,
                    isAutomaticBudgetExpense: true
                )
            }

        createdBudgetExpenses = generatedExpenses
        expenses.removeAll { $0.isAutomaticBudgetExpense }
        expenses.append(contentsOf: generatedExpenses)
    }

    private func sliderMaximum(for draft: SetupBudgetCategoryDraft) -> Double {
        draft.amount + budgetRemaining
    }

    private func updateBudgetDraftAmount(for id: UUID, to newValue: Double) {
        guard let index = budgetDrafts.firstIndex(where: { $0.id == id }) else { return }
        let currentAmount = budgetDrafts[index].amount
        let maximum = currentAmount + budgetRemaining
        let clampedAmount = min(max(newValue, 0), maximum)
        let roundedAmount = (clampedAmount / 10).rounded() * 10

        withAnimation(.snappy(duration: 0.18)) {
            budgetDrafts[index].amount = roundedAmount
        }
    }

    private func saveSetup() {
        let setupMonthStart = Date().monthStart
        let setupYear = Calendar.current.component(.year, from: setupMonthStart)

        for income in incomes {
            let incomeMonthStart = (!income.isRecurring || income.recurrenceType == .monthly || income.recurrenceType == .weekly)
                ? setupMonthStart
                : Date.monthStart(month: income.recurrenceMonth, year: setupYear)

            modelContext.insert(MoneyTransaction(
                title: income.resolvedName,
                day: income.isRecurring && income.recurrenceType == .weekly ? income.weekday : income.day,
                monthStart: incomeMonthStart,
                amount: income.amount,
                kind: TransactionKind.income.rawValue,
                repeatsEveryMonth: income.isRecurring && income.recurrenceType == .monthly,
                incomeDescription: income.isRecurring && !income.description.isEmpty ? income.description : nil,
                recurrenceType: income.isRecurring ? income.recurrenceType.rawValue : nil,
                recurrenceMonth: (!income.isRecurring || income.recurrenceType == .monthly || income.recurrenceType == .weekly) ? 0 : income.recurrenceMonth,
                budgetAllocationType: income.budgetAllocation.rawValue,
                budgetMonthStart: income.budgetAllocation == .nextMonth ? incomeMonthStart.nextMonthStart : incomeMonthStart
            ))
        }

        for expense in expenses {
            let expenseMonthStart = (expense.recurrenceType == .monthly || expense.recurrenceType == .weekly)
                ? setupMonthStart
                : Date.monthStart(month: expense.recurrenceMonth, year: setupYear)

            modelContext.insert(MoneyTransaction(
                title: expense.name,
                day: expense.recurrenceType == .weekly ? expense.weekday : expense.day,
                monthStart: expenseMonthStart,
                amount: expense.amount,
                kind: TransactionKind.expense.rawValue,
                repeatsEveryMonth: expense.recurrenceType == .monthly,
                expenseCategory: expense.category.rawValue,
                expenseName: expense.expenseName,
                recurrenceType: expense.recurrenceType.rawValue,
                recurrenceMonth: expense.recurrenceType == .weekly ? 0 : expense.recurrenceMonth
            ))
        }
    }

    private func handleBackupImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let canAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if canAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                if let backup = try? decodedBackup(from: data) {
                    importBackup(backup)
                } else if let encryptedBackup = try? JSONDecoder().decode(EncryptedSpendWiseBackup.self, from: data) {
                    pendingEncryptedBackup = encryptedBackup
                    importPassword = ""
                    showsImportPasswordPrompt = true
                } else {
                    throw BackupError.invalidBackup
                }
            } catch {
                backupNotice = BackupNotice(
                    title: AppStrings.text(.importBackupFailureTitle),
                    message: backupErrorMessage(error)
                )
            }
        case .failure(let error):
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: error.localizedDescription
            )
        }
    }

    private func decryptAndImportPendingBackup() {
        do {
            guard let pendingEncryptedBackup else {
                throw BackupError.invalidBackup
            }
            guard !importPassword.isEmpty else {
                throw BackupError.emptyPassword
            }

            let backupData = try pendingEncryptedBackup.decrypt(password: importPassword)
            let backup = try decodedBackup(from: backupData)
            self.pendingEncryptedBackup = nil
            importPassword = ""
            importBackup(backup)
        } catch {
            modelContext.rollback()
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: backupErrorMessage(error)
            )
        }
    }

    private func importBackup(_ backup: SpendWiseBackup) {
        payments.forEach(modelContext.delete)
        paymentHistory.forEach(modelContext.delete)
        exclusions.forEach(modelContext.delete)
        transactions.forEach(modelContext.delete)
        creditMovements.forEach(modelContext.delete)
        creditAccounts.forEach(modelContext.delete)
        savingMovements.forEach(modelContext.delete)
        savingAccounts.forEach(modelContext.delete)
        accountMovements.forEach(modelContext.delete)
        spendAccounts.forEach(modelContext.delete)
        auditLogEntries.forEach(modelContext.delete)
        planningMovements.forEach(modelContext.delete)
        planningItems.forEach(modelContext.delete)
        planningItemTypes.forEach(modelContext.delete)
        plannings.forEach(modelContext.delete)

        let importedTransactions = backup.transactions.map(\.model)
        let importedPayments = backup.payments.map(\.model)
        let importedPaymentHistory = backup.paymentHistory.map(\.model)
        let importedExclusions = backup.exclusions.map(\.model)
        let importedSpendAccounts = backup.spendAccounts.map(\.model)
        let importedAccountMovements = backup.accountMovements.map(\.model)
        let importedAuditLogEntries = backup.auditLogEntries.map(\.model)

        importedTransactions.forEach(modelContext.insert)
        importedPayments.forEach(modelContext.insert)
        importedPaymentHistory.forEach(modelContext.insert)
        importedExclusions.forEach(modelContext.insert)
        backup.creditAccounts.map(\.model).forEach(modelContext.insert)
        backup.creditMovements.map(\.model).forEach(modelContext.insert)
        backup.savingAccounts.map(\.model).forEach(modelContext.insert)
        backup.savingMovements.map(\.model).forEach(modelContext.insert)
        importedSpendAccounts.forEach(modelContext.insert)
        importedAccountMovements.forEach(modelContext.insert)
        importedAuditLogEntries.forEach(modelContext.insert)
        backup.plannings.map(\.model).forEach(modelContext.insert)
        backup.planningItemTypes.map(\.model).forEach(modelContext.insert)
        backup.planningItems.map(\.model).forEach(modelContext.insert)
        backup.planningMovements.map(\.model).forEach(modelContext.insert)
        BackupAccountMigration.normalizeImportedAccounts(
            modelContext: modelContext,
            transactions: importedTransactions,
            payments: importedPayments,
            paymentHistory: importedPaymentHistory,
            exclusions: importedExclusions,
            spendAccounts: importedSpendAccounts,
            accountMovements: importedAccountMovements
        )

        do {
            try modelContext.save()
            hasCompletedInitialSetup = true
            onFinish()
        } catch {
            backupNotice = BackupNotice(
                title: AppStrings.text(.importBackupFailureTitle),
                message: error.localizedDescription
            )
        }
    }

    private func decodedBackup(from data: Data) throws -> SpendWiseBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(SpendWiseBackup.self, from: data)
        guard backup.version == SpendWiseBackup.currentVersion,
              backup.structureIdentifier == SpendWiseBackup.currentStructureIdentifier else {
            throw BackupError.unsupportedVersion
        }
        try backup.validateIntegrity()
        return backup
    }

    private func backupErrorMessage(_ error: Error) -> String {
        switch error {
        case BackupError.emptyPassword:
            return "Introduza a palavra-passe do backup."
        case BackupError.invalidPassword:
            return "Não foi possível desencriptar o backup. Confirme a palavra-passe."
        case BackupError.invalidBackup:
            return AppStrings.text(.importBackupFailureMessage)
        case BackupError.unsupportedVersion:
            return "Este backup pertence a uma versão com uma estrutura de dados diferente e não pode ser restaurado nesta versão da app."
        default:
            return error.localizedDescription
        }
    }

    private func categoryRatio(_ category: ExpenseCategory) -> Double {
        guard totalIncome > 0 else { return 0 }
        let amount = expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
        return amount / totalIncome
    }

    private func percentageText(_ amount: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }

    private func budgetAllocationTitle(for allocation: BudgetAllocation) -> String {
        switch allocation {
        case .currentMonth:
            AppStrings.text(.budgetAllocationCurrentMonth)
        case .nextMonth:
            AppStrings.text(.budgetAllocationNextMonth)
        case .custom:
            allocation.title
        }
    }

    private var incomeBudgetAllocationDescription: String {
        switch incomeDraft.budgetAllocation {
        case .currentMonth:
            "Este rendimento fica disponível para planear o orçamento deste mês."
        case .nextMonth:
            "Este rendimento entra agora, mas fica reservado para o orçamento do mês seguinte."
        case .custom:
            "Escolha o mês do orçamento onde este rendimento deve ser usado."
        }
    }
}

private enum SetupIncomeType: CaseIterable, Identifiable {
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
}

private struct SetupIncomeDraft: Identifiable {
    let id = UUID()
    var isRecurring = false
    var selectedType: SetupIncomeType = .salary
    var customName = ""
    var description = ""
    var amount = 0.0
    var budgetAllocation: BudgetAllocation = .currentMonth
    var recurrenceType: RecurrenceType = .monthly
    var day = min(Calendar.current.component(.day, from: Date()), Date().monthStart.daysInMonth)
    var weekday = Calendar.current.component(.weekday, from: Date())
    var recurrenceMonth = Calendar.current.component(.month, from: Date())

    var resolvedName: String {
        if !isRecurring {
            return "Receita inicial"
        }

        return selectedType == .other ? customName : selectedType.title
    }

    var hasRequiredValues: Bool { !resolvedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0 }

    var recurrenceDescription: String {
        if recurrenceType == .weekly {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
            let weekdayName = formatter.weekdaySymbols[min(max(weekday, 1), 7) - 1]
            return "\(recurrenceType.title) - \(weekdayName)"
        }

        if day <= 0 {
            return "\(recurrenceType.title) - \(AppStrings.text(.noSpecificDay))"
        }

        if recurrenceType == .monthly {
            return "\(recurrenceType.title) - Dia \(day)"
        }

        return "\(Date.monthName(forMonthNumber: recurrenceMonth)) - \(recurrenceType.title) - Dia \(day)"
    }

    var listText: String {
        if !isRecurring {
            return "\(resolvedName) · \(amount.currencyText)"
        }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptionPart = trimmedDescription.isEmpty ? "" : " · \(trimmedDescription)"
        return "\(resolvedName)\(descriptionPart) · \(amount.currencyText) · \(recurrenceDescription) · \(budgetAllocation.title)"
    }
}

private struct SetupExpenseDraft: Identifiable {
    let id = UUID()
    var category: ExpenseCategory = .needs {
        didSet {
            if oldValue != category {
                expenseName = ""
            }
        }
    }
    var expenseName = ""
    var name = ""
    var amount = 0.0
    var day = min(Calendar.current.component(.day, from: Date()), Date().monthStart.daysInMonth)
    var recurrenceType: RecurrenceType = .monthly
    var weekday = Calendar.current.component(.weekday, from: Date())
    var recurrenceMonth = Calendar.current.component(.month, from: Date())
    var isAutomaticBudgetExpense = false

    init(
        category: ExpenseCategory = .needs,
        expenseName: String = "",
        name: String = "",
        amount: Double = 0.0,
        day: Int = min(Calendar.current.component(.day, from: Date()), Date().monthStart.daysInMonth),
        recurrenceType: RecurrenceType = .monthly,
        weekday: Int = Calendar.current.component(.weekday, from: Date()),
        recurrenceMonth: Int = Calendar.current.component(.month, from: Date()),
        isAutomaticBudgetExpense: Bool = false
    ) {
        self.category = category
        self.expenseName = expenseName
        self.name = name
        self.amount = amount
        self.day = day
        self.recurrenceType = recurrenceType
        self.weekday = weekday
        self.recurrenceMonth = recurrenceMonth
        self.isAutomaticBudgetExpense = isAutomaticBudgetExpense
    }

    var hasRequiredValues: Bool {
        !expenseName.isEmpty && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0
    }

    var displayTitle: String {
        name.isEmpty ? expenseName : name
    }

    var typeIconName: String {
        ExpenseTypeIcon.name(for: expenseName)
    }

    var recurrenceSummary: String {
        if recurrenceType == .weekly {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
            let weekdayName = formatter.weekdaySymbols[min(max(weekday, 1), 7) - 1]
            return "\(recurrenceType.title) - \(weekdayName)"
        }

        if recurrenceType == .monthly {
            return recurrenceType.title
        }

        return "\(Date.monthName(forMonthNumber: recurrenceMonth)) - \(recurrenceType.title)"
    }

    var recurrenceSummaryText: String {
        if recurrenceType == .weekly {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
            let weekdayName = formatter.weekdaySymbols[min(max(weekday, 1), 7) - 1]
            return "\(recurrenceType.title) todas as \(weekdayName)"
        }

        let dayText = day <= 0 ? "Flexível" : "Dia \(day)"

        if recurrenceType == .monthly {
            return "\(recurrenceType.title) - \(dayText)"
        }

        return "\(recurrenceType.title) - \(Date.monthName(forMonthNumber: recurrenceMonth)) - \(dayText)"
    }
}

private struct SetupBudgetCategoryDraft: Identifiable {
    let id = UUID()
    let title: String
    let category: ExpenseCategory
    let expenseName: String
    let iconName: String
    let tint: Color
    var amount: Double

    static var defaults: [SetupBudgetCategoryDraft] {
        [
            SetupBudgetCategoryDraft(
                title: "Alimentação",
                category: .needs,
                expenseName: expenseName(in: .needs, index: 2, fallback: "Alimentação: compras de supermercado"),
                tint: AppPalette.positive
            ),
            SetupBudgetCategoryDraft(
                title: "Transportes",
                category: .needs,
                expenseName: expenseName(in: .needs, index: 1, fallback: "Transportes: transporte público, prestações e combustível"),
                tint: AppPalette.mediumBlue
            ),
            SetupBudgetCategoryDraft(
                title: "Refeições fora de casa",
                category: .wants,
                expenseName: expenseName(in: .wants, index: 0, fallback: "Refeições fora de casa"),
                tint: AppPalette.primary
            ),
            SetupBudgetCategoryDraft(
                title: "Lazer",
                category: .wants,
                expenseName: expenseName(in: .wants, index: 2, fallback: "Atividades de lazer e entretenimento"),
                tint: AppPalette.accent
            ),
            SetupBudgetCategoryDraft(
                title: "Compras",
                category: .wants,
                expenseName: expenseName(in: .wants, index: 4, fallback: "Roupa e acessórios"),
                tint: AppPalette.secondary
            ),
            SetupBudgetCategoryDraft(
                title: "Outros",
                category: .needs,
                expenseName: expenseName(in: .needs, index: 5, fallback: "Outros"),
                tint: AppPalette.mutedText
            )
        ]
    }

    init(title: String, category: ExpenseCategory, expenseName: String, tint: Color, amount: Double = 0.0) {
        self.title = title
        self.category = category
        self.expenseName = expenseName
        self.iconName = ExpenseTypeIcon.name(for: expenseName)
        self.tint = tint
        self.amount = amount
    }

    private static func expenseName(in category: ExpenseCategory, index: Int, fallback: String) -> String {
        category.names.indices.contains(index) ? category.names[index] : fallback
    }
}

private struct SetupExpenseCategoryPicker: View {
    @Binding var selection: ExpenseCategory

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
                            .minimumScaleFactor(0.82)
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
            .setupSegmentContainerBackground()
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
    func setupSegmentContainerBackground() -> some View {
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

private struct SetupCategoryTotal: Identifiable {
    let category: ExpenseCategory
    let amount: Double

    var id: String { category.rawValue }
}

#Preview {
    InitialSetupWizardView {}
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, PaymentHistoryEntry.self, RecurrenceExclusion.self, CreditAccount.self, CreditMovement.self, SavingAccount.self, SavingMovement.self], inMemory: true)
}
