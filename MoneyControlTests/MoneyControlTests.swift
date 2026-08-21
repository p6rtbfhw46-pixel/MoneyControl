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
    @Test func availableBalanceUsesIncomeUntilTodayAndOnlyPaidExpenses() {
        let july = Date.monthStart(month: 7, year: 2026)
        let august = Date.monthStart(month: 8, year: 2026)
        let salaryJuly = makeIncome(title: "Salario julho", day: 1, month: july, amount: 500)
        let julyExpense = makeExpense(title: "Renda", day: 20, month: july, amount: 400)
        let salaryAugust = makeIncome(title: "Salario agosto", day: 1, month: august, amount: 500)
        let futureExpense = makeExpense(title: "Seguro", day: 20, month: august, amount: 200)
        let payments = [
            ExpensePayment(transactionID: julyExpense.id, monthStart: july, amountPaid: 400),
            ExpensePayment(transactionID: futureExpense.id, monthStart: august, amountPaid: 200)
        ]
        let service = MoneyCalculationService(
            transactions: [salaryJuly, julyExpense, salaryAugust, futureExpense],
            payments: payments,
            exclusions: []
        )

        let summary = service.accountSummary(until: august.date(day: 5))

        #expect(summary.availableBalance == 400)
        #expect(summary.incomeUntilToday == 1_000)
        #expect(summary.paidExpensesUntilToday == 600)
    }

    @Test func monthRemainingUsesAllExpectedIncomeMinusAllExpectedExpenses() {
        let month = Date.monthStart(month: 8, year: 2026)
        let service = MoneyCalculationService(
            transactions: [
                makeIncome(title: "Salario", day: 1, month: month, amount: 2_000),
                makeIncome(title: "Freelance", day: 12, month: month, amount: 300),
                makeExpense(title: "Renda", day: 5, month: month, amount: 700),
                makeExpense(title: "Subscricao", day: 20, month: month, amount: 50)
            ],
            payments: [],
            exclusions: []
        )

        let summary = service.monthSummary(in: month)

        #expect(summary.income == 2_300)
        #expect(summary.expenses == 750)
        #expect(summary.remaining == 1_550)
        #expect(summary.unpaidExpenses == 750)
    }

    @Test func cumulativeBudgetRemainingCarriesPastMonthsIntoSelectedMonth() {
        let august = Date.monthStart(month: 8, year: 2026)
        let september = Date.monthStart(month: 9, year: 2026)
        let service = MoneyCalculationService(
            transactions: [
                makeIncome(title: "Salario agosto", day: 1, month: august, amount: 1_000),
                makeExpense(title: "Renda agosto", day: 5, month: august, amount: 700),
                makeIncome(title: "Salario setembro", day: 1, month: september, amount: 1_000),
                makeExpense(title: "Renda setembro", day: 5, month: september, amount: 1_200)
            ],
            payments: [],
            exclusions: []
        )

        #expect(service.monthSummary(in: august).remaining == 300)
        #expect(service.monthSummary(in: september).remaining == -200)
        #expect(service.cumulativeBudgetRemaining(through: september) == 100)
    }

    @Test func futureBudgetIncomeIsInRealBalanceButNotCurrentBudget() {
        let august = Date.monthStart(month: 8, year: 2026)
        let september = Date.monthStart(month: 9, year: 2026)
        let salary = makeIncome(
            title: "Salario",
            day: 20,
            month: august,
            amount: 1_800,
            budgetAllocation: .nextMonth
        )
        let augustExpense = makeExpense(title: "Renda", day: 5, month: august, amount: 700)
        let service = MoneyCalculationService(
            transactions: [salary, augustExpense],
            payments: [],
            exclusions: []
        )

        let account = service.accountSummary(until: august.date(day: 21))
        let augustSummary = service.monthSummary(in: august)
        let septemberSummary = service.monthSummary(in: september)

        #expect(account.availableBalance == 1_800)
        #expect(account.reservedForFutureBudgetsTotal == 1_800)
        #expect(account.reservedForFutureBudgets.first?.budgetMonth == september)
        #expect(augustSummary.income == 0)
        #expect(augustSummary.remaining == -700)
        #expect(septemberSummary.income == 1_800)
    }

    @Test func customBudgetMonthMovesOneOffIncomeAnalysisOnly() {
        let august = Date.monthStart(month: 8, year: 2026)
        let october = Date.monthStart(month: 10, year: 2026)
        let income = makeIncome(
            title: "Bonus",
            day: 15,
            month: august,
            amount: 500,
            budgetAllocation: .custom,
            budgetMonth: october
        )
        let service = MoneyCalculationService(transactions: [income], payments: [], exclusions: [])

        #expect(service.accountSummary(until: august.date(day: 16)).availableBalance == 500)
        #expect(service.monthSummary(in: august).income == 0)
        #expect(service.monthSummary(in: october).income == 500)
    }

    @Test func paidAmountIsClampedToExpenseValue() {
        let month = Date.monthStart(month: 8, year: 2026)
        let expense = makeExpense(title: "Cartao", day: 3, month: month, amount: 100)
        let service = MoneyCalculationService(
            transactions: [expense],
            payments: [ExpensePayment(transactionID: expense.id, monthStart: month, amountPaid: 150)],
            exclusions: []
        )

        #expect(service.paidAmount(for: expense, in: month) == 100)
        #expect(service.isPaid(expense, in: month))
    }

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
        let income = makeIncome(title: "Salario", day: 1, month: month, amount: 1_000)
        let paidExpense = makeExpense(title: "Renda", day: 1, month: month, amount: 500)
        let payment = ExpensePayment(transactionID: paidExpense.id, monthStart: month, amountPaid: 500)

        let visible = [paidExpense, income, unpaidExpense].visible(in: month, payments: [payment], exclusions: [])

        #expect(visible.map(\.id) == [unpaidExpense.id, income.id, paidExpense.id])
    }

    @Test func selectedCurrencyCodeUsesManualValueAndFallsBackToDeviceRegion() {
        let key = AppPreferences.selectedCurrencyCodeKey
        let previousValue = UserDefaults.standard.string(forKey: key)
        defer {
            if let previousValue {
                UserDefaults.standard.set(previousValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        UserDefaults.standard.set("USD", forKey: key)
        #expect(AppPreferences.selectedCurrencyCode == "USD")
        #expect(!AppPreferences.currencyText(for: 12.5).isEmpty)

        UserDefaults.standard.removeObject(forKey: key)
        #expect(!AppPreferences.selectedCurrencyCode.isEmpty)
    }

    @Test func analyticsDetectsPaidSpendingChangesAndSubscriptionsRatio() {
        let july = Date.monthStart(month: 7, year: 2026)
        let august = Date.monthStart(month: 8, year: 2026)
        let julyRestaurant = makeExpense(title: "Jantar", day: 1, month: july, amount: 100, expenseName: "Refeições fora de casa")
        let augustRestaurant = makeExpense(title: "Jantar", day: 1, month: august, amount: 150, expenseName: "Refeições fora de casa")
        let julyGroceries = makeExpense(title: "Mercado", day: 2, month: july, amount: 200, expenseName: "Alimentação: compras e supermercados")
        let augustGroceries = makeExpense(title: "Mercado", day: 2, month: august, amount: 100, expenseName: "Alimentação: compras e supermercados")
        let subscription = makeExpense(title: "Streaming", day: 3, month: august, amount: 70, expenseName: "Subscrições")
        let income = makeIncome(title: "Salario", day: 1, month: august, amount: 1_000)
        let payments = [julyRestaurant, augustRestaurant, julyGroceries, augustGroceries, subscription].map {
            ExpensePayment(transactionID: $0.id, monthStart: $0.monthStart, amountPaid: $0.amount)
        }
        let service = MoneyCalculationService(
            transactions: [julyRestaurant, augustRestaurant, julyGroceries, augustGroceries, subscription, income],
            payments: payments,
            exclusions: []
        )

        let insights = service.analyticsInsights(currentMonth: august)

        #expect(insights.count == 3)
        #expect(insights.contains { $0.message.contains("Restaurantes") || $0.message.contains("Restaurants") })
        #expect(insights.contains { $0.message.contains("supermercado") || $0.message.contains("Supermarket") })
        #expect(insights.contains { $0.message.contains("subscrições") || $0.message.contains("Subscription") })
    }

    private func makeIncome(
        title: String,
        day: Int,
        month: Date,
        amount: Double,
        recurrenceType: RecurrenceType? = nil,
        budgetAllocation: BudgetAllocation = .currentMonth,
        budgetMonth: Date? = nil
    ) -> MoneyTransaction {
        MoneyTransaction(
            title: title,
            day: day,
            monthStart: month,
            amount: amount,
            kind: TransactionKind.income.rawValue,
            repeatsEveryMonth: recurrenceType == .monthly,
            recurrenceType: recurrenceType?.rawValue,
            budgetAllocationType: budgetAllocation.rawValue,
            budgetMonthStart: budgetMonth?.monthStart ?? (budgetAllocation == .nextMonth ? month.nextMonthStart : month.monthStart)
        )
    }

    private func makeExpense(
        title: String = "Despesa",
        day: Int,
        month: Date,
        amount: Double = 100,
        expenseCategory: ExpenseCategory = .needs,
        expenseName: String = "Outros",
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
            expenseCategory: expenseCategory.rawValue,
            expenseName: expenseName,
            recurrenceType: recurrenceType?.rawValue,
            recurrenceMonth: recurrenceMonth,
            recurrenceEndMonthStart: recurrenceEndMonthStart
        )
    }
}
