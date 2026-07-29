//
//  ContentView.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var settings: [AccountSettings]

    @State private var selectedMonthOffset = 0
    @State private var editorRequest: TransactionEditorRequest?
    @State private var showsSettings = false

    private let monthOffsets = Array(-24...24)
    private var accountSettings: AccountSettings? { settings.first }
    private var selectedMonth: Date { Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date().monthStart) ?? Date().monthStart }
    private var selectedTransactions: [MoneyTransaction] { transactions.visible(in: selectedMonth, payments: payments) }

    private var incomeTotal: Double {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue }
            .reduce(0) { $0 + ($1.amount * Double($1.occurrenceCount(through: selectedMonth))) }
    }

    private var paidExpenses: Double {
        payments
            .filter { $0.monthStart <= selectedMonth }
            .reduce(0) { total, payment in
                guard let transaction = transactions.first(where: { $0.id == payment.transactionID && $0.kind == TransactionKind.expense.rawValue }) else {
                    return total
                }
                return total + transaction.amount
            }
    }

    private var monthUnpaidExpenses: Double {
        selectedTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue && !isPaid($0, in: selectedMonth) }
            .reduce(0) { $0 + $1.amount }
    }

    private var inAccount: Double { (accountSettings?.initialBalance ?? 0) + incomeTotal - paidExpenses }
    private var monthRemaining: Double { inAccount - monthUnpaidExpenses }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryBar

                TabView(selection: $selectedMonthOffset) {
                    ForEach(monthOffsets, id: \.self) { offset in
                        let month = Calendar.current.date(byAdding: .month, value: offset, to: Date().monthStart) ?? Date().monthStart

                        MonthPage(
                            month: month,
                            transactions: transactions.visible(in: month, payments: payments),
                            payments: payments,
                            onTogglePaid: togglePaid,
                            onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: month) },
                            onDelete: deleteTransactions
                        )
                        .tag(offset)
                    }
                }
                .monthPagerStyle()
            }
            .navigationTitle(accountSettings?.personName.isEmpty == false ? accountSettings?.personName ?? "Money Control" : "Money Control")
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .sheet(item: $editorRequest) { request in
                TransactionEditor(request: request)
            }
            .sheet(isPresented: $showsSettings) {
                if let accountSettings {
                    SettingsEditor(settings: accountSettings, onDelete: deleteTransactions)
                }
            }
            .onAppear(perform: ensureSettings)
        }
    }

    private var summaryBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                SummaryTile(title: "Na Conta", value: inAccount)

                Button {
                    showsSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .frame(width: 44, height: 58)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 8) {
                SummaryTile(title: "Mês Falta Pagar", value: monthUnpaidExpenses)
                SummaryTile(title: "Mês Remanescente", value: monthRemaining)
            }
        }
        .padding()
        .background(.thinMaterial)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
            } label: {
                Label("Despesa", systemImage: "minus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
            } label: {
                Label("Income", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.bar)
    }

    private func ensureSettings() {
        guard settings.isEmpty else { return }
        modelContext.insert(AccountSettings())
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        payments.contains { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
    }

    private func togglePaid(_ transaction: MoneyTransaction, in month: Date) {
        if let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) {
            modelContext.delete(payment)
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: month.monthStart))
        }
    }

    private func deleteTransactions(_ transaction: MoneyTransaction) {
        payments
            .filter { $0.transactionID == transaction.id }
            .forEach(modelContext.delete)
        modelContext.delete(transaction)
    }
}

private struct MonthPage: View {
    let month: Date
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let onTogglePaid: (MoneyTransaction, Date) -> Void
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(month.monthTitle)
                .font(.largeTitle.bold())
                .padding(.horizontal)
                .padding(.top)

            if transactions.isEmpty {
                ContentUnavailableView("Sem movimentos", systemImage: "calendar", description: Text("Adiciona despesas ou incomes deste mês."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(transactions) { transaction in
                        TransactionRow(
                            transaction: transaction,
                            isPaid: isPaid(transaction),
                            onTogglePaid: { onTogglePaid(transaction, month) },
                            onEdit: { onEdit(transaction) },
                            onDelete: { onDelete(transaction) }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func isPaid(_ transaction: MoneyTransaction) -> Bool {
        payments.contains { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
    }
}

private struct TransactionRow: View {
    let transaction: MoneyTransaction
    let isPaid: Bool
    let onTogglePaid: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var category: ExpenseCategory? {
        ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
    }

    var body: some View {
        HStack(spacing: 12) {
            if transaction.kind == TransactionKind.expense.rawValue {
                Button(action: onTogglePaid) {
                    Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isPaid ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }

            if let category {
                Circle()
                    .fill(category.color)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayName)
                    .font(.headline)

                Text(transaction.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(transaction.amount.currencyText)
                    .font(.headline)
                    .foregroundStyle(transaction.kind == TransactionKind.income.rawValue ? .green : .red)

                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SummaryTile: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value.currencyText)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SettingsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Bindable var settings: AccountSettings

    let onDelete: (MoneyTransaction) -> Void

    @State private var showsAccountFields = false
    @State private var editorRequest: TransactionEditorRequest?
    @State private var selectedList = 0

    private var accountIsFilled: Bool {
        !settings.personName.trimmingCharacters(in: .whitespaces).isEmpty || settings.initialBalance != 0
    }

    private var periodicExpenses: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.recurrence == .yearlyMonth }
            .sorted { $0.recurrenceMonth == $1.recurrenceMonth ? $0.day < $1.day : $0.recurrenceMonth < $1.recurrenceMonth }
    }

    private var salaries: [MoneyTransaction] {
        transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.recurrence == .monthly }
            .sorted { $0.day == $1.day ? $0.title < $1.title : $0.day < $1.day }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dados da conta") {
                    if showsAccountFields || !accountIsFilled {
                        LabeledContent("Nome") {
                            TextField("Nome da pessoa", text: $settings.personName)
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent("Saldo inicial") {
                            TextField("Saldo inicial", value: $settings.initialBalance, format: .number)
                                .multilineTextAlignment(.trailing)
                                .decimalKeyboard()
                        }
                    } else {
                        LabeledContent("Nome", value: settings.personName)
                        LabeledContent("Saldo inicial", value: settings.initialBalance.currencyText)

                        Button {
                            showsAccountFields = true
                        } label: {
                            Label("Expandir para alterar", systemImage: "chevron.down")
                        }
                    }
                }

                Section {
                    Button {
                        editorRequest = TransactionEditorRequest(mode: .periodicExpense, month: Date().monthStart)
                    } label: {
                        Label("Despesa Periódica", systemImage: "calendar.badge.plus")
                    }

                    Button {
                        editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
                    } label: {
                        Label("Vencimento", systemImage: "banknote")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedList == 0 ? "Lista de despesas periódicas" : "Lista de vencimentos")
                            .font(.headline)

                        TabView(selection: $selectedList) {
                            RecurringList(
                                emptyTitle: "Sem despesas periódicas",
                                transactions: periodicExpenses,
                                payments: payments,
                                onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: Date().monthStart) },
                                onDelete: onDelete
                            )
                            .tag(0)

                            RecurringList(
                                emptyTitle: "Sem vencimentos",
                                transactions: salaries,
                                payments: payments,
                                onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: Date().monthStart) },
                                onDelete: onDelete
                            )
                            .tag(1)
                        }
                        .frame(minHeight: 220)
                        .monthPagerStyle()
                    }
                }
            }
            .navigationTitle("Configurações")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .sheet(item: $editorRequest) { request in
                TransactionEditor(request: request)
            }
        }
    }
}

private struct RecurringList: View {
    let emptyTitle: String
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void

    var body: some View {
        if transactions.isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: "list.bullet.rectangle")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            VStack(spacing: 0) {
                ForEach(transactions) { transaction in
                    TransactionRow(
                        transaction: transaction,
                        isPaid: false,
                        onTogglePaid: {},
                        onEdit: { onEdit(transaction) },
                        onDelete: { onDelete(transaction) }
                    )
                    .padding(.vertical, 6)

                    Divider()
                }
            }
        }
    }
}

private struct TransactionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let request: TransactionEditorRequest

    @State private var title = ""
    @State private var day = 1
    @State private var value = ""
    @State private var repeatsEveryMonth = false
    @State private var expenseCategory: ExpenseCategory?
    @State private var expenseName = ""
    @State private var recurrenceMonth = Calendar.current.component(.month, from: Date())
    @State private var showsDayPicker = false
    @State private var validationMessage: String?
    @State private var didLoad = false

    private var mode: TransactionEditorMode { request.mode }
    private var editedTransaction: MoneyTransaction? { request.transaction }
    private var pickerMonth: Date { Date.monthStart(forMonthNumber: recurrenceMonth) }

    var body: some View {
        NavigationStack {
            Form {
                if mode.needsExpenseClassification {
                    Section("Classificação") {
                        Picker("Tipo de despesa", selection: $expenseCategory) {
                            Text("Selecionar").tag(nil as ExpenseCategory?)
                            ForEach(ExpenseCategory.allCases) { category in
                                Label(category.title, systemImage: "circle.fill")
                                    .foregroundStyle(category.color)
                                    .tag(category as ExpenseCategory?)
                            }
                        }

                        Picker("Nome", selection: $expenseName) {
                            Text("Selecionar").tag("")
                            ForEach(expenseCategory?.names ?? [], id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .disabled(expenseCategory == nil)
                    }
                }

                if mode == .periodicExpense {
                    Section("Recorrência") {
                        Picker("Mês", selection: $recurrenceMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(Date.monthName(forMonthNumber: month)).tag(month)
                            }
                        }
                    }
                }

                Section(mode.sectionTitle) {
                    TextField(mode == .expense || mode == .periodicExpense ? "Texto livre" : "Nome", text: $title)

                    Button {
                        showsDayPicker = true
                    } label: {
                        HStack {
                            Text("Dia")
                            Spacer()
                            Text("\(day)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("Valor", text: $value)
                        .decimalKeyboard()

                    if mode == .expense {
                        Toggle("Adicionar em todos os meses", isOn: $repeatsEveryMonth)
                    }
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(mode.navigationTitle(isEditing: editedTransaction != nil))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: save)
                }
            }
            .sheet(isPresented: $showsDayPicker) {
                DayPicker(month: mode == .periodicExpense ? pickerMonth : request.month, selectedDay: $day)
            }
            .onChange(of: expenseCategory) { _, _ in
                expenseName = ""
            }
            .onAppear(perform: loadInitialValues)
        }
    }

    private var parsedValue: Double? {
        Double(value.replacingOccurrences(of: ",", with: "."))
    }

    private func loadInitialValues() {
        guard !didLoad else { return }
        didLoad = true

        guard let transaction = editedTransaction else {
            recurrenceMonth = Calendar.current.component(.month, from: request.month)
            return
        }

        title = transaction.title
        day = transaction.day
        value = String(transaction.amount)
        repeatsEveryMonth = transaction.recurrence == .monthly && transaction.kind == TransactionKind.expense.rawValue
        expenseCategory = ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
        expenseName = transaction.expenseName ?? ""
        recurrenceMonth = transaction.recurrenceMonth > 0 ? transaction.recurrenceMonth : Calendar.current.component(.month, from: transaction.monthStart)
    }

    private func save() {
        validationMessage = nil

        guard let parsedValue else {
            validationMessage = "Preenche o valor."
            return
        }

        if mode.needsExpenseClassification {
            guard let expenseCategory else {
                validationMessage = "Seleciona o tipo de despesa."
                return
            }

            guard !expenseName.isEmpty else {
                validationMessage = "Seleciona o nome da despesa."
                return
            }

            saveExpense(value: parsedValue, category: expenseCategory)
        } else {
            let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
            guard !trimmedTitle.isEmpty else {
                validationMessage = "Preenche o nome."
                return
            }

            saveIncome(value: parsedValue, title: trimmedTitle)
        }

        dismiss()
    }

    private func saveExpense(value: Double, category: ExpenseCategory) {
        let transaction = editedTransaction ?? MoneyTransaction(
            title: "",
            day: day,
            monthStart: request.month.monthStart,
            amount: value,
            kind: TransactionKind.expense.rawValue
        )

        transaction.title = title.trimmingCharacters(in: .whitespaces)
        transaction.day = day
        transaction.amount = value
        transaction.kind = TransactionKind.expense.rawValue
        transaction.expenseCategory = category.rawValue
        transaction.expenseName = expenseName

        if mode == .periodicExpense {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = RecurrenceType.yearlyMonth.rawValue
            transaction.recurrenceMonth = recurrenceMonth
            transaction.monthStart = Date.monthStart(forMonthNumber: recurrenceMonth)
        } else {
            transaction.repeatsEveryMonth = repeatsEveryMonth
            transaction.recurrenceType = repeatsEveryMonth ? RecurrenceType.monthly.rawValue : nil
            transaction.recurrenceMonth = 0
            transaction.monthStart = request.month.monthStart
        }

        if editedTransaction == nil {
            modelContext.insert(transaction)
        }
    }

    private func saveIncome(value: Double, title: String) {
        let transaction = editedTransaction ?? MoneyTransaction(
            title: title,
            day: day,
            monthStart: request.month.monthStart,
            amount: value,
            kind: TransactionKind.income.rawValue
        )

        transaction.title = title
        transaction.day = day
        transaction.amount = value
        transaction.kind = TransactionKind.income.rawValue
        transaction.expenseCategory = nil
        transaction.expenseName = nil

        if mode == .salary {
            transaction.repeatsEveryMonth = true
            transaction.recurrenceType = RecurrenceType.monthly.rawValue
        } else {
            transaction.repeatsEveryMonth = false
            transaction.recurrenceType = nil
        }

        transaction.recurrenceMonth = 0
        transaction.monthStart = request.month.monthStart

        if editedTransaction == nil {
            modelContext.insert(transaction)
        }
    }
}

private struct DayPicker: View {
    @Environment(\.dismiss) private var dismiss
    let month: Date
    @Binding var selectedDay: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...month.daysInMonth, id: \.self) { day in
                    Button {
                        selectedDay = day
                        dismiss()
                    } label: {
                        Text("\(day)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(day == selectedDay ? Color.accentColor : Color.secondary.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(day == selectedDay ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle(month.monthTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

private struct TransactionEditorRequest: Identifiable {
    let id = UUID()
    let mode: TransactionEditorMode
    let month: Date
    let transaction: MoneyTransaction?

    init(mode: TransactionEditorMode, month: Date, transaction: MoneyTransaction? = nil) {
        self.mode = mode
        self.month = month
        self.transaction = transaction
    }

    init(transaction: MoneyTransaction, month: Date) {
        self.mode = transaction.editorMode
        self.month = month
        self.transaction = transaction
    }
}

private enum TransactionKind: String {
    case expense
    case income
}

private enum RecurrenceType: String {
    case monthly
    case yearlyMonth
}

private enum TransactionEditorMode: String {
    case expense
    case income
    case periodicExpense
    case salary

    var needsExpenseClassification: Bool {
        self == .expense || self == .periodicExpense
    }

    var sectionTitle: String {
        switch self {
        case .expense, .periodicExpense:
            "Detalhes"
        case .income:
            "Income"
        case .salary:
            "Vencimento"
        }
    }

    func navigationTitle(isEditing: Bool) -> String {
        let prefix = isEditing ? "Editar" : "Novo"

        switch self {
        case .expense:
            return "\(prefix) Despesa"
        case .income:
            return "\(prefix) Income"
        case .periodicExpense:
            return "\(prefix) Despesa Periódica"
        case .salary:
            return "\(prefix) Vencimento"
        }
    }
}

private enum ExpenseCategory: String, CaseIterable, Identifiable {
    case needs
    case wants
    case savingsAndDebt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needs:
            "50% Necessidades"
        case .wants:
            "30% Desejos"
        case .savingsAndDebt:
            "20% Pagamentos e Poupança"
        }
    }

    var color: Color {
        switch self {
        case .needs:
            .blue
        case .wants:
            .orange
        case .savingsAndDebt:
            .purple
        }
    }

    var names: [String] {
        switch self {
        case .needs:
            [
                "Habitação: renda ou prestação do crédito à habitação",
                "Transportes: transporte público, prestações e combustível",
                "Alimentação: compras de supermercado",
                "Contas de serviços essenciais: eletricidade, gás, água e telecomunicações",
                "Seguros: saúde, vida e automóvel essenciais"
            ]
        case .wants:
            [
                "Refeições fora de casa",
                "Subscrições mensais",
                "Atividades de lazer e entretenimento",
                "Viagens e férias",
                "Roupa e acessórios"
            ]
        case .savingsAndDebt:
            [
                "Poupança",
                "Amortização de dívidas"
            ]
        }
    }
}

private extension Array where Element == MoneyTransaction {
    func visible(in month: Date, payments: [ExpensePayment]) -> [MoneyTransaction] {
        filter { $0.occurs(in: month) }
            .sorted { first, second in
                let firstRank = first.listRank(in: month, payments: payments)
                let secondRank = second.listRank(in: month, payments: payments)

                if firstRank != secondRank {
                    return firstRank < secondRank
                }

                if first.day != second.day {
                    return first.day < second.day
                }

                return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
            }
    }
}

private extension MoneyTransaction {
    var recurrence: RecurrenceType? {
        if let recurrenceType, let recurrence = RecurrenceType(rawValue: recurrenceType) {
            return recurrence
        }

        return repeatsEveryMonth ? .monthly : nil
    }

    var editorMode: TransactionEditorMode {
        if kind == TransactionKind.expense.rawValue {
            return recurrence == .yearlyMonth ? .periodicExpense : .expense
        }

        return recurrence == .monthly ? .salary : .income
    }

    var displayName: String {
        if kind == TransactionKind.expense.rawValue {
            return expenseName ?? title
        }
        return title
    }

    var detailText: String {
        var parts = ["Dia \(day)"]

        if let category = ExpenseCategory(rawValue: expenseCategory ?? "") {
            parts.append(category.title)
        }

        if kind == TransactionKind.expense.rawValue, !title.isEmpty {
            parts.append(title)
        }

        switch recurrence {
        case .monthly:
            parts.append("todos os meses")
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: recurrenceMonth))
        case nil:
            break
        }

        return parts.joined(separator: " · ")
    }

    func occurs(in month: Date) -> Bool {
        switch recurrence {
        case .monthly:
            return month.monthStart >= monthStart.monthStart
        case .yearlyMonth:
            return month.monthNumber == recurrenceMonth
        case nil:
            return Calendar.current.isDate(monthStart, equalTo: month, toGranularity: .month)
        }
    }

    func occurrenceCount(through month: Date) -> Int {
        guard kind == TransactionKind.income.rawValue else { return 0 }

        switch recurrence {
        case .monthly:
            let months = Calendar.current.dateComponents([.month], from: monthStart.monthStart, to: month.monthStart).month ?? -1
            return max(months + 1, 0)
        case .yearlyMonth:
            return month.monthNumber >= recurrenceMonth ? 1 : 0
        case nil:
            return monthStart.monthStart <= month.monthStart ? 1 : 0
        }
    }

    func listRank(in month: Date, payments: [ExpensePayment]) -> Int {
        guard kind == TransactionKind.expense.rawValue else { return 1 }
        let paid = payments.contains { $0.transactionID == id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }
        return paid ? 2 : 0
    }
}

private extension Date {
    var monthStart: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var monthNumber: Int {
        Calendar.current.component(.month, from: self)
    }

    var monthTitle: String {
        formatted(.dateTime.month(.wide).year())
    }

    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 31
    }

    static func monthStart(forMonthNumber month: Int) -> Date {
        var components = Calendar.current.dateComponents([.year], from: Date())
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components) ?? Date().monthStart
    }

    static func monthName(forMonthNumber month: Int) -> String {
        monthStart(forMonthNumber: month).formatted(.dateTime.month(.wide))
    }
}

private extension Double {
    var currencyText: String {
        formatted(.currency(code: Locale.current.currency?.identifier ?? "EUR"))
    }
}

private extension View {
    @ViewBuilder
    func monthPagerStyle() -> some View {
#if os(iOS)
        tabViewStyle(.page(indexDisplayMode: .never))
#else
        self
#endif
    }

    @ViewBuilder
    func decimalKeyboard() -> some View {
#if os(iOS)
        keyboardType(.decimalPad)
#else
        self
#endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, AccountSettings.self], inMemory: true)
}
