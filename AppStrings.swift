//
//  AppStrings.swift
//  MoneyControl
//

import Foundation

enum AppLanguage {
    case portuguese
    case english
}

enum AppTextKey: String, CaseIterable {
    case appName
    case balanceThisMonth
    case monthUnpaid
    case monthRemaining
    case expense
    case income
    case noTransactions
    case noTransactionsDescription
    case cancel
    case delete
    case deleteConfirmation
    case name
    case settings
    case currentAccount
    case credits
    case monthlyExpense
    case periodicExpense
    case salary
    case monthlyExpensesList
    case periodicExpensesList
    case salariesList
    case noMonthlyExpenses
    case noPeriodicExpenses
    case noSalaries
    case classification
    case expenseType
    case select
    case details
    case recurrence
    case month
    case endDate
    case noEndDate
    case year
    case freeText
    case day
    case value
    case save
    case ok
    case fillValue
    case selectExpenseType
    case selectExpenseName
    case fillName
    case newPrefix
    case editPrefix
    case newExpense
    case editExpense
    case newIncome
    case newIncome2
    case editIncome
    case newMonthlyExpense
    case editMonthlyExpense
    case newPeriodicExpense
    case editPeriodicExpense
    case newSalary
    case editSalary
    case everyMonth
    case expenseLowercase
    case incomeLowercase
    case needsCategory
    case wantsCategory
    case savingsAndDebtCategory
    case futureEditTitle
    case futureEditMessage
    case futureDeleteTitle
    case futureDeleteMessage
    case continueAction
    case overdueExpensesTitle
    case overdueExpensesMessagePrefix
    case previousMonthUnpaidExpensesMessagePrefix
    case overdueExpenseDueDay
    case balanceThisMonthHelp
    case monthUnpaidHelp
    case monthRemainingHelp
    case pay
    case paidAmount
    case amountToPay
    case total
    case payFullAmount
    case monthAnalysis
    case whereSpent
    case budgetRule
    case annualBalance
    case actualExpenses
    case reference503020
    case appSettings
    case budgetSettings
    case showOnboardingAgain
    case deleteAllData
    case deleteAllDataTitle
    case deleteAllDataMessage
}

enum AppStrings {
    static var currentLanguage: AppLanguage = .portuguese

    static var analyticsAdviceCards: [(title: String, message: String)] {
        switch currentLanguage {
        case .portuguese:
            [
                ("Boas práticas", "💰 Poupe primeiro, gaste depois. Reserve uma parte do rendimento assim que o receber."),
                ("Boas práticas", "📊 Conhecer para onde vai o dinheiro é o primeiro passo para o controlar."),
                ("Boas práticas", "🎯 Um pequeno ajuste mensal pode fazer uma grande diferença ao fim de um ano."),
                ("Boas práticas", "📅 Reveja o seu orçamento pelo menos uma vez por semana."),
                ("Boas práticas", "💳 Evite compras por impulso. Espere 24 horas antes de decidir."),
                ("Metodologia 50/30/20", "🏠 Tente manter as Necessidades até 50% do rendimento."),
                ("Metodologia 50/30/20", "🎉 Os Desejos são importantes, mas idealmente não devem ultrapassar 30% do rendimento."),
                ("Metodologia 50/30/20", "🌱 Reserve cerca de 20% do rendimento para poupança ou amortização de dívidas."),
                ("Metodologia 50/30/20", "📈 A regra 50/30/20 é uma orientação. Adapte-a à sua realidade."),
                ("Metodologia 50/30/20", "⚖️ O equilíbrio é mais importante do que a perfeição."),
                ("Poupança", "🐷 Poupar um pouco todos os meses é melhor do que tentar poupar muito de uma só vez."),
                ("Poupança", "💸 Automatizar a poupança torna o hábito mais fácil."),
                ("Poupança", "🎯 Defina um objetivo concreto para a sua poupança."),
                ("Poupança", "🚗 Criar um fundo para despesas inesperadas reduz o stress financeiro."),
                ("Poupança", "📈 Mesmo pequenas poupanças crescem ao longo do tempo."),
                ("Despesas", "🛍️ Pergunte-se: \"Preciso mesmo desta compra?\""),
                ("Despesas", "📱 Reveja regularmente as suas subscrições. Pode estar a pagar por serviços que já não utiliza."),
                ("Despesas", "🛒 Faça uma lista antes de ir às compras para evitar gastos desnecessários."),
                ("Despesas", "🍽️ Preparar refeições em casa pode reduzir significativamente as despesas."),
                ("Despesas", "🚶 Pequenas despesas diárias também contam no orçamento mensal."),
                ("Acompanhamento", "📊 Compare os seus gastos com os meses anteriores para identificar tendências."),
                ("Acompanhamento", "📅 Registe as despesas o mais cedo possível para manter o orçamento atualizado."),
                ("Acompanhamento", "🔍 As categorias com maior despesa são as melhores candidatas para poupar."),
                ("Acompanhamento", "📉 Se ultrapassou o orçamento este mês, identifique a causa antes de definir o próximo."),
                ("Acompanhamento", "🎯 Celebrar pequenos progressos ajuda a manter a motivação."),
                ("Privacidade e motivação", "🔒 Os seus dados permanecem apenas no seu dispositivo."),
                ("Privacidade e motivação", "📱 Não precisa de criar uma conta para controlar o seu orçamento."),
                ("Privacidade e motivação", "🌟 Cada despesa registada aproxima-o de um melhor controlo financeiro."),
                ("Privacidade e motivação", "💡 O objetivo não é gastar menos, mas gastar de forma mais consciente."),
                ("Privacidade e motivação", "🚀 A melhor altura para organizar as finanças foi ontem. A segunda melhor é hoje.")
            ]
        case .english:
            [
                ("Best practices", "💰 Save first, spend after. Set aside part of your income as soon as you receive it."),
                ("Best practices", "📊 Knowing where your money goes is the first step to controlling it."),
                ("Best practices", "🎯 A small monthly adjustment can make a big difference over a year."),
                ("Best practices", "📅 Review your budget at least once a week."),
                ("Best practices", "💳 Avoid impulse purchases. Wait 24 hours before deciding."),
                ("50/30/20 Method", "🏠 Try to keep Needs up to 50% of income."),
                ("50/30/20 Method", "🎉 Wants matter, but ideally should not exceed 30% of income."),
                ("50/30/20 Method", "🌱 Reserve around 20% of income for savings or debt repayment."),
                ("50/30/20 Method", "📈 The 50/30/20 rule is guidance. Adapt it to your reality."),
                ("50/30/20 Method", "⚖️ Balance matters more than perfection."),
                ("Savings", "🐷 Saving a little every month is better than trying to save a lot at once."),
                ("Savings", "💸 Automating savings makes the habit easier."),
                ("Savings", "🎯 Set a concrete savings goal."),
                ("Savings", "🚗 An emergency fund reduces financial stress."),
                ("Savings", "📈 Even small savings grow over time."),
                ("Expenses", "🛍️ Ask yourself: \"Do I really need this purchase?\""),
                ("Expenses", "📱 Review subscriptions regularly. You may be paying for services you no longer use."),
                ("Expenses", "🛒 Make a list before shopping to avoid unnecessary spending."),
                ("Expenses", "🍽️ Preparing meals at home can significantly reduce expenses."),
                ("Expenses", "🚶 Small daily expenses also count in the monthly budget."),
                ("Tracking", "📊 Compare your spending with previous months to identify trends."),
                ("Tracking", "📅 Record expenses as early as possible to keep the budget updated."),
                ("Tracking", "🔍 The highest spending categories are the best candidates for savings."),
                ("Tracking", "📉 If you exceeded the budget this month, identify the cause before setting the next one."),
                ("Tracking", "🎯 Celebrating small progress helps keep motivation."),
                ("Privacy and motivation", "🔒 Your data stays only on your device."),
                ("Privacy and motivation", "📱 You do not need an account to control your budget."),
                ("Privacy and motivation", "🌟 Every recorded expense brings you closer to better financial control."),
                ("Privacy and motivation", "💡 The goal is not to spend less, but to spend more consciously."),
                ("Privacy and motivation", "🚀 The best time to organize finances was yesterday. The second best is today.")
            ]
        }
    }

    private static let textValues: [AppLanguage: [AppTextKey: String]] = [
        .portuguese: [
            .appName: "SpendWise",
            .balanceThisMonth: "Saldo disponível",
            .monthUnpaid: "Falta pagar este mês",
            .monthRemaining: "Pode gastar este mês",
            .expense: "Despesa",
            .income: "Receita",
            .noTransactions: "Sem movimentos",
            .noTransactionsDescription: "Adiciona despesas ou receitas deste mês.",
            .cancel: "Cancelar",
            .delete: "Apagar",
            .deleteConfirmation: "Tem a certeza que quer apagar?",
            .name: "Nome",
            .settings: "Configurações",
            .currentAccount: "Conta Corrente",
            .credits: "Análises",
            .monthlyExpense: "Despesas Mensais",
            .periodicExpense: "Despesa Periódica",
            .salary: "Vencimento",
            .monthlyExpensesList: "Lista de despesas mensais",
            .periodicExpensesList: "Lista de despesas periódicas",
            .salariesList: "Lista de vencimentos",
            .noMonthlyExpenses: "Sem despesas mensais",
            .noPeriodicExpenses: "Sem despesas periódicas",
            .noSalaries: "Sem vencimentos",
            .classification: "Classificação",
            .expenseType: "Tipo de Despesa",
            .select: "Selecionar",
            .details: "Detalhes",
            .recurrence: "Recorrência",
            .month: "Mês",
            .endDate: "Data fim",
            .noEndDate: "Sem data fim",
            .year: "Ano",
            .freeText: "Texto livre",
            .day: "Dia",
            .value: "Valor",
            .save: "Guardar",
            .ok: "OK",
            .fillValue: "Preenche o valor.",
            .selectExpenseType: "Seleciona o tipo de despesa.",
            .selectExpenseName: "Seleciona o nome da despesa.",
            .fillName: "Preenche o nome.",
            .newPrefix: "Novo",
            .editPrefix: "Editar",
            .newExpense: "Nova Despesa",
            .editExpense: "Editar Despesa",
            .newIncome: "Nova Receita",
            .newIncome2: "Podes adicionar aqui uma receita para o mês corrente.",
            .editIncome: "Editar Receita",
            .newMonthlyExpense: "Nova Despesa Mensal",
            .editMonthlyExpense: "Editar Despesa Mensal",
            .newPeriodicExpense: "Nova Despesa Periódica",
            .editPeriodicExpense: "Editar Despesa Periódica",
            .newSalary: "Novo Vencimento",
            .editSalary: "Editar Vencimento",
            .everyMonth: "todos os meses",
            .expenseLowercase: "despesa",
            .incomeLowercase: "receita",
            .needsCategory: "50% Necessidades",
            .wantsCategory: "30% Desejos",
            .savingsAndDebtCategory: "20% Pagamentos e Poupança",
            .futureEditTitle: "Editar meses seguintes",
            .futureEditMessage: "Esta alteração só vai afetar os meses seguintes. Para alterar o mês corrente, edita a despesa ou receita diretamente no mês.",
            .futureDeleteTitle: "Apagar meses seguintes",
            .futureDeleteMessage: "Esta ação só vai apagar os meses seguintes. Para apagar o mês corrente, apaga diretamente no mês.",
            .continueAction: "Continuar",
            .overdueExpensesTitle: "Despesas por pagar",
            .overdueExpensesMessagePrefix: "Existem despesas no mês corrente que já deviam estar pagas:",
            .previousMonthUnpaidExpensesMessagePrefix: "Ficaram despesas por pagar no mês passado:",
            .overdueExpenseDueDay: "devia ter sido paga no dia",
            .balanceThisMonthHelp: "Mostra o dinheiro na conta no dia de hoje. Soma todos os vencimentos e receitas até hoje e subtrai apenas as despesas até hoje que já foram marcadas como pagas.",
            .monthUnpaidHelp: "Mostra o total de despesas do mês apresentado que ainda não foram marcadas como pagas.",
            .monthRemainingHelp: "Mostra o remanescente do mês apresentado. É calculado somando todos os vencimentos e receitas desse mês e subtraindo todas as despesas desse mês.",
            .pay: "Pagar",
            .paidAmount: "Valor pago",
            .amountToPay: "Valor a pagar",
            .total: "Total",
            .payFullAmount: "Pagar totalidade",
            .monthAnalysis: "Análise do Mês",
            .whereSpent: "Onde gastou",
            .budgetRule: "50 / 30 / 20",
            .annualBalance: "Balanço do ano",
            .actualExpenses: "Real",
            .reference503020: "Referência",
            .appSettings: "App",
            .budgetSettings: "Orçamento",
            .showOnboardingAgain: "Ver onboarding novamente",
            .deleteAllData: "Apagar todos os dados",
            .deleteAllDataTitle: "Apagar todos os dados?",
            .deleteAllDataMessage: "Esta ação vai apagar todas as despesas, receitas, vencimentos, pagamentos e exceções guardadas na app. Não é possível anular."
        ],
        .english: [
            .appName: "SpendWise",
            .balanceThisMonth: "Available balance",
            .monthUnpaid: "Left to pay this month",
            .monthRemaining: "Still available this month",
            .expense: "Expense",
            .income: "Income",
            .noTransactions: "No transactions",
            .noTransactionsDescription: "Add expenses or income for this month.",
            .cancel: "Cancel",
            .delete: "Delete",
            .deleteConfirmation: "Are you sure you want to delete?",
            .name: "Name",
            .settings: "Settings",
            .currentAccount: "Current Account",
            .credits: "Analytics",
            .monthlyExpense: "Monthly Expenses",
            .periodicExpense: "Periodic Expense",
            .salary: "Salary",
            .monthlyExpensesList: "Monthly expenses list",
            .periodicExpensesList: "Periodic expenses list",
            .salariesList: "Salaries list",
            .noMonthlyExpenses: "No monthly expenses",
            .noPeriodicExpenses: "No periodic expenses",
            .noSalaries: "No salaries",
            .classification: "Classification",
            .expenseType: "Expense type",
            .select: "Select",
            .details: "Details",
            .recurrence: "Recurrence",
            .month: "Month",
            .endDate: "End date",
            .noEndDate: "No end date",
            .year: "Year",
            .freeText: "Free text",
            .day: "Day",
            .value: "Value",
            .save: "Save",
            .ok: "OK",
            .fillValue: "Fill in the value.",
            .selectExpenseType: "Select the expense type.",
            .selectExpenseName: "Select the expense name.",
            .fillName: "Fill in the name.",
            .newPrefix: "New",
            .editPrefix: "Edit",
            .newExpense: "New Expense",
            .editExpense: "Edit Expense",
            .newIncome: "New Income",
            .newIncome2: "newIncome2",
            .editIncome: "Edit Income",
            .newMonthlyExpense: "New Monthly Expense",
            .editMonthlyExpense: "Edit Monthly Expense",
            .newPeriodicExpense: "New Periodic Expense",
            .editPeriodicExpense: "Edit Periodic Expense",
            .newSalary: "New Salary",
            .editSalary: "Edit Salary",
            .everyMonth: "every month",
            .expenseLowercase: "expense",
            .incomeLowercase: "income",
            .needsCategory: "50% Needs",
            .wantsCategory: "30% Wants",
            .savingsAndDebtCategory: "20% Payments and Savings",
            .futureEditTitle: "Edit following months",
            .futureEditMessage: "This change will only affect following months. To change the current month, edit the expense or income directly in that month.",
            .futureDeleteTitle: "Delete following months",
            .futureDeleteMessage: "This action will only delete following months. To delete the current month, delete it directly in that month.",
            .continueAction: "Continue",
            .overdueExpensesTitle: "Expenses to pay",
            .overdueExpensesMessagePrefix: "There are expenses in the current month that should already be paid:",
            .previousMonthUnpaidExpensesMessagePrefix: "There are unpaid expenses from last month:",
            .overdueExpenseDueDay: "should have been paid on day",
            .balanceThisMonthHelp: "Shows the money in the account today. It sums all salaries and income up to today and subtracts only expenses up to today that have been marked as paid.",
            .monthUnpaidHelp: "Shows the total expenses in the displayed month that have not been marked as paid.",
            .monthRemainingHelp: "Shows the remaining amount for the displayed month. It sums all salaries and income in that month and subtracts all expenses in that month.",
            .pay: "Pay",
            .paidAmount: "Paid amount",
            .amountToPay: "Amount to pay",
            .total: "Total",
            .payFullAmount: "Pay full amount",
            .monthAnalysis: "Month Analysis",
            .whereSpent: "Where you spent",
            .budgetRule: "50 / 30 / 20",
            .annualBalance: "Year balance",
            .actualExpenses: "Actual",
            .reference503020: "Reference",
            .appSettings: "App",
            .budgetSettings: "Budget",
            .showOnboardingAgain: "Show onboarding again",
            .deleteAllData: "Delete all data",
            .deleteAllDataTitle: "Delete all data?",
            .deleteAllDataMessage: "This will delete every expense, income, salary, payment and recurrence exception stored in the app. This cannot be undone."
        ]
    ]

    private static let expenseNames: [AppLanguage: [ExpenseCategory: [String]]] = [
        .portuguese: [
            .needs: [
                "Habitação: renda ou prestação do crédito à habitação",
                "Transportes: transporte público, prestações e combustível",
                "Alimentação: compras de supermercado",
                "Contas de serviços essenciais: eletricidade, gás, água e telecomunicações",
                "Seguros: saúde, vida e automóvel essenciais",
                "Outros"
            ],
            .wants: [
                "Refeições fora de casa",
                "Subscrições mensais",
                "Atividades de lazer e entretenimento",
                "Viagens e férias",
                "Roupa e acessórios",
                "Outros"
            ],
            .savingsAndDebt: [
                "Poupança",
                "Amortização de dívidas",
                "Outros"
            ]
        ],
        .english: [
            .needs: [
                "Housing: rent or mortgage payment",
                "Transport: public transport, payments and fuel",
                "Food: supermarket groceries",
                "Essential bills: electricity, gas, water and telecommunications",
                "Insurance: essential health, life and car insurance",
                "Other"
            ],
            .wants: [
                "Eating out",
                "Monthly subscriptions",
                "Leisure and entertainment",
                "Travel and holidays",
                "Clothing and accessories",
                "Other"
            ],
            .savingsAndDebt: [
                "Savings",
                "Debt repayment",
                "Other"
            ]
        ]
    ]

    static func text(_ key: AppTextKey) -> String {
        textValues[currentLanguage]?[key] ?? textValues[.portuguese]?[key] ?? key.rawValue
    }

    static func expenseNames(for category: ExpenseCategory) -> [String] {
        expenseNames[currentLanguage]?[category] ?? expenseNames[.portuguese]?[category] ?? []
    }
}
