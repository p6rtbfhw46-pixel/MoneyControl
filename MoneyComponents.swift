//
//  MoneyComponents.swift
//  MoneyControl
//

import SwiftUI

struct MonthPage: View {
    let month: Date
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let onSetPaidAmount: (MoneyTransaction, Date, Double) -> Void
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(month.monthTitle)
                .font(.title.bold())
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, -2)

            if transactions.isEmpty {
                ContentUnavailableView(
                    AppStrings.text(.noTransactions),
                    systemImage: "calendar",
                    description: Text(AppStrings.text(.noTransactionsDescription))
                )
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(transactions) { transaction in
                            TransactionCard(
                                transaction: transaction,
                                month: month,
                                amountPaid: amountPaid(for: transaction),
                                onSetPaidAmount: { onSetPaidAmount(transaction, month, $0) },
                                onEdit: { onEdit(transaction) },
                                onDelete: { onDelete(transaction) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(AppPalette.appBackground)
            }
        }
        .background(AppPalette.appBackground)
    }

    private func amountPaid(for transaction: MoneyTransaction) -> Double {
        guard transaction.kind == TransactionKind.expense.rawValue else { return 0 }
        guard let payment = payments.first(where: { $0.transactionID == transaction.id && Calendar.current.isDate($0.monthStart, equalTo: month, toGranularity: .month) }) else { return 0 }
        return min(payment.amountPaid ?? transaction.amount, transaction.amount)
    }
}

struct BudgetStatusCard: View {
    let month: Date
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    var isCompact = false

    @State private var showsDetails = false
    @State private var emojiShake = 0.0

    private var income: Double {
        transactions
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
                message: "👋 Bem-vindo! Adicione os seus rendimentos e despesas para começar a acompanhar o seu orçamento.",
                color: AppPalette.secondary,
                emoji: "🙂"
            )
        }

        if consumedRatio > 1 {
            return BudgetStatusState(message: "🚨 Já ultrapassou o orçamento disponível para este mês. Reveja as suas despesas para recuperar o equilíbrio.", color: AppPalette.primary, emoji: budgetEmoji)
        }

        if categoryRatio(.needs) > 0.50 {
            return BudgetStatusState(message: "⚠️ As despesas essenciais ultrapassaram o limite recomendado de 50% do rendimento.", color: AppPalette.warning, emoji: budgetEmoji)
        }

        if categoryRatio(.wants) > 0.30 {
            return BudgetStatusState(message: "⚠️ Os gastos em lazer e despesas pessoais ultrapassaram o orçamento recomendado.", color: AppPalette.warning, emoji: budgetEmoji)
        }

        if categoryAmount(.savingsAndDebt) == 0, income > 0 {
            return BudgetStatusState(message: "💰 Ainda não registou qualquer poupança este mês. Mesmo um pequeno valor faz diferença.", color: AppPalette.warning, emoji: budgetEmoji)
        }

        if categoryRatio(.savingsAndDebt) < 0.20, income > 0 {
            return BudgetStatusState(message: "🌱 Ainda não atingiu o objetivo de poupança recomendado para este mês.", color: AppPalette.warning, emoji: budgetEmoji)
        }

        if unpaid > 0 {
            return BudgetStatusState(message: "🧾 Ainda tem despesas por liquidar este mês.", color: AppPalette.warning, emoji: budgetEmoji)
        }

        return BudgetStatusState(message: "✅ Excelente! Está dentro do orçamento e a gerir bem as suas finanças.", color: AppPalette.positive, emoji: budgetEmoji)
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
            ? "Mantendo este ritmo, continua dentro do orçamento recomendado."
            : "Está acima do orçamento recomendado. Considere reduzir despesas nas categorias com maior impacto."

        return "Orçamento consumido\nJá utilizou \(consumed) do orçamento disponível para este mês.\n\nAinda disponível\nTem \(available) do orçamento por utilizar.\n\n\(explanation)"
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
        .alert("Estado do orçamento", isPresented: $showsDetails) {
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
    let onSetPaidAmount: (Double) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showsDeleteConfirmation = false
    @State private var showsPaymentPicker = false

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

    private var isFullyPaid: Bool {
        isExpense && amountPaid >= transaction.amount
    }

    private var freeTextTitle: String? {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return isExpense && !trimmedTitle.isEmpty ? trimmedTitle : nil
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
        case .monthly:
            parts.append(AppStrings.text(.everyMonth))
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
            if isExpense {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        AppPalette.separator
                        AppPalette.primary
                            .frame(width: proxy.size.width * unpaidRatio)
                    }
                }
                .frame(height: 7)
            }

            Button {
                withAnimation(.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    transactionIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.displayName)
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        Text(detailTextWithoutFreeText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.mutedText)
                            .lineLimit(2)

                        if let freeTextTitle {
                            Text(freeTextTitle)
                                .font(.caption.bold())
                                .foregroundStyle(AppPalette.darkBlue)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(transaction.amount.currencyText)
                            .font(.headline)
                            .foregroundStyle(transaction.kind == TransactionKind.income.rawValue ? AppPalette.positive : AppPalette.primary)

                        if isExpense {
                            Text("\(amountPaid.currencyText) / \(transaction.amount.currencyText)")
                                .font(.caption2)
                                .foregroundStyle(AppPalette.mutedText)
                        }
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(AppPalette.mutedText)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(spacing: 10) {
                    if isExpense {
                        Button {
                            showsPaymentPicker = true
                        } label: {
                            Label(AppStrings.text(.pay), systemImage: "creditcard")
                                .foregroundStyle(isFullyPaid ? AppPalette.mutedText : AppPalette.background)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(isFullyPaid ? AppPalette.separator : AppPalette.mintSurface, in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8).stroke(AppPalette.separator, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(isFullyPaid)
                    }

                    Button {
                        collapse()
                        onEdit()
                    } label: {
                        Label(AppStrings.text(.editPrefix), systemImage: "pencil")
                            .foregroundStyle(AppPalette.background)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(AppPalette.paleOrange, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label(AppStrings.text(.delete), systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(AppPalette.destructive, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption.bold())
                .foregroundStyle(AppPalette.background)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 14, y: 8)
        .sheet(isPresented: $showsPaymentPicker) {
            PaymentAmountPicker(
                title: transaction.displayName,
                totalAmount: transaction.amount,
                initialAmount: amountPaid,
                onConfirm: { amount in
                    onSetPaidAmount(amount)
                    collapse()
                }
            )
        }
        .alert(deleteConfirmationTitle, isPresented: $showsDeleteConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(AppStrings.text(.delete), role: .destructive) {
                collapse()
                onDelete()
            }
        }
    }

    private func collapse() {
        withAnimation(.snappy) {
            isExpanded = false
        }
    }

    private var deleteConfirmationTitle: String {
        let type = transaction.kind == TransactionKind.expense.rawValue ? AppStrings.text(.expenseLowercase) : AppStrings.text(.incomeLowercase)
        return "\(AppStrings.text(.deleteConfirmation)) - \(type) \(transaction.amount.currencyText)"
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
            .font(.title3)
            .foregroundStyle(iconColor)
            .frame(width: 54, height: 54)
            .background(iconBackground, in: Circle())
    }
}

struct SettingsTransactionCard: View {
    let transaction: MoneyTransaction
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showsDeleteConfirmation = false

    private var category: ExpenseCategory? {
        ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    transactionIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.displayName)
                            .font(.headline)
                            .foregroundStyle(AppPalette.background)

                        Text(transaction.detailText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.mutedText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text(transaction.amount.currencyText)
                        .font(.headline)
                        .foregroundStyle(transaction.kind == TransactionKind.income.rawValue ? AppPalette.positive : AppPalette.primary)

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(AppPalette.mutedText)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(spacing: 10) {
                    Button(action: onEdit) {
                        Label(AppStrings.text(.editPrefix), systemImage: "pencil")
                            .foregroundStyle(AppPalette.background)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(AppPalette.paleOrange, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label(AppStrings.text(.delete), systemImage: "trash")
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(AppPalette.destructive, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption.bold())
                .foregroundStyle(AppPalette.background)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 6)
        .alert(deleteConfirmationTitle, isPresented: $showsDeleteConfirmation) {
            Button(AppStrings.text(.cancel), role: .cancel) {}
            Button(AppStrings.text(.delete), role: .destructive, action: onDelete)
        }
    }

    private var deleteConfirmationTitle: String {
        let type = transaction.kind == TransactionKind.expense.rawValue ? AppStrings.text(.expenseLowercase) : AppStrings.text(.incomeLowercase)
        return "\(AppStrings.text(.deleteConfirmation)) - \(type) \(transaction.amount.currencyText)"
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
            .font(.title3)
            .foregroundStyle(iconColor)
            .frame(width: 50, height: 50)
            .background(iconBackground, in: Circle())
    }
}

struct PaymentAmountPicker: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let totalAmount: Double
    let initialAmount: Double
    let onConfirm: (Double) -> Void

    @State private var selectedAmount: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                    Text("\(AppStrings.text(.total)): \(totalAmount.currencyText)")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                }

                Button {
                    selectedAmount = totalAmount
                    onConfirm(totalAmount)
                    dismiss()
                } label: {
                    Label(AppStrings.text(.payFullAmount), systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(AppPalette.surface)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                MoneyAmountPicker(
                    title: AppStrings.text(.paidAmount),
                    amount: $selectedAmount,
                    maximumAmount: totalAmount,
                    onConfirm: {
                        onConfirm(selectedAmount)
                        dismiss()
                    }
                )

                Text("\(selectedAmount.currencyText) / \(totalAmount.currencyText)")
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

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
                    Button(AppStrings.text(.ok)) {
                        onConfirm(selectedAmount)
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedAmount = min(max(initialAmount, 0), totalAmount)
            }
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
            Text("?")
                .font(.caption.bold())
                .foregroundStyle(AppPalette.background)
                .frame(width: 28, height: 28)
                .background(AppPalette.accent, in: Circle())
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
                    Text("€")
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
                    Label("Confirmar", systemImage: "checkmark.circle.fill")
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
                    Label("Limpar", systemImage: "trash.fill")
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
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Button {
                showsHelp = true
            } label: {
                Text("?")
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 28, height: 28)
                    .background(AppPalette.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
        .alert(title, isPresented: $showsHelp) {
            Button(AppStrings.text(.ok)) {}
        } message: {
            Text(helpText)
        }
    }
}

struct CarouselNavigationButtons: View {
    @Binding var selection: Int
    let lowerBound: Int
    let upperBound: Int

    var body: some View {
        HStack {
            Button {
                selection = max(selection - 1, lowerBound)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(AppPalette.primary)
                    .frame(width: 44, height: 42)
            }
            .buttonStyle(.plain)
            .disabled(selection <= lowerBound)
            .opacity(selection <= lowerBound ? 0.35 : 1)

            Spacer()

            Button {
                selection = min(selection + 1, upperBound)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppPalette.primary)
                    .frame(width: 44, height: 42)
            }
            .buttonStyle(.plain)
            .disabled(selection >= upperBound)
            .opacity(selection >= upperBound ? 0.35 : 1)
        }
    }
}

struct RecurringList: View {
    let emptyTitle: String
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void

    var body: some View {
        if transactions.isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: "list.bullet.rectangle")
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(transactions) { transaction in
                        SettingsTransactionCard(
                            transaction: transaction,
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
