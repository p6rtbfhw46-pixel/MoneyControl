//
//  SavingsViews.swift
//  MoneyControl
//

import Charts
import SwiftData
import SwiftUI

struct SavingsSettingsView: View {
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
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(AppPalette.positive)
                    .frame(width: 46, height: 46)
                    .background(AppPalette.mintSurface, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(saving.name)
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

private struct SavingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [SavingMovement]
    @Query private var transactions: [MoneyTransaction]

    let request: SavingEditorRequest
    var onDelete: (() -> Void)? = nil

    @State private var name = ""
    @State private var currentSaved = 0.0
    @State private var targetAmount = 0.0
    @State private var status: SavingStatus = .active
    @State private var validationMessage: String?
    @State private var showsDeleteConfirmation = false
    @State private var isTargetExpanded = false

    private var isEditing: Bool { request.saving != nil }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    TextField(SavingsStrings.text(.savingName), text: $name)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)

                    Picker(SavingsStrings.text(.active), selection: $status) {
                        ForEach(SavingStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    .tint(AppPalette.background)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    if !isEditing {
                        MoneyAmountPicker(title: SavingsStrings.text(.currentSaved), amount: $currentSaved, maximumAmount: 1_000_000)
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
                    maximumAmount: 1_000_000
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func loadInitialValues() {
        guard let saving = request.saving else { return }
        name = saving.name
        currentSaved = saving.initialAmount
        targetAmount = saving.targetAmount ?? 0
        status = saving.savingStatus
    }

    private func save() {
        validationMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = SavingsStrings.text(.fillSavingName)
            return
        }

        guard currentSaved > 0 || isEditing else {
            validationMessage = SavingsStrings.text(.fillSavingValue)
            return
        }

        let saving = request.saving ?? SavingAccount(name: trimmedName, initialAmount: currentSaved)
        saving.name = trimmedName
        if !isEditing {
            saving.initialAmount = currentSaved
        }
        saving.targetAmount = targetAmount > 0 ? targetAmount : nil
        saving.status = status.rawValue

        if request.saving == nil {
            modelContext.insert(saving)
        }

        dismiss()
    }

    private func deleteSaving() {
        guard let saving = request.saving else { return }

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

    let saving: SavingAccount

    @State private var savingEditorRequest: SavingEditorRequest?
    @State private var movementEditorRequest: SavingMovementEditorRequest?

    private var movements: [SavingMovement] { saving.movements(from: allMovements) }
    private var balance: Double { saving.balance(with: allMovements) }
    private var monthStart: Date { Date().monthStart }
    private var monthDeposits: Double { saving.monthDeposits(in: monthStart, movements: allMovements) }
    private var monthWithdrawals: Double { saving.monthWithdrawals(in: monthStart, movements: allMovements) }
    private var monthVariation: Double { saving.monthVariation(in: monthStart, movements: allMovements) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    savingsHeader
                    if saving.targetAmount != nil { targetCard }
                    monthSummaryCard
                    if !balancePoints.isEmpty { evolutionCard }
                    targetSuggestion
                    movementsSection
                }
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(saving.name)
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
            Text(saving.name)
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

    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(SavingsStrings.text(.movements))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                Spacer()
                Button {
                    movementEditorRequest = SavingMovementEditorRequest(saving: saving)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppPalette.primary)
                }
                .buttonStyle(.plain)
            }

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

    let request: SavingMovementEditorRequest

    @State private var kind: SavingMovementKind = .deposit
    @State private var note = ""
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var transferToIncome = false
    @State private var validationMessage: String?

    private var isEditing: Bool { request.movement != nil }

    private var availableBalanceForWithdrawal: Double {
        let movementsWithoutCurrent = allMovements.filter { movement in
            movement.savingID == request.saving.id && movement.id != request.movement?.id
        }
        return request.saving.balance(with: movementsWithoutCurrent)
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
                    MoneyAmountPicker(title: AppStrings.text(.value), amount: $amount, maximumAmount: 1_000_000)
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
        dismiss()
    }

    private func syncLinkedIncomeIfNeeded(for movement: SavingMovement) {
        guard movement.kind == .withdrawal, transferToIncome else {
            deleteLinkedIncomeIfNeeded(for: movement)
            movement.linkedIncomeTransactionID = nil
            return
        }

        let title = movement.note.isEmpty ? request.saving.name : movement.note
        let existingTransaction = linkedIncomeTransaction(for: movement)
        let transaction = existingTransaction ?? MoneyTransaction(
            title: title,
            day: Calendar.current.component(.day, from: movement.date),
            monthStart: movement.date.monthStart,
            amount: abs(movement.amount),
            kind: TransactionKind.income.rawValue,
            repeatsEveryMonth: false,
            isPaid: true
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

        if existingTransaction == nil {
            modelContext.insert(transaction)
        }
        movement.linkedIncomeTransactionID = transaction.id
    }

    private func linkedIncomeTransaction(for movement: SavingMovement) -> MoneyTransaction? {
        guard let id = movement.linkedIncomeTransactionID else { return nil }
        return transactions.first { $0.id == id }
    }

    private func deleteLinkedIncomeIfNeeded(for movement: SavingMovement) {
        if let transaction = linkedIncomeTransaction(for: movement) {
            modelContext.delete(transaction)
        }
    }
}
