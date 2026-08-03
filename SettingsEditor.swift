//
//  SettingsEditor.swift
//  MoneyControl
//

import SwiftData
import SwiftUI

struct SettingsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var exclusions: [RecurrenceExclusion]
    @State private var editorRequest: TransactionEditorRequest?
    @State private var selectedList = 0
    @State private var selectedTab: SettingsTab = .budget
    @State private var pendingAction: SettingsListAction?
    @State private var showsDeleteAllDataConfirmation = false

    private var nextMonth: Date {
        Date().monthStart.nextMonthStart
    }

    private var monthlyExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.recurrence == .monthly && $0.isActiveForSettingsList }
            .sorted { $0.day == $1.day ? $0.displayName < $1.displayName : $0.day < $1.day }
    }

    private var periodicExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.recurrence == .yearlyMonth && $0.isActiveForSettingsList }
            .sorted { $0.recurrenceMonth == $1.recurrenceMonth ? $0.day < $1.day : $0.recurrenceMonth < $1.recurrenceMonth }
    }

    private var salaries: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.recurrence == .monthly && $0.isActiveForSettingsList }
            .sorted { $0.day == $1.day ? $0.title < $1.title : $0.day < $1.day }
    }

    private var selectedListTitle: String {
        switch selectedList {
        case 0:
            AppStrings.text(.salariesList)
        case 1:
            AppStrings.text(.monthlyExpensesList)
        default:
            AppStrings.text(.periodicExpensesList)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text(AppStrings.text(.budgetSettings)).tag(SettingsTab.budget)
                    Text(AppStrings.text(.appSettings)).tag(SettingsTab.app)
                }
                .pickerStyle(.segmented)
                .tint(AppPalette.background)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)

                switch selectedTab {
                case .app:
                    appSettingsView
                case .budget:
                    budgetSettingsView
                }
            }
            .background(AppPalette.appBackground)
            .navigationTitle(AppStrings.text(.settings))
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                        .liquidGlassButtonStyle()
                }
            }
            .sheet(item: $editorRequest) { request in
                TransactionEditor(request: request)
            }
            .alert(
                pendingAction?.title ?? "",
                isPresented: Binding(
                    get: { pendingAction != nil },
                    set: { if !$0 { pendingAction = nil } }
                ),
                presenting: pendingAction
            ) { action in
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.continueAction), role: action.kind == .delete ? .destructive : nil) {
                    perform(action)
                }
            } message: { action in
                Text(action.message)
            }
            .alert(AppStrings.text(.deleteAllDataTitle), isPresented: $showsDeleteAllDataConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.delete), role: .destructive, action: deleteAllData)
            } message: {
                Text(AppStrings.text(.deleteAllDataMessage))
            }
        }
    }

    private var appSettingsView: some View {
        Form {
            Section {
                Button {
                    hasSeenOnboarding = false
                    hasCompletedInitialSetup = false
                    dismiss()
                } label: {
                    Label(AppStrings.text(.showOnboardingAgain), systemImage: "sparkles.rectangle.stack")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .liquidGlassButtonStyle()

                Button(role: .destructive) {
                    showsDeleteAllDataConfirmation = true
                } label: {
                    Label(AppStrings.text(.deleteAllData), systemImage: "trash")
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .tint(AppPalette.primary)
                .liquidGlassButtonStyle(prominent: true)
            }
            .listRowBackground(AppPalette.surface)
        }
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private var budgetSettingsView: some View {
        Form {
            Section {
                Button {
                    selectedList = 0
                    editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
                } label: {
                    Label(AppStrings.text(.salary), systemImage: "banknote")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .liquidGlassButtonStyle()
                .listRowSeparator(.hidden)

                Button {
                    selectedList = 1
                    editorRequest = TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)
                } label: {
                    Label(AppStrings.text(.monthlyExpense), systemImage: "calendar.badge.clock")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .liquidGlassButtonStyle()
                .listRowSeparator(.hidden)

                Button {
                    selectedList = 2
                    editorRequest = TransactionEditorRequest(mode: .periodicExpense, month: Date().monthStart)
                } label: {
                    Label(AppStrings.text(.periodicExpense), systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .liquidGlassButtonStyle()
                .listRowSeparator(.hidden)
            }
            .listRowBackground(AppPalette.surface)

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedListTitle)
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)

                    TabView(selection: $selectedList) {
                        RecurringList(
                            emptyTitle: AppStrings.text(.noSalaries),
                            transactions: salaries,
                            payments: payments,
                            onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                            onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
                        )
                        .tag(0)

                        RecurringList(
                            emptyTitle: AppStrings.text(.noMonthlyExpenses),
                            transactions: monthlyExpenses,
                            payments: payments,
                            onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                            onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
                        )
                        .tag(1)

                        RecurringList(
                            emptyTitle: AppStrings.text(.noPeriodicExpenses),
                            transactions: periodicExpenses,
                            payments: payments,
                            onEdit: { pendingAction = SettingsListAction(kind: .edit, transaction: $0) },
                            onDelete: { pendingAction = SettingsListAction(kind: .delete, transaction: $0) }
                        )
                        .tag(2)
                    }
                    .frame(minHeight: 220)
                    .monthPagerStyle()

                    CarouselNavigationButtons(
                        selection: $selectedList,
                        lowerBound: 0,
                        upperBound: 2
                    )
                }
            }
            .listRowBackground(AppPalette.surface)
        }
        .scrollContentBackground(.hidden)
        .foregroundStyle(AppPalette.background)
        .tint(AppPalette.background)
        .background(AppPalette.appBackground)
    }

    private func perform(_ action: SettingsListAction) {
        switch action.kind {
        case .edit:
            editorRequest = TransactionEditorRequest(transaction: action.transaction, month: nextMonth, editScope: .futureMonths)
        case .delete:
            action.transaction.recurrenceEndMonthStart = nextMonth
            payments
                .filter { $0.transactionID == action.transaction.id && $0.monthStart >= nextMonth }
                .forEach(modelContext.delete)
        }

        pendingAction = nil
    }

    private func deleteAllData() {
        payments.forEach(modelContext.delete)
        exclusions.forEach(modelContext.delete)
        transactions.forEach(modelContext.delete)
        hasCompletedInitialSetup = false
    }
}

private enum SettingsTab {
    case app
    case budget
}

private struct SettingsListAction: Identifiable {
    enum Kind {
        case edit
        case delete
    }

    let id = UUID()
    let kind: Kind
    let transaction: MoneyTransaction

    var title: String {
        switch kind {
        case .edit:
            AppStrings.text(.futureEditTitle)
        case .delete:
            AppStrings.text(.futureDeleteTitle)
        }
    }

    var message: String {
        switch kind {
        case .edit:
            AppStrings.text(.futureEditMessage)
        case .delete:
            AppStrings.text(.futureDeleteMessage)
        }
    }
}
