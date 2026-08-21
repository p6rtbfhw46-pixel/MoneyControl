//
//  Item.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import Foundation
import SwiftData

@Model
final class MoneyTransaction {
    var id: UUID
    var title: String
    var day: Int
    var monthStart: Date
    var amount: Double
    var kind: String
    var repeatsEveryMonth: Bool
    var isPaid: Bool
    var expenseCategory: String?
    var expenseName: String?
    var recurrenceType: String?
    var recurrenceMonth: Int
    var recurrenceEndMonthStart: Date?
    var linkedCreditID: UUID?
    var linkedCreditMovementID: UUID?
    var linkedSavingID: UUID?
    var linkedSavingMovementID: UUID?

    init(
        title: String,
        day: Int,
        monthStart: Date,
        amount: Double,
        kind: String,
        repeatsEveryMonth: Bool = false,
        isPaid: Bool = false,
        expenseCategory: String? = nil,
        expenseName: String? = nil,
        recurrenceType: String? = nil,
        recurrenceMonth: Int = 0,
        recurrenceEndMonthStart: Date? = nil,
        linkedCreditID: UUID? = nil,
        linkedCreditMovementID: UUID? = nil,
        linkedSavingID: UUID? = nil,
        linkedSavingMovementID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.day = day
        self.monthStart = monthStart
        self.amount = amount
        self.kind = kind
        self.repeatsEveryMonth = repeatsEveryMonth
        self.isPaid = isPaid
        self.expenseCategory = expenseCategory
        self.expenseName = expenseName
        self.recurrenceType = recurrenceType
        self.recurrenceMonth = recurrenceMonth
        self.recurrenceEndMonthStart = recurrenceEndMonthStart
        self.linkedCreditID = linkedCreditID
        self.linkedCreditMovementID = linkedCreditMovementID
        self.linkedSavingID = linkedSavingID
        self.linkedSavingMovementID = linkedSavingMovementID
    }
}

@Model
final class RecurrenceExclusion {
    var transactionID: UUID
    var monthStart: Date

    init(transactionID: UUID, monthStart: Date) {
        self.transactionID = transactionID
        self.monthStart = monthStart
    }
}

@Model
final class ExpensePayment {
    var transactionID: UUID
    var monthStart: Date
    var amountPaid: Double?

    init(transactionID: UUID, monthStart: Date, amountPaid: Double? = nil) {
        self.transactionID = transactionID
        self.monthStart = monthStart
        self.amountPaid = amountPaid
    }
}

@Model
final class PaymentHistoryEntry {
    var id: UUID
    var transactionID: UUID
    var monthStart: Date
    var amount: Double
    var paidAt: Date

    init(transactionID: UUID, monthStart: Date, amount: Double, paidAt: Date = Date()) {
        self.id = UUID()
        self.transactionID = transactionID
        self.monthStart = monthStart
        self.amount = amount
        self.paidAt = paidAt
    }
}

@Model
final class CreditAccount {
    var id: UUID
    var name: String
    var type: String
    var initialDebt: Double
    var creditLimit: Double?
    var createdAt: Date
    var status: String

    init(
        name: String,
        type: String,
        initialDebt: Double,
        creditLimit: Double? = nil,
        createdAt: Date = Date(),
        status: String = CreditStatus.active.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.initialDebt = initialDebt
        self.creditLimit = creditLimit
        self.createdAt = createdAt
        self.status = status
    }
}

@Model
final class CreditMovement {
    var id: UUID
    var creditID: UUID
    var date: Date
    var type: String
    var amount: Double
    var note: String

    init(
        creditID: UUID,
        date: Date,
        type: String,
        amount: Double,
        note: String
    ) {
        self.id = UUID()
        self.creditID = creditID
        self.date = date
        self.type = type
        self.amount = amount
        self.note = note
    }
}

@Model
final class SavingAccount {
    var id: UUID
    var name: String
    var initialAmount: Double
    var targetAmount: Double?
    var createdAt: Date
    var status: String

    init(
        name: String,
        initialAmount: Double,
        targetAmount: Double? = nil,
        createdAt: Date = Date(),
        status: String = SavingStatus.active.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.initialAmount = initialAmount
        self.targetAmount = targetAmount
        self.createdAt = createdAt
        self.status = status
    }
}

@Model
final class SavingMovement {
    var id: UUID
    var savingID: UUID
    var date: Date
    var type: String
    var amount: Double
    var note: String
    var linkedIncomeTransactionID: UUID?

    init(
        savingID: UUID,
        date: Date,
        type: String,
        amount: Double,
        note: String,
        linkedIncomeTransactionID: UUID? = nil
    ) {
        self.id = UUID()
        self.savingID = savingID
        self.date = date
        self.type = type
        self.amount = amount
        self.note = note
        self.linkedIncomeTransactionID = linkedIncomeTransactionID
    }
}
