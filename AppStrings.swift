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
    case monthBudgetExceeded
    case expense
    case income
    case today
    case overdue
    case noTransactions
    case noTransactionsDescription
    case noFilteredTransactions
    case noFilteredTransactionsDescription
    case cancel
    case delete
    case deleteConfirmation
    case name
    case settings
    case add
    case currentAccount
    case currentAccountHeroSubtitle
    case currentAccountMonthlyList
    case currentAccountCalendar
    case credits
    case management
    case managementHeroSubtitle
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
    case monthExpense
    case noSpecificDay
    case autoMarkPaidOnDay
    case autoPaidOnDaySummary
    case nextMonthBudgetOnlySummary
    case fillDay
    case value
    case save
    case ok
    case yes
    case no
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
    case creditPaymentExpenseButton
    case newCreditPaymentExpense
    case newRecurringSavingExpense
    case newRecurringCreditPaymentExpense
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
    case weeklyRecurrence
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
    case currentAndFutureEditTitle
    case currentAndFutureEditMessage
    case futureDeleteTitle
    case futureDeleteMessage
    case continueAction
    case overdueExpensesTitle
    case overdueExpensesMessagePrefix
    case dueTodayExpensesMessagePrefix
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
    case canStillSpend
    case unusedExpense
    case paidExpense
    case unpaidExpense
    case paidToggleHelpTitle
    case paidToggleHelpMessage
    case paidAmount
    case paymentNote
    case paymentNotePlaceholder
    case ofAmount
    case amountToPay
    case total
    case payFullAmount
    case futurePaymentTitle
    case futurePaymentMessage
    case futureFlexiblePaymentMessage
    case monthAnalysis
    case analyticsHeroTitle
    case analyticsHeroSubtitle
    case analyticsMenuTitle
    case analyticsOverview
    case analyticsMonthYear
    case analyticsSummaries
    case analyticsSavingsCredits
    case availableBalanceSummary
    case totalSavedSummary
    case totalDebtSummary
    case netWorthTitle
    case previousMonthComparison
    case netWorthVariationTitle
    case noVariation
    case quickSummary
    case seeAll
    case noSavings
    case noCredits
    case movementHistory
    case movementHistoryDescription
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
    case appSecurityICloudBackupMessage
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
    case iCloudSyncTitle
    case iCloudSyncMessage
    case iCloudSyncRestartNote
    case iCloudSyncPromptTitle
    case iCloudSyncPromptMessage
    case iCloudSyncEnable
    case iCloudSyncNotNow
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
    case valueAbovePaidTitle
    case valueAbovePaidMessage
    case receivedDate
    case useInBudget
    case budgetMonth
    case budgetAllocationCurrentMonth
    case budgetAllocationNextMonth
    case budgetAllocationCustomMonth
    case reservedForBudgetSummary
    case reservedBalanceHelpTitle
    case reservedBalanceHelpMessage
    case futureIncomeReceivedInsight
    case futureIncomeReservedInsight
    case accounts
    case accountsSubtitle
    case accountSingular
    case accountPlural
    case totalSummaryLabel
    case totalAllAccountsSummary
    case netWorthAccountsFormula
    case addAccount
    case moveMoney
    case noAccounts
    case accountsMigrationHint
    case totalInAccounts
    case totalInAccountsDescription
    case primaryAccountBadge
    case editAccount
    case adjustBalance
    case setPrimaryAccount
    case deleteAccount
    case accountHistory
    case noAccountMovements
    case newAccount
    case editAccountTitle
    case account
    case accountNamePlaceholder
    case initialBalance
    case primaryAccount
    case icon
    case color
    case accountNameValidation
    case chooseDifferentAccounts
    case sourceAccountInsufficientBalance
    case fromAccount
    case toAccount
    case swapAccounts
    case note
    case currentBalance
    case newBalance
    case deletePrimaryAccountMessage
    case deleteAccountWithBalanceMessage
    case deleteAccountBlockedTitle
    case deleteAccountWithRecurringIncomeMessage
    case colorBlue
    case colorGreen
    case colorOrange
    case colorPurple
    case colorTeal
    case colorGray
    case accountMovementInitial
    case accountMovementIncome
    case accountMovementExpensePayment
    case accountMovementTransferIn
    case accountMovementTransferOut
    case accountMovementAdjustment
    case accountIconBank
    case accountIconWallet
    case accountIconCash
    case accountIconCard
    case accountIconTravel
    case accountIconHome
    case accountIconOther
    case transferInAccountTitle
    case transferOutAccountTitle
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
            .monthUnpaid: "Ainda por Pagar",
            .monthRemaining: "Disponível no mês",
            .monthBudgetExceeded: "Ultrapassou o orçamento",
            .expense: "Despesa",
            .income: "Receita",
            .today: "Hoje",
            .overdue: "Em Atraso",
            .noTransactions: "Sem movimentos",
            .noTransactionsDescription: "Adiciona despesas ou receitas deste mês.",
            .noFilteredTransactions: "Sem resultados",
            .noFilteredTransactionsDescription: "Existem filtros aplicados. Ajusta ou limpa os filtros para voltar a ver os movimentos.",
            .cancel: "Cancelar",
            .delete: "Apagar",
            .deleteConfirmation: "Tem a certeza que quer apagar?",
            .name: "Nome",
            .settings: "Configurações",
            .add: "Adicionar",
            .currentAccount: "Conta Corrente",
            .currentAccountHeroSubtitle: "Acompanhe as suas despesas\ne mantenha o controlo do mês.",
            .currentAccountMonthlyList: "Lista do Mês",
            .currentAccountCalendar: "Calendário",
            .credits: "Análises",
            .management: "Gestão",
            .managementHeroSubtitle: "Organize rendimentos,\ndespesas e planeie\no seu orçamento.",
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
            .freeText: "Nome da Despesa",
            .day: "Dia",
            .monthExpense: "Mensal",
            .noSpecificDay: "Flexível nenhum dia",
            .autoMarkPaidOnDay: "Marcar automaticamente como paga no dia",
            .autoPaidOnDaySummary: "Paga automaticamente no dia",
            .nextMonthBudgetOnlySummary: "Apenas no orçamento do mês seguinte",
            .fillDay: "Seleciona o dia da despesa ou escolhe Flexível nenhum dia.",
            .value: "Valor",
            .save: "Guardar",
            .ok: "OK",
            .yes: "Sim",
            .no: "Não",
            .fillValue: "Preenche o valor.",
            .selectExpenseType: "Seleciona a categoria da despesa 50/30/20.",
            .selectExpenseName: "Seleciona o tipo de despesa.",
            .fillName: "Preenche o nome.",
            .fillFreeText: "Preencha o Nome da Despesa.",
            .newPrefix: "Novo",
            .editPrefix: "Editar",
            .newExpense: "Agendar nova despesa",
            .editExpense: "Editar Despesa",
            .newSavingExpense: "Agendar nova poupança",
            .creditPaymentExpenseButton: "Crédito",
            .newCreditPaymentExpense: "Agendar pagamento de crédito",
            .newRecurringSavingExpense: "Agendar Nova Poupança Recorrente",
            .newRecurringCreditPaymentExpense: "Agendar Pagamento de Crédito Recorrente",
            .newIncome: "Nova Receita",
            .editIncome: "Editar Receita",
            .newMonthlyExpense: "Agendar Nova Despesa Recorrente",
            .editMonthlyExpense: "Editar Despesa Recorrente",
            .newPeriodicExpense: "Nova Despesa Anual",
            .editPeriodicExpense: "Editar Despesa Anual",
            .newSalary: "Agendar Novo Rendimento Recorrente",
            .editSalary: "Editar Rendimento Recorrente",
            .everyMonth: "todos os meses",
            .periodicity: "Periodicidade",
            .weeklyRecurrence: "Semanal",
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
            .currentAndFutureEditTitle: "Editar mês atual e seguintes",
            .currentAndFutureEditMessage: "Esta alteração vai afetar o mês corrente e os meses seguintes, porque ainda não foi registado nenhum pagamento desta despesa no mês corrente.",
            .futureDeleteTitle: "Apagar meses seguintes",
            .futureDeleteMessage: "Esta ação só vai apagar os meses seguintes. Para apagar o mês corrente, apaga diretamente no mês.",
            .continueAction: "Continuar",
            .overdueExpensesTitle: "Despesas por pagar",
            .overdueExpensesMessagePrefix: "Existem despesas no mês corrente que já deviam estar pagas:",
            .dueTodayExpensesMessagePrefix: "Existem despesas no dia de hoje por pagar:",
            .previousMonthUnpaidExpensesMessagePrefix: "Ficaram despesas por pagar no mês passado:",
            .pastMonthsUnpaidExpensesMessagePrefix: "Existem despesas por pagar em meses anteriores:",
            .overdueExpenseDueDay: "devia ter sido paga no dia",
            .balanceThisMonthHelp: "Mostra o saldo disponível até ao dia de hoje. Soma todos os vencimentos e receitas recebidos até hoje e subtrai apenas as despesas até hoje que já foram marcadas como pagas.",
            .monthUnpaidHelp: "Mostra o total das despesas do mês apresentado que ainda não foram marcadas como pagas.",
            .monthRemainingHelp: "No mês atual, mostra quanto sobra depois de subtrair ao saldo total em contas as despesas do mês que ainda estão por pagar. Nos meses seguintes, parte do disponível do mês anterior, soma os rendimentos previstos desse mês e subtrai as despesas desse mês que ainda estão por pagar.",
            .monthRemainingHelpNote: "Este cartão é apresentado apenas no mês atual e nos dois meses seguintes. O saldo total em contas já inclui valores remanescentes de meses anteriores, por isso esses valores não são somados novamente.",
            .pay: "Pagar",
            .paid: "Pago",
            .notPaid: "Por pagar",
            .canStillSpend: "Ainda pode gastar",
            .unusedExpense: "Por utilizar",
            .paidExpense: "Paga",
            .unpaidExpense: "Por pagar",
            .paidToggleHelpTitle: "Estado do pagamento",
            .paidToggleHelpMessage: "Pode criar a despesa como por pagar ou marcá-la logo como paga. Ao escolher paga, o pagamento total é registado imediatamente e o saldo disponível da Conta Corrente é atualizado.",
            .paidAmount: "Valor pago",
            .paymentNote: "Nota",
            .paymentNotePlaceholder: "Adicionar nota ao histórico",
            .ofAmount: "de",
            .amountToPay: "Valor a pagar",
            .total: "Total",
            .payFullAmount: "Pagar totalidade",
            .futurePaymentTitle: "Pagamento futuro",
            .futurePaymentMessage: "Está a registar um pagamento de %@ para uma despesa marcada para %@.",
            .futureFlexiblePaymentMessage: "Está a registar um pagamento de %@ para uma despesa flexível de %@.",
            .monthAnalysis: "Análise do Mês",
            .analyticsHeroTitle: "Análise",
            .analyticsHeroSubtitle: "Veja os seus padrões de gastos\ne evolua as suas finanças.",
            .analyticsMenuTitle: "Análise",
            .analyticsOverview: "Visão Geral",
            .analyticsMonthYear: "Análise Mês e Ano",
            .analyticsSummaries: "Resumos",
            .analyticsSavingsCredits: "Poupanças e Créditos",
            .availableBalanceSummary: "Saldo disponível",
            .totalSavedSummary: "Total poupado",
            .totalDebtSummary: "Total em dívida",
            .netWorthTitle: "Património líquido",
            .previousMonthComparison: "vs mês anterior",
            .netWorthVariationTitle: "Variação do património",
            .noVariation: "Sem variação",
            .quickSummary: "Resumo rápido",
            .seeAll: "Ver todos",
            .noSavings: "Sem poupanças",
            .noCredits: "Sem créditos",
            .movementHistory: "Histórico de movimentos",
            .movementHistoryDescription: "Ver detalhes dos movimentos registados",
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
            .appSecurityICloudBackupMessage: "Se selecionar Sincronizar com iCloud, os dados também ficam guardados no seu iCloud e podem ser sincronizados ou recuperados nos seus dispositivos Apple com a mesma conta. Este backup/sincronização fica associado ao seu iCloud e não é enviado para servidores da SpendWise.",
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
            .deleteAllDataMessage: "Esta ação vai apagar todas as despesas, receitas, vencimentos, pagamentos, histórico de pagamentos, exceções, contas, transferências, créditos e movimentos de crédito guardados na app. Não é possível anular.",
            .exportBackup: "Exportar backup",
            .importBackup: "Importar backup",
            .backupInfoTitle: "Backup",
            .exportBackupHelp: "Cria um ficheiro encriptado com palavra-passe apenas com os dados registados pelo utilizador: vencimentos, despesas, pagamentos, exceções, créditos e movimentos de crédito. Guarde a palavra-passe num local seguro, porque será necessária para importar o backup.",
            .importBackupHelp: "Permite escolher um backup exportado anteriormente pela SpendWise. Se o ficheiro estiver encriptado, será pedida a palavra-passe para desencriptar antes de importar. Após confirmação, os dados registados atuais são substituídos pelos dados do backup.",
            .exportBackupSuccessTitle: "Backup criado",
            .exportBackupSuccessMessage: "Ficheiro criado com sucesso.",
            .exportBackupFailureTitle: "Não foi possível exportar o backup",
            .importBackupConfirmationTitle: "Importar backup?",
            .importBackupConfirmationMessage: "Esta ação vai substituir todos os dados atuais pelos dados do backup selecionado. Deseja continuar?",
            .importBackupSuccessTitle: "Backup importado",
            .importBackupSuccessMessage: "Os dados do backup foram importados com sucesso.",
            .importBackupFailureTitle: "Não foi possível importar o backup",
            .importBackupFailureMessage: "O ficheiro selecionado não é um backup válido da SpendWise.",
            .iCloudSyncTitle: "Sincronizar com iCloud",
            .iCloudSyncMessage: "Os seus dados são privados. Não criamos perfis nem partilhamos a sua informação. Se ativar a sincronização, os dados são guardados no seu iCloud para estarem disponíveis nos seus dispositivos Apple.",
            .iCloudSyncRestartNote: "Depois de alterar esta opção, reinicie a app para aplicar a configuração de sincronização.",
            .iCloudSyncPromptTitle: "Usar dados do iCloud?",
            .iCloudSyncPromptMessage: "Se já usa a SpendWise noutro dispositivo Apple, pode ativar a sincronização com iCloud para tentar obter os seus dados. Os dados ficam guardados no seu iCloud.",
            .iCloudSyncEnable: "Ativar iCloud",
            .iCloudSyncNotNow: "Agora não",
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
            .setupExpensesTitle: "Despesas Recorrentes",
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
            .setupIncomeCardTitle: "Rendimento",
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
            .setupFinalNote: "Este é apenas o ponto de partida. Pode melhorar sempre o orçamento ao adicionar registos na área Gestão, onde pode gerir e adicionar mais despesas recorrentes, registar poupanças e créditos para ter uma visão mais completa da sua situação.",
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
            .subscriptionsThisMonth: "Subscrições",
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
            .valueBelowPaidMessage: "Esta despesa já tem pagamentos registados superiores ao novo valor. Se continuar, o valor da despesa será ajustado para o total já pago.",
            .valueAbovePaidTitle: "Despesa já paga",
            .valueAbovePaidMessage: "Está a alterar este orçamento que já estava pago para um valor superior. Quer que permaneça como pago totalmente?",
            .receivedDate: "Data de recebimento",
            .useInBudget: "Utilizar no orçamento",
            .budgetMonth: "Mês do orçamento",
            .budgetAllocationCurrentMonth: "Mês em que é recebido",
            .budgetAllocationNextMonth: "Mês seguinte",
            .budgetAllocationCustomMonth: "Selecionar manualmente",
            .reservedForBudgetSummary: "%@ reservados para %@",
            .reservedBalanceHelpTitle: "Saldo disponível",
            .reservedBalanceHelpMessage: "Tem atualmente %@ na conta.\n\nDeste valor, %@ estão reservados para o orçamento de %@ e não são considerados no valor que pode gastar em %@.",
            .futureIncomeReceivedInsight: "📅 Recebeu %@, mas este valor está reservado para o orçamento de %@.",
            .futureIncomeReservedInsight: "🔒 %@ do seu saldo estão reservados para o orçamento de %@.",
            .accounts: "Contas",
            .accountsSubtitle: "Organize o dinheiro por contas, carteiras ou outros saldos.",
            .accountSingular: "conta",
            .accountPlural: "contas",
            .totalSummaryLabel: "Total",
            .totalAllAccountsSummary: "Total em todas as contas: %@",
            .netWorthAccountsFormula: "Contas + poupanças - créditos",
            .addAccount: "Adicionar Conta",
            .moveMoney: "Mover dinheiro",
            .noAccounts: "Ainda não existem contas.",
            .accountsMigrationHint: "A sua Conta Corrente atual passará a ser a Conta Principal. Pode adicionar outras contas para representar dinheiro guardado noutros locais.",
            .totalInAccounts: "Total em contas",
            .totalInAccountsDescription: "Soma do dinheiro disponível em todas as contas.",
            .primaryAccountBadge: "Principal",
            .editAccount: "Editar conta",
            .adjustBalance: "Ajustar saldo",
            .setPrimaryAccount: "Definir como Conta Principal",
            .deleteAccount: "Eliminar conta",
            .accountHistory: "Histórico",
            .noAccountMovements: "Ainda não existem movimentos.",
            .newAccount: "Nova Conta",
            .editAccountTitle: "Editar Conta",
            .account: "Conta",
            .accountNamePlaceholder: "Nome da conta",
            .initialBalance: "Saldo inicial",
            .primaryAccount: "Conta Principal",
            .icon: "Ícone",
            .color: "Cor",
            .accountNameValidation: "Indique o nome da conta.",
            .chooseDifferentAccounts: "Escolha contas diferentes.",
            .sourceAccountInsufficientBalance: "A conta de origem não tem saldo suficiente.",
            .fromAccount: "De",
            .toAccount: "Para",
            .swapAccounts: "Trocar contas",
            .note: "Nota",
            .currentBalance: "Saldo atual",
            .newBalance: "Novo saldo",
            .deletePrimaryAccountMessage: "Escolha outra Conta Principal antes de eliminar esta conta.",
            .deleteAccountWithBalanceMessage: "Esta conta ainda tem %@. Transfira o saldo para outra conta antes de a eliminar.",
            .deleteAccountBlockedTitle: "Não é possível eliminar",
            .deleteAccountWithRecurringIncomeMessage: "Esta conta tem rendimentos recorrentes associados. Altere esses rendimentos para outra conta antes de eliminar.",
            .colorBlue: "Azul",
            .colorGreen: "Verde",
            .colorOrange: "Laranja",
            .colorPurple: "Roxo",
            .colorTeal: "Turquesa",
            .colorGray: "Cinzento",
            .accountMovementInitial: "Saldo inicial",
            .accountMovementIncome: "Receita",
            .accountMovementExpensePayment: "Pagamento",
            .accountMovementTransferIn: "Transferência recebida",
            .accountMovementTransferOut: "Transferência enviada",
            .accountMovementAdjustment: "Ajuste de saldo",
            .accountIconBank: "Banco",
            .accountIconWallet: "Carteira",
            .accountIconCash: "Dinheiro",
            .accountIconCard: "Cartão",
            .accountIconTravel: "Viagem",
            .accountIconHome: "Casa",
            .accountIconOther: "Outro",
            .transferInAccountTitle: "%@ → esta conta",
            .transferOutAccountTitle: "Esta conta → %@"
        ],
        .english: [
            .appName: "SpendWise",
            .balanceThisMonth: "Available balance",
            .monthUnpaid: "Left to pay this month",
            .monthRemaining: "Still available this month",
            .monthBudgetExceeded: "Over budget",
            .expense: "Expense",
            .income: "Income",
            .today: "Today",
            .overdue: "Overdue",
            .noTransactions: "No transactions",
            .noTransactionsDescription: "Add expenses or income for this month.",
            .noFilteredTransactions: "No results",
            .noFilteredTransactionsDescription: "Filters are applied. Adjust or clear the filters to see the transactions again.",
            .cancel: "Cancel",
            .delete: "Delete",
            .deleteConfirmation: "Are you sure you want to delete?",
            .name: "Name",
            .settings: "Settings",
            .add: "Add",
            .currentAccount: "Current Account",
            .currentAccountHeroSubtitle: "Track your expenses\nand stay in control of the month.",
            .currentAccountMonthlyList: "Month List",
            .currentAccountCalendar: "Calendar",
            .credits: "Analytics",
            .management: "Management",
            .managementHeroSubtitle: "Organize income,\nexpenses and plan\nyour budget.",
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
            .freeText: "Expense name",
            .day: "Day",
            .monthExpense: "Monthly",
            .noSpecificDay: "Flexible no day",
            .autoMarkPaidOnDay: "Automatically mark as paid on the day",
            .autoPaidOnDaySummary: "Automatically paid on the day",
            .nextMonthBudgetOnlySummary: "Only for next month's budget",
            .fillDay: "Select the expense day or choose Flexible no day.",
            .value: "Value",
            .save: "Save",
            .ok: "OK",
            .yes: "Yes",
            .no: "No",
            .fillValue: "Fill in the value.",
            .selectExpenseType: "Select the 50/30/20 expense category.",
            .selectExpenseName: "Select the expense type.",
            .fillName: "Fill in the name.",
            .fillFreeText: "Fill in the free text.",
            .newPrefix: "New",
            .editPrefix: "Edit",
            .newExpense: "Schedule new expense",
            .editExpense: "Edit Expense",
            .newSavingExpense: "Schedule new saving",
            .creditPaymentExpenseButton: "Credit",
            .newCreditPaymentExpense: "Schedule credit payment",
            .newRecurringSavingExpense: "Schedule New Recurring Saving",
            .newRecurringCreditPaymentExpense: "Schedule Recurring Credit Payment",
            .newIncome: "New Income",
            .editIncome: "Edit Income",
            .newMonthlyExpense: "Schedule New Recurring Expense",
            .editMonthlyExpense: "Edit Recurring Expense",
            .newPeriodicExpense: "New Annual Expense",
            .editPeriodicExpense: "Edit Annual Expense",
            .newSalary: "Schedule New Recurring Income",
            .editSalary: "Edit Recurring Income",
            .everyMonth: "every month",
            .periodicity: "Frequency",
            .weeklyRecurrence: "Weekly",
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
            .currentAndFutureEditTitle: "Edit current and following months",
            .currentAndFutureEditMessage: "This change will affect the current month and following months because no payment has been registered for this expense in the current month.",
            .futureDeleteTitle: "Delete following months",
            .futureDeleteMessage: "This action will only delete following months. To delete the current month, delete it directly in that month.",
            .continueAction: "Continue",
            .overdueExpensesTitle: "Expenses to pay",
            .overdueExpensesMessagePrefix: "There are expenses in the current month that should already be paid:",
            .dueTodayExpensesMessagePrefix: "There are expenses due today that are still unpaid:",
            .previousMonthUnpaidExpensesMessagePrefix: "There are unpaid expenses from last month:",
            .pastMonthsUnpaidExpensesMessagePrefix: "There are unpaid expenses from previous months:",
            .overdueExpenseDueDay: "should have been paid on day",
            .balanceThisMonthHelp: "Shows the available balance up to today. It sums all salaries and income received up to today and subtracts only expenses up to today that have been marked as paid.",
            .monthUnpaidHelp: "Shows the total expenses in the displayed month that have not been marked as paid.",
            .monthRemainingHelp: "For the current month, it shows what is left after subtracting the month's unpaid expenses from the total balance across accounts. For following months, it starts from the previous month's available amount, adds the income expected for that month, and subtracts that month's unpaid expenses.",
            .monthRemainingHelpNote: "This card is only shown for the current month and the following two months. The total balance across accounts already includes remaining amounts from previous months, so those amounts are not added again.",
            .pay: "Pay",
            .paid: "Paid",
            .notPaid: "To pay",
            .canStillSpend: "Can still spend",
            .unusedExpense: "To use",
            .paidExpense: "Paid",
            .unpaidExpense: "To pay",
            .paidToggleHelpTitle: "Payment status",
            .paidToggleHelpMessage: "You can create the expense as unpaid or mark it as paid straight away. When paid is selected, the full payment is recorded immediately and the Current Account available balance is updated.",
            .paidAmount: "Paid amount",
            .paymentNote: "Note",
            .paymentNotePlaceholder: "Add note to payment history",
            .ofAmount: "of",
            .amountToPay: "Amount to pay",
            .total: "Total",
            .payFullAmount: "Pay full amount",
            .futurePaymentTitle: "Future payment",
            .futurePaymentMessage: "You are recording a payment of %@ for an expense scheduled for %@.",
            .futureFlexiblePaymentMessage: "You are recording a payment of %@ for a flexible expense in %@.",
            .monthAnalysis: "Month Analysis",
            .analyticsHeroTitle: "Analysis",
            .analyticsHeroSubtitle: "See your spending patterns\nand improve your finances.",
            .analyticsMenuTitle: "Analysis",
            .analyticsOverview: "Overview",
            .analyticsMonthYear: "Month and Year Analysis",
            .analyticsSummaries: "Summaries",
            .analyticsSavingsCredits: "Savings and Credits",
            .availableBalanceSummary: "Available balance",
            .totalSavedSummary: "Total saved",
            .totalDebtSummary: "Total debt",
            .netWorthTitle: "Net worth",
            .previousMonthComparison: "vs previous month",
            .netWorthVariationTitle: "Net worth change",
            .noVariation: "No change",
            .quickSummary: "Quick summary",
            .seeAll: "See all",
            .noSavings: "No savings",
            .noCredits: "No credits",
            .movementHistory: "Movement history",
            .movementHistoryDescription: "See details of registered movements",
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
            .appSecurityICloudBackupMessage: "If you select Sync with iCloud, your data is also stored in your iCloud and can be synced or recovered on your Apple devices using the same account. This backup/sync is associated with your iCloud and is not sent to SpendWise servers.",
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
            .deleteAllDataMessage: "This will delete every expense, income, salary, payment, payment history, recurrence exception, account, transfer, credit and credit movement stored in the app. This cannot be undone.",
            .exportBackup: "Export backup",
            .importBackup: "Import backup",
            .backupInfoTitle: "Backup",
            .exportBackupHelp: "Creates a password-encrypted file only with user-entered data: salaries, expenses, payments, recurrence exceptions, credits and credit movements. Keep the password in a safe place because it will be required to import the backup.",
            .importBackupHelp: "Lets you choose a backup previously exported by SpendWise. If the file is encrypted, the password is required to decrypt it before importing. After confirmation, current registered data is replaced with the backup data.",
            .exportBackupSuccessTitle: "Backup created",
            .exportBackupSuccessMessage: "File created successfully.",
            .exportBackupFailureTitle: "Could not export backup",
            .importBackupConfirmationTitle: "Import backup?",
            .importBackupConfirmationMessage: "This will replace all current data with the selected backup data. Do you want to continue?",
            .importBackupSuccessTitle: "Backup imported",
            .importBackupSuccessMessage: "The backup data was imported successfully.",
            .importBackupFailureTitle: "Could not import backup",
            .importBackupFailureMessage: "The selected file is not a valid SpendWise backup.",
            .iCloudSyncTitle: "Sync with iCloud",
            .iCloudSyncMessage: "Your data is private. We do not create profiles or share your information. If you enable sync, your data is stored in your iCloud so it is available on your Apple devices.",
            .iCloudSyncRestartNote: "After changing this option, restart the app to apply the sync configuration.",
            .iCloudSyncPromptTitle: "Use iCloud data?",
            .iCloudSyncPromptMessage: "If you already use SpendWise on another Apple device, you can enable iCloud sync to try to retrieve your data. The data stays stored in your iCloud.",
            .iCloudSyncEnable: "Enable iCloud",
            .iCloudSyncNotNow: "Not now",
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
            .setupExpensesTitle: "Recurring expenses",
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
            .setupIncomeCardTitle: "Income",
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
            .setupFinalNote: "This is only the starting point. You can keep improving your budget by adding records in Management, where you can manage and add more recurring expenses, register savings and credit accounts, and get a clearer view of your situation.",
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
            .subscriptionsThisMonth: "Subscriptions",
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
            .valueBelowPaidMessage: "This expense already has registered payments above the new value. If you continue, the expense value will be adjusted to the total already paid.",
            .valueAbovePaidTitle: "Expense already paid",
            .valueAbovePaidMessage: "You are changing this budget item, which was already paid, to a higher value. Do you want it to remain fully paid?",
            .receivedDate: "Received date",
            .useInBudget: "Use in budget",
            .budgetMonth: "Budget month",
            .budgetAllocationCurrentMonth: "Month received",
            .budgetAllocationNextMonth: "Next month",
            .budgetAllocationCustomMonth: "Select manually",
            .reservedForBudgetSummary: "%@ reserved for %@",
            .reservedBalanceHelpTitle: "Available balance",
            .reservedBalanceHelpMessage: "You currently have %@ in the account.\n\nOf this amount, %@ is reserved for the %@ budget and is not considered in the amount you can spend in %@.",
            .futureIncomeReceivedInsight: "📅 You received %@, but this amount is reserved for the %@ budget.",
            .futureIncomeReservedInsight: "🔒 %@ of your balance is reserved for the %@ budget.",
            .accounts: "Accounts",
            .accountsSubtitle: "Organize money by accounts, wallets, or other balances.",
            .accountSingular: "account",
            .accountPlural: "accounts",
            .totalSummaryLabel: "Total",
            .totalAllAccountsSummary: "Total across all accounts: %@",
            .netWorthAccountsFormula: "Accounts + savings - credits",
            .addAccount: "Add Account",
            .moveMoney: "Move money",
            .noAccounts: "There are no accounts yet.",
            .accountsMigrationHint: "Your current account will become the Primary Account. You can add other accounts to represent money kept elsewhere.",
            .totalInAccounts: "Total in accounts",
            .totalInAccountsDescription: "Sum of the money available across all accounts.",
            .primaryAccountBadge: "Primary",
            .editAccount: "Edit account",
            .adjustBalance: "Adjust balance",
            .setPrimaryAccount: "Set as Primary Account",
            .deleteAccount: "Delete account",
            .accountHistory: "History",
            .noAccountMovements: "There are no movements yet.",
            .newAccount: "New Account",
            .editAccountTitle: "Edit Account",
            .account: "Account",
            .accountNamePlaceholder: "Account name",
            .initialBalance: "Initial balance",
            .primaryAccount: "Primary Account",
            .icon: "Icon",
            .color: "Color",
            .accountNameValidation: "Enter the account name.",
            .chooseDifferentAccounts: "Choose different accounts.",
            .sourceAccountInsufficientBalance: "The source account does not have enough balance.",
            .fromAccount: "From",
            .toAccount: "To",
            .swapAccounts: "Swap accounts",
            .note: "Note",
            .currentBalance: "Current balance",
            .newBalance: "New balance",
            .deletePrimaryAccountMessage: "Choose another Primary Account before deleting this account.",
            .deleteAccountWithBalanceMessage: "This account still has %@. Transfer the balance to another account before deleting it.",
            .deleteAccountBlockedTitle: "Cannot delete",
            .deleteAccountWithRecurringIncomeMessage: "This account has recurring income linked to it. Move those income records to another account before deleting it.",
            .colorBlue: "Blue",
            .colorGreen: "Green",
            .colorOrange: "Orange",
            .colorPurple: "Purple",
            .colorTeal: "Teal",
            .colorGray: "Gray",
            .accountMovementInitial: "Initial balance",
            .accountMovementIncome: "Income",
            .accountMovementExpensePayment: "Payment",
            .accountMovementTransferIn: "Transfer received",
            .accountMovementTransferOut: "Transfer sent",
            .accountMovementAdjustment: "Balance adjustment",
            .accountIconBank: "Bank",
            .accountIconWallet: "Wallet",
            .accountIconCash: "Cash",
            .accountIconCard: "Card",
            .accountIconTravel: "Travel",
            .accountIconHome: "Home",
            .accountIconOther: "Other",
            .transferInAccountTitle: "%@ → this account",
            .transferOutAccountTitle: "This account → %@"
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
                "Subscrições",
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
                "Subscriptions",
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
