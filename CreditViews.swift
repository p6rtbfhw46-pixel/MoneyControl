//
//  CreditViews.swift
//  MoneyControl
//

import Charts
import SwiftData
import SwiftUI

struct CreditsSettingsView: View {
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
                    Text(credit.name)
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

    let request: CreditEditorRequest

    @State private var name = ""
    @State private var type: CreditType = .creditCard
    @State private var currentDebt = 0.0
    @State private var creditLimit = 0.0
    @State private var status: CreditStatus = .active
    @State private var validationMessage: String?

    private var isEditing: Bool { request.credit != nil }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    TextField(CreditStrings.text(.creditName), text: $name)
                        .foregroundStyle(AppPalette.background)
                        .tint(AppPalette.primary)

                    Picker(CreditStrings.text(.creditType), selection: $type) {
                        ForEach(CreditType.allCases) { type in
                            Label(type.title, systemImage: type.iconName).tag(type)
                        }
                    }
                    .tint(AppPalette.background)

                    Picker(CreditStrings.text(.active), selection: $status) {
                        ForEach(CreditStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    .tint(AppPalette.background)
                }
                .listRowBackground(AppPalette.surface)

                Section {
                    MoneyAmountPicker(title: CreditStrings.text(.currentDebt), amount: $currentDebt, maximumAmount: 1_000_000)
                    MoneyAmountPicker(title: "\(CreditStrings.text(.creditLimit)) · \(CreditStrings.text(.optionalLimit))", amount: $creditLimit, maximumAmount: 1_000_000)
                }
                .listRowBackground(AppPalette.surface)
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
        }
    }

    private func loadInitialValues() {
        guard let credit = request.credit else { return }
        name = credit.name
        type = credit.creditType
        currentDebt = credit.initialDebt
        creditLimit = credit.creditLimit ?? 0
        status = credit.creditStatus
    }

    private func save() {
        validationMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = CreditStrings.text(.fillCreditName)
            return
        }

        guard currentDebt > 0 || isEditing else {
            validationMessage = CreditStrings.text(.fillCreditValue)
            return
        }

        let credit = request.credit ?? CreditAccount(name: trimmedName, type: type.rawValue, initialDebt: currentDebt)
        credit.name = trimmedName
        credit.type = type.rawValue
        credit.initialDebt = currentDebt
        credit.creditLimit = creditLimit > 0 ? creditLimit : nil
        credit.status = status.rawValue

        if request.credit == nil {
            modelContext.insert(credit)
        }

        dismiss()
    }
}

struct CreditDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allMovements: [CreditMovement]

    let credit: CreditAccount

    @State private var creditEditorRequest: CreditEditorRequest?
    @State private var movementEditorRequest: CreditMovementEditorRequest?

    private var movements: [CreditMovement] { credit.movements(from: allMovements) }
    private var balance: Double { credit.balance(with: allMovements) }
    private var monthStart: Date { Date().monthStart }
    private var monthIncrease: Double { credit.monthDebtIncrease(in: monthStart, movements: allMovements) }
    private var monthPaid: Double { credit.monthPaid(in: monthStart, movements: allMovements) }
    private var monthVariation: Double { credit.monthVariation(in: monthStart, movements: allMovements) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    debtHeader
                    if credit.creditLimit != nil { limitCard }
                    monthSummaryCard
                    if !balancePoints.isEmpty { evolutionCard }
                    settledSuggestion
                    movementsSection
                }
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(credit.name)
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
                CreditEditor(request: request)
            }
            .sheet(item: $movementEditorRequest) { request in
                CreditMovementEditor(request: request)
            }
        }
    }

    private var debtHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(credit.name)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(CreditStrings.text(.debtEvolution))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

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
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
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
                Text(CreditStrings.text(.movements))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                Spacer()
                Button {
                    movementEditorRequest = CreditMovementEditorRequest(credit: credit)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppPalette.primary)
                }
                .buttonStyle(.plain)
            }

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
                                onDelete: { modelContext.delete(movement) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var movementGroups: [CreditMovementGroup] {
        Dictionary(grouping: movements, by: { $0.date.monthStart })
            .map { CreditMovementGroup(month: $0.key, movements: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    private var balancePoints: [CreditBalancePoint] {
        let firstMonth = min(credit.createdAt.monthStart, movements.map(\.date.monthStart).min() ?? Date().monthStart)
        let months = months(from: firstMonth, through: Date().monthStart).suffix(12)
        return months.map { month in
            let movementsUntilMonth = allMovements.filter { $0.creditID == credit.id && $0.date.monthStart <= month }
            return CreditBalancePoint(month: month, balance: credit.balance(with: movementsUntilMonth))
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

    let request: CreditMovementEditorRequest

    @State private var kind: CreditMovementKind = .debtIncrease
    @State private var note = ""
    @State private var amount = 0.0
    @State private var date = Date()
    @State private var adjustmentIsPositive = true
    @State private var validationMessage: String?

    private var isEditing: Bool { request.movement != nil }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    ValidationBanner(message: validationMessage)
                        .listRowBackground(AppPalette.appBackground)
                }

                Section {
                    Picker(CreditStrings.text(.movementType), selection: $kind) {
                        ForEach(CreditMovementKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.iconName).tag(kind)
                        }
                    }
                    .tint(AppPalette.background)

                    if kind == .adjustment {
                        Picker(CreditStrings.text(.adjustment), selection: $adjustmentIsPositive) {
                            Text("+").tag(true)
                            Text("-").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }

                    DatePicker(CreditStrings.text(.movementDate), selection: $date, displayedComponents: .date)
                        .tint(AppPalette.primary)

                    TextField(CreditStrings.text(.movementNote), text: $note)
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
            .onAppear(perform: loadInitialValues)
        }
    }

    private func loadInitialValues() {
        guard let movement = request.movement else { return }
        kind = movement.kind
        note = movement.note
        amount = abs(movement.amount)
        date = movement.date
        adjustmentIsPositive = movement.amount >= 0
    }

    private func save() {
        validationMessage = nil
        guard amount > 0 else {
            validationMessage = CreditStrings.text(.fillMovementValue)
            return
        }

        let storedAmount = kind == .adjustment && !adjustmentIsPositive ? -amount : amount
        let movement = request.movement ?? CreditMovement(
            creditID: request.credit.id,
            date: date,
            type: kind.rawValue,
            amount: storedAmount,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        movement.creditID = request.credit.id
        movement.date = date
        movement.type = kind.rawValue
        movement.amount = storedAmount
        movement.note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if request.movement == nil {
            modelContext.insert(movement)
        }

        dismiss()
    }
}
