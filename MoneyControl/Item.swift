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
        recurrenceEndMonthStart: Date? = nil
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

