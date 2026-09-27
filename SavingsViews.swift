//
//  SavingsViews.swift
//  MoneyControl
//

import Charts
import SwiftData
import SwiftUI

struct SavingsSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]

    @State private var editorRequest: SavingEditorRequest?
    @State private var selectedSaving: SavingAccount?
    @State private var showsClosed = false

    private var visibleSavings: [SavingAccount] {
        savingAccounts
            .filter { showsClosed || $0.savingStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if horizontalSizeClass == .compact {
                    savingsHeroImage
                }

                if savingAccounts.contains(where: { $0.savingStatus == .closed }) {
                    Toggle(SavingsStrings.text(.showClosed), isOn: $showsClosed)
                        .font(.subheadline.weight(.semibold))
                        .tint(AppPalette.primary)
                        .padding(.horizontal, 4)
                }

                if visibleSavings.isEmpty {
                    ContentUnavailableView(
                        SavingsStrings.text(.emptyTitle),
                        systemImage: "leaf.circle",
                        description: Text(SavingsStrings.text(.addSaving))
                    )
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(visibleSavings) { saving in
                        Button {
                            selectedSaving = saving
                        } label: {
                            SavingSummaryCard(
                                saving: saving,
                                movements: savingMovements.filter { $0.savingID == saving.id }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    editorRequest = SavingEditorRequest()
                } label: {
                    Label(SavingsStrings.text(.addSaving), systemImage: "plus.circle.fill")
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
            SavingEditor(request: request)
        }
        .sheet(item: $selectedSaving) { saving in
            SavingDetailView(saving: saving)
        }
    }

    private var savingsHeroImage: some View {
        Image(AppStrings.currentLanguage == .portuguese ? "SavingsHero" : "SavingsHeroEnglish")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: AppPalette.background.opacity(0.10), radius: 12, y: 6)
    }
}

private struct SavingSummaryCard: View {
    let saving: SavingAccount
    let movements: [SavingMovement]

    private var balance: Double { saving.balance(with: movements) }
    private var variation: Double { saving.monthVariation(in: Date().monthStart, movements: movements) }
    private var targetRatio: Double? {
        guard let target = saving.targetAmount, target > 0 else { return nil }
        return min(max(balance / target, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: saving.purposeIconName)
                    .font(.title2)
                    .foregroundStyle(AppPalette.positive)
                    .frame(width: 46, height: 46)
                    .background(AppPalette.mintSurface, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(saving.displayName)
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                    Text(SavingsStrings.text(.saved))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.mutedText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(balance.currencyText)
                        .font(.title3.bold())
                        .foregroundStyle(AppPalette.background)
                    if saving.savingStatus == .closed {
                        Text(saving.savingStatus.title)
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.positive)
                    }
                }
            }

            HStack {
                Text(variation >= 0 ? "↑ \(variation.currencyText)" : "↓ \(abs(variation).currencyText)")
                    .font(.subheadline.bold())
                    .foregroundStyle(variation >= 0 ? AppPalette.positive : AppPalette.primary)
                Text(AppStrings.text(.month).lowercased())
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                Spacer()
            }

            if let target = saving.targetAmount, let targetRatio {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: targetRatio)
                        .tint(AppPalette.positive)
                    HStack {
                        Text("\(balance.currencyText) / \(target.currencyText)")
                        Spacer()
                        Text(targetRatio.formatted(.percent.precision(.fractionLength(0))))
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

struct SavingEditorRequest: Identifiable {
    let id = UUID()
    let saving: SavingAccount?

    init(saving: SavingAccount? = nil) {
        self.saving = saving
    }
}

private enum SavingPurpose: CaseIterable, Identifiable {
    case emergencyFund
    case savingsAccount
    case investment
    case travel
    case house
    case car
    case children
    case retirement
    case purchase
    case other

    var id: Self { self }

    var title: String {
        switch self {
        case .emergencyFund:
            "Fundo de Emergência"
        case .savingsAccount:
            "Conta Poupança"
        case .investment:
            "Investimento"
        case .travel:
            "Viagem"
        case .house:
            "Casa"
        case .car:
            "Automóvel"
        case .children:
            "Filhos"
        case .retirement:
            "Reforma"
        case .purchase:
            "Compra"
        case .other:
            "Outro"
        }
    }

    var iconName: String {
        switch self {
        case .emergencyFund:
            "cross.case.fill"
        case .savingsAccount:
            "building.columns.fill"
        case .investment:
            "chart.line.uptrend.xyaxis"
        case .travel:
            "airplane"
        case .house:
            "house.fill"
        case .car:
            "car.fill"
        case .children:
            "figure.2.and.child.holdinghands"
        case .retirement:
            "sun.horizon.fill"
        case .purchase:
            "cart.fill"
        case .other:
            "ellipsis.circle.fill"
        }
    }

    static func matching(_ title: String) -> SavingPurpose? {
        allCases.first { $0.title.compare(title, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }
}

private struct SavingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [SavingMovement]
    @Query private var transactions: [MoneyTransaction]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]

    let request: SavingEditorRequest
    var onDelete: (() -> Void)? = nil

    @State private var name = ""
    @State private var details = ""
    @State private var selectedPurpose: SavingPurpose = .emergencyFund
    @State private var currentSaved = 0.0
    @State private var targetAmount = 0.0
    @State private var status: SavingStatus = .active
    @State private var validationMessage: String?
    @State private var showsDeleteConfirmation = false
    @State private var isTargetExpanded = false
    @State private var saveNotice: SaveResultNotice?

    private var isEditing: Bool { request.saving != nil }
    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: allMovements,
            creditAccounts: creditAccounts,
            creditMovements: creditMovements
        )
    }

    private func insertAuditLog(action: AuditLogAction, title: String, amount: Double = 0, balanceAfter: Double? = nil, savingID: UUID? = nil, note: String? = nil) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            details: note ?? "",
            amount: amount,
            balanceAfter: balanceAfter ?? auditBalance,
            savingID: savingID
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
                    savingPurposePicker

                    if selectedPurpose == .other {
                        TextField(SavingsStrings.text(.savingName), text: $name)
                            .foregroundStyle(AppPalette.background)
                            .tint(AppPalette.primary)
                    }

                    TextField(SavingsStrings.text(.savingDescription), text: $details)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)

                    if isEditing {
                        Toggle(SavingsStrings.text(.active), isOn: Binding(
                            get: { status == .active },
                            set: { status = $0 ? .active : .closed }
                        ))
                        .tint(AppPalette.primary)
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    if !isEditing {
                        MoneyAmountPicker(title: SavingsStrings.text(.currentSaved), amount: $currentSaved, maximumAmount: 1_000_000, onConfirm: save)
                    }
                    targetDisclosure
                }
                .listRowBackground(AppPalette.surface)

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showsDeleteConfirmation = true
                        } label: {
                            Label(SavingsStrings.text(.deleteSaving), systemImage: "trash")
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
            .navigationTitle(isEditing ? SavingsStrings.text(.editSaving) : SavingsStrings.text(.newSaving))
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
            .alert(SavingsStrings.text(.deleteSavingTitle), isPresented: $showsDeleteConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.delete), role: .destructive, action: deleteSaving)
            } message: {
                Text(SavingsStrings.text(.deleteSavingMessage))
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

    private var targetDisclosure: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.snappy) {
                    isTargetExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(SavingsStrings.text(.targetAmount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.background)
                        Text(targetAmount > 0 ? targetAmount.currencyText : SavingsStrings.text(.optionalTarget))
                            .font(.caption)
                            .foregroundStyle(AppPalette.mutedText)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mutedText)
                        .rotationEffect(.degrees(isTargetExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isTargetExpanded {
                MoneyAmountPicker(
                    title: "\(SavingsStrings.text(.targetAmount)) · \(SavingsStrings.text(.optionalTarget))",
                    amount: $targetAmount,
                    maximumAmount: 1_000_000,
                    onConfirm: save
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var savingPurposePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SavingPurpose.allCases) { purpose in
                        savingPurposeCard(purpose)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func savingPurposeCard(_ purpose: SavingPurpose) -> some View {
        let isSelected = selectedPurpose == purpose

        return Button {
            selectedPurpose = purpose
            if purpose != .other {
                name = purpose.title
            } else {
                name = ""
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: purpose.iconName)
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

                Text(purpose.title)
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
        guard let saving = request.saving else { return }
        name = saving.name
        details = saving.details
        updatePurposeSelection(for: saving.name)
        currentSaved = saving.initialAmount
        targetAmount = saving.targetAmount ?? 0
        status = saving.savingStatus
    }

    private func save() {
        validationMessage = nil
        let rawName = selectedPurpose == .other ? name : selectedPurpose.title
        let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = SavingsStrings.text(.fillSavingName)
            return
        }

        guard currentSaved > 0 || isEditing else {
            validationMessage = SavingsStrings.text(.fillSavingValue)
            return
        }

        let isNewSaving = request.saving == nil
        let balanceBefore = auditBalance
        let saving = request.saving ?? SavingAccount(name: trimmedName, initialAmount: currentSaved)
        saving.name = trimmedName
        saving.details = trimmedDetails
        if !isEditing {
            saving.initialAmount = currentSaved
        }
        saving.targetAmount = targetAmount > 0 ? targetAmount : nil
        saving.status = status.rawValue

        if isNewSaving {
            modelContext.insert(saving)
        }

        insertAuditLog(
            action: isNewSaving ? .savingCreated : .savingUpdated,
            title: saving.displayName,
            amount: isNewSaving ? currentSaved : 0,
            balanceAfter: isNewSaving ? balanceBefore + currentSaved : auditBalance,
            savingID: saving.id,
            note: trimmedDetails.isEmpty ? nil : trimmedDetails
        )

        saveNotice = .saved(String(
            format: AppStrings.text(isNewSaving ? .savingCreatedMessage : .savingUpdatedMessage),
            saving.displayName
        ))
    }

    private func updatePurposeSelection(for value: String) {
        if let matchingPurpose = SavingPurpose.matching(value) {
            selectedPurpose = matchingPurpose
            name = matchingPurpose.title
        } else {
            selectedPurpose = .other
            name = value
        }
    }

    private func deleteSaving() {
        guard let saving = request.saving else { return }
        let balanceBefore = auditBalance
        let deletedBalance = saving.balance(with: allMovements)

        insertAuditLog(
            action: .savingDeleted,
            title: saving.displayName,
            amount: deletedBalance,
            balanceAfter: balanceBefore - deletedBalance,
            savingID: saving.id,
            note: saving.details.isEmpty ? nil : saving.details
        )

        allMovements
            .filter { $0.savingID == saving.id }
            .forEach(modelContext.delete)

        transactions
            .filter { $0.linkedSavingID == saving.id }
            .forEach { transaction in
                transaction.linkedSavingID = nil
                transaction.linkedSavingMovementID = nil
            }

        modelContext.delete(saving)
        onDelete?()
        dismiss()
    }
}

struct SavingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [SavingMovement]
    @Query private var transactions: [MoneyTransaction]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]

    let saving: SavingAccount

    @State private var savingEditorRequest: SavingEditorRequest?
    @State private var movementEditorRequest: SavingMovementEditorRequest?

    private var movements: [SavingMovement] { saving.movements(from: allMovements) }
    private var balance: Double { saving.balance(with: allMovements) }
    private var monthStart: Date { Date().monthStart }
    private var monthDeposits: Double { saving.monthDeposits(in: monthStart, movements: allMovements) }
    private var monthWithdrawals: Double { saving.monthWithdrawals(in: monthStart, movements: allMovements) }
    private var monthVariation: Double { saving.monthVariation(in: monthStart, movements: allMovements) }
    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: allMovements,
            creditAccounts: creditAccounts,
            creditMovements: creditMovements
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    savingsHeader
                    if saving.targetAmount != nil { targetCard }
                    monthSummaryCard
                    if !balancePoints.isEmpty { evolutionCard }
                    targetSuggestion
                    addMovementButton
                    movementsSection
                }
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(saving.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(SavingsStrings.text(.addMovement), systemImage: "plus") {
                            movementEditorRequest = SavingMovementEditorRequest(saving: saving)
                        }
                        Button(SavingsStrings.text(.editSaving), systemImage: "pencil") {
                            savingEditorRequest = SavingEditorRequest(saving: saving)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $savingEditorRequest) { request in
                SavingEditor(request: request) {
                    dismiss()
                }
            }
            .sheet(item: $movementEditorRequest) { request in
                SavingMovementEditor(request: request)
            }
        }
    }

    private var savingsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(saving.displayName)
                .font(.title2.bold())
                .foregroundStyle(AppPalette.background)
            Text(balance.currencyText)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(AppPalette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(SavingsStrings.text(.saved))
                .font(.headline)
                .foregroundStyle(AppPalette.mutedText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var targetCard: some View {
        let target = saving.targetAmount ?? 0
        let remaining = max(target - balance, 0)
        let ratio = target > 0 ? min(max(balance / target, 0), 1) : 0

        return VStack(alignment: .leading, spacing: 10) {
            ProgressView(value: ratio)
                .tint(AppPalette.positive)
            infoRow(SavingsStrings.text(.target), target.currencyText)
            infoRow(SavingsStrings.text(.saved), balance.currencyText)
            infoRow(SavingsStrings.text(.remainingToTarget), remaining.currencyText)
            infoRow(SavingsStrings.text(.targetProgress), ratio.formatted(.percent.precision(.fractionLength(0))))
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var monthSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SavingsStrings.text(.monthSummary))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)
            summaryRow(SavingsStrings.text(.currentSaved), balance.currencyText, AppPalette.background)
            summaryRow(SavingsStrings.text(.savedThisMonth), "+\(monthDeposits.currencyText)", AppPalette.positive)
            summaryRow(SavingsStrings.text(.withdrawnThisMonth), "-\(monthWithdrawals.currencyText)", AppPalette.primary)
            summaryRow(
                SavingsStrings.text(.monthVariation),
                monthVariation >= 0 ? "↑ \(monthVariation.currencyText)" : "↓ \(abs(monthVariation).currencyText)",
                monthVariation >= 0 ? AppPalette.positive : AppPalette.primary
            )
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var evolutionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SavingsStrings.text(.savingEvolution))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

            Chart(balancePoints) { point in
                LineMark(
                    x: .value(AppStrings.text(.month), point.monthLabel),
                    y: .value(SavingsStrings.text(.saved), point.balance)
                )
                .foregroundStyle(AppPalette.positive)

                PointMark(
                    x: .value(AppStrings.text(.month), point.monthLabel),
                    y: .value(SavingsStrings.text(.saved), point.balance)
                )
                .foregroundStyle(AppPalette.background)
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var targetSuggestion: some View {
        if let target = saving.targetAmount, target > 0, balance >= target, saving.savingStatus == .active {
            VStack(alignment: .leading, spacing: 10) {
                Text(SavingsStrings.text(.markClosedPrompt))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                Button(SavingsStrings.text(.markAsClosed)) {
                    saving.status = SavingStatus.closed.rawValue
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
            movementEditorRequest = SavingMovementEditorRequest(saving: saving)
        } label: {
            Label(SavingsStrings.text(.movements), systemImage: "plus.circle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.surface)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SavingsStrings.text(.movements))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

            if movementGroups.isEmpty {
                ContentUnavailableView(SavingsStrings.text(.noMovements), systemImage: "list.bullet.rectangle")
                    .foregroundStyle(AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ForEach(movementGroups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.month.monthTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.mutedText)
                        ForEach(group.movements) { movement in
                            SavingMovementRow(
                                movement: movement,
                                onEdit: { movementEditorRequest = SavingMovementEditorRequest(saving: saving, movement: movement) },
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

    private var movementGroups: [SavingMovementGroup] {
        Dictionary(grouping: movements, by: { $0.date.monthStart })
            .map { SavingMovementGroup(month: $0.key, movements: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    private var balancePoints: [SavingBalancePoint] {
        let firstMonth = min(saving.createdAt.monthStart, movements.map(\.date.monthStart).min() ?? Date().monthStart)
        let months = months(from: firstMonth, through: Date().monthStart).suffix(12)
        return months.map { month in
            let movementsUntilMonth = allMovements.filter { $0.savingID == saving.id && $0.date.monthStart <= month }
            return SavingBalancePoint(month: month, balance: saving.balance(with: movementsUntilMonth))
        }
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

    private func deleteMovement(_ movement: SavingMovement) {
        let hadLinkedIncome = movement.linkedIncomeTransactionID != nil
        let balanceAfter = hadLinkedIncome ? auditBalance : auditBalance - movement.balanceEffect
        modelContext.insert(AuditLogEntry(
            action: AuditLogAction.savingMovementDeleted.rawValue,
            title: movement.kind.title,
            details: movement.note.isEmpty ? saving.displayName : movement.note,
            amount: abs(movement.amount),
            balanceAfter: balanceAfter,
            savingID: movement.savingID
        ))

        if let incomeID = movement.linkedIncomeTransactionID,
           let income = transactions.first(where: { $0.id == incomeID }) {
            modelContext.delete(income)
        }
        modelContext.delete(movement)
    }
}

private struct SavingMovementGroup: Identifiable {
    let month: Date
    let movements: [SavingMovement]

    var id: Date { month }
}

private struct SavingMovementRow: View {
    let movement: SavingMovement
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
                if !movement.note.isEmpty {
                    Text(movement.note)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                }
            }

            Spacer()

            Text(movement.signedAmountText)
                .font(.subheadline.bold())
                .foregroundStyle(movement.balanceEffect >= 0 ? AppPalette.positive : AppPalette.primary)

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

struct SavingMovementEditorRequest: Identifiable {
    let id = UUID()
    let saving: SavingAccount
    let movement: SavingMovement?

    init(saving: SavingAccount, movement: SavingMovement? = nil) {
        self.saving = saving
        self.movement = movement
    }
}

private struct SavingMovementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [SavingMovement]
    @Query private var transactions: [MoneyTransaction]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]

    let request: SavingMovementEditorRequest

    @State private var kind: SavingMovementKind = .deposit
    @State private var note = ""
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var transferToIncome = false
    @State private var validationMessage: String?
    @State private var saveNotice: SaveResultNotice?

    private var isEditing: Bool { request.movement != nil }

    private var availableBalanceForWithdrawal: Double {
        let movementsWithoutCurrent = allMovements.filter { movement in
            movement.savingID == request.saving.id && movement.id != request.movement?.id
        }
        return request.saving.balance(with: movementsWithoutCurrent)
    }

    private var primarySpendAccountID: UUID? {
        spendAccounts.first(where: \.isPrimary)?.id ?? spendAccounts.first?.id
    }

    private var auditBalance: Double {
        AuditSnapshot.totalBalance(
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: allMovements,
            creditAccounts: creditAccounts,
            creditMovements: creditMovements
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    Picker(SavingsStrings.text(.movementType), selection: $kind) {
                        ForEach(SavingMovementKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.iconName).tag(kind)
                        }
                    }
                    .tint(AppPalette.background)

                    if kind == .withdrawal {
                        HStack(spacing: 10) {
                            Toggle(transferToIncome ? SavingsStrings.text(.transferToIncome) : SavingsStrings.text(.doNotTransferToIncome), isOn: $transferToIncome)
                                .font(.subheadline.weight(.semibold))
                                .tint(AppPalette.primary)
                            HelpIconButton(
                                title: SavingsStrings.text(.transferToIncome),
                                message: SavingsStrings.text(.transferToIncomeHelp)
                            )
                        }
                    }

                    DatePicker(SavingsStrings.text(.movementDate), selection: $date, displayedComponents: .date)
                        .tint(AppPalette.primary)

                    TextField(SavingsStrings.text(.movementNote), text: $note)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    MoneyAmountPicker(title: AppStrings.text(.value), amount: $amount, maximumAmount: 1_000_000, onConfirm: save)
                }
                .listRowBackground(AppPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .navigationTitle(isEditing ? SavingsStrings.text(.editMovement) : SavingsStrings.text(.addMovement))
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

    private func loadInitialValues() {
        guard let movement = request.movement else { return }
        kind = movement.kind == .adjustment ? .deposit : movement.kind
        note = movement.note
        amount = abs(movement.amount)
        date = movement.date
        transferToIncome = movement.linkedIncomeTransactionID != nil
    }

    private func save() {
        validationMessage = nil
        guard amount > 0 else {
            validationMessage = SavingsStrings.text(.fillMovementValue)
            return
        }
        guard kind != .withdrawal || amount <= availableBalanceForWithdrawal else {
            validationMessage = SavingsStrings.text(.withdrawalAboveBalance)
            return
        }

        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let balanceBefore = auditBalance
        let previousNetEffect = auditNetEffect(for: request.movement)
        let newNetEffect = kind == .withdrawal && transferToIncome ? 0 : kind.balanceEffect(for: amount)
        let movement = request.movement ?? SavingMovement(
            savingID: request.saving.id,
            date: date,
            type: kind.rawValue,
            amount: amount,
            note: trimmedNote
        )
        movement.savingID = request.saving.id
        movement.date = date
        movement.type = kind.rawValue
        movement.amount = amount
        movement.note = trimmedNote

        if request.movement == nil {
            modelContext.insert(movement)
        }

        syncLinkedIncomeIfNeeded(for: movement)
        insertAuditLog(
            action: request.movement == nil ? .savingMovementCreated : .savingMovementUpdated,
            title: kind.title,
            amount: abs(amount),
            balanceAfter: balanceBefore - previousNetEffect + newNetEffect,
            savingID: request.saving.id,
            transactionID: movement.linkedIncomeTransactionID,
            note: trimmedNote.isEmpty ? request.saving.displayName : trimmedNote
        )
        saveNotice = .saved(String(format: AppStrings.text(.savingMovementSavedMessage), kind.title))
    }

    private func auditNetEffect(for movement: SavingMovement?) -> Double {
        guard let movement else { return 0 }
        return movement.linkedIncomeTransactionID == nil ? movement.balanceEffect : 0
    }

    private func insertAuditLog(
        action: AuditLogAction,
        title: String,
        amount: Double,
        balanceAfter: Double,
        savingID: UUID? = nil,
        transactionID: UUID? = nil,
        note: String? = nil
    ) {
        modelContext.insert(AuditLogEntry(
            action: action.rawValue,
            title: title,
            details: note ?? "",
            amount: amount,
            balanceAfter: balanceAfter,
            transactionID: transactionID,
            savingID: savingID
        ))
    }

    private func syncLinkedIncomeIfNeeded(for movement: SavingMovement) {
        guard movement.kind == .withdrawal, transferToIncome else {
            deleteLinkedIncomeIfNeeded(for: movement)
            movement.linkedIncomeTransactionID = nil
            return
        }

        let title = movement.note.isEmpty ? request.saving.displayName : movement.note
        let existingTransaction = linkedIncomeTransaction(for: movement)
        let transaction = existingTransaction ?? MoneyTransaction(
            title: title,
            day: Calendar.current.component(.day, from: movement.date),
            monthStart: movement.date.monthStart,
            amount: abs(movement.amount),
            kind: TransactionKind.income.rawValue,
            repeatsEveryMonth: false,
            isPaid: true,
            accountID: primarySpendAccountID
        )
        transaction.title = title
        transaction.day = Calendar.current.component(.day, from: movement.date)
        transaction.monthStart = movement.date.monthStart
        transaction.amount = abs(movement.amount)
        transaction.kind = TransactionKind.income.rawValue
        transaction.repeatsEveryMonth = false
        transaction.isPaid = true
        transaction.expenseCategory = nil
        transaction.expenseName = nil
        transaction.linkedSavingID = request.saving.id
        transaction.linkedSavingMovementID = movement.id
        transaction.accountID = transaction.accountID ?? primarySpendAccountID

        if existingTransaction == nil {
            modelContext.insert(transaction)
        }
        syncLinkedIncomeAccountMovementIfNeeded(transaction, movement: movement)
        movement.linkedIncomeTransactionID = transaction.id
    }

    private func linkedIncomeTransaction(for movement: SavingMovement) -> MoneyTransaction? {
        guard let id = movement.linkedIncomeTransactionID else { return nil }
        return transactions.first { $0.id == id }
    }

    private func deleteLinkedIncomeIfNeeded(for movement: SavingMovement) {
        if let transaction = linkedIncomeTransaction(for: movement) {
            accountMovements
                .filter { $0.transactionID == transaction.id && $0.kind == .income }
                .forEach(modelContext.delete)
            modelContext.delete(transaction)
        }
    }

    private func syncLinkedIncomeAccountMovementIfNeeded(_ transaction: MoneyTransaction, movement: SavingMovement) {
        guard let accountID = transaction.accountID else { return }
        let note = transaction.displayName
        if let accountMovement = accountMovements.first(where: { $0.transactionID == transaction.id && $0.kind == .income }) {
            accountMovement.accountID = accountID
            accountMovement.date = movement.date
            accountMovement.amount = abs(movement.amount)
            accountMovement.note = note
        } else {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                transactionID: transaction.id,
                date: movement.date,
                type: AccountMovementKind.income.rawValue,
                amount: abs(movement.amount),
                note: note
            ))
        }
    }
}
