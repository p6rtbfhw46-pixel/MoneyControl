//
//  MoneyComponents.swift
//  MoneyControl
//

import SwiftUI

struct SaveResultNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    static func saved(_ message: String) -> SaveResultNotice {
        SaveResultNotice(
            title: AppStrings.text(.savedTitle),
            message: message
        )
    }
}

@MainActor
@Observable
final class SaveResultNoticeCenter {
    static let shared = SaveResultNoticeCenter()

    private(set) var notice: SaveResultNotice?

    private init() {}

    func show(_ notice: SaveResultNotice) {
        self.notice = notice

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            guard self.notice?.id == notice.id else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                self.notice = nil
            }
        }
    }

    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            notice = nil
        }
    }
}

struct SaveResultNoticeOverlay: View {
    let notice: SaveResultNotice
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AppPalette.positive)

                VStack(spacing: 7) {
                    Text(notice.title)
                        .font(.title3.bold())
                        .foregroundStyle(AppPalette.background)

                    Text(notice.message)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .multilineTextAlignment(.center)
                }

                Button(AppStrings.text(.ok), action: onDismiss)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(22)
            .frame(maxWidth: 330)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.22), radius: 24, y: 10)
            .padding(.horizontal, 24)
        }
        .accessibilityAddTraits(.isModal)
        .transition(.opacity)
        .zIndex(1000)
    }
}

struct ConfirmationNoticeOverlay: View {
    let title: String
    let message: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AppPalette.primary)

                VStack(spacing: 7) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(AppPalette.background)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    Button(AppStrings.text(.cancel), action: onCancel)
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))

                    Button(AppStrings.text(.ok), action: onConfirm)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 12))
                }
                .font(.headline)
            }
            .padding(22)
            .frame(maxWidth: 350)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.22), radius: 24, y: 10)
            .padding(.horizontal, 24)
        }
        .accessibilityAddTraits(.isModal)
        .zIndex(3000)
    }
}

struct SaveResultToast: View {
    let notice: SaveResultNotice
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppPalette.positive)

            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title)
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Text(notice.message)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppPalette.positive.opacity(0.85), lineWidth: 2)
        }
        .shadow(color: AppPalette.positive.opacity(0.24), radius: 18, y: 8)
        .accessibilityElement(children: .combine)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -20 {
                        onDismiss?()
                    }
                }
        )
    }
}

private struct SaveResultToastPresenter: ViewModifier {
    @State private var noticeCenter = SaveResultNoticeCenter.shared

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let notice = noticeCenter.notice {
                SaveResultToast(notice: notice, onDismiss: noticeCenter.dismiss)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2000)
            }
        }
    }
}

extension View {
    func saveResultToastPresenter() -> some View {
        modifier(SaveResultToastPresenter())
    }

    func confirmationNotice(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                ConfirmationNoticeOverlay(
                    title: title,
                    message: message,
                    onCancel: { isPresented.wrappedValue = false },
                    onConfirm: {
                        isPresented.wrappedValue = false
                        onConfirm()
                    }
                )
            }
        }
    }
}

struct SpendWiseIcon: View {
    let systemName: String
    let color: Color
    let background: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(background)
                .frame(width: size, height: size)
                .shadow(
                    color: .black.opacity(0.06),
                    radius: 5,
                    y: 3
                )

            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

struct ExpenseTypeHorizontalPicker: View {
    let title: String
    let names: [String]
    var tint: Color = AppPalette.background
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(names, id: \.self) { name in
                            expenseTypeButton(name)
                                .id(name)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .onAppear {
                    scrollToSelection(with: proxy)
                }
                .onChange(of: selection) {
                    scrollToSelection(with: proxy)
                }
                .onChange(of: names) {
                    scrollToSelection(with: proxy)
                }
            }
        }
    }

    private func scrollToSelection(with proxy: ScrollViewProxy) {
        guard names.contains(selection) else { return }

        Task { @MainActor in
            proxy.scrollTo(selection, anchor: .center)
        }
    }

    private func expenseTypeButton(_ name: String) -> some View {
        let isSelected = selection == name
        let iconName = ExpenseTypeIcon.name(for: name)

        return Button {
            selection = name
        } label: {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.surface : tint)
                    .frame(width: 46, height: 46)
                    .background(isSelected ? tint : tint.opacity(0.10), in: Circle())

                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? tint : AppPalette.background)
                    .lineLimit(4)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.center)
                    .frame(width: 96, height: 60, alignment: .top)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(width: 112)
            .background(isSelected ? tint.opacity(0.12) : AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? tint.opacity(0.35) : AppPalette.separator, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct MonthPage: View {
    let month: Date
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let paymentHistory: [PaymentHistoryEntry]
    let exclusions: [RecurrenceExclusion]
    var paymentFilter: CurrentAccountPaymentFilter = .all
    var incomeFilter: CurrentAccountIncomeFilter = .all
    var sortOrder: CurrentAccountSortOrder = .currentPaymentStatusOrder
    var hasActiveFilters = false
    let creditAccounts: [CreditAccount]
    let savingAccounts: [SavingAccount]
    let onPay: (MoneyTransaction, Date, Int?, Double) -> Void
    let onEdit: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction, Int?) -> Void
    let onScrollDirectionChanged: (Bool) -> Void

    @State private var expandedTransactionID: String?
    @State private var isFlexibleSectionCollapsed = false
    @State private var previousScrollDragY: CGFloat = 0

    private struct MonthTransactionOccurrence: Identifiable {
        let transaction: MoneyTransaction
        let day: Int

        var id: String {
            "\(transaction.id.uuidString)-\(day)"
        }
    }

    private struct MonthTransactionSections {
        let ordered: [MonthTransactionOccurrence]
        let today: [MonthTransactionOccurrence]
        let overdue: [MonthTransactionOccurrence]
        let flexible: [MonthTransactionOccurrence]
        let remaining: [MonthTransactionOccurrence]
    }

    private struct PaymentLookupKey: Hashable {
        let transactionID: UUID
        let occurrenceDay: Int?
    }

    private struct MonthTransactionRenderData {
        let sections: MonthTransactionSections
        let paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
        let paymentHistoryIDs: Set<UUID>
    }

    private var calculationService: MoneyCalculationService {
        MoneyCalculationService(transactions: transactions, payments: payments, exclusions: exclusions)
    }

    private var monthPaymentsByKey: [PaymentLookupKey: [ExpensePayment]] {
        payments.reduce(into: [PaymentLookupKey: [ExpensePayment]]()) { result, payment in
            guard Calendar.current.isDate(payment.monthStart, equalTo: month, toGranularity: .month) else { return }
            let transactionKey = PaymentLookupKey(transactionID: payment.transactionID, occurrenceDay: nil)
            result[transactionKey, default: []].append(payment)

            if let occurrenceDay = payment.occurrenceDay {
                let occurrenceKey = PaymentLookupKey(transactionID: payment.transactionID, occurrenceDay: occurrenceDay)
                result[occurrenceKey, default: []].append(payment)
            }
        }
    }

    private var monthPaymentHistoryIDs: Set<UUID> {
        Set(paymentHistory.compactMap { entry in
            Calendar.current.isDate(entry.monthStart, equalTo: month, toGranularity: .month) ? entry.transactionID : nil
        })
    }

    private var emptyStateTitle: String {
        hasActiveFilters ? AppStrings.text(.noFilteredTransactions) : AppStrings.text(.noTransactions)
    }

    private var emptyStateDescription: String {
        hasActiveFilters ? AppStrings.text(.noFilteredTransactionsDescription) : AppStrings.text(.noTransactionsDescription)
    }

    var body: some View {
        let renderData = transactionRenderData
        let sections = renderData.sections

        VStack(alignment: .leading, spacing: 0) {
            if sections.ordered.isEmpty {
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: "calendar",
                    description: Text(emptyStateDescription)
                )
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if sections.today.isEmpty, !sections.flexible.isEmpty {
                        flexibleSection(occurrences: sections.flexible, renderData: renderData)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(AppPalette.appBackground)
                    }

                    if !sections.overdue.isEmpty {
                        overdueSection(occurrences: sections.overdue, renderData: renderData)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(AppPalette.appBackground)
                    }

                    if !sections.today.isEmpty {
                        todaySection(occurrences: sections.today, renderData: renderData)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(AppPalette.appBackground)

                        if !sections.flexible.isEmpty {
                            flexibleSection(occurrences: sections.flexible, renderData: renderData)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(AppPalette.appBackground)
                        }
                    }

                    if !sections.remaining.isEmpty {
                        ForEach(sections.remaining) { occurrence in
                            transactionCard(for: occurrence, includesHorizontalPadding: false, renderData: renderData)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(AppPalette.appBackground)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppPalette.appBackground)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .onChanged { value in
                            let delta = value.translation.height - previousScrollDragY
                            guard abs(delta) > 2 else { return }
                            previousScrollDragY = value.translation.height
                            onScrollDirectionChanged(delta < 0)
                        }
                        .onEnded { _ in
                            previousScrollDragY = 0
                        }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppPalette.appBackground)
    }

    private var transactionRenderData: MonthTransactionRenderData {
        let paymentsByKey = monthPaymentsByKey
        let paymentHistoryIDs = monthPaymentHistoryIDs
        let sections = transactionSections(paymentsByKey: paymentsByKey)

        return MonthTransactionRenderData(
            sections: sections,
            paymentsByKey: paymentsByKey,
            paymentHistoryIDs: paymentHistoryIDs
        )
    }

    private func transactionSections(paymentsByKey: [PaymentLookupKey: [ExpensePayment]]) -> MonthTransactionSections {
        let ordered = orderedOccurrences(paymentsByKey: paymentsByKey)
        let today = todayTransactions(from: ordered)
        let overdue = overdueTransactions(from: ordered, paymentsByKey: paymentsByKey)
        let flexible = flexibleTransactions(from: ordered, paymentsByKey: paymentsByKey)
        let todayIDs = Set(today.map(\.id))
        let overdueIDs = Set(overdue.map(\.id))
        let flexibleIDs = Set(flexible.map(\.id))
        let remaining = ordered.filter {
            !todayIDs.contains($0.id) && !overdueIDs.contains($0.id) && !flexibleIDs.contains($0.id)
        }

        return MonthTransactionSections(
            ordered: ordered,
            today: today,
            overdue: overdue,
            flexible: flexible,
            remaining: remaining
        )
    }

    private func todayTransactions(from ordered: [MonthTransactionOccurrence]) -> [MonthTransactionOccurrence] {
        let calendar = Calendar.current
        guard calendar.isDate(month, equalTo: Date(), toGranularity: .month) else { return [] }

        let todayDay = calendar.component(.day, from: Date())
        return ordered.filter {
            $0.day == todayDay && !$0.transaction.isWholeMonthExpense
        }
    }

    private func overdueTransactions(
        from ordered: [MonthTransactionOccurrence],
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> [MonthTransactionOccurrence] {
        let calendar = Calendar.current
        guard calendar.isDate(month, equalTo: Date(), toGranularity: .month) else { return [] }

        let todayDay = calendar.component(.day, from: Date())
        return ordered.filter { occurrence in
            guard occurrence.day < todayDay else { return false }
            guard occurrence.transaction.kind == TransactionKind.expense.rawValue else { return false }
            guard !occurrence.transaction.isWholeMonthExpense else { return false }

            let occurrenceDay = paymentOccurrenceDay(for: occurrence)
            let scheduledAmount = occurrence.transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
            return amountPaid(for: occurrence, paymentsByKey: paymentsByKey) < scheduledAmount
        }
    }

    private func flexibleTransactions(
        from ordered: [MonthTransactionOccurrence],
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> [MonthTransactionOccurrence] {
        ordered.filter { occurrence in
            guard occurrence.transaction.isWholeMonthExpense else { return false }
            let scheduledAmount = occurrence.transaction.scheduledAmount(in: month, occurrenceDay: paymentOccurrenceDay(for: occurrence))
            return amountPaid(for: occurrence, paymentsByKey: paymentsByKey) < scheduledAmount
        }
    }

    private func orderedOccurrences(paymentsByKey: [PaymentLookupKey: [ExpensePayment]]) -> [MonthTransactionOccurrence] {
        transactions.flatMap { transaction in
            transaction.occurrenceDays(in: month, exclusions: exclusions).map {
                MonthTransactionOccurrence(transaction: transaction, day: $0)
            }
        }
        .filter { occurrenceMatchesCurrentFilters($0, paymentsByKey: paymentsByKey) }
        .sorted { first, second in
            if sortOrder == .dateNewestFirst || sortOrder == .dateOldestFirst {
                if first.day != second.day {
                    return sortOrder == .dateNewestFirst ? first.day > second.day : first.day < second.day
                }
                return compareNames(first, second)
            }

            if sortOrder == .amountHighestFirst || sortOrder == .amountLowestFirst {
                let firstAmount = scheduledAmount(for: first)
                let secondAmount = scheduledAmount(for: second)
                if firstAmount != secondAmount {
                    return sortOrder == .amountHighestFirst ? firstAmount > secondAmount : firstAmount < secondAmount
                }
                if first.day != second.day { return first.day > second.day }
                return compareNames(first, second)
            }

            if sortOrder == .nameAscending {
                let nameComparison = freeTextSortValue(for: first).localizedCaseInsensitiveCompare(freeTextSortValue(for: second))
                if nameComparison != .orderedSame { return nameComparison == .orderedAscending }
                return first.day > second.day
            }

            let firstRank = displayRank(for: first, paymentsByKey: paymentsByKey)
            let secondRank = displayRank(for: second, paymentsByKey: paymentsByKey)

            if firstRank != secondRank {
                return firstRank < secondRank
            }

            if first.day != second.day {
                if sortOrder == .paymentStatusNewestFirst {
                    return first.day > second.day
                }
                return first.day < second.day
            }

            if first.transaction.kind != second.transaction.kind {
                return first.transaction.kind == TransactionKind.expense.rawValue
            }

            return first.transaction.displayName.localizedCaseInsensitiveCompare(second.transaction.displayName) == .orderedAscending
        }
    }

    private func scheduledAmount(for occurrence: MonthTransactionOccurrence) -> Double {
        occurrence.transaction.scheduledAmount(
            in: month,
            occurrenceDay: paymentOccurrenceDay(for: occurrence)
        )
    }

    private func compareNames(_ first: MonthTransactionOccurrence, _ second: MonthTransactionOccurrence) -> Bool {
        first.transaction.displayName.localizedCaseInsensitiveCompare(second.transaction.displayName) == .orderedAscending
    }

    private func freeTextSortValue(for occurrence: MonthTransactionOccurrence) -> String {
        let transaction = occurrence.transaction
        let value: String
        if transaction.kind == TransactionKind.expense.rawValue {
            value = transaction.title
        } else {
            value = transaction.incomeDescription ?? ""
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? transaction.displayName : trimmedValue
    }

    private func occurrenceMatchesCurrentFilters(
        _ occurrence: MonthTransactionOccurrence,
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> Bool {
        if occurrence.transaction.kind == TransactionKind.expense.rawValue, paymentFilter != .all {
            let occurrenceDay = paymentOccurrenceDay(for: occurrence)
            let scheduledAmount = occurrence.transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
            let isPaid = amountPaid(for: occurrence, paymentsByKey: paymentsByKey) >= scheduledAmount

            switch paymentFilter {
            case .all:
                break
            case .paid:
                if !isPaid { return false }
            case .unpaid:
                if isPaid { return false }
            }
        }

        if occurrence.transaction.kind == TransactionKind.income.rawValue, incomeFilter != .all {
            let receivedDate = month.monthStart.date(day: occurrence.day)
            let isReceived = Calendar.current.startOfDay(for: receivedDate) <= Calendar.current.startOfDay(for: Date())

            switch incomeFilter {
            case .all:
                break
            case .received:
                if !isReceived { return false }
            case .pending:
                if isReceived { return false }
            }
        }

        return true
    }

    private func displayRank(
        for occurrence: MonthTransactionOccurrence,
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> Int {
        let transaction = occurrence.transaction
        if transaction.kind == TransactionKind.income.rawValue {
            return incomeDayHasPassed(occurrence) ? 2 : 0
        }

        let occurrenceDay = paymentOccurrenceDay(for: occurrence)
        return amountPaid(for: occurrence, paymentsByKey: paymentsByKey) >= occurrence.transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay) ? 1 : 0
    }

    private func incomeDayHasPassed(_ occurrence: MonthTransactionOccurrence) -> Bool {
        let calendar = Calendar.current
        let currentMonth = Date().monthStart

        if month.monthStart < currentMonth {
            return true
        }

        if month.monthStart > currentMonth {
            return false
        }

        return occurrence.day < calendar.component(.day, from: Date())
    }

    private func todaySection(occurrences: [MonthTransactionOccurrence], renderData: MonthTransactionRenderData) -> some View {
        todaySectionCard(occurrences: occurrences, renderData: renderData)
    }

    private func overdueSection(occurrences: [MonthTransactionOccurrence], renderData: MonthTransactionRenderData) -> some View {
        transactionGroupCard(title: AppStrings.text(.overdue), occurrences: occurrences, renderData: renderData)
    }

    private func todaySectionCard(occurrences: [MonthTransactionOccurrence], renderData: MonthTransactionRenderData) -> some View {
        transactionGroupCard(title: AppStrings.text(.today), occurrences: occurrences, renderData: renderData)
    }

    private func flexibleSection(occurrences: [MonthTransactionOccurrence], renderData: MonthTransactionRenderData) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    isFlexibleSectionCollapsed.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("\(occurrences.count)")
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 24, height: 24)
                        .background(AppPalette.mediumBlue, in: Circle())

                    Text(AppStrings.text(.flexible))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.mutedText)
                        .rotationEffect(.degrees(isFlexibleSectionCollapsed ? -90 : 0))
                }
                .frame(height: 28, alignment: .center)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isFlexibleSectionCollapsed {
                VStack(spacing: 8) {
                    ForEach(occurrences) { occurrence in
                        transactionCard(for: occurrence, includesHorizontalPadding: false, renderData: renderData)
                    }
                }
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, isFlexibleSectionCollapsed ? 7 : 12)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppPalette.separator, lineWidth: 1)
        }
        .shadow(color: AppPalette.background.opacity(0.08), radius: 14, y: 8)
    }

    private func transactionGroupCard(
        title: String,
        occurrences: [MonthTransactionOccurrence],
        renderData: MonthTransactionRenderData
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)
                .frame(height: 18, alignment: .center)

            VStack(spacing: 8) {
                ForEach(occurrences) { occurrence in
                    transactionCard(for: occurrence, includesHorizontalPadding: false, renderData: renderData)
                }
            }
            .padding(.vertical, 2)
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

    private func transactionCard(
        for occurrence: MonthTransactionOccurrence,
        includesHorizontalPadding: Bool,
        renderData: MonthTransactionRenderData
    ) -> some View {
        let transaction = occurrence.transaction
        let paidAmount = amountPaid(for: occurrence, paymentsByKey: renderData.paymentsByKey)
        let occurrenceDay = paymentOccurrenceDay(for: occurrence)

        return TransactionCard(
            transaction: transaction,
            month: month,
            displayDay: occurrence.day,
            amountPaid: paidAmount,
            hasPaymentHistory: hasPaymentHistory(for: transaction, paymentHistoryIDs: renderData.paymentHistoryIDs),
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            isExpanded: expandedTransactionID == occurrence.id,
            onExpansionChange: { isExpanded in
                expandedTransactionID = isExpanded ? occurrence.id : nil
            },
            onPay: { onPay(transaction, month, occurrenceDay, paidAmount) },
            onEdit: { onEdit(transaction) },
            onDelete: { onDelete(transaction, occurrenceDay) }
        )
        .padding(.horizontal, includesHorizontalPadding ? 16 : 0)
    }

    private func amountPaid(
        for transaction: MoneyTransaction,
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> Double {
        if transaction.recurrence == .weekly {
            return transaction.occurrenceDays(in: month, exclusions: exclusions)
                .reduce(0) { total, occurrenceDay in
                    total + recordedAmountPaid(for: transaction, occurrenceDay: occurrenceDay, paymentsByKey: paymentsByKey)
                }
        }

        return recordedAmountPaid(for: transaction, occurrenceDay: nil, paymentsByKey: paymentsByKey)
    }

    private func amountPaid(
        for occurrence: MonthTransactionOccurrence,
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> Double {
        recordedAmountPaid(
            for: occurrence.transaction,
            occurrenceDay: paymentOccurrenceDay(for: occurrence),
            paymentsByKey: paymentsByKey
        )
    }

    private func recordedAmountPaid(
        for transaction: MoneyTransaction,
        occurrenceDay: Int?,
        paymentsByKey: [PaymentLookupKey: [ExpensePayment]]
    ) -> Double {
        let normalizedOccurrenceDay = transaction.recurrence == .weekly ? occurrenceDay : nil
        let key = PaymentLookupKey(transactionID: transaction.id, occurrenceDay: normalizedOccurrenceDay)
        let matchingPayments = paymentsByKey[key] ?? []

        guard !matchingPayments.isEmpty else {
            return calculationService.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
        }

        let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
        return matchingPayments.reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
    }

    private func paymentOccurrenceDay(for occurrence: MonthTransactionOccurrence) -> Int? {
        occurrence.transaction.recurrence == .weekly ? occurrence.day : nil
    }

    private func hasPaymentHistory(for transaction: MoneyTransaction, paymentHistoryIDs: Set<UUID>) -> Bool {
        guard transaction.kind == TransactionKind.expense.rawValue else { return false }
        return paymentHistoryIDs.contains(transaction.id)
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
            .reduce(0) { $0 + $1.scheduledAmount(in: month) }
    }

    private var expenses: Double {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { $0 + $1.scheduledAmount(in: month) }
    }

    private var unpaid: Double {
        transactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { total, transaction in
                total + max(transaction.scheduledAmount(in: month) - paidAmount(for: transaction), 0)
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
            .reduce(0) { $0 + $1.scheduledAmount(in: month) }
    }

    private func categoryRatio(_ category: ExpenseCategory) -> Double {
        guard income > 0 else { return 0 }
        return categoryAmount(category) / income
    }

    private func paidAmount(for transaction: MoneyTransaction) -> Double {
        MoneyCalculationService(transactions: transactions, payments: payments, exclusions: [])
            .paidAmount(for: transaction, in: month)
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
    var displayDay: Int? = nil
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

    private var scheduledAmount: Double {
        transaction.scheduledAmount(in: month, occurrenceDay: transaction.recurrence == .weekly ? displayDay : nil)
    }

    private var displayedDayDescription: String {
        if transaction.isWholeMonthExpense {
            return AppStrings.text(.flexible)
        }

        if let displayDay {
            return "\(AppStrings.text(.day)) \(displayDay)"
        }

        return transaction.dayDescription(in: month)
    }

    private var unpaidRatio: Double {
        guard isExpense, scheduledAmount > 0 else { return 0 }
        return min(max((scheduledAmount - amountPaid) / scheduledAmount, 0), 1)
    }

    private var paidRatio: Double {
        guard isExpense, scheduledAmount > 0 else { return 0 }
        return min(max(amountPaid / scheduledAmount, 0), 1)
    }

    private var paidPercentageText: String {
        paidRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    private var isFullyPaid: Bool {
        isExpense && amountPaid >= scheduledAmount
    }

    private var hasPartialPayment: Bool {
        isExpense && amountPaid > 0 && !isFullyPaid
    }

    private var freeTextTitle: String? {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if !isExpense {
            let trimmedDescription = transaction.incomeDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmedDescription.isEmpty ? nil : trimmedDescription
        }

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
        freeTextTitle ?? transaction.displayName
    }

    private var paymentStatusText: String {
        if isFullyPaid {
            return AppStrings.text(.paid)
        }
        if hasPartialPayment {
            let prefix = usesRemainingSpendStatus ? AppStrings.text(.canStillSpend) : AppStrings.text(.notPaid)
            return "\(prefix) \(max(scheduledAmount - amountPaid, 0).currencyText)"
        }
        if usesRemainingSpendStatus {
            return AppStrings.text(.unusedExpense)
        }
        return AppStrings.text(.notPaid)
    }

    private var compactSupplementalDetailText: String? {
        var parts: [String] = []

        if !isExpense && transaction.budgetAllocation == .nextMonth {
            parts.append(AppStrings.text(.nextMonthBudgetOnlySummary))
        }

        if isExpense && transaction.autoMarkPaidOnDay {
            parts.append(AppStrings.text(.autoPaidOnDaySummary))
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var expandedExpenseSupplementalDetailParts: [String] {
        guard isExpense && transaction.autoMarkPaidOnDay else { return [] }
        return [AppStrings.text(.autoPaidOnDaySummary)]
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
                    let safeWidth = max(proxy.size.width, 0)
                    let safeRatio = min(max(paidRatio.isFinite ? paidRatio : 0, 0), 1)

                    ZStack(alignment: .leading) {
                        AppPalette.separator
                        AppPalette.mediumGreen
                            .frame(width: safeWidth * safeRatio)
                    }
                }
                .frame(height: 7)
                .clipShape(Capsule())
            }

            Text("\(amountPaid.currencyText) \(AppStrings.text(.ofAmount)) \(scheduledAmount.currencyText)")
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
                let safeWidth = max(proxy.size.width, 0)
                let safeRatio = min(max(paidRatio.isFinite ? paidRatio : 0, 0), 1)

                ZStack(alignment: .leading) {
                    AppPalette.separator
                    AppPalette.mediumGreen
                        .frame(width: safeWidth * safeRatio)
                }
            }
            .frame(width: 92, height: 7)
            .clipShape(Capsule())

            Text("\(amountPaid.currencyText) \(AppStrings.text(.ofAmount)) \(scheduledAmount.currencyText)")
                .font(.caption2)
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var detailTextWithoutFreeText: String {
        guard freeTextTitle != nil else {
            return detailTextForDisplayedOccurrence()
        }

        var parts = [displayedDayDescription]

        if let category {
            parts.append(category.title)
        }

        if !isExpense {
            parts.append(transaction.displayName)
            let budgetMonth = transaction.budgetMonth(forReceivedMonth: month)
            if !Calendar.current.isDate(budgetMonth, equalTo: month.monthStart, toGranularity: .month) {
                parts.append("\(AppStrings.text(.budgetMonth)) \(budgetMonth.monthTitle)")
            }
        }

        switch transaction.recurrence {
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
            parts.append(transaction.recurrence?.title ?? AppStrings.text(.everyMonth))
            if let recurrenceEndMonthStart = transaction.recurrenceEndMonthStart {
                parts.append("\(AppStrings.text(.endDate)) \(recurrenceEndMonthStart.previousMonthStart.monthTitle)")
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            break
        }

        parts.append(contentsOf: expandedExpenseSupplementalDetailParts)

        return parts.joined(separator: " · ")
    }

    private func detailTextForDisplayedOccurrence() -> String {
        guard displayDay != nil else {
            var parts = [transaction.detailText(in: month)]
            parts.append(contentsOf: expandedExpenseSupplementalDetailParts)
            return parts.joined(separator: " · ")
        }

        var parts = [displayedDayDescription]

        if let category {
            parts.append(category.title)
        }

        if isExpense, !transaction.title.isEmpty {
            parts.append(transaction.title)
        }

        switch transaction.recurrence {
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
            parts.append(transaction.recurrence?.title ?? AppStrings.text(.everyMonth))
            if let recurrenceEndMonthStart = transaction.recurrenceEndMonthStart {
                parts.append("\(AppStrings.text(.endDate)) \(recurrenceEndMonthStart.previousMonthStart.monthTitle)")
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
        case nil:
            break
        }

        parts.append(contentsOf: expandedExpenseSupplementalDetailParts)

        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasPartialPayment {
                GeometryReader { proxy in
                    let safeWidth = max(proxy.size.width, 0)
                    let safeRatio = min(max(unpaidRatio.isFinite ? unpaidRatio : 0, 0), 1)

                    ZStack(alignment: .leading) {
                        AppPalette.separator
                        LinearGradient(
                            colors: [AppPalette.primary, AppPalette.primary.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                            .frame(width: safeWidth * safeRatio)
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
                        Text((isExpense ? scheduledAmount : transaction.amount).currencyText)
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
                        Text(detailTextWithoutFreeText)
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
                            Image(systemName: "trash")
                                .font(.subheadline.bold())
                                .frame(width: 44, height: 40)
                                .background(AppPalette.destructive, in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppStrings.text(.delete))
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
        VStack(alignment: .leading, spacing: 2) {
            if let subscriptionRecurrenceData {
                SubscriptionRecurrenceLabel(
                    day: subscriptionRecurrenceData.day,
                    monthName: subscriptionRecurrenceData.monthName,
                    recurrenceTitle: subscriptionRecurrenceData.recurrenceTitle
                )
                .lineLimit(1)
            } else {
                HStack(spacing: 0) {
                    Text(displayedDayDescription)
                        .fontWeight(.bold)
                    if isExpense || freeTextTitle != nil {
                        Text(" - \(transaction.displayName)")
                    }
                }
                .lineLimit(1)

                if let recurrenceMonthName = recurrenceMonthName(in: month) {
                    RecurrenceMonthLabel(monthName: recurrenceMonthName)
                        .lineLimit(1)
                }
            }

            if let compactSupplementalDetailText {
                Text(compactSupplementalDetailText)
                    .lineLimit(1)
            }
        }
        .font(.caption)
        .foregroundStyle(AppPalette.mutedText)
    }

    private var subscriptionRecurrenceData: (day: Int, monthName: String?, recurrenceTitle: String?)? {
        guard isSubscriptionExpense else { return nil }
        guard !transaction.isWholeMonthExpense else { return nil }
        return subscriptionRecurrenceData(day: displayDay ?? transaction.effectiveDay(in: month), month: month)
    }

    private var isSubscriptionExpense: Bool {
        isExpense && normalized("\(transaction.displayName) \(transaction.title)").contains("subscr")
    }

    private func subscriptionRecurrenceData(day: Int, month: Date) -> (day: Int, monthName: String?, recurrenceTitle: String?) {
        switch transaction.recurrence {
        case .weekly, .monthly:
            return (day, nil, transaction.recurrence?.title)
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
        case .weekly, .monthly, nil:
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
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
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

        return SpendWiseIcon(
            systemName: iconName,
            color: iconColor,
            background: iconBackground,
            size: 44
        )
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
            Text("\(AppStrings.text(.day)) \(day)")
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
    let onSetEnabled: (Bool) -> Void
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
        if isExpense {
            return trimmedTitle.isEmpty ? nil : trimmedTitle
        }

        let trimmedDescription = transaction.incomeDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedDescription.isEmpty ? nil : trimmedDescription
    }

    private var compactTitle: String {
        freeTextTitle ?? transaction.displayName
    }

    private var detailTextWithoutFreeText: String {
        guard freeTextTitle != nil else {
            return transaction.detailText
        }

        var parts = [settingsDayDescription]

        if let category {
            parts.append(category.title)
        }

        if !isExpense {
            parts.append(transaction.displayName)
            if transaction.recurrence != nil {
                parts.append("\(AppStrings.text(.useInBudget)) \(transaction.budgetAllocation.title)")
            }
        }

        switch transaction.recurrence {
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
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
            .accessibilityValue(transaction.isRecurrenceEnabled ? "Ativo" : "Desativado")

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

                        Button {
                            onSetEnabled(!transaction.isRecurrenceEnabled)
                        } label: {
                            CompactActionLabel(
                                title: transaction.isRecurrenceEnabled ? "Desativar" : "Ativar",
                                systemImage: transaction.isRecurrenceEnabled ? "pause.circle" : "play.circle"
                            )
                            .foregroundStyle(transaction.isRecurrenceEnabled ? AppPalette.background : .white)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                transaction.isRecurrenceEnabled ? AppPalette.secondary : AppPalette.positive,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
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
                    Text(settingsDayDescription)
                        .fontWeight(transaction.isWholeMonthExpense ? .bold : .regular)
                    Text(" - \(compactRecurrenceTitle)")
                    if isExpense || freeTextTitle != nil {
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

    private var compactRecurrenceTitle: String {
        switch transaction.recurrence {
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
            return transaction.recurrence?.title ?? AppStrings.text(.everyMonth)
        case .yearlyMonth:
            return AppStrings.text(.annualRecurrence)
        case nil:
            return AppStrings.text(.onlyThisMonth)
        }
    }

    private var settingsDayDescription: String {
        if transaction.isWholeMonthExpense {
            return AppStrings.text(.flexible)
        }

        return transaction.dayDescription()
    }

    private var subscriptionRecurrenceData: (day: Int, monthName: String?, recurrenceTitle: String?)? {
        guard isSubscriptionExpense else { return nil }
        guard !transaction.isWholeMonthExpense else { return nil }
        return subscriptionRecurrenceData(day: transaction.day, month: transaction.monthStart)
    }

    private var isSubscriptionExpense: Bool {
        isExpense && normalized("\(transaction.displayName) \(transaction.title)").contains("subscr")
    }

    private func subscriptionRecurrenceData(day: Int, month: Date) -> (day: Int, monthName: String?, recurrenceTitle: String?) {
        switch transaction.recurrence {
        case .weekly, .monthly:
            return (day, nil, transaction.recurrence?.title)
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
        case .weekly, .monthly, nil:
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
        case .weekly, .monthly, .quarterly, .semiannual, .annual:
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

        if isExpense {
            iconName = ExpenseTypeIcon.name(for: transaction.displayName)
            iconBackground = (category?.color ?? AppPalette.primary).opacity(0.18)
            iconColor = category?.color ?? AppPalette.primary
        } else {
            iconName = "banknote.fill"
            iconBackground = AppPalette.mintSurface
            iconColor = AppPalette.positive
        }

        return SpendWiseIcon(
            systemName: iconName,
            color: iconColor,
            background: iconBackground,
            size: 44
        )
        .overlay(alignment: .topTrailing) {
            if !transaction.isRecurrenceEnabled {
                Image(systemName: "pause.fill")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(AppPalette.destructive, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(AppPalette.surface, lineWidth: 2)
                    }
                    .offset(x: 3, y: -3)
                    .accessibilityHidden(true)
            }
        }
    }
}

private struct CollapsiblePaymentCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content

    init(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 10)
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .tint(AppPalette.background)
        .padding(12)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.04), radius: 8, y: 4)
    }
}

private struct ClosePlanningOnSaveRow: View {
    @Binding var isSelected: Bool

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AppPalette.positive : AppPalette.mutedText)

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.text(.closePlanningOnSave))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.background)

                    Text(AppStrings.text(.closePlanningOnSaveDescription))
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PaymentAmountPicker: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""

    let title: String
    let totalAmount: Double
    let initialAmount: Double
    let paymentDate: Date
    var futureFlexiblePaymentMonth: String? = nil
    let history: [PaymentHistoryEntry]
    let accounts: [SpendAccount]
    let accountMovements: [AccountMovement]
    let transactionAccountID: UUID?
    let onConfirm: (Double, String?, UUID?) -> Void
    let onConfirmAndCloseBudgetWithConsumedValue: (Double, String?, UUID?, Double) -> Void
    let onCloseBudgetWithConsumedValue: (Double) -> Void
    let onDeleteHistoryEntry: (PaymentHistoryEntry) -> Void

    @State private var selectedAmount: Double = 0
    @State private var paidAmountInSheet: Double = 0
    @State private var paymentNote = ""
    @State private var selectedAccountID: UUID?
    @State private var isAccountSectionExpanded = false
    @State private var isQuickPaymentSectionExpanded = false
    @State private var closesPlanningOnSave = false
    @State private var showsOverpaymentConfirmation = false
    @State private var showsCloseBudgetConfirmation = false
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

    private var canCloseBudgetWithConsumedValue: Bool {
        paidAmountInSheet > 0 && paidAmountInSheet < totalAmount
    }

    private var closeBudgetConfirmationMessage: String {
        let isPortuguese = AppStrings.currentLanguage == .portuguese
        if isPortuguese {
            return "Este orçamento vai ser editado apenas neste registo. O valor orçamentado era \(totalAmount.currencyText) e vai passar para \(paidAmountInSheet.currencyText), que já está pago. Depois disto, o orçamento fica fechado como pago."
        }

        return "This budget will be edited only for this entry. The budgeted value was \(totalAmount.currencyText) and will become \(paidAmountInSheet.currencyText), which is already paid. After this, the budget is closed as paid."
    }

    private var visibleHistory: [PaymentHistoryEntry] {
        history.filter { !deletedHistoryEntryIDs.contains($0.id) }
    }

    private var orderedAccounts: [SpendAccount] {
        accounts.sorted { first, second in
            first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
        }
    }

    private var defaultAccountID: UUID? {
        transactionAccountID ?? accounts.first(where: \.isPrimary)?.id ?? accounts.first?.id
    }

    private var selectedAccountName: String? {
        guard let accountID = selectedAccountID ?? defaultAccountID else { return nil }
        return accounts.first(where: { $0.id == accountID })?.displayName
    }

    private var accountSectionTitle: String {
        guard let selectedAccountName else { return AppStrings.text(.account) }
        return "\(AppStrings.text(.account)) - \(selectedAccountName)"
    }

    private var isFuturePaymentDate: Bool {
        Calendar.current.startOfDay(for: paymentDate) > Calendar.current.startOfDay(for: Date())
    }

    private var formattedPaymentDate: String {
        paymentDate.formatted(.dateTime.locale(Locale(identifier: AppStrings.currentLocaleIdentifier)).day().month(.wide).year())
    }

    private var futurePaymentMessage: String {
        if let futureFlexiblePaymentMonth {
            return String(
                format: AppStrings.text(.futureFlexiblePaymentMessage),
                selectedAmount.currencyText,
                futureFlexiblePaymentMonth
            )
        }

        return String(format: AppStrings.text(.futurePaymentMessage), selectedAmount.currencyText, formattedPaymentDate)
    }

    private var paidProgress: Double {
        guard totalAmount > 0 else { return 0 }
        return min(max(paidAmountInSheet / totalAmount, 0), 1)
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
            ScrollView {
                VStack(spacing: 14) {
                    paymentSummaryCard

                    if canAddPayment {
                        accountSelectionSection
                        quickPaymentSection

                        paymentCard {
                            MoneyAmountPicker(
                                title: AppStrings.text(.amountToPay),
                                amount: $selectedAmount,
                                maximumAmount: 1_000_000,
                                onConfirm: confirmPayment
                            )
                        }

                        paymentNoteSection
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

                    Text("\(AppStrings.text(.total)): \((paidAmountInSheet + selectedAmount).currencyText)")
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity)

                    paymentHistorySection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
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
                    Button(AppStrings.text(.save), action: confirmPayment)
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
            .confirmationNotice(
                isPresented: $showsCloseBudgetConfirmation,
                title: "Fechar orçamento?",
                message: closeBudgetConfirmationMessage
            ) {
                onCloseBudgetWithConsumedValue(paidAmountInSheet)
                dismiss()
            }
            .confirmationNotice(
                isPresented: $showsOverpaymentConfirmation,
                title: AppStrings.text(.overpaymentTitle),
                message: AppStrings.text(.overpaymentMessage),
                onConfirm: performPayment
            )
            .confirmationNotice(
                isPresented: $showsFuturePaymentConfirmation,
                title: AppStrings.text(.futurePaymentTitle),
                message: futurePaymentMessage
            ) {
                hasConfirmedFuturePayment = true
                confirmPayment()
            }
            .onAppear {
                paidAmountInSheet = initialAmount
                selectedAmount = 0
                selectedAccountID = selectedAccountID ?? defaultAccountID
            }
            .id(selectedCurrencyCode)
        }
    }

    private var paymentSummaryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: ExpenseTypeIcon.name(for: title))
                .font(.title.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 76, height: 76)
                .background(AppPalette.primary.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 9) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text("\(AppStrings.text(.paid)): \(paidAmountInSheet.currencyText) \(AppStrings.text(.ofAmount)) \(totalAmount.currencyText)")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)

                ProgressView(value: paidProgress)
                    .tint(AppPalette.background)

                HStack {
                    Text(paidAmountInSheet.currencyText)
                    Spacer()
                    Text(totalAmount.currencyText)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppPalette.mutedText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.05), radius: 10, y: 5)
    }

    private var accountSelectionSection: some View {
        CollapsiblePaymentCard(
            title: accountSectionTitle,
            isExpanded: $isAccountSectionExpanded
        ) {
            accountSelectionStrip
        }
    }

    private var quickPaymentSection: some View {
        CollapsiblePaymentCard(
            title: AppStrings.text(.quickPayment),
            isExpanded: $isQuickPaymentSectionExpanded
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        selectedAmount = remainingAmount
                        confirmPayment()
                    } label: {
                        Label(AppStrings.text(.payFullAmount), systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(AppPalette.surface)
                            .frame(maxWidth: .infinity, minHeight: 74)
                            .background(AppPalette.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if canCloseBudgetWithConsumedValue {
                        Button {
                            showsCloseBudgetConfirmation = true
                        } label: {
                            Label(AppStrings.text(.closeBudgetWithConsumedValue), systemImage: "checkmark.seal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.background)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity, minHeight: 74)
                                .padding(.horizontal, 16)
                                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppPalette.mediumBlue.opacity(0.35), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()

                ClosePlanningOnSaveRow(isSelected: $closesPlanningOnSave)
            }
        }
    }

    private var paymentNoteSection: some View {
        paymentCard(title: AppStrings.text(.paymentNote)) {
            TextField(AppStrings.text(.paymentNotePlaceholder), text: $paymentNote, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .padding(12)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppPalette.separator, lineWidth: 1)
                }
        }
    }

    private func paymentCard<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
            }

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.04), radius: 8, y: 4)
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
        let trimmedNote = paymentNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmedNote.isEmpty ? nil : trimmedNote
        let accountID = selectedAccountID ?? defaultAccountID
        let totalPaidAfterSaving = paidAmountInSheet + selectedAmount

        if closesPlanningOnSave, totalPaidAfterSaving < totalAmount {
            onConfirmAndCloseBudgetWithConsumedValue(
                selectedAmount,
                note,
                accountID,
                totalPaidAfterSaving
            )
        } else {
            onConfirm(selectedAmount, note, accountID)
        }

        dismiss()
    }

    @ViewBuilder
    private var accountSelectionStrip: some View {
        if !orderedAccounts.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(orderedAccounts) { account in
                        accountSelectionButton(account)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func accountSelectionButton(_ account: SpendAccount) -> some View {
        let isSelected = (selectedAccountID ?? defaultAccountID) == account.id
        let balance = account.balance(with: accountMovements)

        return Button {
            selectedAccountID = account.id
        } label: {
            HStack(spacing: 8) {
                Image(systemName: account.accountIcon.systemName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? AppPalette.surface : account.tint)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(balance.currencyText)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
            .frame(width: 174, height: 72, alignment: .leading)
            .padding(.horizontal, 12)
            .background(isSelected ? AppPalette.background : AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppPalette.background : AppPalette.separator, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var paymentHistorySection: some View {
        if !visibleHistory.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.text(.paymentHistory))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)

                ForEach(visibleHistory) { entry in
                    PaymentHistoryRow(entry: entry, accounts: accounts) {
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
    let accounts: [SpendAccount]
    let onDelete: () -> Void

    private var accountName: String? {
        guard let accountID = entry.accountID else { return nil }
        return accounts.first { $0.id == accountID }?.displayName
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.paidAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                Text(entry.amount.currencyText)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.background)

                if let accountName {
                    Text("\(AppStrings.text(.account)): \(accountName)")
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(1)
                }

                if let note = entry.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(3)
                }
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
    var arrowEdge: Edge = .trailing

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
        .popover(isPresented: $showsHelp, attachmentAnchor: .point(.center), arrowEdge: arrowEdge) {
            InformationBubble(title: title, message: message)
        }
    }
}

struct InformationBubble: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let title: String
    let message: String
    var boldNote = ""
    var footnote = ""

    private var bubbleWidth: CGFloat {
        horizontalSizeClass == .compact ? 230 : 340
    }

    private var bubbleHeight: CGFloat {
        horizontalSizeClass == .compact ? 340 : 300
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.background)
                    .fixedSize(horizontal: false, vertical: true)

                if !boldNote.isEmpty {
                    Text(boldNote)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !footnote.isEmpty {
                    Text(footnote)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(width: bubbleWidth, alignment: .leading)
        }
        .frame(width: bubbleWidth, alignment: .leading)
        .frame(minHeight: 160, maxHeight: bubbleHeight, alignment: .leading)
        .background(AppPalette.surface)
        .presentationCompactAdaptation(.popover)
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
                .toolbar {
                    if isAmountFocused {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()

                            Button(AppStrings.text(.ok)) {
                                isAmountFocused = false
                                syncTextFromAmount()
                            }
                        }
                    }
                }
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
    var iconImageName: String? = nil
    var boldHelpNote: String = ""
    var footnote: String = ""
    var helpTitle: String? = nil
    var helpArrowEdge: Edge = .trailing
    var isCompact: Bool = false
    var isLoading: Bool = false
    var titleLineLimit: Int = 2
    var fixedHeight: CGFloat? = nil
    var onTap: (() -> Void)? = nil

    @State private var showsHelp = false

    private var hasIconImage: Bool {
        iconImageName != nil
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: hasIconImage ? 10 : 0) {
                if let iconImageName {
                    Image(iconImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 42 : 50, height: isCompact ? 42 : 50)
                        .padding(.leading, 1)
                        .layoutPriority(0)
                }

                VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(titleLineLimit)
                        .fixedSize(horizontal: false, vertical: titleLineLimit > 1)
                        .minimumScaleFactor(titleLineLimit == 1 ? 0.62 : 0.82)
                        .allowsTightening(true)
                        .padding(.trailing, titleLineLimit == 1 ? 26 : 34)
                    if isLoading {
                        ProgressView()
                            .tint(AppPalette.background)
                            .frame(height: isCompact ? 30 : 38, alignment: .leading)
                    } else {
                        Text(value.currencyText)
                            .font(.system(size: isCompact ? 24 : (hasIconImage ? 28 : 34), weight: .bold))
                            .foregroundStyle(value < 0 ? AppPalette.primary : AppPalette.background)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .allowsTightening(true)
                    }
                    if !footnote.isEmpty {
                        Text(footnote)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.mutedText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                    }
                }
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, minHeight: isCompact ? 54 : (hasIconImage ? 70 : 58), alignment: .leading)
            .padding(.horizontal, isCompact ? 8 : (hasIconImage ? 9 : 10))
            .padding(.vertical, isCompact ? 6 : (hasIconImage ? 8 : 6))

            Button {
                showsHelp = true
            } label: {
                Image(systemName: "info.circle")
                    .font((isCompact ? Font.body : Font.title3).weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: isCompact ? 24 : 28, height: isCompact ? 24 : 28)
            }
            .buttonStyle(.plain)
            .padding(isCompact ? 8 : 10)
            .popover(isPresented: $showsHelp, attachmentAnchor: .point(.center), arrowEdge: helpArrowEdge) {
                InformationBubble(
                    title: helpTitle ?? title,
                    message: helpText,
                    boldNote: boldHelpNote,
                    footnote: footnote
                )
            }
        }
        .frame(height: fixedHeight)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            onTap?()
        }
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }
}

struct RecurringList: View {
    let emptyTitle: String
    let transactions: [MoneyTransaction]
    let payments: [ExpensePayment]
    let onEdit: (MoneyTransaction) -> Void
    let onSetEnabled: (MoneyTransaction, Bool) -> Void
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
                            onSetEnabled: { onSetEnabled(transaction, $0) },
                            onDelete: { onDelete(transaction) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
