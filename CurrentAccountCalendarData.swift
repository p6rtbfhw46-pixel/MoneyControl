import Foundation

struct CalendarTransactionRequest: Identifiable {
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?

    var id: String {
        "\(transaction.id.uuidString)-\(month.notificationIdentifierDate)-\(occurrenceDay ?? 0)"
    }
}

struct CalendarDayRequest: Identifiable {
    let day: Int
    let month: Date
    let anchor: String

    var id: String {
        "\(month.notificationIdentifierDate)-\(day)-\(anchor)"
    }
}

enum CurrentAccountCalendarData {
    static func calendarDays(in month: Date, firstWeekday: Int) -> [Int?] {
        let firstDay = month.monthStart
        let weekday = Calendar.current.component(.weekday, from: firstDay)
        let leadingEmptyDays = (weekday - firstWeekday + 7) % 7

        return Array(repeating: nil, count: leadingEmptyDays)
            + (1...month.daysInMonth).map(Optional.init)
    }

    static func weekdaySymbols(
        localeIdentifier: String,
        firstWeekday: Int
    ) -> [String] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: localeIdentifier)

        let fallback = ["S", "M", "T", "W", "T", "F", "S"]
        let symbols = calendar.veryShortWeekdaySymbols
        let resolvedSymbols = symbols.count == 7 ? symbols : fallback
        let startIndex = min(max(firstWeekday - 1, 0), resolvedSymbols.count - 1)

        return Array(resolvedSymbols[startIndex...])
            + Array(resolvedSymbols[..<startIndex])
    }

    static func transactionsByDay(
        transactions: [MoneyTransaction],
        month: Date,
        exclusions: [RecurrenceExclusion]
    ) -> [Int: [MoneyTransaction]] {
        var result: [Int: [MoneyTransaction]] = [:]

        for transaction in transactions {
            let days: [Int]
            if transaction.recurrence == .weekly {
                days = transaction.occurrenceDays(in: month, exclusions: exclusions)
            } else {
                days = [transaction.effectiveDay(in: month)]
            }

            for day in days {
                result[day, default: []].append(transaction)
            }
        }

        for day in result.keys {
            result[day]?.sort(by: transactionSort)
        }

        return result
    }

    nonisolated private static func transactionSort(
        _ first: MoneyTransaction,
        _ second: MoneyTransaction
    ) -> Bool {
        if first.kind != second.kind {
            return first.kind == TransactionKind.income.rawValue
        }
        if first.amount != second.amount {
            return first.amount > second.amount
        }
        return transactionTitle(first)
            .localizedCaseInsensitiveCompare(transactionTitle(second)) == .orderedAscending
    }

    nonisolated static func transactionTitle(_ transaction: MoneyTransaction) -> String {
        let freeText = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return freeText.isEmpty ? transaction.displayName : freeText
    }
}
