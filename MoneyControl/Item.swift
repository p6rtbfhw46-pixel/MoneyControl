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
    var expenseCategory: String? = nil
    var expenseName: String? = nil
    var incomeDescription: String?
    var recurrenceType: String?
    var recurrenceMonth: Int
    var recurrenceEndMonthStart: Date?
    var budgetAllocationType: String?
    var budgetMonthStart: Date?
    var linkedCreditID: UUID?
    var linkedCreditMovementID: UUID?
    var linkedSavingID: UUID?
    var linkedSavingMovementID: UUID?
    var autoMarkPaidOnDay: Bool = false
    var accountID: UUID?

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
        incomeDescription: String? = nil,
        recurrenceType: String? = nil,
        recurrenceMonth: Int = 0,
        recurrenceEndMonthStart: Date? = nil,
        budgetAllocationType: String? = nil,
        budgetMonthStart: Date? = nil,
        linkedCreditID: UUID? = nil,
        linkedCreditMovementID: UUID? = nil,
        linkedSavingID: UUID? = nil,
        linkedSavingMovementID: UUID? = nil,
        autoMarkPaidOnDay: Bool = false,
        accountID: UUID? = nil
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
        self.incomeDescription = incomeDescription
        self.recurrenceType = recurrenceType
        self.recurrenceMonth = recurrenceMonth
        self.recurrenceEndMonthStart = recurrenceEndMonthStart
        self.budgetAllocationType = budgetAllocationType
        self.budgetMonthStart = budgetMonthStart
        self.linkedCreditID = linkedCreditID
        self.linkedCreditMovementID = linkedCreditMovementID
        self.linkedSavingID = linkedSavingID
        self.linkedSavingMovementID = linkedSavingMovementID
        self.autoMarkPaidOnDay = autoMarkPaidOnDay
        self.accountID = accountID
    }
}

@Model
final class RecurrenceExclusion {
    var transactionID: UUID
    var monthStart: Date
    var occurrenceDay: Int?

    init(transactionID: UUID, monthStart: Date, occurrenceDay: Int? = nil) {
        self.transactionID = transactionID
        self.monthStart = monthStart
        self.occurrenceDay = occurrenceDay
    }
}

@Model
final class ExpensePayment {
    var transactionID: UUID
    var monthStart: Date
    var amountPaid: Double?
    var occurrenceDay: Int?

    init(transactionID: UUID, monthStart: Date, amountPaid: Double? = nil, occurrenceDay: Int? = nil) {
        self.transactionID = transactionID
        self.monthStart = monthStart
        self.amountPaid = amountPaid
        self.occurrenceDay = occurrenceDay
    }
}

@Model
final class PaymentHistoryEntry {
    var id: UUID
    var transactionID: UUID
    var monthStart: Date
    var occurrenceDay: Int?
    var amount: Double
    var paidAt: Date
    var note: String? = nil
    var accountID: UUID?

    init(transactionID: UUID, monthStart: Date, occurrenceDay: Int? = nil, amount: Double, paidAt: Date = Date(), note: String? = nil, accountID: UUID? = nil) {
        self.id = UUID()
        self.transactionID = transactionID
        self.monthStart = monthStart
        self.occurrenceDay = occurrenceDay
        self.amount = amount
        self.paidAt = paidAt
        self.note = note
        self.accountID = accountID
    }
}

@Model
final class SpendAccount {
    var id: UUID
    var name: String
    var iconName: String
    var colorName: String
    var initialBalance: Double
    var isPrimary: Bool
    var createdAt: Date

    init(
        name: String,
        iconName: String = "wallet.pass.fill",
        colorName: String = "blue",
        initialBalance: Double,
        isPrimary: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.initialBalance = initialBalance
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}

@Model
final class AccountMovement {
    var id: UUID
    var accountID: UUID
    var relatedAccountID: UUID?
    var transactionID: UUID?
    var paymentHistoryID: UUID?
    var date: Date
    var type: String
    var amount: Double
    var note: String

    init(
        accountID: UUID,
        relatedAccountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        date: Date = Date(),
        type: String,
        amount: Double,
        note: String
    ) {
        self.id = UUID()
        self.accountID = accountID
        self.relatedAccountID = relatedAccountID
        self.transactionID = transactionID
        self.paymentHistoryID = paymentHistoryID
        self.date = date
        self.type = type
        self.amount = amount
        self.note = note
    }
}

@Model
final class AuditLogEntry {
    var id: UUID
    var date: Date
    var action: String
    var title: String
    var details: String
    var note: String
    var amount: Double
    var balanceAfter: Double
    var accountID: UUID?
    var relatedAccountID: UUID?
    var transactionID: UUID?
    var paymentHistoryID: UUID?
    var creditID: UUID?
    var savingID: UUID?

    init(
        date: Date = Date(),
        action: String,
        title: String,
        details: String = "",
        note: String = "",
        amount: Double = 0,
        balanceAfter: Double,
        accountID: UUID? = nil,
        relatedAccountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        creditID: UUID? = nil,
        savingID: UUID? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.action = action
        self.title = title
        self.details = details
        self.note = note
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.accountID = accountID
        self.relatedAccountID = relatedAccountID
        self.transactionID = transactionID
        self.paymentHistoryID = paymentHistoryID
        self.creditID = creditID
        self.savingID = savingID
    }
}

@Model
final class CreditAccount {
    var id: UUID
    var name: String
    var details: String = ""
    var type: String
    var initialDebt: Double
    var creditLimit: Double?
    var createdAt: Date
    var status: String

    init(
        name: String,
        details: String = "",
        type: String,
        initialDebt: Double,
        creditLimit: Double? = nil,
        createdAt: Date = Date(),
        status: String = CreditStatus.active.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.details = details
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
    var expenseCategory: String? = nil
    var expenseName: String? = nil

    init(
        creditID: UUID,
        date: Date,
        type: String,
        amount: Double,
        note: String,
        expenseCategory: String? = nil,
        expenseName: String? = nil
    ) {
        self.id = UUID()
        self.creditID = creditID
        self.date = date
        self.type = type
        self.amount = amount
        self.note = note
        self.expenseCategory = expenseCategory
        self.expenseName = expenseName
    }
}

@Model
final class SavingAccount {
    var id: UUID
    var name: String
    var details: String = ""
    var initialAmount: Double
    var targetAmount: Double?
    var createdAt: Date
    var status: String

    init(
        name: String,
        details: String = "",
        initialAmount: Double,
        targetAmount: Double? = nil,
        createdAt: Date = Date(),
        status: String = SavingStatus.active.rawValue
    ) {
        self.id = UUID()
        self.name = name
        self.details = details
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
