import SwiftUI

enum CurrentAccountCalendarStyle {
    static func icon(for transaction: MoneyTransaction) -> String {
        if transaction.kind == TransactionKind.income.rawValue {
            return "banknote.fill"
        }
        return ExpenseTypeIcon.name(for: transaction.displayName)
    }

    static func backgroundColor(for transaction: MoneyTransaction) -> Color {
        if transaction.kind == TransactionKind.income.rawValue {
            return AppPalette.mintSurface
        }
        return expenseCategoryColor(for: transaction).opacity(0.18)
    }

    static func textColor(for transaction: MoneyTransaction) -> Color {
        if transaction.kind == TransactionKind.income.rawValue {
            return AppPalette.positive
        }
        return expenseCategoryColor(for: transaction)
    }

    static func statusColor(
        for transaction: MoneyTransaction,
        isPaid: Bool
    ) -> Color {
        if transaction.kind == TransactionKind.income.rawValue {
            return AppPalette.positive
        }
        return isPaid ? AppPalette.positive : AppPalette.primary
    }

    private static func expenseCategoryColor(for transaction: MoneyTransaction) -> Color {
        ExpenseCategory(rawValue: transaction.expenseCategory ?? "")?.color ?? AppPalette.primary
    }
}

struct CurrentAccountCalendarWeekdayHeader: View {
    let symbols: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.mutedText)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct CurrentAccountCalendarDayLabel: View {
    let day: Int
    let isToday: Bool

    var body: some View {
        Text("\(day)")
            .font(.caption.bold())
            .foregroundStyle(isToday ? AppPalette.surface : AppPalette.background)
            .frame(width: 24, height: 24)
            .background(isToday ? AppPalette.primary : Color.clear, in: Circle())
    }
}

struct CurrentAccountCalendarMoreLabel: View {
    let hiddenCount: Int

    var body: some View {
        Text("+\(hiddenCount)")
            .font(.caption2.bold())
            .foregroundStyle(AppPalette.mutedText)
            .frame(width: 24, height: 24)
            .background(AppPalette.separator.opacity(0.7), in: Circle())
    }
}

struct CurrentAccountCalendarTransactionLabel: View {
    let icon: String
    let textColor: Color
    let backgroundColor: Color
    let statusColor: Color

    var body: some View {
        Image(systemName: icon)
            .font(.caption.weight(.bold))
            .foregroundStyle(textColor)
            .frame(width: 24, height: 24)
            .background(backgroundColor, in: Circle())
            .overlay {
                Circle()
                    .stroke(textColor.opacity(0.24), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                    .overlay {
                        Circle()
                            .stroke(AppPalette.surface, lineWidth: 1.5)
                    }
                    .offset(x: 1, y: -1)
            }
    }
}

struct CurrentAccountCalendarTransactionPopover: View {
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?
    let amountPaid: Double
    let incomeWasReceived: Bool
    let hasPaymentHistory: Bool
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    let onPay: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        TransactionCard(
            transaction: transaction,
            month: month,
            displayDay: occurrenceDay,
            amountPaid: amountPaid,
            incomeWasReceived: incomeWasReceived,
            hasPaymentHistory: hasPaymentHistory,
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            isExpanded: true,
            onExpansionChange: { _ in },
            onPay: onPay,
            onEdit: onEdit,
            onDelete: onDelete
        )
        .padding(14)
        .frame(width: 420)
        .background(AppPalette.appBackground)
    }
}

struct CurrentAccountCalendarTransactionDetailSheet: View {
    let title: String
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?
    let amountPaid: Double
    let incomeWasReceived: Bool
    let hasPaymentHistory: Bool
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    let onClose: () -> Void
    let onPay: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                TransactionCard(
                    transaction: transaction,
                    month: month,
                    displayDay: occurrenceDay,
                    amountPaid: amountPaid,
                    incomeWasReceived: incomeWasReceived,
                    hasPaymentHistory: hasPaymentHistory,
                    creditAccounts: creditAccounts,
                    savingAccounts: savingAccounts,
                    isExpanded: true,
                    onExpansionChange: { _ in },
                    onPay: onPay,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok), action: onClose)
                        .liquidGlassButtonStyle()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct CurrentAccountCalendarDayItem: Identifiable {
    let transaction: MoneyTransaction
    let occurrenceDay: Int?
    let amountPaid: Double
    let incomeWasReceived: Bool
    let hasPaymentHistory: Bool

    var id: UUID {
        transaction.id
    }
}

struct CurrentAccountCalendarGrid: View {
    let month: Date
    let today: Date
    let days: [Int?]
    let weekdaySymbols: [String]
    let transactionsByDay: [Int: [MoneyTransaction]]
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    @Binding var dayRequest: CalendarDayRequest?
    @Binding var transactionRequest: CalendarTransactionRequest?
    @Binding var expandedTransactionID: UUID?
    let paidAmount: (MoneyTransaction, Date, Int?) -> Double
    let incomeWasReceived: (MoneyTransaction, Date, Int?) -> Bool
    let hasPaymentHistory: (MoneyTransaction, Date, Int?) -> Bool
    let isPaid: (MoneyTransaction, Date, Int?) -> Bool
    let onPay: (MoneyTransaction, Date, Int?, Double) -> Void
    let onEdit: (MoneyTransaction, Date, Int?) -> Void
    let onDelete: (MoneyTransaction, Date, Int?) -> Void

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private static let iconColumns = Array(repeating: GridItem(.fixed(24), spacing: 6), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                CurrentAccountCalendarWeekdayHeader(symbols: weekdaySymbols)

                LazyVGrid(columns: Self.columns, spacing: 8) {
                    ForEach(days.enumerated(), id: \.offset) { _, day in
                        dayCell(
                            day,
                            transactions: day.flatMap { transactionsByDay[$0] } ?? []
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private func dayCell(
        _ day: Int?,
        transactions: [MoneyTransaction]
    ) -> some View {
        if let day {
            VStack(alignment: .leading, spacing: 5) {
                dayNumberButton(day, transactions: transactions)

                LazyVGrid(columns: Self.iconColumns, alignment: .leading, spacing: 6) {
                    ForEach(transactions.prefix(9)) { transaction in
                        transactionButton(transaction, day: day)
                    }

                    if transactions.count > 9 {
                        moreButton(
                            day,
                            hiddenCount: transactions.count - 9,
                            transactions: transactions
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(7)
            .frame(maxWidth: .infinity, minHeight: 144, maxHeight: .infinity, alignment: .topLeading)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday(day) ? AppPalette.primary.opacity(0.45) : AppPalette.separator, lineWidth: 1)
            }
        } else {
            Color.clear
                .frame(minHeight: 144)
        }
    }

    private func dayNumberButton(_ day: Int, transactions: [MoneyTransaction]) -> some View {
        let request = CalendarDayRequest(day: day, month: month, anchor: "day")

        return Button {
            expandedTransactionID = nil
            dayRequest = request
        } label: {
            CurrentAccountCalendarDayLabel(day: day, isToday: isToday(day))
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: dayRequestBinding(for: request),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            dayPopover(for: request, transactions: transactions)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func moreButton(
        _ day: Int,
        hiddenCount: Int,
        transactions: [MoneyTransaction]
    ) -> some View {
        let request = CalendarDayRequest(day: day, month: month, anchor: "more")

        return Button {
            expandedTransactionID = nil
            dayRequest = request
        } label: {
            CurrentAccountCalendarMoreLabel(hiddenCount: hiddenCount)
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: dayRequestBinding(for: request),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            dayPopover(for: request, transactions: transactions)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func transactionButton(_ transaction: MoneyTransaction, day: Int) -> some View {
        let occurrenceDay = transaction.recurrence == .weekly ? day : nil
        let request = CalendarTransactionRequest(
            transaction: transaction,
            month: month,
            occurrenceDay: occurrenceDay
        )

        return Button {
            transactionRequest = request
        } label: {
            CurrentAccountCalendarTransactionLabel(
                icon: CurrentAccountCalendarStyle.icon(for: transaction),
                textColor: CurrentAccountCalendarStyle.textColor(for: transaction),
                backgroundColor: CurrentAccountCalendarStyle.backgroundColor(for: transaction),
                statusColor: CurrentAccountCalendarStyle.statusColor(
                    for: transaction,
                    isPaid: isPaid(transaction, month, occurrenceDay)
                )
            )
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: transactionRequestBinding(for: request),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            transactionPopover(for: request)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func dayRequestBinding(for request: CalendarDayRequest) -> Binding<Bool> {
        Binding(
            get: { dayRequest?.id == request.id },
            set: { isPresented in
                if !isPresented && dayRequest?.id == request.id {
                    dayRequest = nil
                }
            }
        )
    }

    private func transactionRequestBinding(for request: CalendarTransactionRequest) -> Binding<Bool> {
        Binding(
            get: { transactionRequest?.id == request.id },
            set: { isPresented in
                if !isPresented && transactionRequest?.id == request.id {
                    transactionRequest = nil
                }
            }
        )
    }

    private func dayPopover(
        for request: CalendarDayRequest,
        transactions: [MoneyTransaction]
    ) -> some View {
        let items = transactions.map { transaction in
            let occurrenceDay = transaction.recurrence == .weekly ? request.day : nil
            return CurrentAccountCalendarDayItem(
                transaction: transaction,
                occurrenceDay: occurrenceDay,
                amountPaid: paidAmount(transaction, request.month, occurrenceDay),
                incomeWasReceived: incomeWasReceived(transaction, request.month, occurrenceDay),
                hasPaymentHistory: hasPaymentHistory(transaction, request.month, occurrenceDay)
            )
        }

        return CurrentAccountCalendarDayPopover(
            title: dayTitle(for: request),
            month: request.month,
            items: items,
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            expandedTransactionID: $expandedTransactionID,
            onPay: { item in
                dayRequest = nil
                onPay(
                    item.transaction,
                    request.month,
                    item.occurrenceDay,
                    item.amountPaid
                )
            },
            onEdit: { item in
                dayRequest = nil
                onEdit(item.transaction, request.month, item.occurrenceDay)
            },
            onDelete: { item in
                dayRequest = nil
                onDelete(item.transaction, request.month, item.occurrenceDay)
            }
        )
    }

    private func transactionPopover(for request: CalendarTransactionRequest) -> some View {
        let initialAmount = paidAmount(
            request.transaction,
            request.month,
            request.occurrenceDay
        )

        return CurrentAccountCalendarTransactionPopover(
            transaction: request.transaction,
            month: request.month,
            occurrenceDay: request.occurrenceDay,
            amountPaid: initialAmount,
            incomeWasReceived: incomeWasReceived(
                request.transaction,
                request.month,
                request.occurrenceDay
            ),
            hasPaymentHistory: hasPaymentHistory(
                request.transaction,
                request.month,
                request.occurrenceDay
            ),
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            onPay: {
                transactionRequest = nil
                onPay(
                    request.transaction,
                    request.month,
                    request.occurrenceDay,
                    initialAmount
                )
            },
            onEdit: {
                transactionRequest = nil
                onEdit(request.transaction, request.month, request.occurrenceDay)
            },
            onDelete: {
                transactionRequest = nil
                onDelete(request.transaction, request.month, request.occurrenceDay)
            }
        )
    }

    private func isToday(_ day: Int) -> Bool {
        Calendar.current.isDate(month.date(day: day), inSameDayAs: today)
    }

    private func dayTitle(for request: CalendarDayRequest) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: request.month.date(day: request.day))
    }
}

struct CurrentAccountCalendarDayPopover: View {
    let title: String
    let month: Date
    let items: [CurrentAccountCalendarDayItem]
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    @Binding var expandedTransactionID: UUID?
    let onPay: (CurrentAccountCalendarDayItem) -> Void
    let onEdit: (CurrentAccountCalendarDayItem) -> Void
    let onDelete: (CurrentAccountCalendarDayItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Text("\(items.count) \(items.count == 1 ? "registo" : "registos")")
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }

            if items.isEmpty {
                ContentUnavailableView(
                    AppStrings.text(.noTransactions),
                    systemImage: "calendar",
                    description: Text(AppStrings.text(.noTransactionsDescription))
                )
                .frame(width: 360, height: 180)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items) { item in
                            TransactionCard(
                                transaction: item.transaction,
                                month: month,
                                displayDay: item.occurrenceDay,
                                amountPaid: item.amountPaid,
                                incomeWasReceived: item.incomeWasReceived,
                                hasPaymentHistory: item.hasPaymentHistory,
                                creditAccounts: creditAccounts,
                                savingAccounts: savingAccounts,
                                isExpanded: expandedTransactionID == item.id,
                                onExpansionChange: { isExpanded in
                                    expandedTransactionID = isExpanded ? item.id : nil
                                },
                                onPay: { onPay(item) },
                                onEdit: { onEdit(item) },
                                onDelete: { onDelete(item) }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(width: 420, height: min(CGFloat(items.count) * 118 + 16, 520))
            }
        }
        .padding(14)
        .background(AppPalette.appBackground)
    }
}
