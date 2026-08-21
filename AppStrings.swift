//
//  AppStrings.swift
//  MoneyControl
//

import Foundation

enum AppLanguage {
    case portuguese
    case english

    var localeIdentifier: String {
        switch self {
        case .portuguese:
            "pt_PT"
        case .english:
            "en_US"
        }
    }
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
    case add
    case currentAccount
    case credits
    case management
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
    case recurrenceSettingsOnlyMessage
    case recurringIncomeSettingsOnlyMessage
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
    case fillFreeText
    case newPrefix
    case editPrefix
    case newExpense
    case editExpense
    case newSavingExpense
    case newCreditPaymentExpense
    case newIncome
    case editIncome
    case newMonthlyExpense
    case editMonthlyExpense
    case newPeriodicExpense
    case editPeriodicExpense
    case newSalary
    case editSalary
    case everyMonth
    case periodicity
    case monthlyRecurrence
    case quarterlyRecurrence
    case semiannualRecurrence
    case annualRecurrence
    case recurringExpenses
    case recurringIncome
    case recurringExpensesDescription
    case recurringIncomeDescription
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
    case pastMonthsUnpaidExpensesMessagePrefix
    case overdueExpenseDueDay
    case balanceThisMonthHelp
    case monthUnpaidHelp
    case monthRemainingHelp
    case monthRemainingHelpNote
    case pay
    case paid
    case notPaid
    case paidExpense
    case unpaidExpense
    case paidToggleHelpTitle
    case paidToggleHelpMessage
    case paidAmount
    case ofAmount
    case amountToPay
    case total
    case payFullAmount
    case futurePaymentTitle
    case futurePaymentMessage
    case monthAnalysis
    case whereSpent
    case budgetRule
    case annualBalance
    case actualExpenses
    case reference503020
    case appSettings
    case applicationSection
    case preferences
    case preferencesSubtitle
    case dataPrivacy
    case dataPrivacySubtitle
    case aboutSpendWise
    case aboutSpendWiseSubtitle
    case appVersion
    case appDataPrivacyNote
    case appSecurityTitle
    case appSecurityMessage
    case aboutSpendWisePurposeTitle
    case aboutSpendWisePurposeMessage
    case linkedTrackingOptionalHelpTitle
    case linkedTrackingOptionalHelpMessage
    case budgetSettings
    case managementIntro
    case managementBudgetDescription
    case managementSavingsDescription
    case managementCreditsDescription
    case monthlyFixedExpensesInfo
    case salaryHelp
    case monthlyExpenseHelp
    case periodicExpenseHelp
    case deleteAllData
    case deleteAllDataTitle
    case deleteAllDataMessage
    case exportBackup
    case importBackup
    case backupInfoTitle
    case exportBackupHelp
    case importBackupHelp
    case exportBackupSuccessTitle
    case exportBackupSuccessMessage
    case exportBackupFailureTitle
    case importBackupConfirmationTitle
    case importBackupConfirmationMessage
    case importBackupSuccessTitle
    case importBackupSuccessMessage
    case importBackupFailureTitle
    case importBackupFailureMessage
    case confirm
    case clear
    case category503020
    case rule503020Title
    case rule503020Help
    case incomeNameRequired
    case incomeValueRequired
    case expenseValueRequired
    case addIncomeToContinue
    case onlyThisMonth
    case setupExpensesTitle
    case setupExpensesSubtitle
    case setupExpenseCardTitle
    case optionalFreeText
    case dayOfMonth
    case addExpense
    case addedExpenses
    case noAddedExpenses
    case setupExpensesNote
    case setupProgressTitle
    case setupWelcomeTitle
    case setupWelcomeSubtitle
    case setupIncomeCardTitle
    case incomeNamePrompt
    case addIncome
    case addedIncomes
    case noAddedIncomes
    case setupIncomeNote
    case setupSummaryTitle
    case setupSummarySubtitle
    case receives
    case fixedExpenses
    case setupAvailableThisMonth
    case visualSummary
    case automaticAnalysis
    case setupFinalNote
    case back
    case next
    case startUsingSpendWise
    case budgetAnalysisNoIncome
    case budgetAnalysisNeedsHigh
    case budgetAnalysisSavingsLow
    case budgetAnalysisExcellent
    case budgetAnalysisHealthy
    case chartIncome
    case chartExpenses
    case chartBalance
    case budgetStatusNoData
    case budgetStatusExceeded
    case budgetStatusNeedsExceeded
    case budgetStatusWantsExceeded
    case budgetStatusNoSavings
    case budgetStatusSavingsBelowGoal
    case budgetStatusUnpaidExpenses
    case budgetStatusHealthy
    case budgetStatusDetailsTitle
    case budgetStatusDetailConsumedTitle
    case budgetStatusDetailConsumedMessage
    case budgetStatusDetailAvailableTitle
    case budgetStatusDetailAvailableMessage
    case budgetStatusDetailHealthyExplanation
    case budgetStatusDetailExceededExplanation
    case subscriptionsThisMonth
    case yearSavings
    case incomeVsExpenses
    case paidInsights
    case creditAnalysis
    case savingsAnalysis
    case noInsights
    case restaurantsIncreasedInsight
    case groceriesDecreasedInsight
    case savingsIncreasedInsight
    case subscriptionsIncomeInsight
    case creditPayoffInsight
    case creditExtraPaymentInsight
    case creditEstimateHelpTitle
    case creditEstimateHelpMessage
    case smallestCreditInsight
    case largestCreditInsight
    case totalDebtDecreasedInsight
    case totalDebtIncreasedInsight
    case creditNearPayoffInsight
    case totalCreditPayoffPlanInsight
    case creditSettledInsight
    case creditSettledRedirectInsight
    case debtFreeSavingsInsight
    case savingNearTargetInsight
    case savingTargetReachedInsight
    case closestSavingTargetInsight
    case totalSavingsIncreasedInsight
    case noSavingMovementInsight
    case positiveRemainingSavingSuggestionInsight
    case balancedSurplusSplitInsight
    case savingsAndDebtRuleMetInsight
    case balancedBudgetSurplusInsight
    case durationMonthSingular
    case durationMonthPlural
    case durationYearSingular
    case durationYearPlural
    case durationAnd
    case netWorth
    case accountBalance
    case savingsTotal
    case creditsDebt
    case noListData
    case savingsHistoryTitle
    case currentAccountSavingSource
    case initialSavingAmount
    case directSavingMovement
    case currency
    case deviceRegionCurrency
    case currencyFormatHelp
    case filters
    case clearFilters
    case paymentStatus
    case all
    case paidPlural
    case unpaidPlural
    case categories
    case expenseTypeFilter
    case freeTextFilter
    case searchPlaceholder
    case expenseDueTomorrowTitle
    case expenseDueTomorrowBody
    case expenseDueTomorrowBodyWithType
    case paymentHistory
    case totalPaid
    case deletePaymentHistoryTitle
    case deletePaymentHistoryMessage
    case overpaymentTitle
    case overpaymentMessage
    case valueBelowPaidTitle
    case valueBelowPaidMessage
}

enum AppStrings {
    static var currentLanguage: AppLanguage {
        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferredLanguage.hasPrefix("pt") ? .portuguese : .english
    }

    static var currentLocaleIdentifier: String {
        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
        if preferredLanguage.hasPrefix("pt-br") {
            return "pt_BR"
        }
        if preferredLanguage.hasPrefix("pt") {
            return "pt_PT"
        }
        return "en_US"
    }

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
            .add: "Adicionar",
            .currentAccount: "Conta Corrente",
            .credits: "Análises",
            .management: "Gestão",
            .monthlyExpense: "Despesa Recorrente",
            .periodicExpense: "Despesa Anual",
            .salary: "Rendimento Recorrente",
            .monthlyExpensesList: "Despesas recorrentes",
            .periodicExpensesList: "Despesas anuais",
            .salariesList: "Rendimentos recorrentes",
            .noMonthlyExpenses: "Sem despesas mensais",
            .noPeriodicExpenses: "Sem despesas periódicas",
            .noSalaries: "Sem vencimentos",
            .classification: "Classificação",
            .expenseType: "Tipo de Despesa",
            .select: "Selecionar",
            .details: "Detalhes",
            .recurrence: "Recorrência",
            .recurrenceSettingsOnlyMessage: "Está a editar apenas o registo deste mês. Para alterar todos os meses desta despesa recorrente, utilize a opção Gestão.",
            .recurringIncomeSettingsOnlyMessage: "Está a editar apenas o registo deste mês. Para alterar todos os meses deste rendimento recorrente, utilize a opção Gestão.",
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
            .selectExpenseType: "Seleciona a categoria da despesa 50/30/20.",
            .selectExpenseName: "Seleciona o tipo de despesa.",
            .fillName: "Preenche o nome.",
            .fillFreeText: "Preenche o texto livre.",
            .newPrefix: "Novo",
            .editPrefix: "Editar",
            .newExpense: "Nova Despesa",
            .editExpense: "Editar Despesa",
            .newSavingExpense: "Nova poupança",
            .newCreditPaymentExpense: "Pagamento de crédito",
            .newIncome: "Nova Receita",
            .editIncome: "Editar Receita",
            .newMonthlyExpense: "Nova Despesa Recorrente",
            .editMonthlyExpense: "Editar Despesa Recorrente",
            .newPeriodicExpense: "Nova Despesa Anual",
            .editPeriodicExpense: "Editar Despesa Anual",
            .newSalary: "Novo Rendimento Recorrente",
            .editSalary: "Editar Rendimento Recorrente",
            .everyMonth: "todos os meses",
            .periodicity: "Periodicidade",
            .monthlyRecurrence: "Mensal",
            .quarterlyRecurrence: "Trimestral",
            .semiannualRecurrence: "Semestral",
            .annualRecurrence: "Anual",
            .recurringExpenses: "Despesas",
            .recurringIncome: "Rendimentos",
            .recurringExpensesDescription: "Despesas que se repetem no orçamento.",
            .recurringIncomeDescription: "Rendimentos que se repetem no orçamento.",
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
            .pastMonthsUnpaidExpensesMessagePrefix: "Existem despesas por pagar em meses anteriores:",
            .overdueExpenseDueDay: "devia ter sido paga no dia",
            .balanceThisMonthHelp: "Mostra o saldo disponível até ao dia de hoje. Soma todos os vencimentos e receitas recebidos até hoje e subtrai apenas as despesas até hoje que já foram marcadas como pagas.",
            .monthUnpaidHelp: "Mostra o total das despesas do mês apresentado que ainda não foram marcadas como pagas.",
            .monthRemainingHelp: "Mostra o valor restante do mês apresentado. É calculado somando todos os vencimentos e receitas desse mês e subtraindo todas as despesas previstas para o mesmo período.",
            .monthRemainingHelpNote: "Nota: este valor é apenas referente a este mês e não reflete diferenças deixadas nos meses passados.",
            .pay: "Pagar",
            .paid: "Pago",
            .notPaid: "Por pagar",
            .paidExpense: "Paga",
            .unpaidExpense: "Por pagar",
            .paidToggleHelpTitle: "Estado do pagamento",
            .paidToggleHelpMessage: "Pode criar a despesa como por pagar ou marcá-la logo como paga. Ao escolher paga, o pagamento total é registado imediatamente e o saldo disponível da Conta Corrente é atualizado.",
            .paidAmount: "Valor pago",
            .ofAmount: "de",
            .amountToPay: "Valor a pagar",
            .total: "Total",
            .payFullAmount: "Pagar totalidade",
            .futurePaymentTitle: "Pagamento futuro",
            .futurePaymentMessage: "Está a registar um pagamento de %@ para uma despesa marcada para %@.",
            .monthAnalysis: "Análise do Mês",
            .whereSpent: "Onde gastou",
            .budgetRule: "50 / 30 / 20",
            .annualBalance: "Balanço do ano",
            .actualExpenses: "Real",
            .reference503020: "Referência",
            .appSettings: "App",
            .applicationSection: "Aplicação",
            .preferences: "Preferências",
            .preferencesSubtitle: "Moeda, idioma, tema e mais",
            .dataPrivacy: "Dados e privacidade",
            .dataPrivacySubtitle: "Exportar, importar e segurança",
            .aboutSpendWise: "Sobre a SpendWise",
            .aboutSpendWiseSubtitle: "Versão da aplicação e suporte",
            .appVersion: "Versão da aplicação",
            .appDataPrivacyNote: "Os seus dados ficam guardados apenas neste dispositivo, exceto quando exporta um backup manualmente.",
            .appSecurityTitle: "Segurança dos dados",
            .appSecurityMessage: "A SpendWise não se liga a servidores externos, não cria contas e não envia os seus dados para terceiros. Toda a informação registada fica no dispositivo. Os backups são ficheiros criados manualmente por si e só são partilhados se escolher guardar ou enviar esse ficheiro.",
            .aboutSpendWisePurposeTitle: "Para que serve a SpendWise",
            .aboutSpendWisePurposeMessage: "A SpendWise ajuda a acompanhar o dinheiro disponível, despesas, rendimentos, poupanças e créditos num só lugar. O objetivo é dar uma visão simples do mês, apoiar a regra 50/30/20 e ajudar a tomar decisões financeiras com mais clareza, sem funcionar como banco ou simulador financeiro. As notas informativas apresentadas na app são apenas orientações gerais. A SpendWise não se responsabiliza pelas decisões tomadas pelo utilizador; qualquer decisão financeira deve ser tomada de forma consciente e com base na sua própria situação.",
            .linkedTrackingOptionalHelpTitle: "Ligação opcional",
            .linkedTrackingOptionalHelpMessage: "Esta seleção é facultativa. Se escolher uma poupança ou crédito, o movimento continua a entrar normalmente na Conta Corrente e também será refletido nessa área para manter o histórico atualizado.",
            .budgetSettings: "Recorrentes",
            .managementIntro: "Organize e planeie as suas finanças",
            .managementBudgetDescription: "Despesas e rendimentos recorrentes",
            .managementSavingsDescription: "Objetivos e progresso das suas poupanças",
            .managementCreditsDescription: "Dívidas, pagamentos e saldo em aberto",
            .monthlyFixedExpensesInfo: "Tem um total de %@ de despesas fixas mensais.",
            .salaryHelp: "Permite adicionar rendimentos recorrentes com periodicidade mensal, trimestral, semestral ou anual, como salário, pensão, freelance ou outros rendimentos.",
            .monthlyExpenseHelp: "Permite adicionar despesas recorrentes com periodicidade mensal, trimestral, semestral ou anual. Aparecem automaticamente na Conta Corrente quando chegam ao mês correspondente.",
            .periodicExpenseHelp: "Permite adicionar uma despesa que acontece uma vez por ano num mês específico, como seguros, impostos ou pagamentos anuais.",
            .deleteAllData: "Apagar todos os dados",
            .deleteAllDataTitle: "Apagar todos os dados?",
            .deleteAllDataMessage: "Esta ação vai apagar todas as despesas, receitas, vencimentos, pagamentos, histórico de pagamentos, exceções, créditos e movimentos de crédito guardados na app. Não é possível anular.",
            .exportBackup: "Exportar backup",
            .importBackup: "Importar backup",
            .backupInfoTitle: "Backup",
            .exportBackupHelp: "Cria um ficheiro JSON apenas com os dados registados pelo utilizador: vencimentos, despesas, pagamentos, exceções, créditos e movimentos de crédito. Depois pode guardar esse ficheiro no iCloud Drive, Ficheiros, AirDrop ou outro local à sua escolha.",
            .importBackupHelp: "Permite escolher um ficheiro JSON exportado anteriormente pela SpendWise. Após confirmação, os dados registados atuais são substituídos pelos dados do backup.",
            .exportBackupSuccessTitle: "Backup criado",
            .exportBackupSuccessMessage: "O ficheiro de backup foi criado. Escolha onde pretende guardar ou partilhar o ficheiro.",
            .exportBackupFailureTitle: "Não foi possível exportar o backup",
            .importBackupConfirmationTitle: "Importar backup?",
            .importBackupConfirmationMessage: "Esta ação vai substituir todos os dados atuais pelos dados do backup selecionado. Deseja continuar?",
            .importBackupSuccessTitle: "Backup importado",
            .importBackupSuccessMessage: "Os dados do backup foram importados com sucesso.",
            .importBackupFailureTitle: "Não foi possível importar o backup",
            .importBackupFailureMessage: "O ficheiro selecionado não é um backup válido da SpendWise.",
            .confirm: "Confirmar",
            .clear: "Limpar",
            .category503020: "Categoria 50/30/20",
            .rule503020Title: "Regra 50/30/20",
            .rule503020Help: "A metodologia 50/30/20 ajuda a distribuir o rendimento de forma equilibrada: 50% para necessidades, 30% para desejos e 20% para poupança. Não é uma regra obrigatória, mas uma referência para uma melhor gestão financeira.",
            .incomeNameRequired: "Indique o nome do rendimento.",
            .incomeValueRequired: "Indique o valor do rendimento.",
            .expenseValueRequired: "Indique o valor da despesa.",
            .addIncomeToContinue: "Adicione pelo menos um rendimento para continuar.",
            .onlyThisMonth: "só este mês",
            .setupExpensesTitle: "Despesas mensais",
            .setupExpensesSubtitle: "Quais destas despesas paga todos os meses?",
            .setupExpenseCardTitle: "Despesa",
            .optionalFreeText: "Texto livre opcional",
            .dayOfMonth: "Dia do mês",
            .addExpense: "Adicionar despesa",
            .addedExpenses: "Despesas adicionadas",
            .noAddedExpenses: "Ainda não adicionou despesas.",
            .setupExpensesNote: "Pode sempre adicionar novas despesas ou alterar despesas mensais e periódicas mais tarde.",
            .setupProgressTitle: "Configuração inicial",
            .setupWelcomeTitle: "Bem-vindo!",
            .setupWelcomeSubtitle: "Vamos configurar o seu orçamento. Isto demora menos de 2 minutos.",
            .setupIncomeCardTitle: "Rendimentos mensais",
            .incomeNamePrompt: " ... Nome do rendimento",
            .addIncome: "Adicionar rendimento",
            .addedIncomes: "Rendimentos adicionados",
            .noAddedIncomes: "Ainda não adicionou rendimentos.",
            .setupIncomeNote: "Pode sempre adicionar novos rendimentos ou alterar os existentes mais tarde.",
            .setupSummaryTitle: "O seu orçamento está pronto.",
            .setupSummarySubtitle: "Revê o resumo inicial antes de começar a utilizar a SpendWise.",
            .receives: "Recebe",
            .fixedExpenses: "Despesas fixas",
            .setupAvailableThisMonth: "Pode gastar este mês",
            .visualSummary: "Resumo visual",
            .automaticAnalysis: "Análise automática",
            .setupFinalNote: "Este é apenas o ponto de partida. Continue a registar os seus movimentos e acompanhe a evolução do seu orçamento todos os meses.",
            .back: "Voltar",
            .next: "Seguinte",
            .startUsingSpendWise: "Começar a utilizar a\nSpendWise",
            .budgetAnalysisNoIncome: "Adicione os seus rendimentos para obter uma análise inicial do orçamento.",
            .budgetAnalysisNeedsHigh: "Está acima do recomendado em Necessidades. Pode acompanhar esta área com mais atenção nos próximos meses.",
            .budgetAnalysisSavingsLow: "Ainda pode aumentar a sua poupança para se aproximar da regra 50/30/20.",
            .budgetAnalysisExcellent: "Excelente equilíbrio financeiro. Está dentro do orçamento recomendado.",
            .budgetAnalysisHealthy: "Está dentro de um ponto de partida saudável para acompanhar e ajustar o orçamento todos os meses.",
            .chartIncome: "Rendimentos",
            .chartExpenses: "Despesas",
            .chartBalance: "Saldo",
            .budgetStatusNoData: "👋 Bem-vindo! Adicione os seus rendimentos e despesas para começar a acompanhar o seu orçamento.",
            .budgetStatusExceeded: "🚨 Já ultrapassou o orçamento disponível para este mês. Reveja as suas despesas para recuperar o equilíbrio.",
            .budgetStatusNeedsExceeded: "⚠️ As despesas essenciais ultrapassaram o limite recomendado de 50% do rendimento.",
            .budgetStatusWantsExceeded: "⚠️ Os gastos em lazer e despesas pessoais ultrapassaram o orçamento recomendado.",
            .budgetStatusNoSavings: "💰 Ainda não registou qualquer poupança este mês. Mesmo um pequeno valor faz diferença.",
            .budgetStatusSavingsBelowGoal: "🌱 Ainda não atingiu o objetivo de poupança recomendado para este mês.",
            .budgetStatusUnpaidExpenses: "🧾 Ainda tem despesas por liquidar este mês.",
            .budgetStatusHealthy: "✅ Excelente! Está dentro do orçamento e a gerir bem as suas finanças.",
            .budgetStatusDetailsTitle: "Estado do orçamento",
            .budgetStatusDetailConsumedTitle: "Orçamento consumido",
            .budgetStatusDetailConsumedMessage: "Já utilizou %@ do orçamento disponível para este mês.",
            .budgetStatusDetailAvailableTitle: "Ainda disponível",
            .budgetStatusDetailAvailableMessage: "Tem %@ do orçamento por utilizar.",
            .budgetStatusDetailHealthyExplanation: "Mantendo este ritmo, continua dentro do orçamento recomendado.",
            .budgetStatusDetailExceededExplanation: "Está acima do orçamento recomendado. Considere reduzir despesas nas categorias com maior impacto.",
            .subscriptionsThisMonth: "Subscrições do mês",
            .yearSavings: "Poupanças do ano",
            .incomeVsExpenses: "Receitas vs Despesas",
            .paidInsights: "Análises de pagamentos",
            .creditAnalysis: "Análise de Créditos",
            .savingsAnalysis: "Análise de Poupanças",
            .noInsights: "Ainda não existem pagamentos suficientes em meses anteriores para criar comparações.",
            .restaurantsIncreasedInsight: "💡 Este mês gastou %@ mais em Restaurantes do que no mês passado.",
            .groceriesDecreasedInsight: "🛒 As compras de supermercado diminuíram %@.",
            .savingsIncreasedInsight: "🎉 Conseguiu poupar %@ mais do que no mês anterior.",
            .subscriptionsIncomeInsight: "⚠️ As despesas com subscrições representam %@ do seu rendimento.",
            .creditPayoffInsight: "💳 Ao ritmo atual de %@/mês, poderá liquidar %@ em aproximadamente %@.",
            .creditExtraPaymentInsight: "💡 Prevê-se que sobrem %@ este mês. Se utilizar %@ (25%%) para reduzir %@, mantém %@ de margem no orçamento.",
            .creditEstimateHelpTitle: "Estimativa de créditos",
            .creditEstimateHelpMessage: "Estimativa baseada no saldo e nos pagamentos registados na SpendWise. Não considera juros, comissões ou alterações futuras.",
            .smallestCreditInsight: "🎯 %@ é atualmente a sua dívida mais pequena, com %@ por liquidar. Pode ser um bom objetivo para eliminar primeiro.",
            .largestCreditInsight: "💳 %@ representa a sua maior dívida atual: %@ de um total de %@ em créditos.",
            .totalDebtDecreasedInsight: "📉 Boa evolução! A sua dívida total diminuiu %@ desde o mês passado.",
            .totalDebtIncreasedInsight: "⚠️ A sua dívida total aumentou %@ este mês. Vale a pena verificar quais os créditos responsáveis pelo aumento.",
            .creditNearPayoffInsight: "🏁 Está perto! Mantendo pagamentos de cerca de %@/mês, poderá terminar %@ em aproximadamente %@.",
            .totalCreditPayoffPlanInsight: "🧭 A sua dívida total é %@. Com pagamentos de %@/mês, a estimativa para liquidar tudo é de aproximadamente %@.",
            .creditSettledInsight: "🎉 Parabéns! Liquidou %@. Pode agora redirecionar os %@/mês que pagava para poupança ou para outro crédito.",
            .creditSettledRedirectInsight: "🔄 Agora que %@ está liquidado, aplicar os seus %@/mês a %@ pode acelerar a redução da dívida seguinte.",
            .debtFreeSavingsInsight: "🥳 Está sem créditos registados! Se mantiver os %@/mês que utilizava nos pagamentos e os direcionar para poupança, poderá acumular %@ num ano.",
            .savingNearTargetInsight: "🎯 Está quase! Faltam apenas %@ para atingir o objetivo %@.",
            .savingTargetReachedInsight: "🎉 Objetivo alcançado! A poupança %@ chegou aos %@ definidos.",
            .closestSavingTargetInsight: "🌱 %@ é o seu objetivo mais próximo: já atingiu %@ da meta.",
            .totalSavingsIncreasedInsight: "💰 Este mês colocou mais %@ nas suas poupanças do que no mês anterior. Continue assim!",
            .noSavingMovementInsight: "🐷 Ainda não reforçou as suas poupanças este mês. Reservar %@ do valor disponível permitiria começar sem comprometer o orçamento.",
            .positiveRemainingSavingSuggestionInsight: "💡 Prevê-se que sobrem %@ este mês. Pode considerar reservar %@ (25%%) para poupança e manter o restante disponível.",
            .balancedSurplusSplitInsight: "⚖️ Prevê-se que sobrem %@. Uma opção equilibrada seria direcionar %@ para poupança e %@ para reduzir créditos, mantendo uma margem disponível.",
            .savingsAndDebtRuleMetInsight: "🌟 Já destinou %@ do rendimento a Poupanças e Pagamentos este mês, atingindo a referência de 20%% da regra 50/30/20.",
            .balancedBudgetSurplusInsight: "✨ O orçamento está equilibrado e ainda prevê %@ disponíveis. Pode usar parte desse valor para reforçar uma poupança ou reduzir um crédito.",
            .durationMonthSingular: "mês",
            .durationMonthPlural: "meses",
            .durationYearSingular: "ano",
            .durationYearPlural: "anos",
            .durationAnd: "e",
            .netWorth: "Visão global",
            .accountBalance: "Saldo da conta corrente",
            .savingsTotal: "Total em poupanças",
            .creditsDebt: "Total em créditos",
            .noListData: "Ainda não existem dados para mostrar.",
            .savingsHistoryTitle: "Origem das poupanças",
            .currentAccountSavingSource: "Conta Corrente",
            .initialSavingAmount: "Valor inicial da poupança",
            .directSavingMovement: "Movimento direto na poupança",
            .currency: "Moeda",
            .deviceRegionCurrency: "Moeda da região do dispositivo",
            .currencyFormatHelp: "A app usa por defeito a moeda da região do dispositivo. Pode escolher outra moeda; o símbolo muda para a moeda escolhida e os separadores decimais continuam a seguir a região do dispositivo.",
            .filters: "Filtros",
            .clearFilters: "Limpar filtros",
            .paymentStatus: "Estado de pagamento",
            .all: "Todos",
            .paidPlural: "Pagas",
            .unpaidPlural: "Por pagar",
            .categories: "Categorias",
            .expenseTypeFilter: "Tipo de despesa",
            .freeTextFilter: "Texto livre",
            .searchPlaceholder: "Procurar texto",
            .expenseDueTomorrowTitle: "Despesa vence amanhã",
            .expenseDueTomorrowBody: "%@ vence amanhã. Dia %d.",
            .expenseDueTomorrowBodyWithType: "%@ vence amanhã. Dia %d. Tipo: %@.",
            .paymentHistory: "Histórico de pagamentos",
            .totalPaid: "Total pago",
            .deletePaymentHistoryTitle: "Apagar pagamento?",
            .deletePaymentHistoryMessage: "O registo do histórico e o valor pago correspondente vão ser removidos desta despesa.",
            .overpaymentTitle: "Valor superior à dívida",
            .overpaymentMessage: "O valor que está a pagar é superior ao valor em dívida. Se continuar, o total da despesa sobe para refletir o pagamento total registado.",
            .valueBelowPaidTitle: "Valor inferior ao já pago",
            .valueBelowPaidMessage: "Esta despesa já tem pagamentos registados superiores ao novo valor. Se continuar, o valor da despesa será ajustado para o total já pago."
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
            .add: "Add",
            .currentAccount: "Current Account",
            .credits: "Analytics",
            .management: "Management",
            .monthlyExpense: "Recurring Expenses (Month)",
            .periodicExpense: "Single-Month Expense (Annual)",
            .salary: "Monthly Salaries",
            .monthlyExpensesList: "Recurring expenses list",
            .periodicExpensesList: "Single-month expenses list (annual)",
            .salariesList: "Monthly salaries list",
            .noMonthlyExpenses: "No monthly expenses",
            .noPeriodicExpenses: "No periodic expenses",
            .noSalaries: "No salaries",
            .classification: "Classification",
            .expenseType: "Expense type",
            .select: "Select",
            .details: "Details",
            .recurrence: "Recurrence",
            .recurrenceSettingsOnlyMessage: "You are editing only this month's record. To change every month of this recurring expense, use Management.",
            .recurringIncomeSettingsOnlyMessage: "You are editing only this month's record. To change every month of this recurring income, use Management.",
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
            .selectExpenseType: "Select the 50/30/20 expense category.",
            .selectExpenseName: "Select the expense type.",
            .fillName: "Fill in the name.",
            .fillFreeText: "Fill in the free text.",
            .newPrefix: "New",
            .editPrefix: "Edit",
            .newExpense: "New Expense",
            .editExpense: "Edit Expense",
            .newSavingExpense: "New saving",
            .newCreditPaymentExpense: "Credit payment",
            .newIncome: "New Income",
            .editIncome: "Edit Income",
            .newMonthlyExpense: "New Recurring Expense",
            .editMonthlyExpense: "Edit Recurring Expense",
            .newPeriodicExpense: "New Annual Expense",
            .editPeriodicExpense: "Edit Annual Expense",
            .newSalary: "New Recurring Income",
            .editSalary: "Edit Recurring Income",
            .everyMonth: "every month",
            .periodicity: "Frequency",
            .monthlyRecurrence: "Monthly",
            .quarterlyRecurrence: "Quarterly",
            .semiannualRecurrence: "Semiannual",
            .annualRecurrence: "Annual",
            .recurringExpenses: "Expenses",
            .recurringIncome: "Income",
            .recurringExpensesDescription: "Expenses that repeat in the budget.",
            .recurringIncomeDescription: "Income that repeats in the budget.",
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
            .pastMonthsUnpaidExpensesMessagePrefix: "There are unpaid expenses from previous months:",
            .overdueExpenseDueDay: "should have been paid on day",
            .balanceThisMonthHelp: "Shows the available balance up to today. It sums all salaries and income received up to today and subtracts only expenses up to today that have been marked as paid.",
            .monthUnpaidHelp: "Shows the total expenses in the displayed month that have not been marked as paid.",
            .monthRemainingHelp: "Shows the remaining amount for the displayed month. It is calculated by summing all salaries and income in that month and subtracting all expected expenses for the same period.",
            .monthRemainingHelpNote: "Note: this value only refers to this month and does not reflect differences left from previous months.",
            .pay: "Pay",
            .paid: "Paid",
            .notPaid: "To pay",
            .paidExpense: "Paid",
            .unpaidExpense: "To pay",
            .paidToggleHelpTitle: "Payment status",
            .paidToggleHelpMessage: "You can create the expense as unpaid or mark it as paid straight away. When paid is selected, the full payment is recorded immediately and the Current Account available balance is updated.",
            .paidAmount: "Paid amount",
            .ofAmount: "of",
            .amountToPay: "Amount to pay",
            .total: "Total",
            .payFullAmount: "Pay full amount",
            .futurePaymentTitle: "Future payment",
            .futurePaymentMessage: "You are recording a payment of %@ for an expense scheduled for %@.",
            .monthAnalysis: "Month Analysis",
            .whereSpent: "Where you spent",
            .budgetRule: "50 / 30 / 20",
            .annualBalance: "Year balance",
            .actualExpenses: "Actual",
            .reference503020: "Reference",
            .appSettings: "App",
            .applicationSection: "Application",
            .preferences: "Preferences",
            .preferencesSubtitle: "Currency, language, theme and more",
            .dataPrivacy: "Data and privacy",
            .dataPrivacySubtitle: "Export, import and security",
            .aboutSpendWise: "About SpendWise",
            .aboutSpendWiseSubtitle: "App version and support",
            .appVersion: "App version",
            .appDataPrivacyNote: "Your data stays stored only on this device, except when you manually export a backup.",
            .appSecurityTitle: "Data security",
            .appSecurityMessage: "SpendWise does not connect to external servers, does not create accounts and does not send your data to third parties. All registered information stays on the device. Backups are files created manually by you and are only shared if you choose to save or send that file.",
            .aboutSpendWisePurposeTitle: "What SpendWise is for",
            .aboutSpendWisePurposeMessage: "SpendWise helps you track available money, expenses, income, savings and credits in one place. Its purpose is to give a simple monthly overview, support the 50/30/20 rule and help you make clearer financial decisions, without acting as a bank or financial simulator. The informational notes shown in the app are general guidance only. SpendWise is not responsible for decisions made by the user; any financial decision should be made consciously and based on your own situation.",
            .linkedTrackingOptionalHelpTitle: "Optional link",
            .linkedTrackingOptionalHelpMessage: "This selection is optional. If you choose a saving or credit, the movement will still be added normally to the Current Account and will also be reflected in that area to keep its history updated.",
            .budgetSettings: "Recurring",
            .managementIntro: "Organize and plan your finances",
            .managementBudgetDescription: "Recurring expenses and income",
            .managementSavingsDescription: "Goals and progress for your savings",
            .managementCreditsDescription: "Debts, payments and outstanding balance",
            .monthlyFixedExpensesInfo: "You have a total of %@ in fixed monthly expenses.",
            .salaryHelp: "Adds recurring income with a monthly, quarterly, semiannual or annual frequency, such as salary, pension, freelance or other income.",
            .monthlyExpenseHelp: "Adds recurring expenses with a monthly, quarterly, semiannual or annual frequency. They appear automatically in Current Account when the matching month arrives.",
            .periodicExpenseHelp: "Adds an expense that happens once a year in a specific month, such as insurance, taxes or annual payments.",
            .deleteAllData: "Delete all data",
            .deleteAllDataTitle: "Delete all data?",
            .deleteAllDataMessage: "This will delete every expense, income, salary, payment, payment history, recurrence exception, credit and credit movement stored in the app. This cannot be undone.",
            .exportBackup: "Export backup",
            .importBackup: "Import backup",
            .backupInfoTitle: "Backup",
            .exportBackupHelp: "Creates a JSON file only with user-entered data: salaries, expenses, payments, recurrence exceptions, credits and credit movements. You can then save it to iCloud Drive, Files, AirDrop or another location.",
            .importBackupHelp: "Lets you choose a JSON file previously exported by SpendWise. After confirmation, current registered data is replaced with the backup data.",
            .exportBackupSuccessTitle: "Backup created",
            .exportBackupSuccessMessage: "The backup file was created. Choose where you want to save or share it.",
            .exportBackupFailureTitle: "Could not export backup",
            .importBackupConfirmationTitle: "Import backup?",
            .importBackupConfirmationMessage: "This will replace all current data with the selected backup data. Do you want to continue?",
            .importBackupSuccessTitle: "Backup imported",
            .importBackupSuccessMessage: "The backup data was imported successfully.",
            .importBackupFailureTitle: "Could not import backup",
            .importBackupFailureMessage: "The selected file is not a valid SpendWise backup.",
            .confirm: "Confirm",
            .clear: "Clear",
            .category503020: "50/30/20 Category",
            .rule503020Title: "50/30/20 Rule",
            .rule503020Help: "The 50/30/20 method helps distribute income in a balanced way: 50% for needs, 30% for wants and 20% for savings. It is not mandatory, but a reference for better financial management.",
            .incomeNameRequired: "Enter the income name.",
            .incomeValueRequired: "Enter the income amount.",
            .expenseValueRequired: "Enter the expense amount.",
            .addIncomeToContinue: "Add at least one income to continue.",
            .onlyThisMonth: "only this month",
            .setupExpensesTitle: "Monthly expenses",
            .setupExpensesSubtitle: "Which of these expenses do you pay every month?",
            .setupExpenseCardTitle: "Expense",
            .optionalFreeText: "Optional free text",
            .dayOfMonth: "Day of month",
            .addExpense: "Add expense",
            .addedExpenses: "Added expenses",
            .noAddedExpenses: "You have not added expenses yet.",
            .setupExpensesNote: "You can always add new expenses or change monthly and periodic expenses later.",
            .setupProgressTitle: "Initial setup",
            .setupWelcomeTitle: "Welcome!",
            .setupWelcomeSubtitle: "Let's set up your budget. This takes less than 2 minutes.",
            .setupIncomeCardTitle: "Monthly income",
            .incomeNamePrompt: " ... Income name",
            .addIncome: "Add income",
            .addedIncomes: "Added income",
            .noAddedIncomes: "You have not added income yet.",
            .setupIncomeNote: "You can always add new income or change existing income later.",
            .setupSummaryTitle: "Your budget is ready.",
            .setupSummarySubtitle: "Review the initial summary before you start using SpendWise.",
            .receives: "Receives",
            .fixedExpenses: "Fixed expenses",
            .setupAvailableThisMonth: "Available to spend this month",
            .visualSummary: "Visual summary",
            .automaticAnalysis: "Automatic analysis",
            .setupFinalNote: "This is only the starting point. Keep recording your movements and follow your budget evolution every month.",
            .back: "Back",
            .next: "Next",
            .startUsingSpendWise: "Start using\nSpendWise",
            .budgetAnalysisNoIncome: "Add your income to get an initial budget analysis.",
            .budgetAnalysisNeedsHigh: "You are above the recommended amount for Needs. You can monitor this area more closely over the next months.",
            .budgetAnalysisSavingsLow: "You can still increase your savings to get closer to the 50/30/20 rule.",
            .budgetAnalysisExcellent: "Excellent financial balance. You are within the recommended budget.",
            .budgetAnalysisHealthy: "This is a healthy starting point to monitor and adjust your budget every month.",
            .chartIncome: "Income",
            .chartExpenses: "Expenses",
            .chartBalance: "Balance",
            .budgetStatusNoData: "👋 Welcome! Add your income and expenses to start tracking your budget.",
            .budgetStatusExceeded: "🚨 You have exceeded the available budget for this month. Review your expenses to recover balance.",
            .budgetStatusNeedsExceeded: "⚠️ Essential expenses exceeded the recommended limit of 50% of income.",
            .budgetStatusWantsExceeded: "⚠️ Leisure and personal spending exceeded the recommended budget.",
            .budgetStatusNoSavings: "💰 You have not registered any savings this month. Even a small amount makes a difference.",
            .budgetStatusSavingsBelowGoal: "🌱 You have not yet reached the recommended savings goal for this month.",
            .budgetStatusUnpaidExpenses: "🧾 You still have expenses to settle this month.",
            .budgetStatusHealthy: "✅ Excellent! You are within budget and managing your finances well.",
            .budgetStatusDetailsTitle: "Budget status",
            .budgetStatusDetailConsumedTitle: "Budget consumed",
            .budgetStatusDetailConsumedMessage: "You have used %@ of the available budget for this month.",
            .budgetStatusDetailAvailableTitle: "Still available",
            .budgetStatusDetailAvailableMessage: "You have %@ of the budget left to use.",
            .budgetStatusDetailHealthyExplanation: "Keeping this rhythm, you remain within the recommended budget.",
            .budgetStatusDetailExceededExplanation: "You are above the recommended budget. Consider reducing expenses in the categories with the highest impact.",
            .subscriptionsThisMonth: "This month's subscriptions",
            .yearSavings: "Year savings",
            .incomeVsExpenses: "Income vs Expenses",
            .paidInsights: "Payment insights",
            .creditAnalysis: "Credit Analysis",
            .savingsAnalysis: "Savings Analysis",
            .noInsights: "There are not enough payments in previous months yet to create comparisons.",
            .restaurantsIncreasedInsight: "💡 This month you spent %@ more on Restaurants than last month.",
            .groceriesDecreasedInsight: "🛒 Supermarket spending decreased %@.",
            .savingsIncreasedInsight: "🎉 You managed to save %@ more than the previous month.",
            .subscriptionsIncomeInsight: "⚠️ Subscription expenses represent %@ of your income.",
            .creditPayoffInsight: "💳 At the current pace of %@/month, you could settle %@ in approximately %@.",
            .creditExtraPaymentInsight: "💡 You are expected to have %@ left this month. If you use %@ (25%%) to reduce %@, you keep %@ as budget margin.",
            .creditEstimateHelpTitle: "Credit estimate",
            .creditEstimateHelpMessage: "Estimate based on the balance and payments registered in SpendWise. It does not consider interest, fees or future changes.",
            .smallestCreditInsight: "🎯 %@ is currently your smallest debt, with %@ left to settle. It may be a good first target to eliminate.",
            .largestCreditInsight: "💳 %@ is your largest current debt: %@ out of a total of %@ in credits.",
            .totalDebtDecreasedInsight: "📉 Good progress! Your total debt decreased by %@ since last month.",
            .totalDebtIncreasedInsight: "⚠️ Your total debt increased by %@ this month. It is worth checking which credits caused the increase.",
            .creditNearPayoffInsight: "🏁 You are close! Keeping payments around %@/month, you could finish %@ in approximately %@.",
            .totalCreditPayoffPlanInsight: "🧭 Your total debt is %@. With payments of %@/month, the estimate to settle everything is approximately %@.",
            .creditSettledInsight: "🎉 Congratulations! You settled %@. You can now redirect the %@/month you were paying to savings or another credit.",
            .creditSettledRedirectInsight: "🔄 Now that %@ is settled, applying its %@/month to %@ can speed up the next debt reduction.",
            .debtFreeSavingsInsight: "🥳 You have no active credits registered! If you keep the %@/month you used for payments and direct it to savings, you could accumulate %@ in one year.",
            .savingNearTargetInsight: "🎯 You are close! Only %@ left to reach the %@ goal.",
            .savingTargetReachedInsight: "🎉 Goal reached! The %@ saving reached the defined %@.",
            .closestSavingTargetInsight: "🌱 %@ is your closest goal: you have already reached %@ of the target.",
            .totalSavingsIncreasedInsight: "💰 This month you added %@ more to your savings than last month. Keep going!",
            .noSavingMovementInsight: "🐷 You have not reinforced your savings this month yet. Reserving %@ from the available amount would let you start without compromising the budget.",
            .positiveRemainingSavingSuggestionInsight: "💡 You are expected to have %@ left this month. You may consider setting aside %@ (25%%) for savings and keeping the rest available.",
            .balancedSurplusSplitInsight: "⚖️ You are expected to have %@ left. A balanced option would be to direct %@ to savings and %@ to reduce credits, while keeping a margin available.",
            .savingsAndDebtRuleMetInsight: "🌟 You have already directed %@ of income to Savings and Payments this month, reaching the 20%% reference of the 50/30/20 rule.",
            .balancedBudgetSurplusInsight: "✨ The budget is balanced and still expects %@ available. You can use part of that amount to reinforce savings or reduce a credit.",
            .durationMonthSingular: "month",
            .durationMonthPlural: "months",
            .durationYearSingular: "year",
            .durationYearPlural: "years",
            .durationAnd: "and",
            .netWorth: "Overview",
            .accountBalance: "Current account balance",
            .savingsTotal: "Total savings",
            .creditsDebt: "Total credits",
            .noListData: "There is no data to show yet.",
            .savingsHistoryTitle: "Savings sources",
            .currentAccountSavingSource: "Current Account",
            .initialSavingAmount: "Initial saving amount",
            .directSavingMovement: "Direct saving movement",
            .currency: "Currency",
            .deviceRegionCurrency: "Device region currency",
            .currencyFormatHelp: "By default, the app uses the currency from the device region. You can choose another currency; the symbol changes to the selected currency and decimal separators continue to follow the device region.",
            .filters: "Filters",
            .clearFilters: "Clear filters",
            .paymentStatus: "Payment status",
            .all: "All",
            .paidPlural: "Paid",
            .unpaidPlural: "Unpaid",
            .categories: "Categories",
            .expenseTypeFilter: "Expense type",
            .freeTextFilter: "Free text",
            .searchPlaceholder: "Search text",
            .expenseDueTomorrowTitle: "Expense due tomorrow",
            .expenseDueTomorrowBody: "%@ is due tomorrow. Day %d.",
            .expenseDueTomorrowBodyWithType: "%@ is due tomorrow. Day %d. Type: %@.",
            .paymentHistory: "Payment history",
            .totalPaid: "Total paid",
            .deletePaymentHistoryTitle: "Delete payment?",
            .deletePaymentHistoryMessage: "The history entry and the corresponding paid amount will be removed from this expense.",
            .overpaymentTitle: "Amount above debt",
            .overpaymentMessage: "The amount you are paying is higher than the amount due. If you continue, the expense total will increase to reflect the total registered payment.",
            .valueBelowPaidTitle: "Value below amount already paid",
            .valueBelowPaidMessage: "This expense already has registered payments above the new value. If you continue, the expense value will be adjusted to the total already paid."
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
