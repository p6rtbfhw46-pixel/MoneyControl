# SpendWise - Documento tecnico por ecras

Documento de referencia para localizar e compreender os ecras, componentes, acoes, funcoes e variaveis de texto existentes na app.

## Estrutura geral

| Area | Ficheiro principal | Responsabilidade |
| --- | --- | --- |
| App e persistencia | `MoneyControl/MoneyControlApp.swift` | Arranque da app, configuracao SwiftData e ciclo de vida. |
| Ecras principais | `MoneyControl/MoneyControl/ContentView.swift` | Conta Corrente, Analises, Gestao, navegacao inferior, atalhos do botao `+`, filtros e sheets principais. |
| Componentes partilhados | `MoneyComponents.swift` | Cards de movimentos, lista mensal, input monetario, pagamento de despesas, banners, tiles de resumo e listas recorrentes. |
| Editor de movimentos | `TransactionEditor.swift` | Criar/editar despesas, rendimentos, recorrencias, alocacao de rendimento a meses de orcamento e ligacoes a poupancas/creditos. |
| Gestao e definicoes | `SettingsEditor.swift` | Gestao de recorrentes, preferencias, privacidade, backup/importacao e apagar dados. |
| Wizard inicial | `InitialSetupWizardView.swift` | Configuracao inicial de rendimentos, despesas recorrentes e resumo visual. |
| Creditos | `CreditViews.swift`, `CreditDomain.swift` | Lista, detalhe, editor, movimentos e textos de creditos. |
| Poupancas | `SavingsViews.swift`, `SavingsDomain.swift` | Lista, detalhe, editor, movimentos e textos de poupancas. |
| Dominio financeiro | `MoneyDomain.swift` | Enums, categorias, recorrencia, alocacao de orcamento, helpers de data/moeda e icones de tipos. |
| Calculos | `MoneyCalculationService.swift` | Saldos, totais mensais, analises, insights, orcamento acumulado e rendimentos reservados. |
| Strings | `AppStrings.swift`, `CreditDomain.swift`, `SavingsDomain.swift` | Textos localizados PT/EN usados pela interface. |
| Modelos SwiftData | `MoneyControl/Item.swift` | Entidades persistidas: movimentos, pagamentos, creditos e poupancas. |

## Modelos de dados

| Modelo | Ficheiro | Campos principais | Serve para |
| --- | --- | --- | --- |
| `MoneyTransaction` | `MoneyControl/Item.swift` | `title`, `day`, `monthStart`, `amount`, `kind`, `expenseCategory`, `expenseName`, `recurrenceType`, `budgetAllocationType`, `budgetMonthStart`, `linkedCreditID`, `linkedSavingID` | Registar despesas e rendimentos, recorrentes ou pontuais. Tambem liga movimentos a creditos/poupancas e separa data real de rendimento do mes de orcamento. |
| `RecurrenceExclusion` | `MoneyControl/Item.swift` | `transactionID`, `monthStart` | Ocultar uma ocorrencia especifica de uma recorrencia quando se edita/apaga apenas um mes. |
| `ExpensePayment` | `MoneyControl/Item.swift` | `transactionID`, `monthStart`, `amountPaid` | Guardar o estado pago/parcialmente pago de uma despesa num mes. |
| `PaymentHistoryEntry` | `MoneyControl/Item.swift` | `transactionID`, `monthStart`, `amount`, `paidAt` | Historico de pagamentos parciais ou totais. |
| `CreditAccount` | `MoneyControl/Item.swift` | `name`, `type`, `initialDebt`, `creditLimit`, `status` | Conta de credito, cartao, emprestimo ou prestacao. |
| `CreditMovement` | `MoneyControl/Item.swift` | `creditID`, `date`, `type`, `amount`, `note` | Movimento que aumenta, reduz ou ajusta uma divida. |
| `SavingAccount` | `MoneyControl/Item.swift` | `name`, `initialAmount`, `targetAmount`, `status` | Objetivo ou conta de poupanca. |
| `SavingMovement` | `MoneyControl/Item.swift` | `savingID`, `date`, `type`, `amount`, `note`, `linkedIncomeTransactionID` | Depositos, levantamentos e ajustes de poupanca. |

## Dominio e regras

| Tipo/Funcoes | Ficheiro | Uso |
| --- | --- | --- |
| `TransactionKind` | `MoneyDomain.swift` | Distingue `expense` e `income`. |
| `BudgetAllocation` | `MoneyDomain.swift` | Define se rendimento entra no orcamento do mes atual, mes seguinte ou mes customizado. |
| `RecurrenceType` | `MoneyDomain.swift` | Periodicidade mensal, trimestral, semestral, anual e anual por mes. |
| `TransactionEditorMode` | `MoneyDomain.swift` | Controla o modo do editor: despesa, rendimento, recorrente, anual. |
| `ExpenseCategory` | `MoneyDomain.swift` | Categorias 50/30/20, cores, icones e listas de tipos. |
| `ExpenseTypeIcon.name(for:)` | `MoneyDomain.swift` | Mapeia tipo de despesa para SF Symbol usado em filtros, dropdowns e cards. |
| `MoneyTransaction.visible(in:exclusions:)` | `MoneyDomain.swift` | Decide se uma transacao aparece num mes, considerando recorrencia e exclusoes. |
| `MoneyTransaction.effectiveDay(in:)` | `MoneyDomain.swift` | Ajusta o dia quando o mes tem menos dias. |
| `MoneyTransaction.budgetMonth(forReceivedMonth:)` | `MoneyDomain.swift` | Calcula o mes de orcamento efetivo para rendimentos. |

## Servico de calculos

| Funcao | Ficheiro | Serve para |
| --- | --- | --- |
| `visibleTransactions(in:)` | `MoneyCalculationService.swift` | Movimentos visiveis num mes, ja filtrados por recorrencias/exclusoes. |
| `paidAmount(for:in:)`, `isPaid(_:in:)` | `MoneyCalculationService.swift` | Estado de pagamento mensal de uma despesa. |
| `accountSummary(until:)` | `MoneyCalculationService.swift` | Saldo real disponivel ate hoje, incluindo rendimentos recebidos e despesas pagas. |
| `monthSummary(in:)` | `MoneyCalculationService.swift` | Totais de rendimento, despesas e por pagar do mes de orcamento. |
| `cumulativeBudgetRemaining(through:)` | `MoneyCalculationService.swift` | Remanescente acumulado ate um mes, usado em `Pode gastar este mes`. |
| `incomeTotal(in:)`, `incomeOccurrences(budgetedIn:)` | `MoneyCalculationService.swift` | Rendimento por mes de orcamento, nao apenas por data de recebimento. |
| `reservedIncomeForFutureBudgets(until:)` | `MoneyCalculationService.swift` | Rendimentos ja recebidos mas reservados para meses futuros. |
| `categoryExpenses(in:)`, `expenseTypePoints(in:)` | `MoneyCalculationService.swift` | Graficos e listas de analise por categoria/tipo. |
| `annualBalancePoints(in:)`, `yearSavingsPoints(in:)` | `MoneyCalculationService.swift` | Graficos anuais de saldo e poupanca. |
| `analyticsInsights(currentMonth:)` | `MoneyCalculationService.swift` | Mensagens do carrossel de analise. |

## Ecras principais

### App root

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `MoneyControlApp` | `MoneyControl/MoneyControlApp.swift` | `modelContainer(for:)` | Configura SwiftData com todos os modelos persistidos. |
| `ContentView` | `MoneyControl/MoneyControl/ContentView.swift` | `@AppStorage("hasCompletedOnboarding")` e `@AppStorage("hasCompletedInitialSetup")` | Decide se mostra onboarding, wizard inicial ou app principal. |

### Onboarding

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `OnboardingView` | `OnboardingView.swift` | `onComplete` | Ecras introdutorios antes da configuracao inicial. |
| Cards/ilustracoes internas | `OnboardingView.swift` | `illustration`, `iconLabel`, `legend` | Explicam regras, acompanhamento e privacidade. |
| Botao final | `OnboardingView.swift` | `onComplete()` | Marca onboarding como concluido. |
| Textos | `AppStrings.swift` | Chaves de onboarding em `AppTextKey` | Conteudo PT/EN. |

### Wizard inicial - passo 1: rendimentos

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `InitialSetupWizardView.incomeStep` | `InitialSetupWizardView.swift` | `incomeDraft`, `incomes` | Recolhe rendimentos mensais iniciais. |
| Campo nome | `InitialSetupWizardView.swift` | `incomeDraft.name` | Nome do rendimento. |
| Campo valor | `MoneyComponents.swift` | `MoneyAmountPicker` | Input monetario reutilizavel. |
| Botao `Adicionar rendimento` | `InitialSetupWizardView.swift` | `addIncome()` | Valida nome/valor e adiciona draft a lista. |
| Lista `Rendimentos adicionados` | `InitialSetupWizardView.swift` | `draftList(...)` | Mostra drafts e permite apagar por indice. |
| Botao `Seguinte` | `InitialSetupWizardView.swift` | `goForward()` | Valida que existe pelo menos um rendimento. |
| Textos | `AppStrings.swift` | `setupWelcomeTitle`, `setupIncomeCardTitle`, `incomeNamePrompt`, `addIncome`, `addedIncomes`, `setupIncomeNote` | Labels e mensagens. |

### Wizard inicial - passo 2: despesas recorrentes

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `InitialSetupWizardView.expenseStep` | `InitialSetupWizardView.swift` | `expenseDraft`, `expenses` | Recolhe despesas recorrentes iniciais. Em landscape divide formulario e lista lado a lado. |
| Titulo | `AppStrings.swift` | `setupExpensesTitle` | Texto atual: `Despesas Recorrentes`. |
| Categoria 50/30/20 | `InitialSetupWizardView.swift` | `SetupExpenseCategoryPicker(selection:)` | Seleciona categoria com cores equivalentes a Conta Corrente. |
| Tipo de despesa | `InitialSetupWizardView.swift` | `Picker` + `ExpenseTypeIcon.name(for:)` | Dropdown com icone e nomes vindos de `ExpenseCategory.names`. |
| Texto livre/nome | `InitialSetupWizardView.swift` | `expenseDraft.name` | Descricao obrigatoria da despesa. |
| Valor | `MoneyComponents.swift` | `MoneyAmountPicker` | Input monetario. |
| Dia do mes | `InitialSetupWizardView.swift`, `TransactionEditor.swift` | `showsExpenseDayPicker`, `DayPicker` | Escolhe dia de vencimento/ocorrencia. |
| Recorrencia | `InitialSetupWizardView.swift` | `expenseDraft.recurrenceType`, `expenseDraft.recurrenceMonth` | Escolhe mensal/trimestral/semestral/anual e mes inicial quando aplicavel. |
| Botao `Adicionar despesa` | `InitialSetupWizardView.swift` | `addExpense()` | Valida tipo, texto livre e valor; adiciona draft. |
| Lista de despesas adicionadas | `InitialSetupWizardView.swift` | `expenseDraftList`, `sortedExpenses` | Lista ordenada por dia, com icone do tipo, dia em bold azul, valor e recorrencia. |
| Guardar final | `InitialSetupWizardView.swift` | `saveSetup()` | Cria `MoneyTransaction` recorrentes com `recurrenceType` e `monthStart` correto. |
| Textos | `AppStrings.swift` | `setupExpensesTitle`, `setupExpensesSubtitle`, `setupExpenseCardTitle`, `category503020`, `recurrence`, `periodicity`, `addExpense`, `addedExpenses`, `noAddedExpenses`, `setupExpensesNote` | Labels, notas e validacoes. |

### Wizard inicial - passo 3: resumo

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `summaryStep` | `InitialSetupWizardView.swift` | `totalIncome`, `totalExpenses`, `availableBalance` | Mostra resumo inicial antes de usar a app. |
| Resumo de totais | `InitialSetupWizardView.swift` | `summaryRow(...)` | Linhas `Recebe`, `Despesas fixas`, `Pode gastar este mes`. |
| Nota final | `InitialSetupWizardView.swift` | `noteCard(AppStrings.text(.setupFinalNote))` | Explica que a area Gestao permite melhorar o orcamento com mais recorrentes, poupancas e creditos. |
| Resumo visual | `InitialSetupWizardView.swift` | `Chart`, `expenseCategoryTotals`, `percentageText(...)` | Grafico de rendimentos/despesas/saldo e grafico por categoria. |
| Analise automatica | `InitialSetupWizardView.swift` | `bodyAnalysis`, `categoryRatio(...)` | Mensagem baseada na regra 50/30/20. |
| Botao final | `InitialSetupWizardView.swift` | `saveSetup()`, `onFinish()` | Persiste dados iniciais e entra na app. |

## Conta Corrente

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| Tab `Conta Corrente` | `ContentView.swift` | `selectedTab == .currentAccount`, `currentAccountView` | Ecras mensais de movimentos. |
| Cards superiores | `ContentView.swift`, `MoneyComponents.swift` | `summaryBar`, `SummaryTile` | Mostra `Saldo disponivel`, `Falta pagar este mes`, `Pode gastar este mes` ou `Ultrapassou o orcamento`. |
| Ajuda dos cards | `MoneyComponents.swift` | `HelpIconButton`, alert de `SummaryTile` | Explica os calculos. |
| Navegacao mes/ano | `ContentView.swift` | `monthHeader`, `moveMonth(by:)`, `monthArrowButton(...)` | Altera `selectedMonthOffset`. |
| Lista mensal | `MoneyComponents.swift` | `MonthPage` | Mostra movimentos filtrados do mes. |
| Area `Hoje` | `MoneyComponents.swift` | `todayTransactions`, `todaySection`, `todaySectionCard` | Destaca movimentos cujo `effectiveDay` coincide com o dia atual. |
| Cards de movimento | `MoneyComponents.swift` | `TransactionCard` | Mostra titulo, subtitulo, icone, valor, estado de pagamento e acoes expandidas. |
| Expandir card | `MoneyComponents.swift` | `expandedTransactionID`, `onExpansionChange` | Apenas um card expandido por lista. |
| Pagar despesa | `ContentView.swift`, `MoneyComponents.swift` | `paymentEditorRequest`, `PaymentAmountPicker`, `addPaymentAmount(...)` | Regista pagamento total/parcial e historico. |
| Editar movimento | `ContentView.swift`, `TransactionEditor.swift` | `editorRequest`, `TransactionEditorRequest` | Abre editor. Recorrentes na Conta Corrente usam `editScope: .singleMonth`. |
| Apagar movimento | `ContentView.swift` | `deleteTransaction(_:in:)`, `addExclusion(for:in:)` | Apaga pontual ou exclui ocorrencia mensal de recorrente. |
| Filtros | `ContentView.swift` | `CurrentAccountFilterView`, `clearCurrentAccountFilters()`, `persistCurrentAccountFilters()` | Filtra por pago/por pagar, categoria, tipo e texto livre. |
| Navegacao inferior | `ContentView.swift` | `bottomNavigationBar`, `bottomTabButton(...)` | Alterna Conta Corrente, Analises e Gestao. |
| Botao `+` | `ContentView.swift` | `quickActionsBar`, `openPresetExpense(...)`, `savingQuickActionButton`, `creditQuickActionButton`, `incomeQuickActionButton`, `expenseQuickActionButton` | Abre criacao rapida de despesa, rendimento, poupanca ou pagamento de credito. |
| Notificacoes/alertas | `ContentView.swift` | `refreshExpensePaymentNotifications()`, `checkOverdueExpenses()` | Lembra despesas por pagar e mostra avisos de atraso. |

## Editor de movimentos

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `TransactionEditor` | `TransactionEditor.swift` | `TransactionEditorRequest`, `mode`, `editScope` | Editor unico para despesa, rendimento, despesa recorrente, rendimento recorrente e despesa anual. |
| Classificacao | `TransactionEditor.swift` | `ExpenseCategorySegmentedPicker`, `expenseCategory`, `expenseName` | Seleciona categoria 50/30/20 e tipo com icone. |
| Recorrencia | `TransactionEditor.swift` | `selectedRecurrenceType`, `recurrenceMonth`, `hasEndDate`, `selectedEndMonthStart` | Configura mensal/trimestral/semestral/anual e fim de recorrencia. |
| Data/dia | `TransactionEditor.swift` | `DayPicker`, `TransactionDatePicker`, `selectedTransactionDate` | Define data real ou dia da recorrencia. |
| Valor | `MoneyComponents.swift` | `MoneyAmountPicker` | Input monetario com `Confirmar` e `Limpar`. |
| Rendimento no orcamento | `TransactionEditor.swift`, `MoneyDomain.swift` | `BudgetAllocation`, `budgetAllocationTitle(for:)`, `customBudgetMonth`, `customBudgetYear` | Separa data de recebimento de mes de orcamento. |
| Guardar | `TransactionEditor.swift` | `save()`, `saveExpense(...)`, `saveIncome(...)`, `finishSaving(...)` | Valida e persiste alteracoes. |
| Ligacao a credito | `TransactionEditor.swift` | `syncLinkedCreditPaymentIfNeeded(...)`, `deleteLinkedCreditMovementIfNeeded(...)` | Cria/atualiza movimento de credito associado a despesa de pagamento/amortizacao. |
| Ligacao a poupanca | `TransactionEditor.swift` | `syncLinkedSavingDepositIfNeeded(...)`, `deleteLinkedSavingMovementIfNeeded(...)` | Cria/atualiza movimento de poupanca associado. |
| Edicao parcial de recorrencia | `TransactionEditor.swift` | `addExclusion(for:in:)`, `transferPayment(...)`, `movePaymentsAndHistory(...)` | Mantem historico e pagamentos consistentes quando se edita apenas um mes ou meses futuros. |
| Validacoes | `TransactionEditor.swift` | `showValidation(...)`, `ValidationBanner` | Mensagens de categoria, tipo, texto livre/nome e valor. |

## Pagamentos de despesas

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| `PaymentAmountPicker` | `MoneyComponents.swift` | `selectedAmount`, `paidAmountInSheet`, `visibleHistory` | Sheet para pagar uma despesa total/parcialmente. |
| Botao `Pagar total` | `MoneyComponents.swift` | `selectedAmount = remainingAmount`, `confirmPayment()` | Preenche e confirma o restante. |
| Valor a pagar | `MoneyComponents.swift` | `MoneyAmountPicker(onConfirm: confirmPayment)` | Insere valor parcial. |
| Confirmar pagamento | `MoneyComponents.swift` | `confirmPayment()`, `performPayment()` | Valida pagamento futuro/sobrepagamento e chama `onConfirm`. |
| Historico | `MoneyComponents.swift` | `paymentHistorySection`, `deleteHistoryEntry(...)` | Lista e permite remover pagamentos anteriores. |

## Analises

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| Tab `Analises` | `ContentView.swift` | `creditsView` | Pagina de analise financeira. O nome interno ficou historicamente `creditsView`. |
| Patrimonio liquido | `ContentView.swift` | `analyticsNetWorthCard`, `totalCreditDebt(through:)`, poupancas | Junta saldo da conta, poupancas e dividas. |
| Carrossel de insights | `ContentView.swift`, `MoneyCalculationService.swift` | `analyticsInsightCarouselCard`, `analyticsInsights(currentMonth:)`, `moveInsight(by:)` | Mensagens informativas e comparacoes. |
| Periodo de analise | `ContentView.swift` | `analyticsPeriodControls`, `moveAnalyticsMonth(by:)` | Alterna mes/ano analisado. |
| Graficos | `ContentView.swift` | `expenseTypePieChart(...)`, `pieChartColumn(...)` | Mostra onde foi gasto e regra 50/30/20. |
| Listas de analise | `ContentView.swift` | `analyticsListsCard`, `subscriptionList(...)`, `incomeVsExpensesList`, `yearlySavingsList` | Tabs de subscricoes, poupancas anuais e rendimentos vs despesas. |
| Switch subscricoes | `ContentView.swift` | `subscriptionScopePicker` | Alterna `Mensal` e `Todas`. |
| Poupancas | `ContentView.swift` | `analyticsSavingsCard`, `analyticsSavingSubtitle(for:)` | Lista saldos/objetivos de poupanca. |
| Creditos | `ContentView.swift` | `analyticsCreditsCard`, `analyticsCreditSubtitle(for:)` | Lista dividas e estimativas. |
| Conselhos | `ContentView.swift` | `adviceCarouselCard`, `moveAdvice(by:)` | Carrossel de dicas. |

## Gestao

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| Tab `Gestao` | `ContentView.swift` | `managementView` | Entrada para gerir orcamento, poupancas e creditos. |
| Area orcamento | `SettingsEditor.swift` | `BudgetSettingsView` ou `SettingsEditor(openingTab:)` | Gere despesas/rendimentos recorrentes. |
| Area poupancas | `SavingsViews.swift` | `SavingsSettingsView` | Gere contas/objetivos de poupanca. |
| Area creditos | `CreditViews.swift` | `CreditsSettingsView` | Gere creditos e dividas. |
| Botao `+` de recorrencia | `SettingsEditor.swift` | `recurringAddButton`, `recurringActionsBar`, `recurringActionButton(...)` | Abre acoes para nova despesa, rendimento, poupanca recorrente e pagamento de credito recorrente. |
| Despesas recorrentes | `MoneyComponents.swift` | `RecurringList`, `SettingsTransactionCard` | Lista recorrentes configuradas, com expandir/editar/apagar. |
| Editar recorrente | `SettingsEditor.swift` | `editRecurringTransaction(...)`, `confirmedEditStartMonth(for:)` | Decide se altera mes atual e futuros ou apenas futuros, consoante pagamento do mes atual. |
| Apagar recorrente | `SettingsEditor.swift` | `perform(_:)` com `SettingsListAction` | Apaga a partir do mes correto apos confirmacao. |

## Definicoes da app

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| Botao engrenagem | `ContentView.swift` | `settingsToolbarButton`, `showsSettings` | Abre `SettingsEditor`. |
| Inicio das definicoes | `SettingsEditor.swift` | `appSettingsView`, `appSettingsNavigationRow(...)` | Lista Preferencias, Dados e Privacidade, Sobre. |
| Preferencias | `SettingsEditor.swift`, `MoneyDomain.swift` | `appPreferencesView`, `selectedCurrencyCode`, `AppPreferences` | Escolhe moeda e formato. |
| Dados e privacidade | `SettingsEditor.swift` | `appDataPrivacyView`, `exportBackup()`, `handleImportResult(...)`, `importPendingBackup()`, `deleteAllData()` | Exportar/importar JSON e apagar todos os dados. |
| Sobre | `SettingsEditor.swift` | `appAboutView` | Versao e informacao sobre a app. |

## Creditos

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| Lista de creditos | `CreditViews.swift` | `CreditsSettingsView`, `visibleCredits`, `showsSettled` | Mostra creditos ativos e opcionalmente liquidados. |
| Card de credito | `CreditViews.swift` | `CreditSummaryCard`, `credit.balance(with:)`, `credit.monthVariation(...)` | Resumo da divida, limite e variacao. |
| Botao `Adicionar credito` | `CreditViews.swift` | `editorRequest = CreditEditorRequest()` | Abre editor. |
| Editor de credito | `CreditViews.swift` | `CreditEditor`, `save()`, `deleteCredit()` | Cria/edita/apaga credito, valida nome e valor. |
| Detalhe de credito | `CreditViews.swift` | `CreditDetailView` | Mostra cabecalho, limite, resumo mensal, graficos e movimentos. |
| Grafico `Evolucao do mes` | `CreditViews.swift` | `evolutionCard`, `CreditBalancePoint` | Evolucao da divida. |
| Grafico estimativa 1 ano | `CreditViews.swift` | `paymentEstimateCard`, `averageLastThreeMonths` | Projeta pagamentos com base nos ultimos 3 meses. |
| Movimentos | `CreditViews.swift` | `movementsSection`, `CreditMovementEditor` | Lista/adiciona/edita movimentos de credito. |
| Textos | `CreditDomain.swift` | `CreditTextKey`, `CreditStrings.text(...)` | Labels e validacoes de credito. |

## Poupancas

| Elemento | Ficheiro | Funcao/Estado | Serve para |
| --- | --- | --- | --- |
| Lista de poupancas | `SavingsViews.swift` | `SavingsSettingsView`, `visibleSavings`, `showsClosed` | Mostra poupancas ativas e opcionalmente fechadas. |
| Card de poupanca | `SavingsViews.swift` | `SavingSummaryCard`, `saving.balance(with:)`, `saving.monthVariation(...)` | Resumo de saldo, objetivo e progresso. |
| Botao `Adicionar poupanca` | `SavingsViews.swift` | `editorRequest = SavingEditorRequest()` | Abre editor. |
| Editor de poupanca | `SavingsViews.swift` | `SavingEditor`, `save()`, `deleteSaving()` | Cria/edita/apaga objetivo/conta de poupanca. |
| Detalhe de poupanca | `SavingsViews.swift` | `SavingDetailView` | Mostra cabecalho, objetivo, resumo mensal, grafico e movimentos. |
| Movimentos | `SavingsViews.swift` | `SavingMovementEditor`, `save()`, `syncLinkedIncomeIfNeeded(...)` | Depositos, levantamentos e ajustes; pode criar rendimento ligado na Conta Corrente. |
| Textos | `SavingsDomain.swift` | `SavingsTextKey`, `SavingsStrings.text(...)` | Labels e validacoes de poupanca. |

## Componentes reutilizaveis

| Componente | Ficheiro | Propriedades/acoes | Serve para |
| --- | --- | --- | --- |
| `MonthPage` | `MoneyComponents.swift` | `transactions`, `payments`, `onPay`, `onEdit`, `onDelete` | Lista mensal da Conta Corrente com area `Hoje`. |
| `TransactionCard` | `MoneyComponents.swift` | `isExpanded`, `onExpansionChange`, `onPay`, `onEdit`, `onDelete` | Card expansivel de despesa/rendimento. |
| `SettingsTransactionCard` | `MoneyComponents.swift` | `onEdit`, `onDelete`, `isExpanded` | Card usado em listas de Gestao/recorrentes. |
| `BudgetStatusCard` | `MoneyComponents.swift` | `month`, `transactions`, `payments`, `budgetIncome` | Estado do orcamento mensal e explicacao de consumo. |
| `MoneyAmountPicker` | `MoneyComponents.swift` | `amount`, `maximumAmount`, `onConfirm` | Input numerico de dinheiro. Botao `Confirmar` usa `keyboard.chevron.compact.down`. |
| `PaymentAmountPicker` | `MoneyComponents.swift` | `onConfirm`, `onDeleteHistoryEntry` | Pagamento parcial/total de despesas. |
| `ValidationBanner` | `MoneyComponents.swift` | `message`, `shakeBanner()` | Mensagens de validacao com destaque visual. |
| `HelpIconButton` | `MoneyComponents.swift` | `title`, `message` | Icone de informacao com alert. |
| `SummaryTile` | `MoneyComponents.swift` | `title`, `value`, `helpText`, `footnote` | Cards pequenos de resumo. |
| `RecurringList` | `MoneyComponents.swift` | `transactions`, `onEdit`, `onDelete` | Lista de recorrentes em Gestao. |
| `DayPicker` | `TransactionEditor.swift` | `month`, `selectedDay` | Seleciona dia valido do mes. |
| `TransactionDatePicker` | `TransactionEditor.swift` | `selectedDate`, `title` | Seleciona data completa. |

## Variaveis de texto

### Textos gerais da app

| Enum | Ficheiro | Funcao | Conteudo |
| --- | --- | --- | --- |
| `AppLanguage` | `AppStrings.swift` | `currentLanguage` | Linguas suportadas: portugues e ingles. |
| `AppTextKey` | `AppStrings.swift` | Chaves de texto globais | Labels, titulos, validacoes, mensagens de ajuda, filtros, analises, wizard e textos de orcamento. |
| `AppStrings.text(_:)` | `AppStrings.swift` | Resolve texto pela lingua atual | Vai buscar `textValues[currentLanguage]` e faz fallback para portugues. |

Principais grupos de `AppTextKey`:

| Grupo | Chaves principais |
| --- | --- |
| Navegacao | `appName`, `currentAccount`, `credits`, `management`, `settings`, `back`, `next`, `ok`, `cancel`, `save` |
| Conta Corrente | `balanceThisMonth`, `monthUnpaid`, `monthRemaining`, `monthBudgetExceeded`, `today`, `noTransactions`, `pay`, `paid`, `notPaid`, `canStillSpend`, `paymentHistory` |
| Ajuda/resumos | `balanceThisMonthHelp`, `monthUnpaidHelp`, `monthRemainingHelp`, `reservedBalanceHelpTitle`, `reservedBalanceHelpMessage` |
| Movimentos | `expense`, `income`, `expenseType`, `classification`, `category503020`, `day`, `value`, `freeText`, `receivedDate`, `useInBudget`, `budgetMonth` |
| Recorrencia | `recurrence`, `periodicity`, `monthlyRecurrence`, `quarterlyRecurrence`, `semiannualRecurrence`, `annualRecurrence`, `endDate`, `noEndDate` |
| Editores | `newExpense`, `editExpense`, `newIncome`, `editIncome`, `newMonthlyExpense`, `editMonthlyExpense`, `newSalary`, `editSalary`, `newRecurringSavingExpense`, `newRecurringCreditPaymentExpense` |
| Validacoes | `fillValue`, `selectExpenseType`, `selectExpenseName`, `fillName`, `fillFreeText`, `incomeNameRequired`, `incomeValueRequired`, `expenseValueRequired` |
| Gestao/backup | `appSettings`, `preferences`, `dataPrivacy`, `aboutSpendWise`, `exportBackup`, `importBackup`, `deleteAllData`, `backupInfoTitle` |
| Wizard | `setupProgressTitle`, `setupWelcomeTitle`, `setupIncomeCardTitle`, `setupExpensesTitle`, `setupSummaryTitle`, `visualSummary`, `automaticAnalysis`, `setupFinalNote` |
| Analises | `monthAnalysis`, `whereSpent`, `budgetRule`, `actualExpenses`, `reference503020`, `subscriptionsThisMonth`, `incomeVsExpenses`, `netWorth`, `creditAnalysis`, `savingsAnalysis` |
| Insights | `restaurantsIncreasedInsight`, `groceriesDecreasedInsight`, `futureIncomeReceivedInsight`, `futureIncomeReservedInsight`, `creditPayoffInsight`, `savingTargetReachedInsight`, `balancedBudgetSurplusInsight` |

### Textos de creditos

| Enum | Ficheiro | Funcao | Chaves principais |
| --- | --- | --- | --- |
| `CreditTextKey` | `CreditDomain.swift` | Chaves especificas de creditos | `settingsTitle`, `emptyTitle`, `addCredit`, `newCredit`, `editCredit`, `creditName`, `creditType`, `currentDebt`, `creditLimit`, `debt`, `movements`, `addMovement`, `debtEvolution`, `paymentEstimateTrajectory`, `averageLastThreeMonths`, `fillCreditName`, `fillCreditValue`, `fillMovementValue` |
| `CreditStrings.text(_:)` | `CreditDomain.swift` | Resolve textos PT/EN de creditos | Usado em `CreditViews.swift`. |

### Textos de poupancas

| Enum | Ficheiro | Funcao | Chaves principais |
| --- | --- | --- | --- |
| `SavingsTextKey` | `SavingsDomain.swift` | Chaves especificas de poupancas | `settingsTitle`, `emptyTitle`, `addSaving`, `newSaving`, `editSaving`, `savingName`, `targetAmount`, `currentSaved`, `saved`, `target`, `movements`, `addMovement`, `savingEvolution`, `monthSummary`, `fillSavingName`, `fillSavingValue`, `transferToIncome` |
| `SavingsStrings.text(_:)` | `SavingsDomain.swift` | Resolve textos PT/EN de poupancas | Usado em `SavingsViews.swift`. |

## Fluxos importantes

### Criar despesa pontual

1. `ContentView.quickActionsBar` abre `TransactionEditorRequest(mode: .expense, month: selectedMonth)`.
2. `TransactionEditor.save()` valida categoria, tipo, texto livre e valor.
3. `TransactionEditor.saveExpense(...)` cria/atualiza `MoneyTransaction`.
4. Se marcada como paga, `markAsFullyPaidIfNeeded(...)` cria `ExpensePayment` e `PaymentHistoryEntry`.

### Criar despesa recorrente

1. `SettingsEditor.recurringActionsBar` abre `TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)`.
2. `TransactionEditor` guarda `recurrenceType`, `monthStart`, `recurrenceEndMonthStart` e classificacao.
3. `MoneyCalculationService.visibleTransactions(in:)` passa a gerar a ocorrencia correta em cada mes.
4. `RecurringList` e `SettingsTransactionCard` mostram a configuracao em Gestao.

### Editar despesa recorrente

1. `SettingsEditor.editRecurringTransaction(...)` chama `confirmedEditStartMonth(for:)`.
2. Se existir ocorrencia no mes atual sem pagamentos, permite alterar mes atual e seguintes.
3. Se existir pagamento parcial/total no mes atual, altera a partir do mes seguinte.
4. `TransactionEditor.finishSaving(...)` fecha a recorrencia antiga e cria nova configuracao.

### Pagar uma despesa

1. `TransactionCard.onPay` abre `PaymentAmountPicker`.
2. `PaymentAmountPicker.confirmPayment()` valida valor, pagamento futuro e sobrepagamento.
3. `ContentView.addPaymentAmount(...)` atualiza `ExpensePayment` e cria `PaymentHistoryEntry`.
4. `ContentView.syncLinkedCreditPayment(...)` ou `syncLinkedSavingDeposit(...)` sincroniza movimentos ligados quando aplicavel.

### Rendimento recebido noutro mes de orcamento

1. `TransactionEditor` recolhe `receivedDate`, `BudgetAllocation` e, se necessario, `budgetMonth`.
2. `MoneyTransaction.budgetMonth(forReceivedMonth:)` calcula o mes efetivo de orcamento.
3. `MoneyCalculationService.accountSummary(until:)` inclui o valor no saldo real quando recebido.
4. `MoneyCalculationService.incomeTotal(in:)` inclui o valor apenas no mes de orcamento.
5. `reservedIncomeForFutureBudgets(until:)` alimenta informacao discreta no saldo disponivel.

## Onde procurar quando alterar comportamento

| Alteracao pretendida | Comecar por |
| --- | --- |
| Texto/label/mensagem | `AppStrings.swift`, `CreditDomain.swift`, `SavingsDomain.swift` |
| Cores, superficies e sombras | `AppPalette.swift` |
| Tipo/categoria/icones de despesa | `MoneyDomain.swift` |
| Lista da Conta Corrente | `MoneyComponents.swift` (`MonthPage`, `TransactionCard`) e `ContentView.swift` (`filteredTransactions`) |
| Calculo de saldo/orcamento/analises | `MoneyCalculationService.swift` |
| Criar/editar movimentos | `TransactionEditor.swift` |
| Recorrentes em Gestao | `SettingsEditor.swift`, `MoneyComponents.swift` |
| Creditos | `CreditViews.swift`, `CreditDomain.swift` |
| Poupancas | `SavingsViews.swift`, `SavingsDomain.swift` |
| Wizard inicial | `InitialSetupWizardView.swift` |
