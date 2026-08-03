//
//  InitialSetupWizardView.swift
//  MoneyControl
//

import Charts
import SwiftData
import SwiftUI

struct InitialSetupWizardView: View {
    @Environment(\.modelContext) private var modelContext

    let onFinish: () -> Void

    @State private var step = 0
    @State private var direction = 1
    @State private var validationMessage: String?
    @State private var incomeDraft = SetupIncomeDraft()
    @State private var expenseDraft = SetupExpenseDraft()
    @State private var incomes: [SetupIncomeDraft] = []
    @State private var expenses: [SetupExpenseDraft] = []
    @State private var showsExpenseDayPicker = false

    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var availableBalance: Double {
        totalIncome - totalExpenses
    }

    private var expenseCategoryTotals: [SetupCategoryTotal] {
        ExpenseCategory.allCases.map { category in
            SetupCategoryTotal(
                category: category,
                amount: expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
            )
        }
    }

    private var bodyAnalysis: String {
        guard totalIncome > 0 else {
            return "Adicione os seus rendimentos para obter uma análise inicial do orçamento."
        }

        let needsRatio = categoryRatio(.needs)
        let wantsRatio = categoryRatio(.wants)
        let savingsRatio = categoryRatio(.savingsAndDebt)

        if needsRatio > 0.50 {
            return "Está acima do recomendado em Necessidades. Pode acompanhar esta área com mais atenção nos próximos meses."
        }

        if savingsRatio < 0.20 {
            return "Ainda pode aumentar a sua poupança para se aproximar da regra 50/30/20."
        }

        if wantsRatio <= 0.30 && needsRatio <= 0.50 && savingsRatio >= 0.20 {
            return "Excelente equilíbrio financeiro. Está dentro do orçamento recomendado."
        }

        return "Está dentro de um ponto de partida saudável para acompanhar e ajustar o orçamento todos os meses."
    }

    var body: some View {
        ZStack {
            AppPalette.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                ZStack {
                    currentStepView
                        .id(step)
                        .transition(.asymmetric(
                            insertion: .move(edge: direction >= 0 ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: direction >= 0 ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
                .animation(.snappy, value: step)

                footer
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    .background(AppPalette.appBackground)
            }
        }
        .preferredColorScheme(.light)
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(step + 1)/3")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Spacer()

                Text("Configuração inicial")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.mutedText)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppPalette.separator)
                    Capsule()
                        .fill(AppPalette.primary)
                        .frame(width: proxy.size.width * CGFloat(step + 1) / 3)
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case 0:
            incomeStep
        case 1:
            expenseStep
        default:
            summaryStep
        }
    }

    private var incomeStep: some View {
        wizardScroll {
            stepTitle(
                title: "Bem-vindo!",
                subtitle: "Vamos configurar o seu orçamento. Isto demora menos de 2 minutos."
            )

            inputCard(title: "Rendimentos mensais", systemImage: "banknote.fill", tint: AppPalette.positive) {
                TextField("Nome", text: $incomeDraft.name, prompt: Text(" ... Nome do rendimento").foregroundStyle(AppPalette.secondaryText))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppPalette.background)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))

                MoneyAmountPicker(title: "Valor", amount: $incomeDraft.amount, maximumAmount: 20_000)

                Button {
                    addIncome()
                } label: {
                    Label("Adicionar rendimento", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            draftList(title: "Rendimentos adicionados", drafts: incomes.map { $0.listText }, emptyText: "Ainda não adicionou rendimentos.") { index in
                incomes.remove(at: index)
            }

            noteCard("Pode sempre adicionar novos rendimentos ou alterar os existentes mais tarde.")
        }
    }

    private var expenseStep: some View {
        wizardScroll {
            stepTitle(
                title: "Despesas mensais",
                subtitle: "Quais destas despesas paga todos os meses?"
            )

            inputCard(title: "Despesa", systemImage: "creditcard.fill", tint: AppPalette.primary) {
                HStack(spacing: 10) {
                    Text("Categoria 50/30/20")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)

                    HelpIconButton(
                        title: "Regra 50/30/20",
                        message: "A metodologia 50/30/20 ajuda a distribuir o rendimento de forma equilibrada: 50% para necessidades, 30% para desejos e 20% para poupança. Não é uma regra obrigatória, mas uma referência para uma melhor gestão financeira."
                    )

                    Spacer()
                }

                Picker("Categoria", selection: $expenseDraft.category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AppPalette.background)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tipo de Despesa")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)

                    Picker("Tipo de Despesa", selection: $expenseDraft.expenseName) {
                        Text("Selecionar").tag("")
                        ForEach(expenseDraft.category.names, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .font(.headline)
                    .tint(AppPalette.background)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, 12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                }

                TextField("Nome", text: $expenseDraft.name, prompt: Text("Texto livre opcional").foregroundStyle(AppPalette.secondaryText))
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppPalette.background)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))

                MoneyAmountPicker(title: "Valor", amount: $expenseDraft.amount, maximumAmount: 20_000)

                Button {
                    showsExpenseDayPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppPalette.primary)
                            .frame(width: 34, height: 34)
                            .background(AppPalette.paleOrange, in: Circle())

                        Text("Dia do mês")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)

                        Spacer()

                        Text("\(expenseDraft.day)")
                            .font(.headline.bold())
                            .foregroundStyle(AppPalette.background)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Toggle("Todos os meses", isOn: $expenseDraft.repeatsEveryMonth)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .tint(AppPalette.primary)
                    .padding(12)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))

                Button {
                    addExpense()
                } label: {
                    Label("Adicionar despesa", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(AppPalette.primary, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .id(expenseDraft.id)

            draftList(title: "Despesas adicionadas", drafts: expenses.map { $0.listText }, emptyText: "Ainda não adicionou despesas.") { index in
                expenses.remove(at: index)
            }

            noteCard("Pode sempre adicionar novas despesas ou alterar despesas mensais e periódicas mais tarde.")
        }
        .sheet(isPresented: $showsExpenseDayPicker) {
            DayPicker(month: Date().monthStart, selectedDay: $expenseDraft.day)
        }
    }

    private var summaryStep: some View {
        wizardScroll {
            stepTitle(
                title: "O seu orçamento está pronto.",
                subtitle: "Revê o resumo inicial antes de começar a utilizar a SpendWise."
            )

            VStack(spacing: 10) {
                summaryRow("Recebe", totalIncome.currencyText, AppPalette.positive)
                summaryRow("Despesas fixas", totalExpenses.currencyText, AppPalette.primary)
                summaryRow("Pode gastar este mês", availableBalance.currencyText, AppPalette.background)
            }
            .padding(16)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)

            inputCard(title: "Resumo visual", systemImage: "chart.pie.fill", tint: AppPalette.secondary) {
                Chart {
                    BarMark(x: .value("Tipo", "Rendimentos"), y: .value("Valor", totalIncome))
                        .foregroundStyle(AppPalette.positive)
                    BarMark(x: .value("Tipo", "Despesas"), y: .value("Valor", totalExpenses))
                        .foregroundStyle(AppPalette.primary)
                    BarMark(x: .value("Tipo", "Saldo"), y: .value("Valor", max(availableBalance, 0)))
                        .foregroundStyle(AppPalette.background)
                }
                .frame(height: 170)
                .chartYAxis { AxisMarks(position: .leading) }

                if totalExpenses > 0 {
                    Chart(expenseCategoryTotals.filter { $0.amount > 0 }) { point in
                        SectorMark(angle: .value("Valor", point.amount), innerRadius: .ratio(0.58), angularInset: 1.5)
                            .foregroundStyle(point.category.color)
                            .cornerRadius(4)
                    }
                    .frame(height: 170)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(expenseCategoryTotals) { point in
                            HStack(spacing: 8) {
                                Circle().fill(point.category.color).frame(width: 10, height: 10)
                                Text("\(point.category.title): \(percentageText(point.amount, total: totalExpenses))")
                                    .font(.caption)
                                    .foregroundStyle(AppPalette.mutedText)
                            }
                        }
                    }
                }
            }

            inputCard(title: "Análise automática", systemImage: "lightbulb.fill", tint: AppPalette.accent) {
                Text(bodyAnalysis)
                    .font(.body)
                    .foregroundStyle(AppPalette.bodyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            noteCard("Este é apenas o ponto de partida. Continue a registar os seus movimentos e acompanhe a evolução do seu orçamento todos os meses.")
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button {
                    goBack()
                } label: {
                    Label("Voltar", systemImage: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16).stroke(AppPalette.separator, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(step == 0)
                .opacity(step == 0 ? 0.35 : 1)

                Button {
                    goForward()
                } label: {
                    Text(step == 2 ? "Começar a utilizar a\nSpendWise" : "Seguinte")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(step == 2 ? AppPalette.background : AppPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func wizardScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
    }

    private func stepTitle(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(AppPalette.background)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(AppPalette.bodyText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inputCard<Content: View>(title: String, systemImage: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.16), in: Circle())

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
            }

            content()
        }
        .padding(16)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }

    private func draftList(title: String, drafts: [String], emptyText: String, onDelete: @escaping (Int) -> Void) -> some View {
        inputCard(title: title, systemImage: "list.bullet.rectangle", tint: AppPalette.secondary) {
            if drafts.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(drafts.enumerated()), id: \.offset) { index, text in
                        HStack(spacing: 10) {
                            Text(text)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.bodyText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                onDelete(index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(AppPalette.primary)
                                    .frame(width: 34, height: 34)
                                    .background(AppPalette.paleOrange, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func noteCard(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(AppPalette.mutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppPalette.mintSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }

    private func summaryRow(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppPalette.bodyText)
            Spacer()
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(color)
        }
    }

    private func addIncome() {
        validationMessage = nil
        let name = incomeDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            validationMessage = "Indique o nome do rendimento."
            return
        }

        guard incomeDraft.amount > 0 else {
            validationMessage = "Indique o valor do rendimento."
            return
        }

        incomeDraft.name = name
        incomes.append(incomeDraft)
        incomeDraft = SetupIncomeDraft()
    }

    private func addExpense() {
        validationMessage = nil

        guard !expenseDraft.expenseName.isEmpty else {
            validationMessage = "Selecione o tipo de despesa."
            return
        }

        guard expenseDraft.amount > 0 else {
            validationMessage = "Indique o valor da despesa."
            return
        }

        expenseDraft.name = expenseDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        expenses.append(expenseDraft)
        expenseDraft = SetupExpenseDraft()
    }

    private func goBack() {
        guard step > 0 else { return }
        validationMessage = nil
        direction = -1
        step -= 1
    }

    private func goForward() {
        validationMessage = nil

        if step == 0 {
            if incomeDraft.hasRequiredValues {
                addIncome()
            }
            guard !incomes.isEmpty else {
                validationMessage = "Adicione pelo menos um rendimento para continuar."
                return
            }
        }

        if step == 1 {
            if expenseDraft.hasRequiredValues {
                addExpense()
            }
        }

        if step < 2 {
            direction = 1
            step += 1
        } else {
            saveSetup()
            onFinish()
        }
    }

    private func saveSetup() {
        let monthStart = Date().monthStart

        for income in incomes {
            modelContext.insert(MoneyTransaction(
                title: income.name,
                day: 1,
                monthStart: monthStart,
                amount: income.amount,
                kind: TransactionKind.income.rawValue,
                repeatsEveryMonth: true,
                recurrenceType: RecurrenceType.monthly.rawValue
            ))
        }

        for expense in expenses {
            modelContext.insert(MoneyTransaction(
                title: expense.name,
                day: expense.day,
                monthStart: monthStart,
                amount: expense.amount,
                kind: TransactionKind.expense.rawValue,
                repeatsEveryMonth: expense.repeatsEveryMonth,
                expenseCategory: expense.category.rawValue,
                expenseName: expense.expenseName,
                recurrenceType: expense.repeatsEveryMonth ? RecurrenceType.monthly.rawValue : nil,
                recurrenceMonth: 0
            ))
        }
    }

    private func categoryRatio(_ category: ExpenseCategory) -> Double {
        guard totalIncome > 0 else { return 0 }
        let amount = expenses.filter { $0.category == category }.reduce(0) { $0 + $1.amount }
        return amount / totalIncome
    }

    private func percentageText(_ amount: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct SetupIncomeDraft: Identifiable {
    let id = UUID()
    var name = ""
    var amount = 0.0

    var hasRequiredValues: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0 }
    var listText: String { "\(name) · \(amount.currencyText)" }
}

private struct SetupExpenseDraft: Identifiable {
    let id = UUID()
    var category: ExpenseCategory = .needs {
        didSet {
            if oldValue != category {
                expenseName = ""
            }
        }
    }
    var expenseName = ""
    var name = ""
    var amount = 0.0
    var day = 1
    var repeatsEveryMonth = true

    var hasRequiredValues: Bool { !expenseName.isEmpty && amount > 0 }
    var listText: String {
        let title = name.isEmpty ? expenseName : name
        let recurrenceText = repeatsEveryMonth ? "todos os meses" : "só este mês"
        return "\(title) · \(amount.currencyText) · dia \(day) · \(recurrenceText) · \(category.title)"
    }
}

private struct SetupCategoryTotal: Identifiable {
    let category: ExpenseCategory
    let amount: Double

    var id: String { category.rawValue }
}

#Preview {
    InitialSetupWizardView {}
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, RecurrenceExclusion.self], inMemory: true)
}
