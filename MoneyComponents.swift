//
//  MoneyComponents.swift
//  MoneyControl
//

import SwiftUI

struct MonthPage: View {
    let month: Date
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let paymentHistory: [PaymentHistoryEntry]
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    let onPay: (MoneyTransaction, Date, Double) -> Void
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void

    @State private var expandedTransactionID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if transactions.isEmpty {
                ContentUnavailableView(
                    AppStrings.text(.noTransactions),
                    systemImage: "calendar",
                    description: Text(AppStrings.text(.noTransactionsDescription))
                )
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !todayTransactions.isEmpty {
                        todaySection
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(AppPalette.appBackground)
                    }

                    if !remainingTransactions.isEmpty {
                        ForEach(remainingTransactions, id: \.id) { transaction in
                            transactionCard(for: transaction, includesHorizontalPadding: false)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(AppPalette.appBackground)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppPalette.appBackground)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppPalette.appBackground)
    }

    private var todayTransactions: [MoneyTransaction] {
        let calendar = Calendar.current
        guard calendar.isDate(month, equalTo: Date(), toGranularity: .month) else { return [] }

        let todayDay = calendar.component(.day, from: Date())
        return transactions.filter { $0.effectiveDay(in: month) == todayDay }
    }

    private var remainingTransactions: [MoneyTransaction] {
        let todayIDs = Set(todayTransactions.map(\.id))
        return transactions.filter { !todayIDs.contains($0.id) }
    }

    private var todaySection: some View {
        todaySectionCard
    }

    private var todaySectionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(AppStrings.text(.today))
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)
                .frame(height: 18, alignment: .center)

            todayTransactionsList
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, 12)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppPalette.separator, lineWidth: 1)
        }
        .shadow(color: AppPalette.background.opacity(0.08), radius: 14, y: 8)
    }

    @ViewBuilder
    private var todayTransactionsList: some View {
        VStack(spacing: 8) {
            ForEach(todayTransactions, id: \.id) { transaction in
                transactionCard(for: transaction, includesHorizontalPadding: false)
            }
        }
        .padding(.vertical, 2)
    }

    private func transactionCard(for transaction: MoneyTransaction, includesHorizontalPadding: Bool) -> some View {
        let paidAmount = amountPaid(for: transaction)

        return TransactionCard(
            transaction: transaction,
            month: month,
            amountPaid: paidAmount,
            hasPaymentHistory: hasPaymentHistory(for: transaction),
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            isExpanded: expandedTransactionID == transaction.id,
            onExpansionChange: { isExpanded in
                expandedTransactionID = isExpanded ? transaction.id : nil
            },
            onPay: { onPay(transaction, month, paidAmount) },
            onEdit: { onEdit(transaction) },
            onDelete: { onDelete(transaction) }
        )
        .padding(.horizontal, includesHorizontalPadding ? 16 : 0)
    }

    private func amountPaid(for transaction: MoneyTransaction) -> Double {
        guard transaction.kind == TransactionKind.expense.rawValue else { return 0 }
        guard let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else { return 0 }
        return min(payment.amountPaid ?? transaction.amount, transaction.amount)
    }

    private func hasPaymentHistory(for transaction: MoneyTransaction) -> Bool {
        guard transaction.kind == TransactionKind.expense.rawValue else { return false }
        return paymentHistory.contains {
            $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month)
        }
    }

}

struct BudgetStatusCard: View {
    let month: Date
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    var budgetIncome: Double? = nil
    var isCompact = false

    @State private var showsDetails = false
    @State private var emojiShake = 0.0

    private var income: Double {
        if let budgetIncome {
            return budgetIncome
        }

        return transactions
            .filter { $0.kind == TransactionKind.income.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private var expenses: Double {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private var unpaid: Double {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { total, transaction in
                total + max(transaction.amount - paidAmount(for: transaction), 0)
            }
    }

    private var consumedRatio: Double {
        guard income > 0 else { return expenses > 0 ? 1 : 0 }
        return expenses / income
    }

    private var availableRatio: Double {
        max(1 - consumedRatio, 0)
    }

    private var state: BudgetStatusState {
        if income <= 0 && expenses <= 0 {
            return BudgetStatusState(
                message: AppStrings.text(.budgetStatusNoData),
                color: AppPalette.secondary,
                emoji: "🙂"
            )
        }

        if consumedRatio > 1 {
            return BudgetStatusState(message: AppStrings.text(.budgetStatusExceeded), color: AppPalette.primary, emoji: budgetEmoji)
        }

        if categoryRatio(.needs) > 0.50 {
            return BudgetStatusState(message: AppStrings.text(.budgetStatusNeedsExceeded), color: AppPalette.warning, emoji: budgetEmoji)
        }

        if categoryRatio(.wants) > 0.30 {
            return BudgetStatusState(message: AppStrings.text(.budgetStatusWantsExceeded), color: AppPalette.warning, emoji: budgetEmoji)
        }

        if categoryAmount(.savingsAndDebt) == 0, income > 0 {
            return BudgetStatusState(message: AppStrings.text(.budgetStatusNoSavings), color: AppPalette.warning, emoji: budgetEmoji)
        }

        if categoryRatio(.savingsAndDebt) < 0.20, income > 0 {
            return BudgetStatusState(message: AppStrings.text(.budgetStatusSavingsBelowGoal), color: AppPalette.warning, emoji: budgetEmoji)
        }

        if unpaid > 0 {
            return BudgetStatusState(message: AppStrings.text(.budgetStatusUnpaidExpenses), color: AppPalette.warning, emoji: budgetEmoji)
        }

        return BudgetStatusState(message: AppStrings.text(.budgetStatusHealthy), color: AppPalette.positive, emoji: budgetEmoji)
    }

    private var budgetEmoji: String {
        switch consumedRatio {
        case ...0.40:
            "😍"
        case ...0.60:
            "😀"
        case ...0.80:
            "🙂"
        case ...0.95:
            "😐"
        case ...1.0:
            "😟"
        default:
            "😱"
        }
    }

    private var detailMessage: String {
        let consumed = consumedRatio.formatted(.percent.precision(.fractionLength(0)))
        let available = availableRatio.formatted(.percent.precision(.fractionLength(0)))
        let explanation = consumedRatio <= 1
            ? AppStrings.text(.budgetStatusDetailHealthyExplanation)
            : AppStrings.text(.budgetStatusDetailExceededExplanation)

        return "\(AppStrings.text(.budgetStatusDetailConsumedTitle))\n\(String(format: AppStrings.text(.budgetStatusDetailConsumedMessage), consumed))\n\n\(AppStrings.text(.budgetStatusDetailAvailableTitle))\n\(String(format: AppStrings.text(.budgetStatusDetailAvailableMessage), available))\n\n\(explanation)"
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(state.color)
                .frame(width: isCompact ? 4 : 5)

            Text(state.message)
                .font(isCompact ? .caption.bold() : .subheadline.bold())
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(isCompact ? 2 : nil)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: !isCompact)

            Button {
                showsDetails = true
            } label: {
                Text(state.emoji)
                    .font(isCompact ? .body : .title3)
                    .frame(width: isCompact ? 28 : 36, height: isCompact ? 28 : 36)
                    .background(state.color.opacity(0.16), in: Circle())
                    .modifier(ShakeEffect(animatableData: emojiShake))
            }
            .buttonStyle(.plain)
        }
        .padding(isCompact ? 8 : 14)
        .frame(minHeight: isCompact ? 48 : nil)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: isCompact ? 12 : 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: isCompact ? 8 : 14, y: isCompact ? 4 : 7)
        .alert(AppStrings.text(.budgetStatusDetailsTitle), isPresented: $showsDetails) {
            Button(AppStrings.text(.ok)) {}
        } message: {
            Text(detailMessage)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: 0.55)) {
                    emojiShake += 1
                }
            }
        }
    }

    private func categoryAmount(_ category: ExpenseCategory) -> Double {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.expenseCategory == category.rawValue }
            .reduce(0) { $0 + $1.amount }
    }

    private func categoryRatio(_ category: ExpenseCategory) -> Double {
        guard income > 0 else { return 0 }
        return categoryAmount(category) / income
    }

    private func paidAmount(for transaction: MoneyTransaction) -> Double {
        guard let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else {
            return 0
        }
        return min(payment.amountPaid ?? transaction.amount, transaction.amount)
    }
}

private struct BudgetStatusState {
    let message: String
    let color: Color
    let emoji: String
}

private struct ShakeEffect: GeometryEffect {
    var animatableData: Double

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: sin(animatableData * .pi * 6) * 3, y: 0))
    }
}

struct TransactionCard: View {
    let transaction: MoneyTransaction
    let month: Date
    let amountPaid: Double
    let hasPaymentHistory: Bool
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    let isExpanded: Bool
    let onExpansionChange: (Bool) -> Void
    let onPay: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showsDeleteConfirmation = false

    private var category: ExpenseCategory? {
        ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
    }

    private var isExpense: Bool {
        transaction.kind == TransactionKind.expense.rawValue
    }

    private var unpaidRatio: Double {
        guard isExpense, transaction.amount > 0 else { return 0 }
        return min(max((transaction.amount - amountPaid) / transaction.amount, 0), 1)
    }

    private var paidRatio: Double {
        guard isExpense, transaction.amount > 0 else { return 0 }
        return min(max(amountPaid / transaction.amount, 0), 1)
    }

    private var paidPercentageText: String {
        paidRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    private var isFullyPaid: Bool {
        isExpense && amountPaid >= transaction.amount
    }

    private var hasPartialPayment: Bool {
        isExpense && amountPaid > 0 && !isFullyPaid
    }

    private var freeTextTitle: String? {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isExpense else { return nil }

        let linkedAccountName = linkedCreditName ?? linkedSavingName
        if !trimmedTitle.isEmpty, let linkedAccountName {
            return "\(trimmedTitle) - \(linkedAccountName)"
        }
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }
        return linkedAccountName
    }

    private var compactTitle: String {
        if isExpense {
            return freeTextTitle ?? transaction.displayName
        }
        return transaction.displayName
    }

    private var paymentStatusText: String {
        if isFullyPaid {
            return AppStrings.text(.paid)
        }
        if hasPartialPayment {
            let prefix = usesRemainingSpendStatus ? AppStrings.text(.canStillSpend) : AppStrings.text(.notPaid)
            return "\(prefix) \(max(transaction.amount - amountPaid, 0).currencyText)"
        }
        return AppStrings.text(.notPaid)
    }

    private var usesRemainingSpendStatus: Bool {
        guard isExpense else { return false }
        return Self.remainingSpendExpenseNames.contains(normalized(transaction.displayName))
    }

    private static let remainingSpendExpenseNames: Set<String> = [
        "alimentacao: compras de supermercado",
        "transportes: transporte publico, prestacoes e combustivel",
        "refeicoes fora de casa",
        "viagens e ferias",
        "atividades de lazer e entretenimento",
        "roupa e acessorios"
    ]

    private var linkedCreditName: String? {
        guard let linkedCreditID = transaction.linkedCreditID else { return nil }
        return creditAccounts.first { $0.id == linkedCreditID }?.name
    }

    private var linkedSavingName: String? {
        guard let linkedSavingID = transaction.linkedSavingID else { return nil }
        return savingAccounts.first { $0.id == linkedSavingID }?.name
    }

    private var paymentProgressSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(AppStrings.text(.paid))
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.background)
                Spacer()
                Text(paidPercentageText)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.background)
            }

            if hasPartialPayment {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        AppPalette.separator
                        AppPalette.mediumGreen
                            .frame(width: proxy.size.width * paidRatio)
                    }
                }
                .frame(height: 7)
                .clipShape(Capsule())
            }

            Text("\(amountPaid.currencyText) \(AppStrings.text(.ofAmount)) \(transaction.amount.currencyText)")
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var compactPaymentStatus: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("\(AppStrings.text(.paid)) \(paidPercentageText)")
                .font(.caption2.bold())
                .foregroundStyle(AppPalette.background)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    AppPalette.separator
                    AppPalette.mediumGreen
                        .frame(width: proxy.size.width * paidRatio)
                }
            }
            .frame(width: 92, height: 7)
            .clipShape(Capsule())

            Text("\(amountPaid.currencyText) \(AppStrings.text(.ofAmount)) \(transaction.amount.currencyText)")
                .font(.caption2)
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var detailTextWithoutFreeText: String {
        guard freeTextTitle != nil else {
            return transaction.detailText(in: month)
        }

        var parts = ["\(AppStrings.text(.day)) \(transaction.effectiveDay(in: month))"]

        if let category {
            parts.append(category.title)
        }

        switch transaction.recurrence {
        case .monthly, .quarterly, .semiannual, .annual:
            parts.append(transaction.recurrence?.title ?? AppStrings.text(.everyMonth))
            if let recurrenceEndMonthStart = transaction.recurrenceEndMonthStart {
                parts.append("\(AppStrings.text(.endDate)) \(recurrenceEndMonthStart.previousMonthStart.monthTitle)")
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            break
        }

        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasPartialPayment {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        AppPalette.separator
                        LinearGradient(
                            colors: [AppPalette.primary, AppPalette.primary.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                            .frame(width: proxy.size.width * unpaidRatio)
                    }
                }
                .frame(height: 4)
            }

            Button {
                onExpansionChange(!isExpanded)
            } label: {
                HStack(spacing: 8) {
                    transactionIcon

                    VStack(alignment: .leading, spacing: 3) {
                        Text(compactTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)
                            .lineLimit(1)

                        compactSubtitleView
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(transaction.amount.currencyText)
                            .font(.subheadline.bold())
                            .foregroundStyle(transaction.kind == TransactionKind.income.rawValue ? AppPalette.positive : AppPalette.primary)

                        if isExpense {
                            Text(paymentStatusText)
                                .font(.caption.bold())
                                .foregroundStyle(isFullyPaid ? AppPalette.positive : AppPalette.mutedText)
                        }
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(AppPalette.mutedText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if isExpense {
                        Text(expandedDetailText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.mutedText)

                        paymentProgressSummary
                    } else {
                        Text(transaction.detailText(in: month))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.mutedText)
                    }

                    HStack(spacing: 10) {
                        if isExpense {
                            Button {
                                collapse()
                                onPay()
                            } label: {
                                CompactActionLabel(title: paymentButtonTitle, systemImage: paymentButtonIcon)
                                    .foregroundStyle(paymentButtonForeground)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(paymentButtonBackground, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8).stroke(AppPalette.separator, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(isFullyPaid && !hasPaymentHistory)
                        }

                        Button {
                            collapse()
                            onEdit()
                        } label: {
                            CompactActionLabel(title: AppStrings.text(.editPrefix), systemImage: "pencil")
                                .foregroundStyle(AppPalette.background)
                                .frame(minWidth: isExpense ? 94 : nil, maxWidth: isExpense ? 94 : .infinity, minHeight: 40)
                                .background(AppPalette.paleOrange, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            showsDeleteConfirmation = true
                        } label: {
                            CompactActionLabel(title: AppStrings.text(.delete), systemImage: "trash")
                                .frame(minWidth: isExpense ? 94 : nil, maxWidth: isExpense ? 94 : .infinity, minHeight: 40)
                                .background(AppPalette.destructive, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption.bold())
                }
                .foregroundStyle(AppPalette.background)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 14, y: 8)
        .alert(deleteConfirmationTitle, isPresented: $showsDeleteConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(AppStrings.text(.delete), role: .destructive) {
                collapse()
                onDelete()
            }
        }
    }

    private func collapse() {
        onExpansionChange(false)
    }

    private var paymentButtonTitle: String {
        isFullyPaid && hasPaymentHistory ? AppStrings.text(.paymentHistory) : AppStrings.text(.pay)
    }

    private var paymentButtonIcon: String {
        isFullyPaid && hasPaymentHistory ? "clock.arrow.circlepath" : "creditcard"
    }

    private var paymentButtonForeground: Color {
        isFullyPaid && !hasPaymentHistory ? AppPalette.mutedText : AppPalette.background
    }

    private var paymentButtonBackground: Color {
        isFullyPaid && !hasPaymentHistory ? AppPalette.separator : AppPalette.mintSurface
    }

    @ViewBuilder
    private var compactSubtitleView: some View {
        if let subscriptionRecurrenceData {
            SubscriptionRecurrenceLabel(
                day: subscriptionRecurrenceData.day,
                monthName: subscriptionRecurrenceData.monthName,
                recurrenceTitle: subscriptionRecurrenceData.recurrenceTitle
            )
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)
            .lineLimit(1)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("\(AppStrings.text(.day)) ")
                    Text("\(transaction.effectiveDay(in: month))")
                        .fontWeight(.bold)
                    if isExpense {
                        Text(" - \(transaction.displayName)")
                    }
                }
                .lineLimit(1)

                if let recurrenceMonthName = recurrenceMonthName(in: month) {
                    RecurrenceMonthLabel(monthName: recurrenceMonthName)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)
        }
    }

    private var subscriptionRecurrenceData: (day: Int, monthName: String?, recurrenceTitle: String?)? {
        guard isSubscriptionExpense else { return nil }
        return subscriptionRecurrenceData(day: transaction.effectiveDay(in: month), month: month)
    }

    private var isSubscriptionExpense: Bool {
        isExpense && normalized("\(transaction.displayName) \(transaction.title)").contains("subscr")
    }

    private func subscriptionRecurrenceData(day: Int, month: Date) -> (day: Int, monthName: String?, recurrenceTitle: String?) {
        switch transaction.recurrence {
        case .monthly:
            return (day, nil, RecurrenceType.monthly.title)
        case .quarterly, .semiannual, .annual:
            return (day, Date.monthName(forMonthNumber: month.monthNumber), transaction.recurrence?.title)
        case .yearlyMonth:
            return (day, Date.monthName(forMonthNumber: transaction.recurrenceMonth), AppStrings.text(.annualRecurrence))
        case nil:
            return (day, nil, nil)
        }
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }

    private func recurrenceMonthName(in month: Date) -> String? {
        guard isExpense else { return nil }

        switch transaction.recurrence {
        case .monthly, nil:
            return nil
        case .quarterly, .semiannual, .annual:
            return month.monthTitle
        case .yearlyMonth:
            return Date.monthName(forMonthNumber: transaction.recurrenceMonth)
        }
    }

    private var expandedDetailText: String {
        var parts: [String] = []
        if let category {
            parts.append(category.title)
        }

        switch transaction.recurrence {
        case .monthly, .quarterly, .semiannual, .annual:
            parts.append(transaction.recurrence?.title ?? AppStrings.text(.everyMonth))
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            if transaction.kind == TransactionKind.expense.rawValue {
                parts.append(AppStrings.text(.onlyThisMonth))
            }
        }

        return parts.joined(separator: " · ")
    }

    private var deleteConfirmationTitle: String {
        let type = transaction.kind == TransactionKind.expense.rawValue ? AppStrings.text(.expenseLowercase) : AppStrings.text(.incomeLowercase)
        return "\(AppStrings.text(.deleteConfirmation)) - \(type) \(transaction.amount.currencyText)"
    }

    private var transactionIcon: some View {
        let iconName: String
        let iconBackground: Color
        let iconColor: Color

        if isExpense {
            iconName = ExpenseTypeIcon.name(for: transaction.displayName)
            iconBackground = (category?.color ?? AppPalette.primary).opacity(0.18)
            iconColor = category?.color ?? AppPalette.primary
        } else {
            iconName = "banknote.fill"
            iconBackground = AppPalette.mintSurface
            iconColor = AppPalette.positive
        }

        return Image(systemName: iconName)
            .font(.subheadline)
            .foregroundStyle(iconColor)
            .frame(width: 42, height: 42)
            .background(iconBackground, in: Circle())
    }
}

private struct CompactActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(title)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct SubscriptionRecurrenceLabel: View {
    let day: Int
    let monthName: String?
    let recurrenceTitle: String?

    var body: some View {
        HStack(spacing: 0) {
            Text("\(AppStrings.text(.day)) ")
            Text("\(day)")
                .fontWeight(.bold)

            if let monthName {
                Text(" - ")
                Text(monthName)
                    .fontWeight(.bold)
            }

            if let recurrenceTitle {
                Text(" - \(recurrenceTitle)")
            }
        }
    }
}

private struct RecurrenceMonthLabel: View {
    let monthName: String

    var body: some View {
        HStack(spacing: 0) {
            Text("\(AppStrings.text(.month)) ")
            Text(monthName)
                .fontWeight(.bold)
        }
    }
}

struct SettingsTransactionCard: View {
    let transaction: MoneyTransaction
    let isExpanded: Bool
    let onExpansionChange: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showsDeleteConfirmation = false

    private var category: ExpenseCategory? {
        ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
    }

    private var isExpense: Bool {
        transaction.kind == TransactionKind.expense.rawValue
    }

    private var freeTextTitle: String? {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return isExpense && !trimmedTitle.isEmpty ? trimmedTitle : nil
    }

    private var compactTitle: String {
        if isExpense {
            return freeTextTitle ?? transaction.displayName
        }
        return transaction.displayName
    }

    private var detailTextWithoutFreeText: String {
        guard freeTextTitle != nil else {
            return transaction.detailText
        }

        var parts = ["\(AppStrings.text(.day)) \(transaction.day)"]

        if let category {
            parts.append(category.title)
        }

        switch transaction.recurrence {
        case .monthly, .quarterly, .semiannual, .annual:
            parts.append(transaction.recurrence?.title ?? AppStrings.text(.everyMonth))
            if let recurrenceEndMonthStart = transaction.recurrenceEndMonthStart {
                parts.append("\(AppStrings.text(.endDate)) \(recurrenceEndMonthStart.previousMonthStart.monthTitle)")
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            break
        }

        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onExpansionChange(!isExpanded)
            } label: {
                HStack(spacing: 8) {
                    transactionIcon

                    VStack(alignment: .leading, spacing: 3) {
                        Text(compactTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)
                            .lineLimit(1)

                        compactSubtitleView
                    }

                    Spacer()

                    Text(transaction.amount.currencyText)
                        .font(.subheadline.bold())
                        .foregroundStyle(transaction.kind == TransactionKind.income.rawValue ? AppPalette.positive : AppPalette.primary)

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(AppPalette.mutedText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text(expandedDetailText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.mutedText)

                    HStack(spacing: 10) {
                        Button {
                            onExpansionChange(false)
                            onEdit()
                        } label: {
                            CompactActionLabel(title: AppStrings.text(.editPrefix), systemImage: "pencil")
                                .foregroundStyle(AppPalette.background)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(AppPalette.paleOrange, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            showsDeleteConfirmation = true
                        } label: {
                            CompactActionLabel(title: AppStrings.text(.delete), systemImage: "trash")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(AppPalette.destructive, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption.bold())
                }
                .foregroundStyle(AppPalette.background)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 6)
        .alert(deleteConfirmationTitle, isPresented: $showsDeleteConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(AppStrings.text(.delete), role: .destructive) {
                onExpansionChange(false)
                onDelete()
            }
        }
    }

    private var deleteConfirmationTitle: String {
        let type = transaction.kind == TransactionKind.expense.rawValue ? AppStrings.text(.expenseLowercase) : AppStrings.text(.incomeLowercase)
        return "\(AppStrings.text(.deleteConfirmation)) - \(type) \(transaction.amount.currencyText)"
    }

    @ViewBuilder
    private var compactSubtitleView: some View {
        if let subscriptionRecurrenceData {
            SubscriptionRecurrenceLabel(
                day: subscriptionRecurrenceData.day,
                monthName: subscriptionRecurrenceData.monthName,
                recurrenceTitle: subscriptionRecurrenceData.recurrenceTitle
            )
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)
            .lineLimit(1)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("\(AppStrings.text(.day)) ")
                    Text("\(transaction.day)")
                        .fontWeight(.bold)
                    if isExpense {
                        Text(" - \(transaction.displayName)")
                    }
                }
                .lineLimit(1)

                if let recurrenceMonthName {
                    RecurrenceMonthLabel(monthName: recurrenceMonthName)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)
        }
    }

    private var subscriptionRecurrenceData: (day: Int, monthName: String?, recurrenceTitle: String?)? {
        guard isSubscriptionExpense else { return nil }
        return subscriptionRecurrenceData(day: transaction.day, month: transaction.monthStart)
    }

    private var isSubscriptionExpense: Bool {
        isExpense && normalized("\(transaction.displayName) \(transaction.title)").contains("subscr")
    }

    private func subscriptionRecurrenceData(day: Int, month: Date) -> (day: Int, monthName: String?, recurrenceTitle: String?) {
        switch transaction.recurrence {
        case .monthly:
            return (day, nil, RecurrenceType.monthly.title)
        case .quarterly, .semiannual, .annual:
            return (day, Date.monthName(forMonthNumber: month.monthNumber), transaction.recurrence?.title)
        case .yearlyMonth:
            return (day, Date.monthName(forMonthNumber: transaction.recurrenceMonth), AppStrings.text(.annualRecurrence))
        case nil:
            return (day, nil, nil)
        }
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).lowercased()
    }

    private var recurrenceMonthName: String? {
        guard isExpense else { return nil }

        switch transaction.recurrence {
        case .monthly, nil:
            return nil
        case .quarterly, .semiannual, .annual:
            return transaction.monthStart.monthTitle
        case .yearlyMonth:
            return Date.monthName(forMonthNumber: transaction.recurrenceMonth)
        }
    }

    private var expandedDetailText: String {
        guard isExpense else { return detailTextWithoutFreeText }

        var parts: [String] = []
        if let category {
            parts.append(category.title)
        }

        switch transaction.recurrence {
        case .monthly, .quarterly, .semiannual, .annual:
            parts.append(transaction.recurrence?.title ?? AppStrings.text(.everyMonth))
            if let recurrenceEndMonthStart = transaction.recurrenceEndMonthStart {
                parts.append("\(AppStrings.text(.endDate)) \(recurrenceEndMonthStart.previousMonthStart.monthTitle)")
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            parts.append(AppStrings.text(.onlyThisMonth))
        }

        return parts.joined(separator: " · ")
    }

    private var transactionIcon: some View {
        let iconName: String
        let iconBackground: Color
        let iconColor: Color

        if let category {
            iconName = category.iconName
            iconBackground = category.color.opacity(0.18)
            iconColor = category.color
        } else {
            iconName = "banknote.fill"
            iconBackground = AppPalette.mintSurface
            iconColor = AppPalette.positive
        }

        return Image(systemName: iconName)
            .font(.subheadline)
            .foregroundStyle(iconColor)
            .frame(width: 42, height: 42)
            .background(iconBackground, in: Circle())
    }
}

struct PaymentAmountPicker: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""

    let title: String
    let totalAmount: Double
    let initialAmount: Double
    let paymentDate: Date
    let history: [PaymentHistoryEntry]
    let onConfirm: (Double) -> Void
    let onDeleteHistoryEntry: (PaymentHistoryEntry) -> Void

    @State private var selectedAmount: Double = 0
    @State private var paidAmountInSheet: Double = 0
    @State private var showsOverpaymentConfirmation = false
    @State private var showsFuturePaymentConfirmation = false
    @State private var hasConfirmedFuturePayment = false
    @State private var pendingHistoryDelete: PaymentHistoryEntry?
    @State private var deletedHistoryEntryIDs: Set<UUID> = []

    private var remainingAmount: Double {
        max(totalAmount - paidAmountInSheet, 0)
    }

    private var canAddPayment: Bool {
        remainingAmount > 0
    }

    private var visibleHistory: [PaymentHistoryEntry] {
        history.filter { !deletedHistoryEntryIDs.contains($0.id) }
    }

    private var isFuturePaymentDate: Bool {
        Calendar.current.startOfDay(for: paymentDate) > Calendar.current.startOfDay(for: Date())
    }

    private var formattedPaymentDate: String {
        paymentDate.formatted(.dateTime.locale(Locale(identifier: AppStrings.currentLocaleIdentifier)).day().month(.wide).year())
    }

    private var futurePaymentMessage: String {
        String(format: AppStrings.text(.futurePaymentMessage), selectedAmount.currencyText, formattedPaymentDate)
    }

    private var isShowingDeleteHistoryConfirmation: Binding<Bool> {
        Binding(
            get: { pendingHistoryDelete != nil },
            set: { isPresented in
                if !isPresented {
                    pendingHistoryDelete = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                    Text("\(AppStrings.text(.paid)): \(paidAmountInSheet.currencyText) \(AppStrings.text(.ofAmount)) \(totalAmount.currencyText)")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                }

                if canAddPayment {
                    Button {
                        selectedAmount = remainingAmount
                        confirmPayment()
                    } label: {
                        Label(AppStrings.text(.payFullAmount), systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(AppPalette.surface)
                            .frame(maxWidth: .infinity, minHeight: 88)
                            .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    MoneyAmountPicker(
                        title: AppStrings.text(.amountToPay),
                        amount: $selectedAmount,
                        maximumAmount: 1_000_000,
                        onConfirm: confirmPayment
                    )

                    Text("\(AppStrings.text(.total)): \((paidAmountInSheet + selectedAmount).currencyText)")
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                } else {
                    VStack(spacing: 6) {
                        Text(AppStrings.text(.totalPaid))
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.mutedText)
                        Text(paidAmountInSheet.currencyText)
                            .font(.title2.bold())
                            .foregroundStyle(AppPalette.background)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                }

                paymentHistorySection

                Spacer()
            }
            .padding()
            .background(AppPalette.appBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.text(.pay))
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .tint(AppPalette.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok), action: confirmPayment)
                }
            }
            .alert(AppStrings.text(.deletePaymentHistoryTitle), isPresented: isShowingDeleteHistoryConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.delete), role: .destructive) {
                    if let pendingHistoryDelete {
                        deleteHistoryEntry(pendingHistoryDelete)
                    }
                }
            } message: {
                Text(AppStrings.text(.deletePaymentHistoryMessage))
            }
            .alert(AppStrings.text(.overpaymentTitle), isPresented: $showsOverpaymentConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.ok)) {
                    performPayment()
                }
            } message: {
                Text(AppStrings.text(.overpaymentMessage))
            }
            .alert(AppStrings.text(.futurePaymentTitle), isPresented: $showsFuturePaymentConfirmation) {
                Button(AppStrings.text(.cancel), role: .cancel) {}
                Button(AppStrings.text(.ok)) {
                    hasConfirmedFuturePayment = true
                    confirmPayment()
                }
            } message: {
                Text(futurePaymentMessage)
            }
            .onAppear {
                paidAmountInSheet = initialAmount
                selectedAmount = 0
            }
            .id(selectedCurrencyCode)
        }
    }

    private func confirmPayment() {
        guard selectedAmount > 0 else {
            dismiss()
            return
        }

        if isFuturePaymentDate && !hasConfirmedFuturePayment {
            showsFuturePaymentConfirmation = true
            return
        }

        if selectedAmount > remainingAmount {
            showsOverpaymentConfirmation = true
        } else {
            performPayment()
        }
    }

    private func performPayment() {
        onConfirm(selectedAmount)
        dismiss()
    }

    @ViewBuilder
    private var paymentHistorySection: some View {
        if !visibleHistory.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.text(.paymentHistory))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)

                ForEach(visibleHistory) { entry in
                    PaymentHistoryRow(entry: entry) {
                        pendingHistoryDelete = entry
                    }
                }
            }
            .padding(12)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func deleteHistoryEntry(_ entry: PaymentHistoryEntry) {
        deletedHistoryEntryIDs.insert(entry.id)
        paidAmountInSheet = max(paidAmountInSheet - entry.amount, 0)
        selectedAmount = 0
        onDeleteHistoryEntry(entry)
    }
}

private struct PaymentHistoryRow: View {
    let entry: PaymentHistoryEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.paidAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                Text(entry.amount.currencyText)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.background)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(AppPalette.destructive, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct ValidationBanner: View {
    let message: String

    @State private var shake = 0.0

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.primary)
                .padding(.top, 2)

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.background)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.paleOrange, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppPalette.primary.opacity(0.18), lineWidth: 1)
        }
        .modifier(ShakeEffect(animatableData: shake))
        .onAppear(perform: shakeBanner)
        .onChange(of: message) { _, _ in shakeBanner() }
    }

    private func shakeBanner() {
        withAnimation(.linear(duration: 0.45)) {
            shake += 1
        }
    }
}

struct HelpIconButton: View {
    let title: String
    let message: String

    @State private var showsHelp = false

    var body: some View {
        Button {
            showsHelp = true
        } label: {
            Image(systemName: "info.circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.background)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .alert(title, isPresented: $showsHelp) {
            Button(AppStrings.text(.ok)) {}
        } message: {
            Text(message)
        }
    }
}

struct MoneyAmountPicker: View {
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""

    let title: String
    @Binding var amount: Double
    let maximumAmount: Double
    let onConfirm: (() -> Void)?

    @State private var amountText = ""
    @State private var isUpdatingText = false
    @FocusState private var isAmountFocused: Bool

    init(title: String, amount: Binding<Double>, maximumAmount: Double, onConfirm: (() -> Void)? = nil) {
        self.title = title
        self._amount = amount
        self.maximumAmount = maximumAmount
        self.onConfirm = onConfirm
    }

    private var currencySymbol: String {
        _ = selectedCurrencyCode
        return AppPreferences.selectedCurrencySymbol
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            TextField("0,00", text: $amountText)
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppPalette.background)
                .keyboardType(.decimalPad)
                .focused($isAmountFocused)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .trailing) {
                    Text(currencySymbol)
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.mutedText)
                        .padding(.trailing, 16)
                }
            .overlay {
                RoundedRectangle(cornerRadius: 14).stroke(AppPalette.separator, lineWidth: 1)
            }

            HStack(spacing: 8) {
                Button {
                    isAmountFocused = false
                    if let onConfirm {
                        onConfirm()
                    } else {
                        syncTextFromAmount()
                    }
                } label: {
                    Label(AppStrings.text(.confirm), systemImage: "keyboard.chevron.compact.down")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button {
                    amount = 0
                    isAmountFocused = false
                    syncTextFromAmount()
                } label: {
                    Label(AppStrings.text(.clear), systemImage: "trash.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(AppPalette.primary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Text(amount.currencyText)
                .font(.headline)
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear(perform: syncTextFromAmount)
        .onChange(of: amount) { _, _ in syncTextFromAmount() }
        .onChange(of: amountText) { _, newValue in updateAmount(from: newValue) }
        .onChange(of: isAmountFocused) { _, isFocused in
            if !isFocused {
                syncTextFromAmount()
            }
        }
    }

    private func syncTextFromAmount() {
        guard !isAmountFocused else { return }
        let clampedAmount = min(max(amount, 0), maximumAmount)
        if clampedAmount != amount {
            amount = clampedAmount
        }

        isUpdatingText = true
        amountText = clampedAmount == 0 ? "" : String(format: "%.2f", clampedAmount).replacingOccurrences(of: ".", with: ",")
        isUpdatingText = false
    }

    private func updateAmount(from text: String) {
        guard !isUpdatingText else { return }
        let normalizedText = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }

        guard let parsedAmount = Double(normalizedText) else {
            amount = 0
            return
        }

        amount = min(max(parsedAmount, 0), maximumAmount)
    }
}

struct SummaryTile: View {
    let title: String
    let value: Double
    let helpText: String
    var boldHelpNote: String = ""
    var footnote: String = ""
    var helpTitle: String? = nil

    @State private var showsHelp = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.trailing, 34)
                Text(value.currencyText)
                    .font(.title.bold())
                    .foregroundStyle(value < 0 ? AppPalette.primary : AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !footnote.isEmpty {
                    Text(footnote)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Button {
                showsHelp = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
        .alert(helpTitle ?? title, isPresented: $showsHelp) {
            Button(AppStrings.text(.ok)) {}
        } message: {
            if boldHelpNote.isEmpty {
                Text(helpText)
            } else {
                Text("\(helpText)\n\n\(Text(boldHelpNote).bold())")
            }
        }
    }
}

struct RecurringList: View {
    let emptyTitle: String
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void

    @State private var expandedTransactionID: UUID?

    var body: some View {
        if transactions.isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: "list.bullet.rectangle")
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(transactions, id: \.id) { transaction in
                        SettingsTransactionCard(
                            transaction: transaction,
                            isExpanded: expandedTransactionID == transaction.id,
                            onExpansionChange: { isExpanded in
                                expandedTransactionID = isExpanded ? transaction.id : nil
                            },
                            onEdit: { onEdit(transaction) },
                            onDelete: { onDelete(transaction) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
