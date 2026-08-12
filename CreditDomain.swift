//
//  CreditDomain.swift
//  MoneyControl
//

import Foundation
import SwiftUI

enum CreditType: String, CaseIterable, Identifiable {
    case creditCard
    case loan
    case installmentPurchase
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .creditCard:
            CreditStrings.text(.creditCard)
        case .loan:
            CreditStrings.text(.loan)
        case .installmentPurchase:
            CreditStrings.text(.installmentPurchase)
        case .other:
            CreditStrings.text(.other)
        }
    }

    var iconName: String {
        switch self {
        case .creditCard:
            "creditcard"
        case .loan:
            "building.columns"
        case .installmentPurchase:
            "calendar.badge.clock"
        case .other:
            "doc.text"
        }
    }
}

enum CreditStatus: String, CaseIterable, Identifiable {
    case active
    case settled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            CreditStrings.text(.active)
        case .settled:
            CreditStrings.text(.settled)
        }
    }
}

enum CreditMovementKind: String, CaseIterable, Identifiable {
    case debtIncrease
    case payment
    case fee
    case adjustment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .debtIncrease:
            CreditStrings.text(.increaseDebt)
        case .payment:
            CreditStrings.text(.payment)
        case .fee:
            CreditStrings.text(.fee)
        case .adjustment:
            CreditStrings.text(.adjustment)
        }
    }

    var iconName: String {
        switch self {
        case .debtIncrease:
            "plus.circle.fill"
        case .payment:
            "minus.circle.fill"
        case .fee:
            "percent"
        case .adjustment:
            "slider.horizontal.3"
        }
    }

    var tint: Color {
        switch self {
        case .payment:
            AppPalette.positive
        case .adjustment:
            AppPalette.mediumBlue
        case .debtIncrease, .fee:
            AppPalette.primary
        }
    }

    func balanceEffect(for amount: Double) -> Double {
        switch self {
        case .debtIncrease, .fee:
            abs(amount)
        case .payment:
            -abs(amount)
        case .adjustment:
            amount
        }
    }
}

enum CreditTextKey {
    case settingsTitle
    case emptyTitle
    case addCredit
    case newCredit
    case editCredit
    case creditName
    case creditType
    case currentDebt
    case creditLimit
    case optionalLimit
    case creditCard
    case loan
    case installmentPurchase
    case other
    case active
    case settled
    case debt
    case totalLimit
    case usedValue
    case availableValue
    case usedPercentage
    case movements
    case addMovement
    case editMovement
    case movementType
    case movementNote
    case movementDate
    case increaseDebt
    case payment
    case fee
    case adjustment
    case noMovements
    case debtEvolution
    case monthSummary
    case newDebtThisMonth
    case paidThisMonth
    case monthVariation
    case markSettledPrompt
    case markAsSettled
    case showSettled
    case fillCreditName
    case fillCreditValue
    case fillMovementValue
    case credit
    case selectCredit
}

enum CreditStrings {
    static func text(_ key: CreditTextKey) -> String {
        values[AppStrings.currentLanguage]?[key] ?? values[.english]?[key] ?? ""
    }

    private static let values: [AppLanguage: [CreditTextKey: String]] = [
        .portuguese: [
            .settingsTitle: "Créditos",
            .emptyTitle: "Ainda não tem créditos registados.",
            .addCredit: "Adicionar Crédito",
            .newCredit: "Novo Crédito",
            .editCredit: "Editar Crédito",
            .creditName: "Nome",
            .creditType: "Tipo",
            .currentDebt: "Valor atual em dívida",
            .creditLimit: "Limite de crédito",
            .optionalLimit: "Opcional",
            .creditCard: "Cartão de Crédito",
            .loan: "Empréstimo",
            .installmentPurchase: "Compra a Prestações",
            .other: "Outro",
            .active: "Ativo",
            .settled: "Liquidado",
            .debt: "Em dívida",
            .totalLimit: "Limite total",
            .usedValue: "Valor utilizado",
            .availableValue: "Valor disponível",
            .usedPercentage: "Percentagem utilizada",
            .movements: "Movimentos",
            .addMovement: "Adicionar movimento",
            .editMovement: "Editar movimento",
            .movementType: "Tipo de movimento",
            .movementNote: "Descrição",
            .movementDate: "Data",
            .increaseDebt: "Aumentar dívida",
            .payment: "Pagamento",
            .fee: "Juros / Comissão",
            .adjustment: "Ajuste",
            .noMovements: "Ainda não existem movimentos.",
            .debtEvolution: "Evolução da dívida",
            .monthSummary: "Resumo do mês",
            .newDebtThisMonth: "Novas dívidas este mês",
            .paidThisMonth: "Pago este mês",
            .monthVariation: "Variação do mês",
            .markSettledPrompt: "🎉 Este crédito está totalmente pago. Deseja marcá-lo como liquidado?",
            .markAsSettled: "Marcar como liquidado",
            .showSettled: "Mostrar liquidados",
            .fillCreditName: "Preenche o nome do crédito.",
            .fillCreditValue: "Preenche o valor atual em dívida.",
            .fillMovementValue: "Preenche o valor do movimento.",
            .credit: "Crédito",
            .selectCredit: "Selecionar crédito"
        ],
        .english: [
            .settingsTitle: "Credits",
            .emptyTitle: "You do not have any credits registered yet.",
            .addCredit: "Add Credit",
            .newCredit: "New Credit",
            .editCredit: "Edit Credit",
            .creditName: "Name",
            .creditType: "Type",
            .currentDebt: "Current debt amount",
            .creditLimit: "Credit limit",
            .optionalLimit: "Optional",
            .creditCard: "Credit Card",
            .loan: "Loan",
            .installmentPurchase: "Installment Purchase",
            .other: "Other",
            .active: "Active",
            .settled: "Settled",
            .debt: "In debt",
            .totalLimit: "Total limit",
            .usedValue: "Used value",
            .availableValue: "Available value",
            .usedPercentage: "Used percentage",
            .movements: "Movements",
            .addMovement: "Add movement",
            .editMovement: "Edit movement",
            .movementType: "Movement type",
            .movementNote: "Description",
            .movementDate: "Date",
            .increaseDebt: "Increase debt",
            .payment: "Payment",
            .fee: "Interest / Fee",
            .adjustment: "Adjustment",
            .noMovements: "There are no movements yet.",
            .debtEvolution: "Debt evolution",
            .monthSummary: "Month summary",
            .newDebtThisMonth: "New debt this month",
            .paidThisMonth: "Paid this month",
            .monthVariation: "Month variation",
            .markSettledPrompt: "🎉 This credit is fully paid. Do you want to mark it as settled?",
            .markAsSettled: "Mark as settled",
            .showSettled: "Show settled",
            .fillCreditName: "Fill in the credit name.",
            .fillCreditValue: "Fill in the current debt amount.",
            .fillMovementValue: "Fill in the movement amount.",
            .credit: "Credit",
            .selectCredit: "Select credit"
        ]
    ]
}

extension CreditAccount {
    var creditType: CreditType {
        CreditType(rawValue: type) ?? .other
    }

    var creditStatus: CreditStatus {
        CreditStatus(rawValue: status) ?? .active
    }

    func movements(from allMovements: [CreditMovement]) -> [CreditMovement] {
        allMovements
            .filter { $0.creditID == id }
            .sorted { $0.date == $1.date ? $0.note < $1.note : $0.date > $1.date }
    }

    func balance(with allMovements: [CreditMovement]) -> Double {
        max(initialDebt + allMovements.filter { $0.creditID == id }.reduce(0) { $0 + $1.balanceEffect }, 0)
    }

    func monthDebtIncrease(in month: Date, movements: [CreditMovement]) -> Double {
        movements.filter { $0.creditID == id && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
            .filter { $0.kind == .debtIncrease || $0.kind == .fee }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func monthPaid(in month: Date, movements: [CreditMovement]) -> Double {
        movements.filter { $0.creditID == id && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) && $0.kind == .payment }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func monthVariation(in month: Date, movements: [CreditMovement]) -> Double {
        movements.filter { $0.creditID == id && Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.balanceEffect }
    }
}

extension CreditMovement {
    var kind: CreditMovementKind {
        CreditMovementKind(rawValue: type) ?? .adjustment
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

struct CreditBalancePoint: Identifiable {
    let month: Date
    let balance: Double

    var id: Date { month }
    var monthLabel: String { month.formatted(.dateTime.month(.abbreviated)) }
}
