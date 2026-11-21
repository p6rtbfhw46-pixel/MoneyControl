import SwiftUI

struct AnalyticsSubscriptionList: View {
    let transactions: [MoneyTransaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if transactions.isEmpty {
                ContentUnavailableView(
                    AppStrings.text(.noListData),
                    systemImage: "list.bullet.rectangle"
                )
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ForEach(transactions) { transaction in
                    AnalyticsRow(
                        icon: ExpenseTypeIcon.name(for: transaction.displayName),
                        title: analyticsTransactionTitle(for: transaction),
                        subtitle: subtitle(for: transaction),
                        value: transaction.amount.currencyText,
                        tint: AppPalette.primary
                    )
                }
            }
        }
    }

    private func subtitle(for transaction: MoneyTransaction) -> String {
        let displayMonth = transaction.recurrence == .yearlyMonth
            ? Date.monthStart(forMonthNumber: transaction.recurrenceMonth)
            : transaction.monthStart
        var parts = [transaction.dayDescription()]

        switch transaction.recurrence {
        case .weekly:
            parts.append(RecurrenceType.weekly.title)
        case .monthly:
            parts.append(RecurrenceType.monthly.title)
        case .quarterly, .semiannual, .annual:
            parts.append(Date.monthName(forMonthNumber: displayMonth.monthNumber))
            if let recurrence = transaction.recurrence {
                parts.append(recurrence.title)
            }
        case .yearlyMonth:
            parts.append(Date.monthName(forMonthNumber: transaction.recurrenceMonth))
            parts.append(AppStrings.text(.annualRecurrence))
        case nil:
            break
        }

        return parts.joined(separator: " - ")
    }
}

func analyticsTransactionTitle(for transaction: MoneyTransaction) -> String {
    let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedTitle.isEmpty ? transaction.displayName : trimmedTitle
}
