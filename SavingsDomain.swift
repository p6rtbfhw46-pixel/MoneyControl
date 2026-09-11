//
//  SavingsDomain.swift
//  MoneyControl
//

import Foundation
import SwiftUI

enum SavingStatus: String, CaseIterable, Identifiable {
    case active
    case closed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            SavingsStrings.text(.active)
        case .closed:
            SavingsStrings.text(.closed)
        }
    }
}

enum SavingMovementKind: String, CaseIterable, Identifiable {
    case deposit
    case withdrawal
    case adjustment

    static let allCases: [SavingMovementKind] = [.deposit, .withdrawal]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deposit:
            SavingsStrings.text(.deposit)
        case .withdrawal:
            SavingsStrings.text(.withdrawal)
        case .adjustment:
            SavingsStrings.text(.adjustment)
        }
    }

    var iconName: String {
        switch self {
        case .deposit:
            "plus.circle.fill"
        case .withdrawal:
            "minus.circle.fill"
        case .adjustment:
            "slider.horizontal.3"
        }
    }

    var tint: Color {
        switch self {
        case .deposit:
            AppPalette.positive
        case .withdrawal:
            AppPalette.primary
        case .adjustment:
            AppPalette.mediumBlue
        }
    }

    func balanceEffect(for amount: Double) -> Double {
        switch self {
        case .deposit:
            abs(amount)
        case .withdrawal:
            -abs(amount)
        case .adjustment:
            amount
        }
    }
}

enum SavingsTextKey {
    case settingsTitle
    case emptyTitle
    case addSaving
    case deleteSaving
    case deleteSavingTitle
    case deleteSavingMessage
    case newSaving
    case editSaving
    case savingName
    case savingDescription
    case targetAmount
    case currentSaved
    case optionalTarget
    case active
    case closed
    case saved
    case target
    case remainingToTarget
    case targetProgress
    case movements
    case addMovement
    case editMovement
    case movementType
    case movementNote
    case movementDate
    case deposit
    case withdrawal
    case adjustment
    case noMovements
    case savingEvolution
    case monthSummary
    case savedThisMonth
    case withdrawnThisMonth
    case monthVariation
    case markClosedPrompt
    case markAsClosed
    case showClosed
    case fillSavingName
    case fillSavingValue
    case fillMovementValue
    case withdrawalAboveBalance
    case transferToIncome
    case doNotTransferToIncome
    case transferToIncomeHelp
    case saving
    case selectSaving
}

enum SavingsStrings {
    static func text(_ key: SavingsTextKey) -> String {
        values[AppStrings.currentLanguage]?[key] ?? values[.english]?[key] ?? ""
    }

    private static let values: [AppLanguage: [SavingsTextKey: String]] = [
        .portuguese: [
            .settingsTitle: "Poupanças",
            .emptyTitle: "Ainda não tem poupanças registadas.",
            .addSaving: "Adicionar Poupança",
            .deleteSaving: "Apagar poupança",
            .deleteSavingTitle: "Apagar poupança?",
            .deleteSavingMessage: "Esta ação vai apagar a poupança e todo o seu histórico de movimentos. As despesas da conta corrente associadas deixam apenas de estar ligadas a esta poupança.",
            .newSaving: "Nova Poupança",
            .editSaving: "Editar Poupança",
            .savingName: "Nome",
            .savingDescription: "Descrição",
            .targetAmount: "Objetivo de poupança",
            .currentSaved: "Valor atual poupado",
            .optionalTarget: "Objetivo opcional",
            .active: "Ativa",
            .closed: "Fechada",
            .saved: "Poupado",
            .target: "Objetivo",
            .remainingToTarget: "Falta para o objetivo",
            .targetProgress: "Progresso do objetivo",
            .movements: "Movimentos",
            .addMovement: "Adicionar movimento",
            .editMovement: "Editar movimento",
            .movementType: "Tipo de movimento",
            .movementNote: "Descrição",
            .movementDate: "Data",
            .deposit: "Entrada de poupança",
            .withdrawal: "Retirada",
            .adjustment: "Ajuste",
            .noMovements: "Ainda não existem movimentos.",
            .savingEvolution: "Evolução da poupança",
            .monthSummary: "Resumo do mês",
            .savedThisMonth: "Poupado este mês",
            .withdrawnThisMonth: "Retirado este mês",
            .monthVariation: "Variação do mês",
            .markClosedPrompt: "🎉 Esta poupança atingiu o objetivo. Deseja marcá-la como fechada?",
            .markAsClosed: "Marcar como fechada",
            .showClosed: "Mostrar fechadas",
            .fillSavingName: "Preenche o nome da poupança.",
            .fillSavingValue: "Preenche o valor atual poupado.",
            .fillMovementValue: "Preenche o valor do movimento.",
            .withdrawalAboveBalance: "Não é possível retirar mais do que o valor atualmente poupado.",
            .transferToIncome: "Passar para receita",
            .doNotTransferToIncome: "Não passar para receita",
            .transferToIncomeHelp: "Quando ativo, a retirada da poupança cria uma receita na Conta Corrente nesse dia. Quando desativo, o movimento fica apenas no histórico da poupança.",
            .saving: "Poupança",
            .selectSaving: "Selecionar poupança"
        ],
        .english: [
            .settingsTitle: "Savings",
            .emptyTitle: "You do not have any savings registered yet.",
            .addSaving: "Add Saving",
            .deleteSaving: "Delete saving",
            .deleteSavingTitle: "Delete saving?",
            .deleteSavingMessage: "This will delete the saving and all of its movement history. Current account expenses linked to it will only be unlinked from this saving.",
            .newSaving: "New Saving",
            .editSaving: "Edit Saving",
            .savingName: "Name",
            .savingDescription: "Description",
            .targetAmount: "Saving goal",
            .currentSaved: "Current saved amount",
            .optionalTarget: "Optional goal",
            .active: "Active",
            .closed: "Closed",
            .saved: "Saved",
            .target: "Goal",
            .remainingToTarget: "Remaining to goal",
            .targetProgress: "Goal progress",
            .movements: "Movements",
            .addMovement: "Add movement",
            .editMovement: "Edit movement",
            .movementType: "Movement type",
            .movementNote: "Description",
            .movementDate: "Date",
            .deposit: "Saving deposit",
            .withdrawal: "Withdrawal",
            .adjustment: "Adjustment",
            .noMovements: "There are no movements yet.",
            .savingEvolution: "Saving evolution",
            .monthSummary: "Month summary",
            .savedThisMonth: "Saved this month",
            .withdrawnThisMonth: "Withdrawn this month",
            .monthVariation: "Month variation",
            .markClosedPrompt: "🎉 This saving reached its goal. Do you want to mark it as closed?",
            .markAsClosed: "Mark as closed",
            .showClosed: "Show closed",
            .fillSavingName: "Fill in the saving name.",
            .fillSavingValue: "Fill in the current saved amount.",
            .fillMovementValue: "Fill in the movement amount.",
            .withdrawalAboveBalance: "You cannot withdraw more than the amount currently saved.",
            .transferToIncome: "Move to income",
            .doNotTransferToIncome: "Do not move to income",
            .transferToIncomeHelp: "When enabled, the saving withdrawal creates an income entry in the Current Account on that date. When disabled, the movement stays only in the saving history.",
            .saving: "Saving",
            .selectSaving: "Select saving"
        ]
    ]
}

extension SavingAccount {
    var displayName: String {
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDetails.isEmpty ? name : "\(name) - \(trimmedDetails)"
    }

    var savingStatus: SavingStatus {
        SavingStatus(rawValue: status) ?? .active
    }

    var purposeIconName: String {
        let normalizedName = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
        if normalizedName.contains("emergencia") { return "cross.case.fill" }
        if normalizedName.contains("conta poupanca") { return "building.columns.fill" }
        if normalizedName.contains("investimento") { return "chart.line.uptrend.xyaxis" }
        if normalizedName.contains("viagem") { return "airplane" }
        if normalizedName.contains("casa") { return "house.fill" }
        if normalizedName.contains("automovel") { return "car.fill" }
        if normalizedName.contains("filhos") { return "figure.2.and.child.holdinghands" }
        if normalizedName.contains("reforma") { return "sun.horizon.fill" }
        if normalizedName.contains("compra") { return "cart.fill" }
        return "leaf.fill"
    }

    func movements(from allMovements: [SavingMovement]) -> [SavingMovement] {
        allMovements
            .filter { $0.savingID == id }
            .sorted { $0.date == $1.date ? $0.note < $1.note : $0.date > $1.date }
    }

    func balance(with allMovements: [SavingMovement]) -> Double {
        max(initialAmount + allMovements.filter { $0.savingID == id }.reduce(0) { $0 + $1.balanceEffect }, 0)
    }

    func monthDeposits(in month: Date, movements: [SavingMovement]) -> Double {
        movements.filter { $0.savingID == id && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) && $0.kind == .deposit }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func monthWithdrawals(in month: Date, movements: [SavingMovement]) -> Double {
        movements.filter { $0.savingID == id && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) && $0.kind == .withdrawal }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func monthVariation(in month: Date, movements: [SavingMovement]) -> Double {
        movements.filter { $0.savingID == id && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.balanceEffect }
    }
}

extension SavingMovement {
    var kind: SavingMovementKind {
        SavingMovementKind(rawValue: type) ?? .adjustment
    }

    var balanceEffect: Double {
        kind.balanceEffect(for: amount)
    }

    var signedAmountText: String {
        let effect = balanceEffect
        let prefix = effect > 0 ? "+" : ""
        return "\(prefix)\(effect.currencyText)"
    }
}

struct SavingBalancePoint: Identifiable {
    let month: Date
    let balance: Double

    var id: Date { month }
    var monthLabel: String { month.formatted(.dateTime.month(.abbreviated)) }
}
