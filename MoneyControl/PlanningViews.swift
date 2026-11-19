//
//  PlanningViews.swift
//  MoneyControl
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private func planningText(_ portuguese: String, _ english: String) -> String {
    AppStrings.currentLanguage == .portuguese ? portuguese : english
}

private func planningMovementNote(for draft: PlanningMovementDraft) -> String {
    let planningName = draft.planning?.name ?? planningText("Planeamento", "Planning")
    var lines = [
        planningText("Planeamento: \(planningName)", "Planning: \(planningName)"),
        planningText("Item: \(draft.item.name)", "Item: \(draft.item.name)"),
        planningText("Movimento: \(draft.title)", "Movement: \(draft.title)")
    ]
    if !draft.item.details.isEmpty {
        lines.append(planningText("Detalhes: \(draft.item.details)", "Details: \(draft.item.details)"))
    }
    if !draft.note.isEmpty {
        lines.append(planningText("Nota: \(draft.note)", "Note: \(draft.note)"))
    }
    return lines.joined(separator: "\n")
}

private func createCurrentAccountEntry(
    for draft: PlanningMovementDraft,
    accountID: UUID,
    accountMovement: AccountMovement,
    modelContext: ModelContext
) {
    let planningName = draft.planning?.name ?? planningText("Planeamento", "Planning")
    var itemTexts = [draft.title]
    if !draft.note.isEmpty {
        itemTexts.append(draft.note)
    }

    let transaction = MoneyTransaction(
        title: itemTexts.joined(separator: " · "),
        day: Calendar.current.component(.day, from: draft.date),
        monthStart: draft.date.monthStart,
        amount: abs(draft.amount),
        kind: TransactionKind.expense.rawValue,
        repeatsEveryMonth: false,
        isPaid: true,
        expenseCategory: ExpenseCategory.wants.rawValue,
        expenseName: planningName,
        accountID: accountID
    )
    let payment = ExpensePayment(
        transactionID: transaction.id,
        monthStart: draft.date.monthStart,
        amountPaid: abs(draft.amount)
    )
    let historyEntry = PaymentHistoryEntry(
        transactionID: transaction.id,
        monthStart: draft.date.monthStart,
        amount: abs(draft.amount),
        paidAt: draft.date,
        note: planningMovementNote(for: draft),
        accountID: accountID
    )

    accountMovement.transactionID = transaction.id
    accountMovement.paymentHistoryID = historyEntry.id
    modelContext.insert(transaction)
    modelContext.insert(payment)
    modelContext.insert(historyEntry)
}

struct PlanningManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plannings: [Planning]
    @Query private var itemTypes: [PlanningItemType]
    @Query private var planningItems: [PlanningItem]
    @Query private var planningMovements: [PlanningMovement]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingMovements: [SavingMovement]

    @State private var editorRequest: PlanningEditorRequest?
    @State private var planningToDelete: Planning?
    @State private var showsDeleteConfirmation = false
    @State private var saveNotice: SaveResultNotice?

    private var orderedPlannings: [Planning] {
        plannings.sorted { first, second in
            if first.planningStatus != second.planningStatus {
                return first.planningStatus.sortRank < second.planningStatus.sortRank
            }
            if first.createdAt != second.createdAt {
                return first.createdAt > second.createdAt
            }
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(AppStrings.currentLanguage == .portuguese ? "ManagementPlaneamentosHero" : "ManagementPlaneamentosHeroEnglish")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: AppPalette.background.opacity(0.10), radius: 12, y: 6)
                    .accessibilityLabel(AppStrings.text(.planningBannerTitle))

                if orderedPlannings.isEmpty {
                    PlanningEmptyState()
                } else {
                    PlanningListSection(
                        plannings: orderedPlannings,
                        itemTypes: itemTypes,
                        items: planningItems,
                        movements: planningMovements,
                        onEdit: { planning in
                            editorRequest = PlanningEditorRequest(planning: planning)
                        },
                        onDelete: { planning in
                            planningToDelete = planning
                            showsDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.planning))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorRequest = PlanningEditorRequest()
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .accessibilityLabel(planningText("Novo planeamento", "New planning"))
            }
        }
        .sheet(item: $editorRequest) { request in
            PlanningEditorView(request: request) { draft in
                savePlanning(draft)
            }
        }
        .alert(item: $saveNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(AppStrings.text(.ok)))
            )
        }
        .alert(planningText("Eliminar planeamento?", "Delete planning?"), isPresented: $showsDeleteConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {
                planningToDelete = nil
            }
            Button(AppStrings.text(.delete), role: .destructive) {
                if let planningToDelete {
                    deletePlanning(planningToDelete)
                }
                planningToDelete = nil
            }
        } message: {
            Text(planningText(
                "Isto elimina o planeamento, os seus itens e os movimentos associados nas contas ou poupanças.",
                "This deletes the planning, its items, and the associated account or savings movements."
            ))
        }
    }

    private func savePlanning(_ draft: PlanningDraft) {
        if let planning = draft.planning {
            planning.name = draft.name
            planning.planningType = draft.type
            planning.totalBudget = draft.totalBudget
            planning.startDate = draft.startDate
            planning.endDate = draft.endDate
            planning.planningStatus = draft.status
            SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningUpdatedMessage), draft.name)))
        } else {
            let planning = Planning(
                name: draft.name,
                type: draft.type.rawValue,
                totalBudget: draft.totalBudget,
                startDate: draft.startDate,
                endDate: draft.endDate,
                status: draft.status.rawValue
            )
            modelContext.insert(planning)
            createSuggestedItemTypes(for: planning, type: draft.type)
            SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningCreatedMessage), draft.name)))
        }
    }

    private func createSuggestedItemTypes(for planning: Planning, type: PlanningType) {
        for (index, template) in type.suggestedItemTypes.enumerated() {
            let itemType = PlanningItemType(
                name: template.name,
                icon: template.icon,
                colorIdentifier: template.color,
                planningId: planning.id,
                isCustom: false
            )
            modelContext.insert(itemType)
            modelContext.insert(PlanningItem(
                planningId: planning.id,
                itemTypeId: itemType.id,
                name: template.name,
                plannedAmount: 0,
                icon: template.icon,
                colorIdentifier: template.color,
                sortOrder: Double(index)
            ))
        }
    }

    private func deletePlanning(_ planning: Planning) {
        for itemType in itemTypes where itemType.planningId == planning.id {
            modelContext.delete(itemType)
        }
        for item in planningItems where item.planningId == planning.id {
            modelContext.delete(item)
        }
        for movement in planningMovements where movement.planningId == planning.id {
            deleteLinkedRealMovement(for: movement)
            modelContext.delete(movement)
        }
        modelContext.delete(planning)
    }

    private func deleteLinkedRealMovement(for movement: PlanningMovement) {
        if let id = movement.linkedAccountMovementID,
           let linkedMovement = accountMovements.first(where: { $0.id == id }) {
            modelContext.delete(linkedMovement)
        }
        if let id = movement.linkedSavingMovementID,
           let linkedMovement = savingMovements.first(where: { $0.id == id }) {
            modelContext.delete(linkedMovement)
        }
    }
}

private struct PlanningListSection: View {
    let plannings: [Planning]
    let itemTypes: [PlanningItemType]
    let items: [PlanningItem]
    let movements: [PlanningMovement]
    let onEdit: (Planning) -> Void
    let onDelete: (Planning) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(plannings) { planning in
                let planningItems = items.filter { $0.planningId == planning.id }
                let planningMovements = movements.filter { $0.planningId == planning.id }
                let plannedAmount = planningItems.reduce(0) { $0 + $1.plannedAmount }
                let realAmount = planningMovements.reduce(0) { $0 + abs($1.amount) }

                NavigationLink {
                    PlanningDetailView(planning: planning)
                } label: {
                    PlanningRow(
                        planning: planning,
                        itemTypeCount: planningItems.count,
                        plannedAmount: plannedAmount,
                        realAmount: realAmount
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        onEdit(planning)
                    } label: {
                        Label(planningText("Editar", "Edit"), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDelete(planning)
                    } label: {
                        Label(AppStrings.text(.delete), systemImage: "trash")
                    }
                }
            }
        }
    }
}

private struct PlanningSummaryStrip: View {
    let activeCount: Int
    let activeBudget: Double
    let realSpent: Double

    var body: some View {
        HStack(spacing: 0) {
            PlanningSummaryMetric(
                icon: "calendar.badge.checkmark",
                title: planningText("Ativos", "Active plans"),
                value: "\(activeCount)",
                tint: .purple
            )

            Divider().padding(.vertical, 14)

            PlanningSummaryMetric(
                icon: "banknote.fill",
                title: planningText("Planeado", "Total planned"),
                value: activeBudget.currencyText,
                tint: AppPalette.savings
            )

            Divider().padding(.vertical, 14)

            PlanningSummaryMetric(
                icon: "chart.bar.fill",
                title: planningText("Movimentos Feitos", "Completed movements"),
                value: realSpent.currencyText,
                tint: AppPalette.primary
            )
        }
        .padding(.vertical, 18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningSummaryMetric: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline.bold())
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(tint.opacity(0.14), in: Circle())

            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppPalette.mediumBlue)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppPalette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
}

private struct PlanningEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("ManagementPlaneamentosIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)

            Text(planningText("Ainda não existem planeamentos", "No planning yet"))
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            Text(planningText(
                "Crie um planeamento para preparar uma viagem, obra, curso ou compra grande.",
                "Create a planning area for a trip, renovation, course or large purchase."
            ))
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(AppPalette.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningRow: View {
    let planning: Planning
    let itemTypeCount: Int
    let plannedAmount: Double
    let realAmount: Double

    private var effectivePlannedAmount: Double {
        planning.totalBudget
    }

    private var progress: Double {
        guard effectivePlannedAmount > 0 else { return 0 }
        return min(realAmount / effectivePlannedAmount, 1)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: planning.planningType.iconName)
                .font(.title2.bold())
                .foregroundStyle(planning.planningType.color)
                .frame(width: 58, height: 58)
                .background(planning.planningType.color.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(planning.name)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                Text(planning.planningType.title)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)

                ProgressView(value: progress)
                    .tint(planning.planningType.color)
                    .progressViewStyle(.linear)

                HStack(spacing: 8) {
                    Text(planning.planningStatus.title)
                        .font(.caption.bold())
                        .foregroundStyle(planning.planningStatus.tint)

                    Text("·")
                        .foregroundStyle(AppPalette.secondaryText)

                    Text(planningText("\(itemTypeCount) itens", "\(itemTypeCount) items"))
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mediumBlue)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(planning.totalBudget.currencyText)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(planningText("Movimentos feitos \(realAmount.currencyText)", "Completed movements \(realAmount.currencyText)"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppPalette.secondaryText)
            }
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct PlanningDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allItemTypes: [PlanningItemType]
    @Query private var allItems: [PlanningItem]
    @Query private var allMovements: [PlanningMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]

    let planning: Planning

    @State private var planningEditorRequest: PlanningEditorRequest?
    @State private var itemTypeEditorRequest: PlanningItemTypeEditorRequest?
    @State private var itemEditorRequest: PlanningItemEditorRequest?
    @State private var movementEditorRequest: PlanningMovementEditorRequest?
    @State private var movementConfirmation: PlanningMovementConfirmation?
    @State private var itemTypeToDelete: PlanningItemType?
    @State private var itemToDelete: PlanningItem?
    @State private var showsDeletePlanningConfirmation = false
    @State private var showsDeleteItemTypeConfirmation = false
    @State private var showsDeleteItemConfirmation = false
    @State private var saveNotice: SaveResultNotice?

    private var itemTypes: [PlanningItemType] {
        allItemTypes
            .filter { $0.planningId == planning.id }
            .sorted { first, second in
                if first.createdAt != second.createdAt {
                    return first.createdAt < second.createdAt
                }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    private var items: [PlanningItem] {
        allItems
            .filter { $0.planningId == planning.id }
            .sorted { first, second in
                let firstOrder = first.sortOrder ?? 0
                let secondOrder = second.sortOrder ?? 0
                if firstOrder != secondOrder {
                    return firstOrder < secondOrder
                }
                if first.createdAt != second.createdAt {
                    return first.createdAt < second.createdAt
                }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    private var movements: [PlanningMovement] {
        allMovements.filter { $0.planningId == planning.id }
    }

    private var plannedAmount: Double {
        items.reduce(0) { $0 + $1.plannedAmount }
    }

    private var realAmount: Double {
        movements.reduce(0) { $0 + abs($1.amount) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlanningDetailHeader(
                    planning: planning,
                    itemCount: items.count,
                    plannedAmount: plannedAmount,
                    realAmount: realAmount
                )

                PlanningIndependenceNotice()

                PlanningBudgetItemsSection(
                    items: items,
                    movements: movements,
                    onAddItem: {
                        itemEditorRequest = PlanningItemEditorRequest(
                            planning: planning,
                            itemTypes: itemTypes,
                            maximumBudget: maximumBudgetForItem(nil)
                        )
                    },
                    onEditItem: { item in
                        itemEditorRequest = PlanningItemEditorRequest(
                            planning: planning,
                            itemTypes: itemTypes,
                            item: item,
                            maximumBudget: maximumBudgetForItem(item)
                        )
                    },
                    onDeleteItem: { item in
                        itemToDelete = item
                        showsDeleteItemConfirmation = true
                    },
                    onMoveItem: { sourceID, destinationID in
                        moveItem(sourceID: sourceID, destinationID: destinationID)
                    }
                )
            }
            .padding(16)
        }
        .background(AppPalette.appBackground)
        .navigationTitle(planning.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        planningEditorRequest = PlanningEditorRequest(planning: planning)
                    } label: {
                        Label(planningText("Editar", "Edit"), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showsDeletePlanningConfirmation = true
                    } label: {
                        Label(AppStrings.text(.delete), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $planningEditorRequest) { request in
            PlanningEditorView(request: request) { draft in
                planning.name = draft.name
                planning.planningType = draft.type
                planning.totalBudget = draft.totalBudget
                planning.startDate = draft.startDate
                planning.endDate = draft.endDate
                planning.planningStatus = draft.status
                SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningUpdatedMessage), draft.name)))
            }
        }
        .sheet(item: $itemTypeEditorRequest) { request in
            PlanningItemTypeEditorView(request: request) { draft in
                saveItemType(draft)
            }
        }
        .sheet(item: $itemEditorRequest) { request in
            PlanningItemEditorView(request: request) { draft in
                saveItem(draft)
            }
        }
        .sheet(item: $movementEditorRequest) { request in
            PlanningMovementEditorView(request: request) { draft in
                if draft.affectMode == .planningOnly {
                    saveMovement(draft)
                } else {
                    movementConfirmation = PlanningMovementConfirmation(draft: draft, item: draft.item, planning: planning)
                }
            }
        }
        .sheet(item: $movementConfirmation) { confirmation in
            PlanningMovementConfirmationView(
                confirmation: confirmation,
                account: confirmation.draft.accountID.flatMap { id in spendAccounts.first { $0.id == id } },
                saving: confirmation.draft.savingID.flatMap { id in savingAccounts.first { $0.id == id } },
                accountMovements: accountMovements,
                savingMovements: savingMovements
            ) {
                saveMovement(confirmation.draft)
                movementConfirmation = nil
            }
        }
        .alert(item: $saveNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(AppStrings.text(.ok)))
            )
        }
        .alert(planningText("Eliminar planeamento?", "Delete planning?"), isPresented: $showsDeletePlanningConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(AppStrings.text(.delete), role: .destructive) {
                deletePlanning()
            }
        } message: {
            Text(planningText(
                "Isto elimina o planeamento, os seus itens e os movimentos associados nas contas ou poupanças.",
                "This deletes the planning, its items, and the associated account or savings movements."
            ))
        }
        .alert(planningText("Eliminar tipo de item?", "Delete item type?"), isPresented: $showsDeleteItemTypeConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {
                itemTypeToDelete = nil
            }
            Button(AppStrings.text(.delete), role: .destructive) {
                if let itemTypeToDelete {
                    modelContext.delete(itemTypeToDelete)
                }
                itemTypeToDelete = nil
            }
        } message: {
            Text(planningText(
                "O planeamento mantém-se. Só remove esta categoria interna.",
                "The planning remains. This only removes this internal category."
            ))
        }
        .alert(planningText("Eliminar item?", "Delete item?"), isPresented: $showsDeleteItemConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {
                itemToDelete = nil
            }
            Button(AppStrings.text(.delete), role: .destructive) {
                if let itemToDelete {
                    deleteItem(itemToDelete)
                }
                itemToDelete = nil
            }
        } message: {
            Text(planningText(
                "Isto elimina o item e os movimentos associados nas contas ou poupanças.",
                "This deletes the item and its associated account or savings movements."
            ))
        }
        .onAppear(perform: ensureItemsForItemTypes)
        .onAppear(perform: normalizeItemSortOrderIfNeeded)
    }

    private func saveItemType(_ draft: PlanningItemTypeDraft) {
        if let itemType = draft.itemType {
            itemType.name = draft.name
            itemType.icon = draft.icon
            itemType.colorIdentifier = draft.colorIdentifier
            SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningItemTypeUpdatedMessage), draft.name)))
        } else {
            modelContext.insert(PlanningItemType(
                name: draft.name,
                icon: draft.icon,
                colorIdentifier: draft.colorIdentifier,
                planningId: planning.id,
                isCustom: true
            ))
            SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningItemTypeCreatedMessage), draft.name)))
        }
    }

    private func maximumBudgetForItem(_ item: PlanningItem?) -> Double {
        let otherItemsBudget = items
            .filter { candidate in
                guard let item else { return true }
                return candidate.id != item.id
            }
            .reduce(0) { $0 + $1.plannedAmount }
        return max(planning.totalBudget - otherItemsBudget, 0)
    }

    private func saveItem(_ draft: PlanningItemDraft) {
        if let item = draft.item {
            item.itemTypeId = draft.itemType?.id ?? item.itemTypeId
            item.name = draft.name
            item.details = draft.details
            item.plannedAmount = draft.plannedAmount
            item.icon = draft.icon
            item.colorIdentifier = draft.colorIdentifier
            SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningItemUpdatedMessage), draft.name)))
        } else {
            let nextOrder = ((items.compactMap(\.sortOrder).max() ?? -1) + 1)
            modelContext.insert(PlanningItem(
                planningId: planning.id,
                itemTypeId: draft.itemType?.id,
                name: draft.name,
                details: draft.details,
                plannedAmount: draft.plannedAmount,
                icon: draft.icon,
                colorIdentifier: draft.colorIdentifier,
                sortOrder: nextOrder
            ))
            SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningItemCreatedMessage), draft.name)))
        }
    }

    private func deleteItem(_ item: PlanningItem) {
        for movement in movements where movement.itemId == item.id {
            deleteLinkedRealMovement(for: movement)
            modelContext.delete(movement)
        }
        if let itemTypeId = item.itemTypeId,
           let itemType = itemTypes.first(where: { $0.id == itemTypeId }) {
            modelContext.delete(itemType)
        }
        modelContext.delete(item)
    }

    private func deletePlanning() {
        for itemType in itemTypes {
            modelContext.delete(itemType)
        }
        for item in items {
            modelContext.delete(item)
        }
        for movement in movements {
            deleteLinkedRealMovement(for: movement)
            modelContext.delete(movement)
        }
        modelContext.delete(planning)
        dismiss()
    }

    private func deleteLinkedRealMovement(for movement: PlanningMovement) {
        if let id = movement.linkedAccountMovementID,
           let linkedMovement = accountMovements.first(where: { $0.id == id }) {
            modelContext.delete(linkedMovement)
        }
        if let id = movement.linkedSavingMovementID,
           let linkedMovement = savingMovements.first(where: { $0.id == id }) {
            modelContext.delete(linkedMovement)
        }
    }

    private func ensureItemsForItemTypes() {
        var nextOrder = (items.compactMap(\.sortOrder).max() ?? -1) + 1
        for itemType in itemTypes where items.first(where: { $0.itemTypeId == itemType.id }) == nil {
            modelContext.insert(PlanningItem(
                planningId: planning.id,
                itemTypeId: itemType.id,
                name: itemType.name,
                plannedAmount: 0,
                icon: itemType.icon,
                colorIdentifier: itemType.colorIdentifier,
                sortOrder: nextOrder
            ))
            nextOrder += 1
        }
    }

    private func normalizeItemSortOrderIfNeeded() {
        guard !items.isEmpty else { return }
        let hasMeaningfulOrder = items.contains { ($0.sortOrder ?? 0) != 0 }
        guard !hasMeaningfulOrder else { return }

        for (index, item) in items.enumerated() {
            item.sortOrder = Double(index)
        }
    }

    private func moveItem(sourceID: UUID, destinationID: UUID) {
        var orderedItems = items
        guard let sourceIndex = orderedItems.firstIndex(where: { $0.id == sourceID }),
              let destinationIndex = orderedItems.firstIndex(where: { $0.id == destinationID }),
              sourceIndex != destinationIndex
        else { return }

        let movedItem = orderedItems.remove(at: sourceIndex)
        orderedItems.insert(movedItem, at: destinationIndex)

        for (index, item) in orderedItems.enumerated() {
            item.sortOrder = Double(index)
        }
    }

    private func movementRequest(for item: PlanningItem) -> PlanningMovementEditorRequest {
        PlanningMovementEditorRequest(
            item: item,
            planning: planning,
            accounts: spendAccounts.sorted { $0.createdAt < $1.createdAt },
            accountMovements: accountMovements,
            savings: savingAccounts.sorted { $0.createdAt < $1.createdAt },
            savingMovements: savingMovements
        )
    }

    private func saveMovement(_ draft: PlanningMovementDraft) {
        PlanningMovementWriter.save(
            draft,
            modelContext: modelContext,
            spendAccounts: spendAccounts,
            accountMovements: accountMovements,
            savingAccounts: savingAccounts,
            savingMovements: savingMovements
        )
        SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningMovementSavedMessage), draft.title)))
    }
}

private struct PlanningItemTypesSection: View {
    let itemTypes: [PlanningItemType]
    let onAdd: () -> Void
    let onEdit: (PlanningItemType) -> Void
    let onDelete: (PlanningItemType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(planningText("Tipos de item", "Item types"))
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(width: 38, height: 38)
                        .background(AppPalette.appBackground, in: Circle())
                }
                .accessibilityLabel(planningText("Adicionar tipo de item", "Add item type"))
            }

            if itemTypes.isEmpty {
                Text(planningText(
                    "Adicione tipos para organizar os itens deste planeamento.",
                    "Add types to organize this planning's items."
                ))
                .font(.subheadline)
                .foregroundStyle(AppPalette.mutedText)
            } else {
                VStack(spacing: 10) {
                    ForEach(itemTypes) { itemType in
                        PlanningItemTypeRow(
                            itemType: itemType,
                            onEdit: {
                                onEdit(itemType)
                            },
                            onDelete: {
                                onDelete(itemType)
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningDetailHeader: View {
    let planning: Planning
    let itemCount: Int
    let plannedAmount: Double
    let realAmount: Double

    private var remainingAmount: Double {
        max(plannedAmount - realAmount, 0)
    }

    private var unplannedAmount: Double {
        max(planning.totalBudget - plannedAmount, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: planning.planningType.iconName)
                    .font(.title.bold())
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 64, height: 64)
                    .background(planning.planningType.color, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(planning.name)
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.background)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(planning.planningType.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.mutedText)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    PlanningMetric(title: planningText("Orçamento", "Budget"), value: planning.totalBudget.currencyText)
                    Divider().padding(.vertical, 8)
                    PlanningMetric(title: planningText("Por planear", "Unplanned"), value: unplannedAmount.currencyText)
                }

                HStack(spacing: 0) {
                    PlanningMetric(title: planningText("Planeado", "Planned"), value: plannedAmount.currencyText)
                    Divider().padding(.vertical, 8)
                    PlanningMetric(title: planningText("Movimentos Feitos", "Completed movements"), value: realAmount.currencyText)
                    Divider().padding(.vertical, 8)
                    PlanningMetric(title: planningText("Restante", "Remaining"), value: remainingAmount.currencyText)
                }
            }
            .padding(.vertical, 4)
            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 8) {
                Label(planning.planningStatus.title, systemImage: "circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(planning.planningStatus.tint)

                if let dateDescription = planning.dateDescription {
                    Text(dateDescription)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mediumBlue)
                }

                Text("·")
                    .foregroundStyle(AppPalette.secondaryText)

                Text(planningText("\(itemCount) itens", "\(itemCount) items"))
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.mediumBlue)
            }
        }
        .padding(18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}

private struct PlanningBudgetItemsSection: View {
    let items: [PlanningItem]
    let movements: [PlanningMovement]
    let onAddItem: () -> Void
    let onEditItem: (PlanningItem) -> Void
    let onDeleteItem: (PlanningItem) -> Void
    let onMoveItem: (UUID, UUID) -> Void

    @State private var expandedItemID: UUID?
    @State private var draggingItem: PlanningItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(planningText("Itens", "Items"))
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Button(action: onAddItem) {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 38, height: 38)
                        .background(AppPalette.background, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(planningText("Adicionar item", "Add item"))
            }

            if items.isEmpty {
                Text(planningText(
                    "Os itens sugeridos aparecem aqui para distribuir o orçamento e adicionar movimentos.",
                    "Suggested items appear here to distribute the budget and add movements."
                ))
                .font(.subheadline)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        PlanningItemNavigationRow(
                            item: item,
                            realAmount: item.realAmount(from: movements),
                            isExpanded: expandedItemID == item.id,
                            draggingItem: $draggingItem,
                            onToggle: {
                                withAnimation(.snappy) {
                                    expandedItemID = expandedItemID == item.id ? nil : item.id
                                }
                            },
                            onEdit: {
                                onEditItem(item)
                            },
                            onDelete: {
                                onDeleteItem(item)
                            },
                            onMove: { sourceID, destinationID in
                                onMoveItem(sourceID, destinationID)
                            }
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningItemNavigationRow: View {
    let item: PlanningItem
    let realAmount: Double
    let isExpanded: Bool
    @Binding var draggingItem: PlanningItem?
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: (UUID, UUID) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onToggle) {
                PlanningItemRow(item: item, realAmount: realAmount, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)
            .onDrag {
                draggingItem = item
                return NSItemProvider(object: item.id.uuidString as NSString)
            }
            .onDrop(
                of: [UTType.text],
                delegate: PlanningItemDropDelegate(
                    destinationItem: item,
                    draggingItem: $draggingItem,
                    onMove: onMove
                )
            )

            if isExpanded {
                PlanningItemActionTray(
                    item: item,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private struct PlanningItemDropDelegate: DropDelegate {
    let destinationItem: PlanningItem
    @Binding var draggingItem: PlanningItem?
    let onMove: (UUID, UUID) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingItem, draggingItem.id != destinationItem.id else { return }
        onMove(draggingItem.id, destinationItem.id)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
}

private struct PlanningItemActionTray: View {
    let item: PlanningItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            NavigationLink {
                PlanningItemDetailView(item: item)
            } label: {
                PlanningActionPill(title: planningText("Orçamento / Movimentos", "Budget / Movements"), icon: "list.bullet.rectangle")
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                PlanningIconActionButton(icon: "pencil", tint: AppPalette.background)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(planningText("Editar", "Edit"))

            Button(role: .destructive, action: onDelete) {
                PlanningIconActionButton(icon: "trash", tint: AppPalette.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.text(.delete))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppPalette.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct PlanningActionPill: View {
    let title: String
    let icon: String
    var tint: Color = AppPalette.background

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(AppPalette.appBackground.opacity(0.75), in: Capsule())
    }
}

private struct PlanningIconActionButton: View {
    let icon: String
    let tint: Color

    var body: some View {
        Image(systemName: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(AppPalette.appBackground.opacity(0.75), in: Circle())
    }
}

private struct PlanningItemRow: View {
    let item: PlanningItem
    let realAmount: Double
    let isExpanded: Bool

    private var progress: Double {
        guard item.plannedAmount > 0 else { return 0 }
        return min(realAmount / item.plannedAmount, 1)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.title3.bold())
                .foregroundStyle(item.tint)
                .frame(width: 58, height: 58)
                .background(item.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                if !item.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.details)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(1)
                }

                ProgressView(value: progress)
                    .tint(item.tint)
                    .progressViewStyle(.linear)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.plannedAmount.currencyText)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(planningText("\(realAmount.currencyText) real", "\(realAmount.currencyText) real"))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(item.tint)
            }

            Image(systemName: "chevron.down")
                .font(.headline)
                .foregroundStyle(AppPalette.secondaryText)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(12)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PlanningIndependenceNotice: View {
    var body: some View {
        Label {
            Text(planningText(
                "Área independente: criar ou editar planeamentos e tipos de item não altera Conta Corrente, contas, poupanças, créditos, despesas ou análises. Pode arrastar os itens para ficarem na ordem que preferir.",
                "Independent area: creating or editing planning and item types does not change Current Account, accounts, savings, credits, expenses or analytics. You can drag items into your preferred order."
            ))
            .font(.footnote)
            .foregroundStyle(AppPalette.mutedText)
            .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppPalette.mediumBlue)
        }
        .padding(14)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct PlanningItemTypeRow: View {
    let itemType: PlanningItemType
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: itemType.iconName)
                .font(.headline.bold())
                .foregroundStyle(itemType.tint)
                .frame(width: 42, height: 42)
                .background(itemType.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(itemType.name)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                Text(itemType.isCustom ? planningText("Personalizado", "Custom") : planningText("Sugerido", "Suggested"))
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.mutedText)
            }

            Spacer()

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label(planningText("Editar", "Edit"), systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(AppStrings.text(.delete), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(AppPalette.mutedText)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(12)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PlanningItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var plannings: [Planning]
    @Query private var allItems: [PlanningItem]
    @Query private var allMovements: [PlanningMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]

    let item: PlanningItem

    @State private var movementEditorRequest: PlanningMovementEditorRequest?
    @State private var movementConfirmation: PlanningMovementConfirmation?
    @State private var movementToDelete: PlanningMovement?
    @State private var showsDeleteMovementConfirmation = false
    @State private var isBudgetExpanded = false
    @State private var saveNotice: SaveResultNotice?

    private var planning: Planning? {
        plannings.first { $0.id == item.planningId }
    }

    private var otherItemsBudget: Double {
        allItems
            .filter { $0.planningId == item.planningId && $0.id != item.id }
            .reduce(0) { $0 + $1.plannedAmount }
    }

    private var maximumItemBudget: Double {
        max((planning?.totalBudget ?? item.plannedAmount) - otherItemsBudget, 0)
    }

    private var itemMovements: [PlanningMovement] {
        allMovements
            .filter { $0.itemId == item.id }
            .sorted { $0.date == $1.date ? $0.title < $1.title : $0.date > $1.date }
    }

    private var realAmount: Double {
        itemMovements.reduce(0) { $0 + abs($1.amount) }
    }

    private var remainingAmount: Double {
        max(item.plannedAmount - realAmount, 0)
    }

    private var progress: Double {
        guard item.plannedAmount > 0 else { return 0 }
        return min(realAmount / item.plannedAmount, 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlanningItemDetailHeader(
                    item: item,
                    planning: planning,
                    realAmount: realAmount,
                    remainingAmount: remainingAmount,
                    progress: progress
                )

                DisclosureGroup(isExpanded: $isBudgetExpanded) {
                    PlanningItemBudgetConfigurator(
                        item: item,
                        maximumBudget: maximumItemBudget,
                        otherItemsBudget: otherItemsBudget,
                        planningBudget: planning?.totalBudget ?? 0
                    )
                    .padding(.top, 12)
                } label: {
                    HStack {
                        Text(planningText("Orçamento", "Budget"))
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.background)

                        Spacer()

                        Text(item.plannedAmount.currencyText)
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.mediumBlue)
                    }
                }
                .padding(16)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 12) {
                    Text(planningText("Movimentos", "Movements"))
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.background)

                    if itemMovements.isEmpty {
                        Text(planningText(
                            "Ainda não existem movimentos neste item.",
                            "There are no movements in this item yet."
                        ))
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(itemMovements) { movement in
                                PlanningMovementRow(
                                    movement: movement,
                                    accountName: movement.linkedAccountID.flatMap { id in spendAccounts.first(where: { $0.id == id })?.displayName },
                                    savingName: movement.linkedSavingID.flatMap { id in savingAccounts.first(where: { $0.id == id })?.displayName },
                                    onEdit: {
                                        movementEditorRequest = PlanningMovementEditorRequest(
                                            item: item,
                                            planning: planning,
                                            movement: movement,
                                            accounts: spendAccounts.sorted { $0.createdAt < $1.createdAt },
                                            accountMovements: accountMovements,
                                            savings: savingAccounts.sorted { $0.createdAt < $1.createdAt },
                                            savingMovements: savingMovements
                                        )
                                    },
                                    onDelete: {
                                        movementToDelete = movement
                                        showsDeleteMovementConfirmation = true
                                    }
                                )
                                .contextMenu {
                                    Button {
                                        movementEditorRequest = PlanningMovementEditorRequest(
                                            item: item,
                                            planning: planning,
                                            movement: movement,
                                            accounts: spendAccounts.sorted { $0.createdAt < $1.createdAt },
                                            accountMovements: accountMovements,
                                            savings: savingAccounts.sorted { $0.createdAt < $1.createdAt },
                                            savingMovements: savingMovements
                                        )
                                    } label: {
                                        Label(planningText("Editar", "Edit"), systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        movementToDelete = movement
                                        showsDeleteMovementConfirmation = true
                                    } label: {
                                        Label(AppStrings.text(.delete), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    movementEditorRequest = PlanningMovementEditorRequest(
                        item: item,
                        planning: planning,
                        accounts: spendAccounts.sorted { $0.createdAt < $1.createdAt },
                        accountMovements: accountMovements,
                        savings: savingAccounts.sorted { $0.createdAt < $1.createdAt },
                        savingMovements: savingMovements
                    )
                } label: {
                    Label(planningText("Adicionar movimento", "Add movement"), systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(AppPalette.appBackground)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $movementEditorRequest) { request in
            PlanningMovementEditorView(request: request) { draft in
                let existingAlreadyAffectsSpendWise = draft.movement != nil && draft.movement?.affectMode != .planningOnly
                if draft.affectMode == .planningOnly || existingAlreadyAffectsSpendWise {
                    saveMovement(draft)
                } else {
                    movementConfirmation = PlanningMovementConfirmation(draft: draft, item: item, planning: planning)
                }
            }
        }
        .sheet(item: $movementConfirmation) { confirmation in
            PlanningMovementConfirmationView(
                confirmation: confirmation,
                account: confirmation.draft.accountID.flatMap { id in spendAccounts.first { $0.id == id } },
                saving: confirmation.draft.savingID.flatMap { id in savingAccounts.first { $0.id == id } },
                accountMovements: accountMovements,
                savingMovements: savingMovements
            ) {
                saveMovement(confirmation.draft)
                movementConfirmation = nil
            }
        }
        .alert(item: $saveNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(AppStrings.text(.ok)))
            )
        }
        .alert(planningText("Eliminar movimento?", "Delete movement?"), isPresented: $showsDeleteMovementConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {
                movementToDelete = nil
            }
            Button(AppStrings.text(.delete), role: .destructive) {
                if let movementToDelete {
                    deleteLinkedRealMovement(for: movementToDelete)
                    modelContext.delete(movementToDelete)
                }
                movementToDelete = nil
            }
        } message: {
            Text(planningText(
                "Remove o movimento do planeamento e o movimento associado da conta ou poupança.",
                "Removes the planning movement and its associated account or savings movement."
            ))
        }
    }

    private func deleteLinkedRealMovement(for movement: PlanningMovement) {
        if let accountMovementID = movement.linkedAccountMovementID,
           let accountMovement = accountMovements.first(where: { $0.id == accountMovementID }) {
            modelContext.delete(accountMovement)
        }
        if let savingMovementID = movement.linkedSavingMovementID,
           let savingMovement = savingMovements.first(where: { $0.id == savingMovementID }) {
            modelContext.delete(savingMovement)
        }
    }

    private func saveMovement(_ draft: PlanningMovementDraft) {
        let isNewMovement = draft.movement == nil
        let movement = draft.movement ?? PlanningMovement(
            planningId: item.planningId,
            itemId: item.id,
            date: draft.date,
            title: draft.title,
            amount: draft.amount,
            note: draft.note,
            affectModeRawValue: draft.affectMode.rawValue,
            linkedAccountID: draft.accountID,
            linkedSavingID: draft.savingID
        )

        let wasPlanningOnly = movement.affectMode == .planningOnly
        movement.date = draft.date
        movement.title = draft.title
        movement.amount = draft.amount
        movement.note = draft.note
        let realMovementNote = planningMovementNote(for: draft)

        if wasPlanningOnly {
            movement.affectModeRawValue = draft.affectMode.rawValue
            movement.linkedAccountID = draft.accountID
            movement.linkedSavingID = draft.savingID
        }

        switch wasPlanningOnly ? draft.affectMode : movement.affectMode {
        case .planningOnly:
            break
        case .account:
            if (isNewMovement || wasPlanningOnly), let accountID = draft.accountID {
                let realMovement = AccountMovement(
                    accountID: accountID,
                    date: draft.date,
                    type: AccountMovementKind.expensePayment.rawValue,
                    amount: -abs(draft.amount),
                    note: realMovementNote
                )
                modelContext.insert(realMovement)
                movement.linkedAccountMovementID = realMovement.id
                createCurrentAccountEntry(
                    for: draft,
                    accountID: accountID,
                    accountMovement: realMovement,
                    modelContext: modelContext
                )
                insertAccountAudit(for: realMovement)
            } else if let movementID = movement.linkedAccountMovementID,
                      let realMovement = accountMovements.first(where: { $0.id == movementID }) {
                realMovement.date = draft.date
                realMovement.amount = -abs(draft.amount)
                realMovement.note = realMovementNote
            }
        case .saving:
            if (isNewMovement || wasPlanningOnly), let savingID = draft.savingID {
                let realMovement = SavingMovement(
                    savingID: savingID,
                    date: draft.date,
                    type: SavingMovementKind.withdrawal.rawValue,
                    amount: abs(draft.amount),
                    note: realMovementNote
                )
                modelContext.insert(realMovement)
                movement.linkedSavingMovementID = realMovement.id
                insertSavingAudit(for: realMovement)
            } else if let movementID = movement.linkedSavingMovementID,
                      let realMovement = savingMovements.first(where: { $0.id == movementID }) {
                realMovement.date = draft.date
                realMovement.amount = abs(draft.amount)
                realMovement.note = realMovementNote
            }
        }

        if isNewMovement {
            modelContext.insert(movement)
        }

        SaveResultNoticeCenter.shared.show(.saved(String(format: AppStrings.text(.planningMovementSavedMessage), draft.title)))
    }

    private func insertAccountAudit(for movement: AccountMovement) {
        let balanceAfter = spendAccounts.first { $0.id == movement.accountID }?.balance(with: accountMovements) ?? 0
        modelContext.insert(AuditLogEntry(
            action: AuditLogAction.accountBalanceAdjusted.rawValue,
            title: movement.note,
            details: planningText("Movimento de planeamento", "Planning movement"),
            amount: movement.amount,
            balanceAfter: balanceAfter + movement.amount,
            accountID: movement.accountID
        ))
    }

    private func insertSavingAudit(for movement: SavingMovement) {
        let balanceAfter = savingAccounts.first { $0.id == movement.savingID }?.balance(with: savingMovements) ?? 0
        modelContext.insert(AuditLogEntry(
            action: AuditLogAction.savingMovementCreated.rawValue,
            title: movement.note,
            details: planningText("Movimento de planeamento", "Planning movement"),
            amount: -abs(movement.amount),
            balanceAfter: max(balanceAfter - abs(movement.amount), 0),
            savingID: movement.savingID
        ))
    }
}

private struct PlanningItemDetailHeader: View {
    let item: PlanningItem
    let planning: Planning?
    let realAmount: Double
    let remainingAmount: Double
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: item.iconName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(item.tint)
                    .frame(width: 86, height: 86)
                    .background(item.tint.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.background)
                        .fixedSize(horizontal: false, vertical: true)

                    if let planning {
                        Text("\(planning.name) · \(planning.planningType.title)")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.mediumBlue)
                    }
                }
            }

            HStack(spacing: 12) {
                PlanningMetric(title: planningText("Planeado", "Planned"), value: item.plannedAmount.currencyText)
                PlanningMetric(title: planningText("Movimentos Feitos", "Completed movements"), value: realAmount.currencyText)
                PlanningMetric(title: planningText("Restante", "Remaining"), value: remainingAmount.currencyText)
            }
            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 16))

            HStack {
                ProgressView(value: progress)
                    .tint(item.tint)
                    .progressViewStyle(.linear)

                Text("\(Int(progress * 100))%")
                    .font(.headline.bold())
                    .foregroundStyle(item.tint)
            }
        }
        .padding(18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningItemBudgetConfigurator: View {
    let item: PlanningItem
    let maximumBudget: Double
    let otherItemsBudget: Double
    let planningBudget: Double

    @State private var draftBudget: Double = 0

    private var sliderRange: ClosedRange<Double> {
        0...max(maximumBudget, 0)
    }

    private var availableText: String {
        let remaining = max(planningBudget - otherItemsBudget - draftBudget, 0)
        return planningText(
            "\(remaining.currencyText) ainda livres no planeamento",
            "\(remaining.currencyText) still free in planning"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(planningText("Orçamento do item", "Item budget"))
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text(draftBudget.currencyText)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }

            HStack(spacing: 12) {
                Button {
                    adjustBudget(by: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(width: 42, height: 42)
                        .background(AppPalette.appBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(draftBudget <= 0)
                .opacity(draftBudget <= 0 ? 0.45 : 1)
                .accessibilityLabel(planningText("Reduzir orçamento", "Decrease budget"))

                Slider(value: $draftBudget, in: sliderRange, step: 1)
                    .tint(item.tint)
                    .onChange(of: draftBudget) { _, newValue in
                        item.plannedAmount = min(max(newValue, 0), maximumBudget)
                    }

                Button {
                    adjustBudget(by: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 42, height: 42)
                        .background(item.tint, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(draftBudget >= maximumBudget)
                .opacity(draftBudget >= maximumBudget ? 0.45 : 1)
                .accessibilityLabel(planningText("Aumentar orçamento", "Increase budget"))
            }

            HStack {
                Text(Double.zero.currencyText)
                Spacer()
                Text(maximumBudget.currencyText)
            }
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)

            Text(availableText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppPalette.mediumBlue)
        }
        .padding(18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
        .onAppear {
            draftBudget = min(max(item.plannedAmount, 0), maximumBudget)
        }
        .onChange(of: item.plannedAmount) { _, newValue in
            draftBudget = min(max(newValue, 0), maximumBudget)
        }
    }

    private func adjustBudget(by delta: Double) {
        let adjusted = min(max(draftBudget + delta, 0), maximumBudget)
        draftBudget = adjusted
        item.plannedAmount = adjusted
    }
}

private struct PlanningMovementRow: View {
    let movement: PlanningMovement
    let accountName: String?
    let savingName: String?
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var sourceText: String {
        switch movement.affectMode {
        case .planningOnly:
            return planningText("Só planeamento", "Only planning")
        case .account:
            return accountName.map { planningText("Conta: \($0)", "Account: \($0)") } ?? movement.affectMode.title
        case .saving:
            return savingName.map { planningText("Poupança: \($0)", "Saving: \($0)") } ?? movement.affectMode.title
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: movement.date))")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                Text(movement.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }
            .frame(width: 54, height: 62)
            .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))

            Image(systemName: movement.affectMode.iconName)
                .font(.headline.bold())
                .foregroundStyle(movement.affectMode.tint)
                .frame(width: 48, height: 48)
                .background(movement.affectMode.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(movement.title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                if !movement.note.isEmpty {
                    Text(movement.note)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(2)
                }

                Text(sourceText)
                    .font(.caption.bold())
                    .foregroundStyle(movement.affectMode.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(movement.affectMode.tint.opacity(0.12), in: Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(abs(movement.amount).currencyText)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Menu {
                    Button(action: onEdit) {
                        Label(planningText("Editar", "Edit"), systemImage: "pencil")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label(AppStrings.text(.delete), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundStyle(AppPalette.mutedText)
                        .frame(width: 32, height: 28)
                }
            }
        }
        .padding(14)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct PlanningItemEditorRequest: Identifiable {
    let id = UUID()
    let planning: Planning
    let itemTypes: [PlanningItemType]
    let item: PlanningItem?
    let maximumBudget: Double

    init(planning: Planning, itemTypes: [PlanningItemType], item: PlanningItem? = nil, maximumBudget: Double) {
        self.planning = planning
        self.itemTypes = itemTypes
        self.item = item
        self.maximumBudget = maximumBudget
    }
}

struct PlanningItemDraft {
    let item: PlanningItem?
    let itemType: PlanningItemType?
    let name: String
    let details: String
    let plannedAmount: Double
    let icon: String
    let colorIdentifier: String
}

struct PlanningItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let request: PlanningItemEditorRequest
    let onSave: (PlanningItemDraft) -> Void

    @State private var name: String
    @State private var details: String
    @State private var plannedAmount: Double
    @State private var icon: String
    @State private var colorIdentifier: String

    private let iconOptions = ["tag.fill", "airplane", "car.fill", "bed.double.fill", "fork.knife", "ticket.fill", "bag.fill", "gift.fill", "hammer.fill", "book.fill", "shippingbox.fill", "camera.fill", "leaf.fill", "ellipsis.circle.fill"]
    private let colorOptions = ["blue", "green", "orange", "purple", "teal", "pink", "red", "yellow", "gray"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(request: PlanningItemEditorRequest, onSave: @escaping (PlanningItemDraft) -> Void) {
        self.request = request
        self.onSave = onSave
        _name = State(initialValue: request.item?.name ?? "")
        _details = State(initialValue: request.item?.details ?? "")
        _plannedAmount = State(initialValue: min(max(request.item?.plannedAmount ?? 0, 0), request.maximumBudget))
        _icon = State(initialValue: request.item?.iconName ?? "tag.fill")
        _colorIdentifier = State(initialValue: request.item?.colorIdentifier ?? "blue")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PlanningTextInput(title: planningText("Nome", "Name"), placeholder: planningText("Ex.: Restaurantes e compras", "E.g. Restaurants and groceries"), text: $name)
                    PlanningTextInput(title: planningText("Descrição", "Description"), placeholder: planningText("Opcional", "Optional"), text: $details)

                    PlanningItemEditorBudgetSlider(
                        plannedAmount: $plannedAmount,
                        maximumBudget: request.maximumBudget
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Ícone", "Icon"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 10)], spacing: 10) {
                            ForEach(iconOptions, id: \.self) { option in
                                Button {
                                    icon = option
                                } label: {
                                    Image(systemName: option)
                                        .font(.headline)
                                        .foregroundStyle(icon == option ? AppPalette.surface : AppPalette.background)
                                        .frame(width: 52, height: 52)
                                        .background(icon == option ? PlanningPalette.color(for: colorIdentifier) : AppPalette.surface, in: Circle())
                                        .overlay {
                                            Circle().stroke(AppPalette.separator, lineWidth: icon == option ? 0 : 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Cor", "Color"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 12)], spacing: 12) {
                            ForEach(colorOptions, id: \.self) { option in
                                Button {
                                    colorIdentifier = option
                                } label: {
                                    Circle()
                                        .fill(PlanningPalette.color(for: option))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            if colorIdentifier == option {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(AppPalette.surface)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(request.item == nil ? planningText("Novo item", "New item") : planningText("Editar item", "Edit item"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.save)) {
                        onSave(PlanningItemDraft(
                            item: request.item,
                            itemType: nil,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                            plannedAmount: plannedAmount,
                            icon: icon,
                            colorIdentifier: colorIdentifier
                        ))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

private struct PlanningItemEditorBudgetSlider: View {
    @Binding var plannedAmount: Double
    let maximumBudget: Double

    private var sliderRange: ClosedRange<Double> {
        0...max(maximumBudget, 0)
    }

    private var freeAmount: Double {
        max(maximumBudget - plannedAmount, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(planningText("Orçamento", "Budget"))
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text(plannedAmount.currencyText)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)
            }

            HStack(spacing: 12) {
                Button {
                    adjust(by: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(width: 40, height: 40)
                        .background(AppPalette.appBackground, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(plannedAmount <= 0)
                .opacity(plannedAmount <= 0 ? 0.45 : 1)

                Slider(value: $plannedAmount, in: sliderRange, step: 1)
                    .tint(AppPalette.mediumBlue)
                    .onChange(of: plannedAmount) { _, newValue in
                        plannedAmount = min(max(newValue, 0), maximumBudget)
                    }

                Button {
                    adjust(by: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 40, height: 40)
                        .background(AppPalette.mediumBlue, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(plannedAmount >= maximumBudget)
                .opacity(plannedAmount >= maximumBudget ? 0.45 : 1)
            }

            HStack {
                Text(Double.zero.currencyText)
                Spacer()
                Text(maximumBudget.currencyText)
            }
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)

            Text(planningText(
                "\(freeAmount.currencyText) ainda livres no planeamento",
                "\(freeAmount.currencyText) still free in planning"
            ))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppPalette.mediumBlue)
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func adjust(by delta: Double) {
        plannedAmount = min(max(plannedAmount + delta, 0), maximumBudget)
    }
}

private struct PlanningTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.sentences)
                .font(.headline)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14).stroke(AppPalette.separator, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PlanningMovementEditorRequest: Identifiable {
    let id = UUID()
    let item: PlanningItem
    let planning: Planning?
    let movement: PlanningMovement?
    let accounts: [SpendAccount]
    let accountMovements: [AccountMovement]
    let savings: [SavingAccount]
    let savingMovements: [SavingMovement]

    init(
        item: PlanningItem,
        planning: Planning?,
        movement: PlanningMovement? = nil,
        accounts: [SpendAccount],
        accountMovements: [AccountMovement],
        savings: [SavingAccount],
        savingMovements: [SavingMovement]
    ) {
        self.item = item
        self.planning = planning
        self.movement = movement
        self.accounts = accounts
        self.accountMovements = accountMovements
        self.savings = savings
        self.savingMovements = savingMovements
    }
}

struct PlanningMovementDraft {
    let item: PlanningItem
    let planning: Planning?
    let movement: PlanningMovement?
    let title: String
    let amount: Double
    let date: Date
    let note: String
    let affectMode: PlanningMovementAffectMode
    let accountID: UUID?
    let savingID: UUID?
}

struct PlanningMovementEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let request: PlanningMovementEditorRequest
    let onContinue: (PlanningMovementDraft) -> Void

    @State private var title: String
    @State private var amount: Double
    @State private var date = Date()
    @State private var note = ""
    @State private var affectMode: PlanningMovementAffectMode = .planningOnly
    @State private var selectedAccountID: UUID?
    @State private var selectedSavingID: UUID?

    private var locksSpendWiseAffectMode: Bool {
        request.movement?.affectMode != .planningOnly && request.movement != nil
    }

    private var canContinue: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount > 0 &&
        (affectMode != .account || selectedAccountID != nil) &&
        (affectMode != .saving || selectedSavingID != nil)
    }

    init(request: PlanningMovementEditorRequest, onContinue: @escaping (PlanningMovementDraft) -> Void) {
        self.request = request
        self.onContinue = onContinue
        _title = State(initialValue: request.movement?.title ?? request.item.name)
        _amount = State(initialValue: abs(request.movement?.amount ?? 0))
        _date = State(initialValue: request.movement?.date ?? Date())
        _note = State(initialValue: request.movement?.note ?? "")
        _affectMode = State(initialValue: request.movement?.affectMode ?? .planningOnly)
        _selectedAccountID = State(initialValue: request.movement?.linkedAccountID ?? request.accounts.first?.id)
        _selectedSavingID = State(initialValue: request.movement?.linkedSavingID ?? request.savings.first?.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PlanningMovementContextCard(item: request.item, planning: request.planning)

                    MoneyAmountPicker(
                        title: planningText("Valor", "Amount"),
                        amount: $amount,
                        maximumAmount: 999_999
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        DatePicker(planningText("Data", "Date"), selection: $date, displayedComponents: .date)
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        PlanningTextInput(title: planningText("Descrição", "Description"), placeholder: planningText("Ex.: Restaurante Bellagio", "E.g. Restaurant Bellagio"), text: $title)
                        PlanningTextInput(title: planningText("Nota", "Note"), placeholder: planningText("Adicionar nota", "Add note"), text: $note)
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Afetar SpendWise", "Affect SpendWise"))
                            .font(.title3.bold())
                            .foregroundStyle(AppPalette.background)

                        let availableModes = locksSpendWiseAffectMode ? [affectMode] : PlanningMovementAffectMode.allCases
                        ForEach(availableModes) { mode in
                            Button {
                                affectMode = mode
                            } label: {
                                PlanningAffectModeRow(mode: mode, isSelected: affectMode == mode)
                            }
                            .buttonStyle(.plain)
                            .disabled(locksSpendWiseAffectMode || mode == .account && request.accounts.isEmpty || mode == .saving && request.savings.isEmpty)
                        }

                        if locksSpendWiseAffectMode {
                            Text(planningText(
                                "Este movimento já criou um registo real na SpendWise. Aqui pode alterar apenas o registo do planeamento. Para alterar ou apagar o movimento real, vá à conta ou poupança onde ele foi criado.",
                                "This movement already created a real SpendWise record. Here you can only change the planning record. To change or delete the real movement, go to the account or saving where it was created."
                            ))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppPalette.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppPalette.paleOrange.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
                        }

                        if affectMode == .account {
                            PlanningAccountSelection(
                                accounts: locksSpendWiseAffectMode ? request.accounts.filter { $0.id == selectedAccountID } : request.accounts,
                                movements: request.accountMovements,
                                selectedAccountID: $selectedAccountID,
                                isLocked: locksSpendWiseAffectMode
                            )
                        }

                        if affectMode == .saving {
                            PlanningSavingSelection(
                                savings: locksSpendWiseAffectMode ? request.savings.filter { $0.id == selectedSavingID } : request.savings,
                                movements: request.savingMovements,
                                selectedSavingID: $selectedSavingID,
                                isLocked: locksSpendWiseAffectMode
                            )
                        }
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
                }
                .padding(16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(request.movement == nil ? planningText("Novo movimento", "New movement") : planningText("Editar movimento", "Edit movement"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(affectMode == .planningOnly || locksSpendWiseAffectMode ? AppStrings.text(.save) : planningText("Continuar", "Continue")) {
                        onContinue(PlanningMovementDraft(
                            item: request.item,
                            planning: request.planning,
                            movement: request.movement,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: amount,
                            date: date,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                            affectMode: affectMode,
                            accountID: affectMode == .account ? selectedAccountID : nil,
                            savingID: affectMode == .saving ? selectedSavingID : nil
                        ))
                        dismiss()
                    }
                    .disabled(!canContinue)
                }
            }
        }
    }
}

private struct PlanningMovementContextCard: View {
    let item: PlanningItem
    let planning: Planning?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.iconName)
                .font(.title2.bold())
                .foregroundStyle(item.tint)
                .frame(width: 58, height: 58)
                .background(item.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(planning?.name ?? planningText("Planeamento", "Planning"))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mediumBlue)
            }
            Spacer()
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningAffectModeRow: View {
    let mode: PlanningMovementAffectMode
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.iconName)
                .font(.headline.bold())
                .foregroundStyle(mode.tint)
                .frame(width: 46, height: 46)
                .background(mode.tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                Text(mode.subtitle)
                    .font(.footnote)
                    .foregroundStyle(AppPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : AppPalette.secondaryText)
        }
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.blue : AppPalette.separator, lineWidth: isSelected ? 1.2 : 1)
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PlanningAccountSelection: View {
    let accounts: [SpendAccount]
    let movements: [AccountMovement]
    @Binding var selectedAccountID: UUID?
    var isLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(planningText("Escolher conta", "Choose account"))
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(accounts) { account in
                        PlanningSelectableCard(
                            title: account.displayName,
                            subtitle: account.balance(with: movements).currencyText,
                            icon: account.iconName,
                            tint: account.tint,
                            isSelected: selectedAccountID == account.id,
                            isLocked: isLocked
                        ) {
                            if !isLocked {
                                selectedAccountID = account.id
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PlanningSavingSelection: View {
    let savings: [SavingAccount]
    let movements: [SavingMovement]
    @Binding var selectedSavingID: UUID?
    var isLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(planningText("Escolher poupança", "Choose saving"))
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(savings) { saving in
                        PlanningSelectableCard(
                            title: saving.displayName,
                            subtitle: saving.balance(with: movements).currencyText,
                            icon: saving.purposeIconName,
                            tint: AppPalette.savings,
                            isSelected: selectedSavingID == saving.id,
                            isLocked: isLocked
                        ) {
                            if !isLocked {
                                selectedSavingID = saving.id
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PlanningSelectableCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isSelected: Bool
    var isLocked = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline.bold())
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mutedText)
                }

                Image(systemName: isLocked ? "lock.fill" : (isSelected ? "largecircle.fill.circle" : "circle"))
                    .foregroundStyle(isSelected ? .blue : AppPalette.secondaryText)
            }
            .padding(12)
            .frame(minWidth: 190, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.blue : AppPalette.separator, lineWidth: isSelected ? 1.2 : 1)
            }
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

struct PlanningMovementConfirmation: Identifiable {
    let id = UUID()
    let draft: PlanningMovementDraft
    let item: PlanningItem
    let planning: Planning?
}

struct PlanningMovementConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    let confirmation: PlanningMovementConfirmation
    let account: SpendAccount?
    let saving: SavingAccount?
    let accountMovements: [AccountMovement]
    let savingMovements: [SavingMovement]
    let onConfirm: () -> Void

    private var targetName: String {
        switch confirmation.draft.affectMode {
        case .planningOnly:
            return planningText("Só planeamento", "Only planning")
        case .account:
            return account?.displayName ?? planningText("Conta", "Account")
        case .saving:
            return saving?.displayName ?? planningText("Poupança", "Saving")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PlanningConfirmationSummary(confirmation: confirmation, targetName: targetName)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(planningText("O que vai acontecer", "What will happen"))
                            .font(.title2.bold())
                            .foregroundStyle(AppPalette.background)

                        PlanningConfirmationFact(
                            icon: "calendar.badge.checkmark",
                            tint: AppPalette.mediumBlue,
                            text: planningText(
                                "Será registado um movimento de \(confirmation.draft.amount.currencyText) neste item do planeamento.",
                                "A movement of \(confirmation.draft.amount.currencyText) will be registered in this planning item."
                            )
                        )

                        if confirmation.draft.affectMode == .account {
                            PlanningConfirmationFact(
                                icon: "wallet.pass.fill",
                                tint: .blue,
                                text: planningText(
                                    "Será criada uma saída de \(confirmation.draft.amount.currencyText) na conta \(targetName).",
                                    "An outgoing movement of \(confirmation.draft.amount.currencyText) will be created in account \(targetName)."
                                )
                            )

                            if let account {
                                let before = account.balance(with: accountMovements)
                                PlanningBalancePreview(
                                    title: planningText("Saldo da conta", "Account balance"),
                                    before: before,
                                    after: before - confirmation.draft.amount
                                )
                            }
                        }

                        if confirmation.draft.affectMode == .saving {
                            PlanningConfirmationFact(
                                icon: "leaf.fill",
                                tint: .purple,
                                text: planningText(
                                    "Será criado um levantamento de \(confirmation.draft.amount.currencyText) na poupança \(targetName).",
                                    "A withdrawal of \(confirmation.draft.amount.currencyText) will be created in saving \(targetName)."
                                )
                            )

                            if let saving {
                                let before = saving.balance(with: savingMovements)
                                PlanningBalancePreview(
                                    title: planningText("Saldo da poupança", "Saving balance"),
                                    before: before,
                                    after: max(before - confirmation.draft.amount, 0)
                                )
                            }
                        }

                        Label {
                            Text(planningText(
                                "Esta ação vai afetar valores existentes. Confirme apenas se é isto que pretende.",
                                "This action will affect existing values. Confirm only if this is what you want."
                            ))
                            .font(.subheadline.weight(.semibold))
                        } icon: {
                            Image(systemName: "info.circle.fill")
                        }
                        .foregroundStyle(AppPalette.primary)
                        .padding(14)
                        .background(AppPalette.paleOrange, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(18)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))

                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text(planningText("Confirmar e criar", "Confirm and create"))
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.surface)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(planningText("Confirmar movimento", "Confirm movement"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
            }
        }
    }
}

private struct PlanningConfirmationSummary: View {
    let confirmation: PlanningMovementConfirmation
    let targetName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: confirmation.item.iconName)
                .font(.title.bold())
                .foregroundStyle(confirmation.item.tint)
                .frame(width: 70, height: 70)
                .background(confirmation.item.tint.opacity(0.14), in: Circle())

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text(planningText("Plano", "Plan")).foregroundStyle(AppPalette.mutedText)
                    Text(confirmation.planning?.name ?? planningText("Planeamento", "Planning"))
                }
                GridRow {
                    Text(planningText("Item", "Item")).foregroundStyle(AppPalette.mutedText)
                    Text(confirmation.item.name)
                }
                GridRow {
                    Text(planningText("Movimento", "Movement")).foregroundStyle(AppPalette.mutedText)
                    Text(confirmation.draft.title)
                }
                GridRow {
                    Text(planningText("Valor", "Value")).foregroundStyle(AppPalette.mutedText)
                    Text(confirmation.draft.amount.currencyText)
                }
                GridRow {
                    Text(planningText("Destino", "Target")).foregroundStyle(AppPalette.mutedText)
                    Text(targetName)
                }
            }
            .font(.subheadline)
            .foregroundStyle(AppPalette.background)
        }
        .padding(18)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct PlanningConfirmationFact: View {
    let icon: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(tint.opacity(0.14), in: Circle())

            Text(text)
                .font(.headline)
                .foregroundStyle(AppPalette.background)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .overlay {
            RoundedRectangle(cornerRadius: 16).stroke(AppPalette.separator, lineWidth: 1)
        }
    }
}

private struct PlanningBalancePreview: View {
    let title: String
    let before: Double
    let after: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(before.currencyText) → \(after.currencyText)")
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
        .font(.subheadline)
        .foregroundStyle(AppPalette.mediumBlue)
        .padding(14)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

enum PlanningMovementWriter {
    static func save(
        _ draft: PlanningMovementDraft,
        modelContext: ModelContext,
        spendAccounts: [SpendAccount],
        accountMovements: [AccountMovement],
        savingAccounts: [SavingAccount],
        savingMovements: [SavingMovement]
    ) {
        let movement = PlanningMovement(
            planningId: draft.item.planningId,
            itemId: draft.item.id,
            date: draft.date,
            title: draft.title,
            amount: draft.amount,
            note: draft.note,
            affectModeRawValue: draft.affectMode.rawValue,
            linkedAccountID: draft.accountID,
            linkedSavingID: draft.savingID
        )
        let realMovementNote = planningMovementNote(for: draft)

        switch draft.affectMode {
        case .planningOnly:
            break
        case .account:
            if let accountID = draft.accountID {
                let realMovement = AccountMovement(
                    accountID: accountID,
                    date: draft.date,
                    type: AccountMovementKind.expensePayment.rawValue,
                    amount: -abs(draft.amount),
                    note: realMovementNote
                )
                modelContext.insert(realMovement)
                movement.linkedAccountMovementID = realMovement.id
                createCurrentAccountEntry(
                    for: draft,
                    accountID: accountID,
                    accountMovement: realMovement,
                    modelContext: modelContext
                )

                let balanceBefore = spendAccounts.first { $0.id == accountID }?.balance(with: accountMovements) ?? 0
                modelContext.insert(AuditLogEntry(
                    action: AuditLogAction.accountBalanceAdjusted.rawValue,
                    title: draft.title,
                    details: planningText("Movimento de planeamento", "Planning movement"),
                    amount: -abs(draft.amount),
                    balanceAfter: balanceBefore - abs(draft.amount),
                    accountID: accountID
                ))
            }
        case .saving:
            if let savingID = draft.savingID {
                let realMovement = SavingMovement(
                    savingID: savingID,
                    date: draft.date,
                    type: SavingMovementKind.withdrawal.rawValue,
                    amount: abs(draft.amount),
                    note: realMovementNote
                )
                modelContext.insert(realMovement)
                movement.linkedSavingMovementID = realMovement.id

                let balanceBefore = savingAccounts.first { $0.id == savingID }?.balance(with: savingMovements) ?? 0
                modelContext.insert(AuditLogEntry(
                    action: AuditLogAction.savingMovementCreated.rawValue,
                    title: draft.title,
                    details: planningText("Movimento de planeamento", "Planning movement"),
                    amount: -abs(draft.amount),
                    balanceAfter: max(balanceBefore - abs(draft.amount), 0),
                    savingID: savingID
                ))
            }
        }

        modelContext.insert(movement)
    }
}

struct PlanningEditorRequest: Identifiable {
    let id = UUID()
    let planning: Planning?

    init(planning: Planning? = nil) {
        self.planning = planning
    }
}

struct PlanningDraft {
    let planning: Planning?
    let name: String
    let type: PlanningType
    let totalBudget: Double
    let startDate: Date?
    let endDate: Date?
    let status: PlanningStatus
}

struct PlanningEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let request: PlanningEditorRequest
    let onSave: (PlanningDraft) -> Void

    @State private var name: String
    @State private var type: PlanningType
    @State private var totalBudget: Double
    @State private var hasStartDate: Bool
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var status: PlanningStatus

    private var isEditing: Bool {
        request.planning != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && totalBudget >= 0
    }

    init(request: PlanningEditorRequest, onSave: @escaping (PlanningDraft) -> Void) {
        self.request = request
        self.onSave = onSave
        let planning = request.planning
        let initialType = planning?.planningType ?? .travel
        let initialStartDate = planning?.startDate ?? Date()
        let initialEndDate = planning?.endDate ?? initialStartDate
        _name = State(initialValue: planning?.name ?? "")
        _type = State(initialValue: initialType)
        _totalBudget = State(initialValue: planning?.totalBudget ?? 0)
        _hasStartDate = State(initialValue: planning?.startDate != nil)
        _startDate = State(initialValue: initialStartDate)
        _hasEndDate = State(initialValue: planning?.endDate != nil)
        _endDate = State(initialValue: initialEndDate)
        _status = State(initialValue: planning?.planningStatus ?? .active)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Nome", "Name"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        TextField(planningText("Ex.: Itália Novembro 2026", "E.g. Italy November 2026"), text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.headline)
                            .padding(14)
                            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14).stroke(AppPalette.separator, lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Tipo de planeamento", "Planning type"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                            ForEach(PlanningType.allCases) { planningType in
                                Button {
                                    type = planningType
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: planningType.iconName)
                                            .foregroundStyle(type == planningType ? AppPalette.surface : planningType.color)
                                            .frame(width: 28)

                                        Text(planningType.title)
                                            .font(.subheadline.bold())
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        Spacer(minLength: 0)
                                    }
                                    .foregroundStyle(type == planningType ? AppPalette.surface : AppPalette.background)
                                    .padding(12)
                                    .frame(minHeight: 56)
                                    .background(type == planningType ? planningType.color : AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    MoneyAmountPicker(
                        title: planningText("Orçamento total", "Total budget"),
                        amount: $totalBudget,
                        maximumAmount: 999_999
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(planningText("Data de início", "Start date"), isOn: $hasStartDate)
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        if hasStartDate {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }

                        Divider()

                        Toggle(planningText("Data de fim", "End date"), isOn: $hasEndDate)
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        if hasEndDate {
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))

                    if isEditing {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(planningText("Estado", "Status"))
                                .font(.headline)
                                .foregroundStyle(AppPalette.background)

                            Picker(planningText("Estado", "Status"), selection: $status) {
                                ForEach(PlanningStatus.allCases) { planningStatus in
                                    Text(planningStatus.title).tag(planningStatus)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(16)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(isEditing ? planningText("Editar planeamento", "Edit planning") : planningText("Novo planeamento", "New planning"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.save)) {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        onSave(PlanningDraft(
            planning: request.planning,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            totalBudget: totalBudget,
            startDate: hasStartDate ? startDate : nil,
            endDate: hasEndDate ? endDate : nil,
            status: status
        ))
        dismiss()
    }
}

struct PlanningItemTypeEditorRequest: Identifiable {
    let id = UUID()
    let itemType: PlanningItemType?

    init(itemType: PlanningItemType? = nil) {
        self.itemType = itemType
    }
}

struct PlanningItemTypeDraft {
    let itemType: PlanningItemType?
    let name: String
    let icon: String
    let colorIdentifier: String
}

struct PlanningItemTypeEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let request: PlanningItemTypeEditorRequest
    let onSave: (PlanningItemTypeDraft) -> Void

    @State private var name: String
    @State private var icon: String
    @State private var colorIdentifier: String

    private let iconOptions = ["tag.fill", "airplane", "bed.double.fill", "fork.knife", "ticket.fill", "bag.fill", "gift.fill", "hammer.fill", "book.fill", "shippingbox.fill", "sparkles", "ellipsis.circle.fill"]
    private let colorOptions = ["blue", "green", "orange", "purple", "teal", "pink", "red", "gray"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(request: PlanningItemTypeEditorRequest, onSave: @escaping (PlanningItemTypeDraft) -> Void) {
        self.request = request
        self.onSave = onSave
        _name = State(initialValue: request.itemType?.name ?? "")
        _icon = State(initialValue: request.itemType?.iconName ?? "tag.fill")
        _colorIdentifier = State(initialValue: request.itemType?.colorIdentifier ?? "blue")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Nome do tipo", "Type name"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        TextField(planningText("Ex.: Alimentação", "E.g. Food"), text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.headline)
                            .padding(14)
                            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14).stroke(AppPalette.separator, lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Ícone", "Icon"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 10)], spacing: 10) {
                            ForEach(iconOptions, id: \.self) { option in
                                Button {
                                    icon = option
                                } label: {
                                    Image(systemName: option)
                                        .font(.headline)
                                        .foregroundStyle(icon == option ? AppPalette.surface : AppPalette.background)
                                        .frame(width: 48, height: 48)
                                        .background(icon == option ? PlanningPalette.color(for: colorIdentifier) : AppPalette.surface, in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(planningText("Cor", "Color"))
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { option in
                                Button {
                                    colorIdentifier = option
                                } label: {
                                    Circle()
                                        .fill(PlanningPalette.color(for: option))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            if colorIdentifier == option {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(AppPalette.surface)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(request.itemType == nil ? planningText("Novo tipo", "New type") : planningText("Editar tipo", "Edit type"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.save)) {
                        onSave(PlanningItemTypeDraft(
                            itemType: request.itemType,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            icon: icon,
                            colorIdentifier: colorIdentifier
                        ))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

private extension PlanningStatus {
    var sortRank: Int {
        switch self {
        case .active:
            return 0
        case .completed, .archived:
            return 2
        }
    }
}

private extension Planning {
    var dateDescription: String? {
        switch (startDate, endDate) {
        case (.some(let start), .some(let end)):
            return "\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))"
        case (.some(let start), .none):
            return start.formatted(date: .abbreviated, time: .omitted)
        case (.none, .some(let end)):
            return planningText("Até \(end.formatted(date: .abbreviated, time: .omitted))", "Until \(end.formatted(date: .abbreviated, time: .omitted))")
        case (.none, .none):
            return nil
        }
    }
}
