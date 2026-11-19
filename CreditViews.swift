//
//  CreditViews.swift
//  MoneyControl
//

import Charts
import SwiftData
import SwiftUI

struct CreditsSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]

    @State private var editorRequest: CreditEditorRequest?
    @State private var selectedCredit: CreditAccount?
    @State private var showsSettled = false

    private var visibleCredits: [CreditAccount] {
        creditAccounts
            .filter { showsSettled || $0.creditStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if horizontalSizeClass == .compact {
                    creditsHeroImage
                }

                if creditAccounts.contains(where: { $0.creditStatus == .settled }) {
                    Toggle(CreditStrings.text(.showSettled), isOn: $showsSettled)
                        .font(.subheadline.weight(.semibold))
                        .tint(AppPalette.primary)
                        .padding(.horizontal, 4)
                }

                if visibleCredits.isEmpty {
                    ContentUnavailableView(
                        CreditStrings.text(.emptyTitle),
                        systemImage: "creditcard",
                        description: Text(CreditStrings.text(.addCredit))
                    )
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(visibleCredits) { credit in
                        Button {
                            selectedCredit = credit
                        } label: {
                            CreditSummaryCard(
                                credit: credit,
                                movements: creditMovements.filter { $0.creditID == credit.id }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    editorRequest = CreditEditorRequest()
                } label: {
                    Label(CreditStrings.text(.addCredit), systemImage: "plus.circle.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(AppPalette.appBackground)
        .sheet(item: $editorRequest) { request in
            CreditEditor(request: request)
        }
        .sheet(item: $selectedCredit) { credit in
            CreditDetailView(credit: credit)
        }
    }

    private var creditsHeroImage: some View {
        Image(AppStrings.currentLanguage == .portuguese ? "CreditHero" : "CreditHeroEnglish")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: AppPalette.background.opacity(0.10), radius: 12, y: 6)
    }
}

private struct CreditSummaryCard: View {
    let credit: CreditAccount
    let movements: [CreditMovement]

    private var balance: Double { credit.balance(with: movements) }
    private var variation: Double { credit.monthVariation(in: Date().monthStart, movements: movements) }
    private var usedRatio: Double? {
        guard let limit = credit.creditLimit, limit > 0 else { return nil }
        return min(max(balance / limit, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: credit.creditType.iconName)
                    .font(.title2)
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 46, height: 46)
                    .background(AppPalette.mintSurface, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(credit.displayName)
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                    Text(credit.creditType.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(balance.currencyText)
                        .font(.title3.bold())
                        .foregroundStyle(AppPalette.background)
                    Text(CreditStrings.text(.debt))
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                }
            }

            HStack {
                Text(variation <= 0 ? "↓ \(abs(variation).currencyText)" : "↑ \(variation.currencyText)")
                    .font(.subheadline.bold())
                    .foregroundStyle(variation <= 0 ? AppPalette.positive : AppPalette.primary)
                Text(AppStrings.text(.month).lowercased())
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                Spacer()
                if credit.creditStatus == .settled {
                    Text(credit.creditStatus.title)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.positive)
                }
            }

            if let limit = credit.creditLimit, let usedRatio {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: usedRatio)
                        .tint(usedRatio >= 0.8 ? AppPalette.primary : AppPalette.secondary)
                    HStack {
                        Text("\(balance.currencyText) / \(limit.currencyText)")
                        Spacer()
                        Text(usedRatio.formatted(.percent.precision(.fractionLength(0))))
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
                }
            }
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 6)
    }
}

struct CreditEditorRequest: Identifiable {
    let id = UUID()
    let credit: CreditAccount?

    init(credit: CreditAccount? = nil) {
        self.credit = credit
    }
}

private struct CreditEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [CreditMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var transactions: [MoneyTransaction]

    let request: CreditEditorRequest
    var onDelete: (() -> Void)? = nil

    @State private var name = ""
    @State private var details = ""
    @State private var type: CreditType = .creditCard
    @State private var currentDebt = 0.0
    @State private var creditLimit = 0.0
    @State private var status: CreditStatus = .active
    @State private var validationMessage: String?
    @State private var showsDeleteConfirmation = false
    @State private var isCreditLimitExpanded = false
    @State private var saveNotice: SaveResultNotice?

    private var isEditing: Bool { request.credit != nil }
    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: savingMovements,
            creditAccounts: creditAccounts,
            creditMovements: allMovements
        )
    }

    private func insertAuditLog(action: AuditLogAction, title: String, amount: Double = 0, balanceAfter: Double? = nil, creditID: UUID? = nil, note: String? = nil) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            details: note ?? "",
            amount: amount,
            balanceAfter: balanceAfter ?? auditBalance,
            creditID: creditID
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    creditTypePicker

                    if type == .other {
                        TextField(CreditStrings.text(.creditName), text: $name)
                            .foregroundStyle(AppPalette.background)
                            .tint(AppPalette.primary)
                    }

                    TextField(CreditStrings.text(.creditDescription), text: $details)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)

                    if isEditing {
                        Toggle(CreditStrings.text(.active), isOn: Binding(
                            get: { status == .active },
                            set: { status = $0 ? .active : .settled }
                        ))
                        .tint(AppPalette.primary)
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    if !isEditing {
                        MoneyAmountPicker(title: CreditStrings.text(.currentDebt), amount: $currentDebt, maximumAmount: 1_000_000, onConfirm: save)
                        MoneyAmountPicker(title: "\(CreditStrings.text(.creditLimit)) · \(CreditStrings.text(.optionalLimit))", amount: $creditLimit, maximumAmount: 1_000_000, onConfirm: save)
                    } else {
                        creditLimitDisclosure
                    }
                }
                .listRowBackground(AppPalette.surface)

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showsDeleteConfirmation = true
                        } label: {
                            Label(CreditStrings.text(.deleteCredit), systemImage: "trash")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(AppPalette.destructive, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(AppPalette.appBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .navigationTitle(isEditing ? CreditStrings.text(.editCredit) : CreditStrings.text(.newCredit))
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
            .onAppear(perform: loadInitialValues)
            .alert(CreditStrings.text(.deleteCreditTitle), isPresented: $showsDeleteConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.delete), role: .destructive, action: deleteCredit)
            } message: {
                Text(CreditStrings.text(.deleteCreditMessage))
            }
            .alert(item: $saveNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text(AppStrings.text(.ok))) {
                        dismiss()
                    }
                )
            }
        }
    }

    private var creditTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CreditType.allCases) { creditType in
                    creditTypeCard(creditType)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func creditTypeCard(_ creditType: CreditType) -> some View {
        let isSelected = type == creditType

        return Button {
            type = creditType
            if creditType != .other {
                name = creditType.title
            } else {
                name = ""
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: creditType.iconName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.background)
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

                Text(creditType.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.background)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(width: 112)
            .frame(minHeight: 104)
            .background(isSelected ? AppPalette.positive.opacity(0.08) : AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppPalette.positive.opacity(0.55) : AppPalette.separator, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func loadInitialValues() {
        guard let credit = request.credit else { return }
        name = credit.name
        details = credit.details
        type = credit.creditType
        currentDebt = credit.initialDebt
        creditLimit = credit.creditLimit ?? 0
        status = credit.creditStatus
    }

    private var creditLimitDisclosure: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.snappy) {
                    isCreditLimitExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(CreditStrings.text(.creditLimit))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.background)
                        Text(creditLimit > 0 ? creditLimit.currencyText : CreditStrings.text(.optionalLimit))
                            .font(.caption)
                            .foregroundStyle(AppPalette.mutedText)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mutedText)
                        .rotationEffect(.degrees(isCreditLimitExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isCreditLimitExpanded {
                MoneyAmountPicker(
                    title: "\(CreditStrings.text(.creditLimit)) · \(CreditStrings.text(.optionalLimit))",
                    amount: $creditLimit,
                    maximumAmount: 1_000_000,
                    onConfirm: save
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func save() {
        validationMessage = nil
        let rawName = type == .other ? name : type.title
        let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = CreditStrings.text(.fillCreditName)
            return
        }

        guard currentDebt > 0 || isEditing else {
            validationMessage = CreditStrings.text(.fillCreditValue)
            return
        }

        let isNewCredit = request.credit == nil
        let balanceBefore = auditBalance
        let credit = request.credit ?? CreditAccount(name: trimmedName, type: type.rawValue, initialDebt: currentDebt)
        credit.name = trimmedName
        credit.details = trimmedDetails
        credit.type = type.rawValue
        if !isEditing {
            credit.initialDebt = currentDebt
        }
        credit.creditLimit = creditLimit > 0 ? creditLimit : nil
        credit.status = status.rawValue

        if isNewCredit {
            modelContext.insert(credit)
        }

        insertAuditLog(
            action: isNewCredit ? .creditCreated : .creditUpdated,
            title: credit.displayName,
            amount: isNewCredit ? currentDebt : 0,
            balanceAfter: isNewCredit ? balanceBefore - currentDebt : auditBalance,
            creditID: credit.id,
            note: trimmedDetails.isEmpty ? nil : trimmedDetails
        )

        SaveResultNoticeCenter.shared.show(.saved(String(
            format: AppStrings.text(isNewCredit ? .creditCreatedMessage : .creditUpdatedMessage),
            credit.displayName
        )))
        dismiss()
    }

    private func deleteCredit() {
        guard let credit = request.credit else { return }
        let balanceBefore = auditBalance
        let deletedDebt = credit.balance(with: allMovements)

        insertAuditLog(
            action: .creditDeleted,
            title: credit.displayName,
            amount: deletedDebt,
            balanceAfter: balanceBefore + deletedDebt,
            creditID: credit.id,
            note: credit.details.isEmpty ? nil : credit.details
        )

        allMovements
            .filter { $0.creditID == credit.id }
            .forEach(modelContext.delete)

        transactions
            .filter { $0.linkedCreditID == credit.id }
            .forEach { transaction in
                transaction.linkedCreditID = nil
                transaction.linkedCreditMovementID = nil
            }

        modelContext.delete(credit)
        onDelete?()
        dismiss()
    }
}

struct CreditDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [CreditMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var creditAccounts: [CreditAccount]

    let credit: CreditAccount

    @State private var creditEditorRequest: CreditEditorRequest?
    @State private var movementEditorRequest: CreditMovementEditorRequest?
    @State private var isEvolutionExpanded = false
    @State private var isPaymentEstimateExpanded = false
    @State private var selectedMovementYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMovementMonth: Int? = Calendar.current.component(.month, from: Date())
    @State private var selectedCreditUsageID: String?

    private var movements: [CreditMovement] { credit.movements(from: allMovements) }
    private var balance: Double { credit.balance(with: allMovements) }
    private var monthStart: Date { Date().monthStart }
    private var monthIncrease: Double { credit.monthDebtIncrease(in: monthStart, movements: allMovements) }
    private var monthPaid: Double { credit.monthPaid(in: monthStart, movements: allMovements) }
    private var monthVariation: Double { credit.monthVariation(in: monthStart, movements: allMovements) }
    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: savingMovements,
            creditAccounts: creditAccounts,
            creditMovements: allMovements
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    debtHeader
                    if credit.creditLimit != nil { limitCard }
                    monthSummaryCard
                    if !balancePoints.isEmpty { evolutionCard }
                    if !paymentEstimatePoints.isEmpty { paymentEstimateCard }
                    settledSuggestion
                    addMovementButton
                    movementsSection
                }
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(credit.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(CreditStrings.text(.addMovement), systemImage: "plus") {
                            movementEditorRequest = CreditMovementEditorRequest(credit: credit)
                        }
                        Button(CreditStrings.text(.editCredit), systemImage: "pencil") {
                            creditEditorRequest = CreditEditorRequest(credit: credit)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $creditEditorRequest) { request in
                CreditEditor(request: request) {
                    dismiss()
                }
            }
            .sheet(item: $movementEditorRequest) { request in
                CreditMovementEditor(request: request)
            }
        }
    }

    private var debtHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(credit.displayName)
                .font(.title2.bold())
                .foregroundStyle(AppPalette.background)
            Text(balance.currencyText)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(AppPalette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(CreditStrings.text(.debt))
                .font(.headline)
                .foregroundStyle(AppPalette.mutedText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var limitCard: some View {
        let limit = credit.creditLimit ?? 0
        let available = max(limit - balance, 0)
        let ratio = limit > 0 ? min(max(balance / limit, 0), 1) : 0

        return VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: ratio)
                .tint(ratio >= 0.8 ? AppPalette.primary : AppPalette.secondary)
            infoRow(CreditStrings.text(.totalLimit), limit.currencyText)
            infoRow(CreditStrings.text(.usedValue), balance.currencyText)
            infoRow(CreditStrings.text(.availableValue), available.currencyText)
            infoRow(CreditStrings.text(.usedPercentage), ratio.formatted(.percent.precision(.fractionLength(0))))
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var monthSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CreditStrings.text(.monthSummary))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)
            summaryRow(CreditStrings.text(.currentDebt), balance.currencyText, AppPalette.background)
            summaryRow(CreditStrings.text(.newDebtThisMonth), "+\(monthIncrease.currencyText)", AppPalette.primary)
            summaryRow(CreditStrings.text(.paidThisMonth), "-\(monthPaid.currencyText)", AppPalette.positive)
            summaryRow(
                CreditStrings.text(.monthVariation),
                monthVariation <= 0 ? "↓ \(abs(monthVariation).currencyText)" : "↑ \(monthVariation.currencyText)",
                monthVariation <= 0 ? AppPalette.positive : AppPalette.primary
            )
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var evolutionCard: some View {
        collapsibleChartCard(
            title: CreditStrings.text(.debtEvolution),
            value: balance.currencyText,
            isExpanded: $isEvolutionExpanded
        ) {
            Chart(balancePoints) { point in
                LineMark(
                    x: .value(AppStrings.text(.month), point.monthLabel),
                    y: .value(CreditStrings.text(.debt), point.balance)
                )
                .foregroundStyle(AppPalette.background)

                PointMark(
                    x: .value(AppStrings.text(.month), point.monthLabel),
                    y: .value(CreditStrings.text(.debt), point.balance)
                )
                .foregroundStyle(AppPalette.primary)
            }
            .frame(height: 180)
        }
    }

    private var paymentEstimateCard: some View {
        collapsibleChartCard(
            title: CreditStrings.text(.paymentEstimateTrajectory),
            value: projectedBalanceAfterOneYear.currencyText,
            subtitle: "\(CreditStrings.text(.averageLastThreeMonths)): \(averageMonthlyPaymentLastThreeMonths.currencyText)",
            isExpanded: $isPaymentEstimateExpanded
        ) {
            Chart(paymentEstimatePoints) { point in
                LineMark(
                    x: .value(AppStrings.text(.month), point.monthLabel),
                    y: .value(CreditStrings.text(.debt), point.balance)
                )
                .foregroundStyle(AppPalette.positive)

                PointMark(
                    x: .value(AppStrings.text(.month), point.monthLabel),
                    y: .value(CreditStrings.text(.debt), point.balance)
                )
                .foregroundStyle(AppPalette.primary)
            }
            .frame(height: 180)
        }
    }

    @ViewBuilder
    private var settledSuggestion: some View {
        if balance <= 0.01 && credit.creditStatus == .active {
            VStack(alignment: .leading, spacing: 10) {
                Text(CreditStrings.text(.markSettledPrompt))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                Button(CreditStrings.text(.markAsSettled)) {
                    credit.status = CreditStatus.settled.rawValue
                    insertAuditLog(action: .creditUpdated, title: credit.displayName, creditID: credit.id)
                }
                .liquidGlassButtonStyle(prominent: true)
                .tint(AppPalette.positive)
            }
            .padding(16)
            .background(AppPalette.mintSurface, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var addMovementButton: some View {
        Button {
            movementEditorRequest = CreditMovementEditorRequest(credit: credit)
        } label: {
            Label(CreditStrings.text(.movements), systemImage: "plus.circle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.surface)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CreditStrings.text(.movements))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

            movementFilters
            movementKindFilter
            movementTotals

            if movementGroups.isEmpty {
                ContentUnavailableView(CreditStrings.text(.noMovements), systemImage: "list.bullet.rectangle")
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ForEach(movementGroups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.month.monthTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.mutedText)
                        ForEach(group.movements) { movement in
                            CreditMovementRow(
                                movement: movement,
                                onEdit: { movementEditorRequest = CreditMovementEditorRequest(credit: credit, movement: movement) },
                                onDelete: { deleteMovement(movement) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var movementFilters: some View {
        HStack(spacing: 8) {
            movementFilterPicker(title: AppStrings.text(.year)) {
                Picker(AppStrings.text(.year), selection: $selectedMovementYear) {
                    ForEach(availableMovementYears, id: \.self) { year in
                        Text(year.formatted(.number.grouping(.never))).tag(year)
                    }
                }
            }

            movementFilterPicker(title: AppStrings.text(.month)) {
                Picker(AppStrings.text(.month), selection: $selectedMovementMonth) {
                    Text(AppStrings.text(.allMonths)).tag(Optional<Int>.none)
                    ForEach(1...12, id: \.self) { month in
                        Text(Date.monthName(forMonthNumber: month)).tag(Optional(month))
                    }
                }
            }
        }
    }

    private var movementKindFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(CreditStrings.text(.movementUsageFilter))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.mutedText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    movementKindButton(
                        title: AppStrings.text(.all),
                        iconName: "square.grid.2x2.fill",
                        color: AppPalette.background,
                        usageID: nil
                    )

                    ForEach(CreditAccountExpenseTypeOption.creditUsageOptions) { option in
                        movementKindButton(
                            title: option.name,
                            iconName: ExpenseTypeIcon.name(for: option.name),
                            color: option.category.color,
                            usageID: option.id
                        )
                    }
                }
            }
        }
    }

    private func movementKindButton(
        title: String,
        iconName: String,
        color: Color,
        usageID: String?
    ) -> some View {
        let isSelected = selectedCreditUsageID == usageID

        return Button {
            selectedCreditUsageID = usageID
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .foregroundStyle(isSelected ? AppPalette.surface : color)
                Text(title)
                    .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
            }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(
                    isSelected ? AppPalette.background : AppPalette.appBackground,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var movementTotals: some View {
        HStack(spacing: 8) {
            movementTotalCard(
                symbol: "+",
                value: positiveMovementTotal,
                color: AppPalette.primary
            )
            movementTotalCard(
                symbol: "−",
                value: negativeMovementTotal,
                color: AppPalette.positive
            )
        }
    }

    private func movementTotalCard(symbol: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.headline.bold())
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: Circle())

            Text(value.currencyText)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func movementFilterPicker<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(1)

            content()
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private var availableMovementYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let movementYears = movements.map { Calendar.current.component(.year, from: $0.date) }
        return Array(Set(movementYears + [currentYear])).sorted(by: >)
    }

    private var filteredMovements: [CreditMovement] {
        let calendar = Calendar.current
        return movements.filter { movement in
            guard calendar.component(.year, from: movement.date) == selectedMovementYear else {
                return false
            }
            if let selectedMovementMonth,
               calendar.component(.month, from: movement.date) != selectedMovementMonth {
                return false
            }
            if let selectedCreditUsageID,
               creditUsageOption(for: movement).id != selectedCreditUsageID {
                return false
            }
            return true
        }
    }

    private func creditUsageOption(for movement: CreditMovement) -> CreditAccountExpenseTypeOption {
        guard let expenseName = movement.expenseName,
              !expenseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let option = CreditAccountExpenseTypeOption.creditUsageOptions.first(where: {
                  $0.name.caseInsensitiveCompare(expenseName) == .orderedSame
              }) else {
            return CreditAccountExpenseTypeOption.other
        }
        return option
    }

    private var positiveMovementTotal: Double {
        filteredMovements.reduce(0) { total, movement in
            total + max(movement.balanceEffect, 0)
        }
    }

    private var negativeMovementTotal: Double {
        filteredMovements.reduce(0) { total, movement in
            total + abs(min(movement.balanceEffect, 0))
        }
    }

    private var movementGroups: [CreditMovementGroup] {
        Dictionary(grouping: filteredMovements, by: { $0.date.monthStart })
            .map { CreditMovementGroup(month: $0.key, movements: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    private func insertAuditLog(action: AuditLogAction, title: String, amount: Double = 0, balanceAfter: Double? = nil, creditID: UUID? = nil, note: String? = nil) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            details: note ?? "",
            amount: amount,
            balanceAfter: balanceAfter ?? auditBalance,
            creditID: creditID
        ))
    }

    private func deleteMovement(_ movement: CreditMovement) {
        let balanceAfter = auditBalance + movement.balanceEffect
        insertAuditLog(
            action: .creditMovementDeleted,
            title: movement.kind.title,
            amount: abs(movement.amount),
            balanceAfter: balanceAfter,
            creditID: movement.creditID,
            note: movement.note.isEmpty ? credit.displayName : movement.note
        )
        modelContext.delete(movement)
    }

    private var balancePoints: [CreditBalancePoint] {
        let firstMonth = min(credit.createdAt.monthStart, movements.map(\.date.monthStart).min() ?? Date().monthStart)
        let months = months(from: firstMonth, through: Date().monthStart).suffix(12)
        return months.map { month in
            let movementsUntilMonth = allMovements.filter { $0.creditID == credit.id && $0.date.monthStart <= month }
            return CreditBalancePoint(month: month, balance: credit.balance(with: movementsUntilMonth))
        }
    }

    private var paymentEstimatePoints: [CreditBalancePoint] {
        guard balance > 0, averageMonthlyPaymentLastThreeMonths > 0 else { return [] }

        return (1...12).map { offset in
            let month = monthAdding(offset, to: monthStart)
            let projectedBalance = max(balance - (averageMonthlyPaymentLastThreeMonths * Double(offset)), 0)
            return CreditBalancePoint(month: month, balance: projectedBalance)
        }
    }

    private var averageMonthlyPaymentLastThreeMonths: Double {
        let months = (0..<3).map { monthAdding(-$0, to: monthStart) }
        let total = months.reduce(0) { total, month in
            total + credit.monthPaid(in: month, movements: allMovements)
        }
        return total / 3
    }

    private var projectedBalanceAfterOneYear: Double {
        paymentEstimatePoints.last?.balance ?? balance
    }

    private func collapsibleChartCard<Content: View>(
        title: String,
        value: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isExpanded.wrappedValue.toggle()
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.background)
                            .lineLimit(2)

                        if let subtitle {
                            Text(subtitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.mutedText)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Text(value)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mutedText)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
            }
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func monthAdding(_ value: Int, to month: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: value, to: month.monthStart) ?? month.monthStart
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).fontWeight(.bold)
        }
        .font(.subheadline)
        .foregroundStyle(AppPalette.background)
    }

    private func summaryRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppPalette.mutedText)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .font(.subheadline)
    }

    private func months(from start: Date, through end: Date) -> [Date] {
        var result: [Date] = []
        var cursor = start.monthStart
        while cursor <= end.monthStart {
            result.append(cursor)
            cursor = cursor.nextMonthStart
        }
        return result
    }
}

private struct CreditMovementGroup: Identifiable {
    let month: Date
    let movements: [CreditMovement]

    var id: Date { month }
}

private struct CreditMovementRow: View {
    let movement: CreditMovement
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: movement.kind.iconName)
                .foregroundStyle(movement.kind.tint)
                .frame(width: 34, height: 34)
                .background(movement.kind.tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(movement.kind.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                Text(movement.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
                if movement.kind == .debtIncrease, let expenseName = movement.expenseName, !expenseName.isEmpty {
                    Text(expenseName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.primary)
                }

                if !movement.note.isEmpty {
                    Text(movement.note)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                }
            }

            Spacer()

            Text(movement.signedAmountText)
                .font(.subheadline.bold())
                .foregroundStyle(movement.balanceEffect <= 0 ? AppPalette.positive : AppPalette.primary)

            Menu {
                Button(AppStrings.text(.editPrefix), systemImage: "pencil", action: onEdit)
                Button(AppStrings.text(.delete), systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct CreditMovementEditorRequest: Identifiable {
    let id = UUID()
    let credit: CreditAccount
    let movement: CreditMovement?

    init(credit: CreditAccount, movement: CreditMovement? = nil) {
        self.credit = credit
        self.movement = movement
    }
}

private struct CreditMovementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]

    let request: CreditMovementEditorRequest

    @State private var kind: CreditMovementKind = .debtIncrease
    @State private var note = ""
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var adjustmentIsPositive = true
    @State private var markAsPaid = false
    @State private var selectedCurrentAccountExpenseCategory: ExpenseCategory = .needs
    @State private var selectedCurrentAccountExpenseName = ""
    @State private var selectedDestinationAccountID: UUID?
    @State private var validationMessage: String?
    @State private var saveNotice: SaveResultNotice?

    private var isEditing: Bool { request.movement != nil }
    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: savingMovements,
            creditAccounts: creditAccounts,
            creditMovements: creditMovements
        )
    }
    private var primarySpendAccountID: UUID? {
        spendAccounts.first(where: \.isPrimary)?.id ?? spendAccounts.first?.id
    }
    private var sortedSpendAccounts: [SpendAccount] {
        spendAccounts.sorted { first, second in
            if first.isPrimary != second.isPrimary {
                return first.isPrimary
            }
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
    }
    private var resolvedDestinationAccountID: UUID? {
        guard let selectedDestinationAccountID,
              spendAccounts.contains(where: { $0.id == selectedDestinationAccountID }) else {
            return primarySpendAccountID
        }
        return selectedDestinationAccountID
    }
    private var normalizedDestinationAccountID: Binding<UUID?> {
        Binding(
            get: { resolvedDestinationAccountID },
            set: { selectedDestinationAccountID = $0 }
        )
    }

    private var debtAmortizationExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { isDebtAmortizationExpense($0) } ?? "Amortização de dívida"
    }

    private var currentAccountDebtIncreaseOptions: [CreditAccountExpenseTypeOption] {
        CreditAccountExpenseTypeOption.creditUsageOptions
    }
    private var selectedDebtIncreaseCreatesAccountEntry: Bool {
        let selectedName = normalized(selectedCurrentAccountExpenseName)
        return selectedName.contains("cash advance")
            || selectedName.contains("levantamento")
            || selectedName.contains("transferencia de saldo")
            || selectedName.contains("balance transfer")
    }
    private var shouldCreateDebtIncreaseAccountEntry: Bool {
        !isEditing && kind == .debtIncrease && selectedDebtIncreaseCreatesAccountEntry
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    affectedCreditCard
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    MoneyAmountPicker(title: AppStrings.text(.value), amount: $amount, maximumAmount: 1_000_000, onConfirm: save)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    DatePicker(CreditStrings.text(.movementDate), selection: $date, displayedComponents: .date)
                        .tint(AppPalette.primary)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    movementKindHorizontalPicker

                    if kind == .adjustment {
                        Picker(CreditStrings.text(.adjustment), selection: $adjustmentIsPositive) {
                            Text("+").tag(true)
                            Text("-").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .listRowBackground(AppPalette.surface)

                if kind == .debtIncrease || kind == .payment {
                    Section {
                        currentAccountImpactCard
                    }
                    .listRowBackground(AppPalette.surface)
                }

                Section {
                    TextField(CreditStrings.text(.movementNote), text: $note)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)
                }
                .listRowBackground(AppPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .navigationTitle(isEditing ? CreditStrings.text(.editMovement) : CreditStrings.text(.addMovement))
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
            .onAppear {
                loadInitialValues()
                selectedDestinationAccountID = resolvedDestinationAccountID
                prepareCurrentAccountSelection(for: kind)
            }
            .onChange(of: kind) { _, newKind in
                prepareCurrentAccountSelection(for: newKind)
            }
            .alert(item: $saveNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text(AppStrings.text(.ok))) {
                        dismiss()
                    }
                )
            }
        }
    }

    private var affectedCreditCard: some View {
        HStack(spacing: 14) {
            Image(systemName: request.credit.creditType.iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 44, height: 44)
                .background(AppPalette.primary.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(CreditStrings.text(.affectedCredit))
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                Text(request.credit.displayName)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private var movementKindHorizontalPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CreditStrings.text(.movementType))
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CreditMovementKind.allCases) { movementKind in
                        movementKindCard(movementKind)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func movementKindCard(_ movementKind: CreditMovementKind) -> some View {
        let title = movementKind == .debtIncrease ? "Aumentar\ndívida" : movementKind.title

        return Button {
            kind = movementKind
        } label: {
            VStack(spacing: 10) {
                Image(systemName: movementKind.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(kind == movementKind ? movementKind.tint : AppPalette.background)
                    .frame(width: 44, height: 44)
                    .background(movementKind.tint.opacity(kind == movementKind ? 0.18 : 0.08), in: Circle())

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(kind == movementKind ? movementKind.tint : AppPalette.background)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 118, height: 118)
            .background(kind == movementKind ? movementKind.tint.opacity(0.10) : AppPalette.appBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(kind == movementKind ? movementKind.tint.opacity(0.55) : AppPalette.mutedText.opacity(0.16), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var currentAccountImpactCard: some View {
        if kind == .debtIncrease {
            VStack(alignment: .leading, spacing: 14) {
                Label(CreditStrings.text(.creditUsageQuestion), systemImage: "tag.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Text(selectedDebtIncreaseCreatesAccountEntry && !isEditing
                    ? CreditStrings.text(.debtIncreaseAccountEntryMessage)
                    : CreditStrings.text(.debtIncreaseCreditOnlyMessage))
                    .font(.footnote)
                    .foregroundStyle(AppPalette.mutedText)

                accountExpenseTypePicker(options: currentAccountDebtIncreaseOptions)

                if selectedDebtIncreaseCreatesAccountEntry {
                    Divider()

                    Label(CreditStrings.text(.currentAccountEntry), systemImage: "wallet.pass.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.background)

                    Text(isEditing
                        ? CreditStrings.text(.accountEntryEditMessage)
                        : CreditStrings.text(.accountEntryCreateMessage))
                        .font(.footnote)
                        .foregroundStyle(AppPalette.mutedText)

                    if !isEditing {
                        if sortedSpendAccounts.isEmpty {
                            Text(CreditStrings.text(.createAccountToReceiveValue))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AppPalette.primary)
                        } else {
                            Picker(AppStrings.text(.account), selection: normalizedDestinationAccountID) {
                                ForEach(sortedSpendAccounts) { account in
                                    Label(account.displayName, systemImage: account.iconName)
                                        .tag(account.id as UUID?)
                                }
                            }
                            .tint(AppPalette.background)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        } else if kind == .payment {
            VStack(alignment: .leading, spacing: 14) {
                Label(CreditStrings.text(.affectCurrentAccount), systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Text(isEditing
                    ? CreditStrings.text(.paymentEditCurrentAccountExpenseMessage)
                    : CreditStrings.text(.paymentCreatesCurrentAccountExpenseMessage))
                    .font(.footnote)
                    .foregroundStyle(AppPalette.mutedText)

                if !isEditing {
                    Toggle(isOn: $markAsPaid) {
                        Text(markAsPaid ? AppStrings.text(.paidExpense) : AppStrings.text(.unpaidExpense))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.background)
                    }
                    .toggleStyle(.switch)
                    .tint(AppPalette.primary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func accountExpenseTypePicker(options: [CreditAccountExpenseTypeOption]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options) { option in
                    accountExpenseTypeCard(option)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func accountExpenseTypeCard(_ option: CreditAccountExpenseTypeOption) -> some View {
        let isSelected = selectedCurrentAccountExpenseCategory == option.category && selectedCurrentAccountExpenseName == option.name

        return Button {
            selectedCurrentAccountExpenseCategory = option.category
            selectedCurrentAccountExpenseName = option.name
        } label: {
            VStack(spacing: 10) {
                Image(systemName: ExpenseTypeIcon.name(for: option.name))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? option.category.color : AppPalette.background)
                    .frame(width: 44, height: 44)
                    .background(option.category.color.opacity(isSelected ? 0.18 : 0.08), in: Circle())

                Text(option.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? option.category.color : AppPalette.background)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 132, height: 122)
            .background(isSelected ? option.category.color.opacity(0.10) : AppPalette.appBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? option.category.color.opacity(0.55) : AppPalette.mutedText.opacity(0.16), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func loadInitialValues() {
        guard let movement = request.movement else { return }
        kind = movement.kind
        note = movement.note
        amount = abs(movement.amount)
        date = movement.date
        adjustmentIsPositive = movement.amount >= 0
        if movement.kind == .debtIncrease,
           let expenseCategory = ExpenseCategory(rawValue: movement.expenseCategory ?? ""),
           let expenseName = movement.expenseName,
           !expenseName.isEmpty {
            selectedCurrentAccountExpenseCategory = expenseCategory
            selectedCurrentAccountExpenseName = expenseName
        }
    }

    private func prepareCurrentAccountSelection(for movementKind: CreditMovementKind) {
        if movementKind == .payment {
            selectedCurrentAccountExpenseCategory = .savingsAndDebt
            selectedCurrentAccountExpenseName = debtAmortizationExpenseName
        } else if selectedCurrentAccountExpenseName.isEmpty || isDebtAmortizationExpense(selectedCurrentAccountExpenseName) {
            guard let firstOption = currentAccountDebtIncreaseOptions.first else { return }
            selectedCurrentAccountExpenseCategory = firstOption.category
            selectedCurrentAccountExpenseName = firstOption.name
        }
    }

    private func isDebtAmortizationExpense(_ name: String) -> Bool {
        let normalizedName = normalized(name)
        return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
    }

    private func normalized(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private func save() {
        validationMessage = nil
        guard amount > 0 else {
            validationMessage = CreditStrings.text(.fillMovementValue)
            return
        }
        if shouldCreateDebtIncreaseAccountEntry && resolvedDestinationAccountID == nil {
            validationMessage = CreditStrings.text(.selectReceivingAccount)
            return
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if kind == .payment && request.movement == nil {
            savePaymentThroughCurrentAccount(note: trimmedNote)
            SaveResultNoticeCenter.shared.show(.saved(AppStrings.text(.creditPaymentSavedMessage)))
            dismiss()
            return
        }

        let storedAmount = kind == .adjustment && !adjustmentIsPositive ? -amount : amount
        let previousEffect = request.movement?.balanceEffect ?? 0
        let newEffect = kind.balanceEffect(for: storedAmount)
        let movement = request.movement ?? CreditMovement(
            creditID: request.credit.id,
            date: date,
            type: kind.rawValue,
            amount: storedAmount,
            note: trimmedNote
        )
        movement.creditID = request.credit.id
        movement.date = date
        movement.type = kind.rawValue
        movement.amount = storedAmount
        movement.note = trimmedNote
        movement.expenseCategory = kind == .debtIncrease ? selectedCurrentAccountExpenseCategory.rawValue : nil
        movement.expenseName = kind == .debtIncrease ? selectedCurrentAccountExpenseName : nil

        if request.movement == nil {
            modelContext.insert(movement)
        }

        let accountEntryAmount = shouldCreateDebtIncreaseAccountEntry ? amount : 0
        if shouldCreateDebtIncreaseAccountEntry, let accountID = resolvedDestinationAccountID {
            let movementNote = trimmedNote.isEmpty ? selectedCurrentAccountExpenseName : trimmedNote
            modelContext.insert(AccountMovement(
                accountID: accountID,
                date: date,
                type: AccountMovementKind.transferIn.rawValue,
                amount: amount,
                note: movementNote
            ))
            insertAuditLog(
                action: .accountTransfer,
                title: selectedCurrentAccountExpenseName,
                amount: amount,
                balanceAfter: auditBalance - newEffect + previousEffect + accountEntryAmount,
                accountID: accountID,
                creditID: request.credit.id,
                note: movementNote
            )
        }

        insertAuditLog(
            action: request.movement == nil ? .creditMovementCreated : .creditMovementUpdated,
            title: kind.title,
            amount: abs(storedAmount),
            balanceAfter: auditBalance - newEffect + previousEffect + accountEntryAmount,
            creditID: request.credit.id,
            note: trimmedNote.isEmpty ? request.credit.displayName : trimmedNote
        )

        SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.creditMovementSavedMessage), kind.title)))
        dismiss()
    }

    private func savePaymentThroughCurrentAccount(note: String) {
        let transaction = MoneyTransaction(
            title: note.isEmpty ? AppStrings.text(.newCreditPaymentExpense) : note,
            day: Calendar.current.component(.day, from: date),
            monthStart: date.monthStart,
            amount: amount,
            kind: TransactionKind.expense.rawValue,
            expenseCategory: ExpenseCategory.savingsAndDebt.rawValue,
            expenseName: debtAmortizationExpenseName,
            linkedCreditID: request.credit.id,
            accountID: primarySpendAccountID
        )
        modelContext.insert(transaction)
        insertAuditLog(
            action: .expenseCreated,
            title: transaction.displayName,
            amount: amount,
            balanceAfter: auditBalance,
            accountID: transaction.accountID,
            transactionID: transaction.id,
            creditID: request.credit.id,
            note: transaction.title
        )

        guard markAsPaid else { return }

        modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: date.monthStart, amountPaid: amount))
        let historyEntry = PaymentHistoryEntry(transactionID: transaction.id, monthStart: date.monthStart, amount: amount, accountID: transaction.accountID)
        modelContext.insert(historyEntry)
        if let accountID = transaction.accountID {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                transactionID: transaction.id,
                paymentHistoryID: historyEntry.id,
                date: historyEntry.paidAt,
                type: AccountMovementKind.expensePayment.rawValue,
                amount: -amount,
                note: transaction.title
            ))
        }

        let movement = CreditMovement(
            creditID: request.credit.id,
            date: date,
            type: CreditMovementKind.payment.rawValue,
            amount: amount,
            note: transaction.title
        )
        modelContext.insert(movement)
        transaction.linkedCreditMovementID = movement.id
        insertAuditLog(
            action: .expensePaymentCreated,
            title: transaction.displayName,
            amount: amount,
            balanceAfter: auditBalance - amount,
            accountID: transaction.accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            note: transaction.title
        )
        insertAuditLog(
            action: .creditMovementCreated,
            title: CreditMovementKind.payment.title,
            amount: amount,
            balanceAfter: auditBalance,
            transactionID: transaction.id,
            creditID: request.credit.id,
            note: transaction.title
        )
    }

    private func insertAuditLog(
        action: AuditLogAction,
        title: String,
        amount: Double,
        balanceAfter: Double,
        accountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        creditID: UUID? = nil,
        note: String? = nil
    ) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            details: note ?? "",
            amount: amount,
            balanceAfter: balanceAfter,
            accountID: accountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID,
            creditID: creditID
        ))
    }
}

private struct CreditAccountExpenseTypeOption: Identifiable, Hashable {
    let category: ExpenseCategory
    let name: String

    var id: String { "\(category.rawValue)-\(name)" }

    static let creditUsageOptions: [CreditAccountExpenseTypeOption] = [
        CreditAccountExpenseTypeOption(category: .wants, name: "Refeições / Restaurantes"),
        CreditAccountExpenseTypeOption(category: .savingsAndDebt, name: "Cash Advance / Levantamento"),
        CreditAccountExpenseTypeOption(category: .needs, name: "Supermercado"),
        CreditAccountExpenseTypeOption(category: .wants, name: "Roupa e Acessórios"),
        CreditAccountExpenseTypeOption(category: .needs, name: "Transportes"),
        CreditAccountExpenseTypeOption(category: .wants, name: "Viagens"),
        CreditAccountExpenseTypeOption(category: .needs, name: "Casa / Habitação"),
        CreditAccountExpenseTypeOption(category: .needs, name: "Saúde"),
        CreditAccountExpenseTypeOption(category: .wants, name: "Lazer"),
        CreditAccountExpenseTypeOption(category: .wants, name: "Compras gerais"),
        CreditAccountExpenseTypeOption(category: .savingsAndDebt, name: "Transferência de saldo"),
        CreditAccountExpenseTypeOption(category: .wants, name: "Outro")
    ]

    static let other = CreditAccountExpenseTypeOption(category: .wants, name: "Outro")
}

struct CurrentAccountCreditMovementRequest: Identifiable {
    let id = UUID()
    let month: Date
}

struct CurrentAccountCreditMovementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var creditAccounts: [CreditAccount]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var creditMovements: [CreditMovement]

    let request: CurrentAccountCreditMovementRequest

    @State private var selectedCreditID: UUID?
    @State private var kind: CreditMovementKind = .payment
    @State private var note = ""
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var markAsPaid = false
    @State private var selectedExpenseCategory: ExpenseCategory = .needs
    @State private var selectedExpenseName = ""
    @State private var selectedDestinationAccountID: UUID?
    @State private var validationMessage: String?
    @State private var saveNotice: SaveResultNotice?

    private var activeCreditAccounts: [CreditAccount] {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var selectedCredit: CreditAccount? {
        guard let selectedCreditID else { return activeCreditAccounts.first }
        return activeCreditAccounts.first { $0.id == selectedCreditID }
    }
    private var primarySpendAccountID: UUID? {
        spendAccounts.first(where: \.isPrimary)?.id ?? spendAccounts.first?.id
    }
    private var sortedSpendAccounts: [SpendAccount] {
        spendAccounts.sorted { first, second in
            if first.isPrimary != second.isPrimary {
                return first.isPrimary
            }
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
    }
    private var resolvedDestinationAccountID: UUID? {
        guard let selectedDestinationAccountID,
              spendAccounts.contains(where: { $0.id == selectedDestinationAccountID }) else {
            return primarySpendAccountID
        }
        return selectedDestinationAccountID
    }
    private var normalizedDestinationAccountID: Binding<UUID?> {
        Binding(
            get: { resolvedDestinationAccountID },
            set: { selectedDestinationAccountID = $0 }
        )
    }

    private var movementKinds: [CreditMovementKind] { [.debtIncrease, .payment] }
    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: savingMovements,
            creditAccounts: creditAccounts,
            creditMovements: creditMovements
        )
    }

    private var debtAmortizationExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalized(name)
            return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
        } ?? "Amortização de dívida"
    }

    private var currentAccountDebtIncreaseOptions: [CreditAccountExpenseTypeOption] {
        CreditAccountExpenseTypeOption.creditUsageOptions
    }
    private var selectedDebtIncreaseCreatesAccountEntry: Bool {
        let selectedName = normalized(selectedExpenseName)
        return selectedName.contains("cash advance")
            || selectedName.contains("levantamento")
            || selectedName.contains("transferencia de saldo")
            || selectedName.contains("balance transfer")
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    creditSelectionArea
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    movementTypeArea
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    MoneyAmountPicker(title: AppStrings.text(.value), amount: $amount, maximumAmount: 1_000_000, onConfirm: save)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    DatePicker(CreditStrings.text(.movementDate), selection: $date, displayedComponents: .date)
                        .tint(AppPalette.primary)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    TextField(CreditStrings.text(.movementNote), text: $note)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    if kind == .payment {
                        currentAccountImpactInfo
                    } else {
                        debtIncreaseExpenseTypeArea
                    }
                }
                .listRowBackground(AppPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .navigationTitle(CreditStrings.text(.credit))
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
            .onAppear {
                date = defaultMovementDate()
                selectedCreditID = selectedCredit?.id
                selectedDestinationAccountID = resolvedDestinationAccountID
                prepareExpenseTypeSelection()
            }
            .onChange(of: kind) { _, newKind in
                if newKind == .debtIncrease {
                    prepareExpenseTypeSelection()
                }
            }
            .alert(item: $saveNotice) { notice in
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    dismissButton: .default(Text(AppStrings.text(.ok))) {
                        dismiss()
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var creditSelectionArea: some View {
        if activeCreditAccounts.isEmpty {
            Text(CreditStrings.text(.emptyTitle))
                .font(.subheadline)
                .foregroundStyle(AppPalette.mutedText)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(CreditStrings.text(.selectCredit))
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeCreditAccounts) { credit in
                            creditCard(credit)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var movementTypeArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CreditStrings.text(.movementType))
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movementKinds) { movementKind in
                        movementKindCard(movementKind)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var currentAccountImpactInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(CreditStrings.text(.affectCurrentAccount), systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            Text(CreditStrings.text(.paymentCreatesCurrentAccountExpenseMessage))
                .font(.footnote)
                .foregroundStyle(AppPalette.mutedText)

            if sortedSpendAccounts.isEmpty {
                Text(CreditStrings.text(.createAccountToReceiveValue))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppPalette.primary)
            } else {
                destinationAccountHorizontalPicker
            }

            Toggle(isOn: $markAsPaid) {
                Text(markAsPaid ? AppStrings.text(.paidExpense) : AppStrings.text(.unpaidExpense))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
            }
            .toggleStyle(.switch)
            .tint(AppPalette.primary)
        }
        .padding(.vertical, 6)
    }

    private var debtIncreaseExpenseTypeArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(CreditStrings.text(.creditUsageQuestion), systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            Text(CreditStrings.text(.debtIncreaseCreditOnlyMessage))
                .font(.footnote)
                .foregroundStyle(AppPalette.mutedText)

            accountExpenseTypePicker(options: currentAccountDebtIncreaseOptions)

            if selectedDebtIncreaseCreatesAccountEntry {
                Divider()

                Label(CreditStrings.text(.currentAccountEntry), systemImage: "wallet.pass.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.background)

                Text(CreditStrings.text(.accountEntryCreateMessage))
                    .font(.footnote)
                    .foregroundStyle(AppPalette.mutedText)

                if sortedSpendAccounts.isEmpty {
                    Text(CreditStrings.text(.createAccountToReceiveValue))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppPalette.primary)
                } else {
                    destinationAccountHorizontalPicker
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var destinationAccountHorizontalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppStrings.text(.account))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.background)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(sortedSpendAccounts) { account in
                        destinationAccountCard(account)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func destinationAccountCard(_ account: SpendAccount) -> some View {
        let isSelected = resolvedDestinationAccountID == account.id
        let balance = account.balance(with: accountMovements)

        return Button {
            selectedDestinationAccountID = account.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: account.iconName)
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
                        .foregroundStyle(isSelected ? AppPalette.surface.opacity(0.86) : AppPalette.mutedText)
                        .lineLimit(1)
                }
            }
            .frame(width: 178, height: 70, alignment: .leading)
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

    private func creditCard(_ credit: CreditAccount) -> some View {
        let isSelected = selectedCredit?.id == credit.id

        return Button {
            selectedCreditID = credit.id
        } label: {
            VStack(spacing: 10) {
                Image(systemName: credit.creditType.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.background)
                    .frame(width: 44, height: 44)
                    .background(AppPalette.primary.opacity(isSelected ? 0.18 : 0.08), in: Circle())

                Text(credit.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.background)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 140, height: 124)
            .background(isSelected ? AppPalette.primary.opacity(0.10) : AppPalette.appBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppPalette.primary.opacity(0.55) : AppPalette.mutedText.opacity(0.16), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func movementKindCard(_ movementKind: CreditMovementKind) -> some View {
        let isSelected = kind == movementKind
        let title = movementKind == .debtIncrease ? "Aumentar\ndívida" : movementKind.title

        return Button {
            kind = movementKind
        } label: {
            VStack(spacing: 10) {
                Image(systemName: movementKind.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? movementKind.tint : AppPalette.background)
                    .frame(width: 44, height: 44)
                    .background(movementKind.tint.opacity(isSelected ? 0.18 : 0.08), in: Circle())

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? movementKind.tint : AppPalette.background)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 132, height: 118)
            .background(isSelected ? movementKind.tint.opacity(0.10) : AppPalette.appBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? movementKind.tint.opacity(0.55) : AppPalette.mutedText.opacity(0.16), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func accountExpenseTypePicker(options: [CreditAccountExpenseTypeOption]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options) { option in
                    accountExpenseTypeCard(option)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func accountExpenseTypeCard(_ option: CreditAccountExpenseTypeOption) -> some View {
        let isSelected = selectedExpenseCategory == option.category && selectedExpenseName == option.name

        return Button {
            selectedExpenseCategory = option.category
            selectedExpenseName = option.name
        } label: {
            VStack(spacing: 10) {
                Image(systemName: ExpenseTypeIcon.name(for: option.name))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? option.category.color : AppPalette.background)
                    .frame(width: 44, height: 44)
                    .background(option.category.color.opacity(isSelected ? 0.18 : 0.08), in: Circle())

                Text(option.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? option.category.color : AppPalette.background)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .frame(width: 132, height: 122)
            .background(isSelected ? option.category.color.opacity(0.10) : AppPalette.appBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? option.category.color.opacity(0.55) : AppPalette.mutedText.opacity(0.16), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func defaultMovementDate(now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let day = min(calendar.component(.day, from: now), request.month.daysInMonth)
        let baseDate = request.month.date(day: day)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
        return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: timeComponents.second ?? 0, of: baseDate) ?? baseDate
    }

    private func save() {
        validationMessage = nil

        guard let credit = selectedCredit else {
            validationMessage = CreditStrings.text(.selectCredit)
            return
        }

        guard amount > 0 else {
            validationMessage = CreditStrings.text(.fillMovementValue)
            return
        }
        if kind == .payment && resolvedDestinationAccountID == nil {
            validationMessage = CreditStrings.text(.selectReceivingAccount)
            return
        }
        if kind == .debtIncrease && selectedDebtIncreaseCreatesAccountEntry && resolvedDestinationAccountID == nil {
            validationMessage = CreditStrings.text(.selectReceivingAccount)
            return
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .payment:
            savePayment(for: credit, note: trimmedNote)
        case .debtIncrease:
            saveDebtIncrease(for: credit, note: trimmedNote)
        case .fee, .adjustment:
            break
        }

        SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.creditMovementSavedMessage), kind.title)))
        dismiss()
    }

    private func savePayment(for credit: CreditAccount, note: String) {
        let transaction = MoneyTransaction(
            title: note.isEmpty ? AppStrings.text(.newCreditPaymentExpense) : note,
            day: Calendar.current.component(.day, from: date),
            monthStart: date.monthStart,
            amount: amount,
            kind: TransactionKind.expense.rawValue,
            expenseCategory: ExpenseCategory.savingsAndDebt.rawValue,
            expenseName: debtAmortizationExpenseName,
            linkedCreditID: credit.id,
            accountID: resolvedDestinationAccountID
        )
        modelContext.insert(transaction)
        insertAuditLog(
            action: .expenseCreated,
            title: transaction.displayName,
            amount: amount,
            balanceAfter: auditBalance,
            accountID: transaction.accountID,
            transactionID: transaction.id,
            creditID: credit.id,
            note: transaction.title
        )

        guard markAsPaid else { return }

        modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: date.monthStart, amountPaid: amount))
        let historyEntry = PaymentHistoryEntry(transactionID: transaction.id, monthStart: date.monthStart, amount: amount, accountID: transaction.accountID)
        modelContext.insert(historyEntry)
        if let accountID = transaction.accountID {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                transactionID: transaction.id,
                paymentHistoryID: historyEntry.id,
                date: historyEntry.paidAt,
                type: AccountMovementKind.expensePayment.rawValue,
                amount: -amount,
                note: transaction.title
            ))
        }

        let movement = CreditMovement(
            creditID: credit.id,
            date: date,
            type: CreditMovementKind.payment.rawValue,
            amount: amount,
            note: transaction.title
        )
        modelContext.insert(movement)
        transaction.linkedCreditMovementID = movement.id
        insertAuditLog(
            action: .expensePaymentCreated,
            title: transaction.displayName,
            amount: amount,
            balanceAfter: auditBalance - amount,
            accountID: transaction.accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            creditID: credit.id,
            note: transaction.title
        )
        insertAuditLog(
            action: .creditMovementCreated,
            title: CreditMovementKind.payment.title,
            amount: amount,
            balanceAfter: auditBalance,
            transactionID: transaction.id,
            creditID: credit.id,
            note: transaction.title
        )
    }

    private func saveDebtIncrease(for credit: CreditAccount, note: String) {
        prepareExpenseTypeSelection()
        let movementNote = note.isEmpty ? CreditMovementKind.debtIncrease.title : note
        let movement = CreditMovement(
            creditID: credit.id,
            date: date,
            type: CreditMovementKind.debtIncrease.rawValue,
            amount: amount,
            note: movementNote,
            expenseCategory: selectedExpenseCategory.rawValue,
            expenseName: selectedExpenseName
        )
        modelContext.insert(movement)
        if selectedDebtIncreaseCreatesAccountEntry, let accountID = resolvedDestinationAccountID {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                date: date,
                type: AccountMovementKind.transferIn.rawValue,
                amount: amount,
                note: movementNote
            ))
            insertAuditLog(
                action: .accountTransfer,
                title: selectedExpenseName,
                amount: amount,
                balanceAfter: auditBalance - movement.balanceEffect + amount,
                accountID: accountID,
                creditID: credit.id,
                note: movementNote
            )
        }
        insertAuditLog(
            action: .creditMovementCreated,
            title: CreditMovementKind.debtIncrease.title,
            amount: amount,
            balanceAfter: auditBalance - movement.balanceEffect + (selectedDebtIncreaseCreatesAccountEntry ? amount : 0),
            creditID: credit.id,
            note: movementNote
        )
    }

    private func prepareExpenseTypeSelection() {
        if selectedExpenseName.isEmpty || normalized(selectedExpenseName).contains("amort") || normalized(selectedExpenseName).contains("divida") || normalized(selectedExpenseName).contains("debt") {
            guard let firstOption = currentAccountDebtIncreaseOptions.first else { return }
            selectedExpenseCategory = firstOption.category
            selectedExpenseName = firstOption.name
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private func insertAuditLog(
        action: AuditLogAction,
        title: String,
        amount: Double,
        balanceAfter: Double,
        accountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        creditID: UUID? = nil,
        note: String? = nil
    ) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            details: note ?? "",
            amount: amount,
            balanceAfter: balanceAfter,
            accountID: accountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID,
            creditID: creditID
        ))
    }
}
