//
//  MoneyControlTests.swift
//  MoneyControlTests
//
//  Created by Paulo Gaio on 29/07/2026.
//

import Foundation
import Testing
@testable import MoneyControl

struct MoneyControlTests {
    @Test func effectiveDayUsesLastDayWhenMonthIsShorter() {
        let transaction = makeExpense(day: 31, month: Date.monthStart(month: 1, year: 2026))

        #expect(transaction.effectiveDay(in: Date.monthStart(month: 2, year: 2026)) == 28)
        #expect(transaction.effectiveDay(in: Date.monthStart(month: 2, year: 2028)) == 29)
        #expect(transaction.effectiveDay(in: Date.monthStart(month: 3, year: 2026)) == 31)
    }

    @Test func monthlyRecurrenceStopsBeforeEndMonthStart() {
        let transaction = makeExpense(
            day: 10,
            month: Date.monthStart(month: 1, year: 2026),
            recurrenceType: .monthly,
            recurrenceEndMonthStart: Date.monthStart(month: 3, year: 2026)
        )

        #expect(transaction.occurs(in: Date.monthStart(month: 1, year: 2026), exclusions: []))
        #expect(transaction.occurs(in: Date.monthStart(month: 2, year: 2026), exclusions: []))
        #expect(!transaction.occurs(in: Date.monthStart(month: 3, year: 2026), exclusions: []))
    }

    @Test func yearlyMonthRecurrenceOnlyAppearsInConfiguredMonthAfterStart() {
        let transaction = makeExpense(
            day: 5,
            month: Date.monthStart(month: 4, year: 2026),
            recurrenceType: .yearlyMonth,
            recurrenceMonth: 8
        )

        #expect(!transaction.occurs(in: Date.monthStart(month: 7, year: 2026), exclusions: []))
        #expect(transaction.occurs(in: Date.monthStart(month: 8, year: 2026), exclusions: []))
        #expect(!transaction.occurs(in: Date.monthStart(month: 9, year: 2026), exclusions: []))
        #expect(transaction.occurs(in: Date.monthStart(month: 8, year: 2027), exclusions: []))
    }

    @Test func recurrenceExclusionHidesOnlyThatMonth() {
        let transaction = makeExpense(
            day: 10,
            month: Date.monthStart(month: 1, year: 2026),
            recurrenceType: .monthly
        )
        let excludedMonth = Date.monthStart(month: 2, year: 2026)
        let exclusion = RecurrenceExclusion(transactionID: transaction.id, monthStart: excludedMonth)

        #expect(transaction.occurs(in: Date.monthStart(month: 1, year: 2026), exclusions: [exclusion]))
        #expect(!transaction.occurs(in: excludedMonth, exclusions: [exclusion]))
        #expect(transaction.occurs(in: Date.monthStart(month: 3, year: 2026), exclusions: [exclusion]))
    }

    @Test func visibleTransactionsSortUnpaidExpensesBeforeIncomeAndPaidExpenses() {
        let month = Date.monthStart(month: 8, year: 2026)
        let unpaidExpense = makeExpense(title: "Luz", day: 2, month: month, amount: 40)
        let income = MoneyTransaction(
            title: "Salario",
            day: 1,
            monthStart: month,
            amount: 1_000,
            kind: TransactionKind.income.rawValue
        )
        let paidExpense = makeExpense(title: "Renda", day: 1, month: month, amount: 500)
        let payment = ExpensePayment(transactionID: paidExpense.id, monthStart: month, amountPaid: 500)

        let visible = [paidExpense, income, unpaidExpense].visible(in: month, payments: [payment], exclusions: [])

        #expect(visible.map(\.id) == [unpaidExpense.id, income.id, paidExpense.id])
    }

    private func makeExpense(
        title: String = "Despesa",
        day: Int,
        month: Date,
        amount: Double = 100,
        recurrenceType: RecurrenceType? = nil,
        recurrenceMonth: Int = 0,
        recurrenceEndMonthStart: Date? = nil
    ) -> MoneyTransaction {
        MoneyTransaction(
            title: title,
            day: day,
            monthStart: month,
            amount: amount,
            kind: TransactionKind.expense.rawValue,
            repeatsEveryMonth: recurrenceType == .monthly,
            expenseCategory: ExpenseCategory.needs.rawValue,
            expenseName: "Outros",
            recurrenceType: recurrenceType?.rawValue,
            recurrenceMonth: recurrenceMonth,
            recurrenceEndMonthStart: recurrenceEndMonthStart
        )
    }
}
