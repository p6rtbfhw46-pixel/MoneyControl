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
    case deleteCredit
    case deleteCreditTitle
    case deleteCreditMessage
    case newCredit
    case editCredit
    case creditName
    case creditDescription
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
    case movementUsageFilter
    case movementNote
    case movementDate
    case increaseDebt
    case payment
    case fee
    case adjustment
    case noMovements
    case debtEvolution
    case paymentEstimateTrajectory
    case averageLastThreeMonths
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
    case affectedCredit
    case creditUsageQuestion
    case currentAccountEntry
    case accountEntryCreateMessage
    case accountEntryEditMessage
    case createAccountToReceiveValue
    case affectCurrentAccount
    case paymentAccount
    case createAccountToPayValue
    case selectPaymentAccount
    case paymentCreatesCurrentAccountExpenseMessage
    case paymentEditCurrentAccountExpenseMessage
    case debtIncreaseCreditOnlyMessage
    case debtIncreaseAccountEntryMessage
    case selectReceivingAccount
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
            .deleteCredit: "Apagar crédito",
            .deleteCreditTitle: "Apagar crédito?",
            .deleteCreditMessage: "Esta ação vai apagar o crédito e todo o seu histórico de movimentos. As despesas da conta corrente associadas deixam apenas de estar ligadas a este crédito.",
            .newCredit: "Novo Crédito",
            .editCredit: "Editar Crédito",
            .creditName: "Nome",
            .creditDescription: "Descrição",
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
            .movementUsageFilter: "Onde foi utilizado este crédito",
            .movementNote: "Descrição",
            .movementDate: "Data",
            .increaseDebt: "Aumentar dívida",
            .payment: "Pagamento",
            .fee: "Juros / Comissão",
            .adjustment: "Ajuste",
            .noMovements: "Ainda não existem movimentos.",
            .debtEvolution: "Evolução da dívida",
            .paymentEstimateTrajectory: "Estimativa de pagamentos a 1 ano",
            .averageLastThreeMonths: "Média dos últimos 3 meses",
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
            .selectCredit: "Selecionar crédito",
            .affectedCredit: "Crédito afetado",
            .creditUsageQuestion: "Como utilizou este crédito?",
            .currentAccountEntry: "Entrada numa conta",
            .accountEntryCreateMessage: "O valor também será lançado como entrada na conta escolhida.",
            .accountEntryEditMessage: "Este movimento já existe. Para evitar duplicar saldo, a entrada automática numa conta só é criada em novos movimentos.",
            .createAccountToReceiveValue: "Cria uma conta para poder receber este valor.",
            .affectCurrentAccount: "Afetar a Conta Corrente",
            .paymentAccount: "Conta do pagamento",
            .createAccountToPayValue: "Cria uma conta para poder registar este pagamento.",
            .selectPaymentAccount: "Seleciona a conta utilizada para o pagamento.",
            .paymentCreatesCurrentAccountExpenseMessage: "Será criada uma despesa de Amortização de dívida na conta escolhida. A dívida só baixa quando essa despesa for marcada como paga.",
            .paymentEditCurrentAccountExpenseMessage: "Este pagamento já é um movimento de crédito e não cria uma nova despesa ao editar.",
            .debtIncreaseCreditOnlyMessage: "Este aumento de dívida fica apenas registado no crédito e não cria movimento na Conta Corrente.",
            .debtIncreaseAccountEntryMessage: "Este aumento de dívida também pode entrar numa conta, porque representa dinheiro transferido do crédito.",
            .selectReceivingAccount: "Seleciona uma conta para receber este valor."
        ],
        .english: [
            .settingsTitle: "Credits",
            .emptyTitle: "You do not have any credits registered yet.",
            .addCredit: "Add Credit",
            .deleteCredit: "Delete credit",
            .deleteCreditTitle: "Delete credit?",
            .deleteCreditMessage: "This will delete the credit and all of its movement history. Current account expenses linked to it will only be unlinked from this credit.",
            .newCredit: "New Credit",
            .editCredit: "Edit Credit",
            .creditName: "Name",
            .creditDescription: "Description",
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
            .movementUsageFilter: "Where this credit was used",
            .movementNote: "Description",
            .movementDate: "Date",
            .increaseDebt: "Increase debt",
            .payment: "Payment",
            .fee: "Interest / Fee",
            .adjustment: "Adjustment",
            .noMovements: "There are no movements yet.",
            .debtEvolution: "Debt evolution",
            .paymentEstimateTrajectory: "1-year payment estimate",
            .averageLastThreeMonths: "Average over the last 3 months",
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
            .selectCredit: "Select credit",
            .affectedCredit: "Affected credit",
            .creditUsageQuestion: "How did you use this credit?",
            .currentAccountEntry: "Entry into an account",
            .accountEntryCreateMessage: "The value will also be recorded as an entry in the selected account.",
            .accountEntryEditMessage: "This movement already exists. To avoid duplicating balance, automatic account entry is only created for new movements.",
            .createAccountToReceiveValue: "Create an account to receive this value.",
            .affectCurrentAccount: "Affect Current Account",
            .paymentAccount: "Payment account",
            .createAccountToPayValue: "Create an account to record this payment.",
            .selectPaymentAccount: "Select the account used for the payment.",
            .paymentCreatesCurrentAccountExpenseMessage: "A debt amortization expense will be created in the selected account. The debt only decreases when that expense is marked as paid.",
            .paymentEditCurrentAccountExpenseMessage: "This payment is already a credit movement and does not create a new expense when edited.",
            .debtIncreaseCreditOnlyMessage: "This debt increase is only recorded in the credit and does not create a Current Account movement.",
            .debtIncreaseAccountEntryMessage: "This debt increase can also enter an account because it represents money transferred from the credit.",
            .selectReceivingAccount: "Select an account to receive this value."
        ]
    ]
}

extension CreditAccount {
    var displayName: String {
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDetails.isEmpty ? name : "\(name) - \(trimmedDetails)"
    }

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
