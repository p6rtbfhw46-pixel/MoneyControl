//
//  ContentView.swift
//  MoneyControl
//
//  Created by Paulo Gaio on 29/07/2026.
//

import SwiftData
import SwiftUI
import Charts
import UIKit
import UserNotifications
import Vision
import VisionKit

private enum MainTab: CaseIterable, Identifiable {
    case currentAccount
    case credits
    case management

    var id: Self { self }

    var title: String {
        switch self {
        case .currentAccount:
            AppStrings.text(.currentAccount)
        case .credits:
            AppStrings.text(.credits)
        case .management:
            AppStrings.text(.management)
        }
    }

    var systemImage: String {
        switch self {
        case .currentAccount:
            "list.bullet.rectangle"
        case .credits:
            "chart.bar"
        case .management:
            "square.grid.2x2"
        }
    }

    var bannerColor: Color {
        switch self {
        case .currentAccount:
            AppPalette.mediumBlue
        case .credits:
            AppPalette.positive
        case .management:
            AppPalette.purple
        }
    }
}

private enum PhoneTab: Hashable, Identifiable {
    case currentAccount
    case credits
    case management
    case filters

    var id: Self { self }

    var mainTab: MainTab? {
        switch self {
        case .currentAccount:
            .currentAccount
        case .credits:
            .credits
        case .management:
            .management
        case .filters:
            nil
        }
    }
}

private enum AnalyticsExpenseTab {
    case whereSpent
    case budgetRule
}

private enum AnalyticsPeriod {
    case month
    case year
}

private enum LightweightEvolutionKind: String, CaseIterable, Identifiable {
    case balance
    case savings
    case credits

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balance:
            "Saldo"
        case .savings:
            SavingsStrings.text(.settingsTitle)
        case .credits:
            CreditStrings.text(.settingsTitle)
        }
    }

    var systemImage: String {
        switch self {
        case .balance:
            "wallet.pass"
        case .savings:
            "leaf.fill"
        case .credits:
            "creditcard"
        }
    }

    var currentMetricTitle: String {
        switch self {
        case .balance:
            "Saldo atual"
        case .savings:
            "Total atual"
        case .credits:
            "Dívida atual"
        }
    }

    var tint: Color {
        switch self {
        case .balance, .savings:
            AppPalette.savings
        case .credits:
            AppPalette.primary
        }
    }
}

private struct LightweightEvolutionPoint: Identifiable {
    let month: Date
    let value: Double
    let markerTitle: String?
    let markerIcon: String?
    let markerTint: Color?

    var id: Date { month }
    var label: String { month.formatted(.dateTime.month(.abbreviated)) }
}

private struct LightweightEvolutionTable {
    let balance: [LightweightEvolutionPoint]
    let savings: [LightweightEvolutionPoint]
    let credits: [LightweightEvolutionPoint]

    static let empty = LightweightEvolutionTable(balance: [], savings: [], credits: [])

    func points(for kind: LightweightEvolutionKind) -> [LightweightEvolutionPoint] {
        switch kind {
        case .balance:
            balance
        case .savings:
            savings
        case .credits:
            credits
        }
    }

    func replacing(_ points: [LightweightEvolutionPoint], for kind: LightweightEvolutionKind) -> LightweightEvolutionTable {
        switch kind {
        case .balance:
            LightweightEvolutionTable(balance: points, savings: savings, credits: credits)
        case .savings:
            LightweightEvolutionTable(balance: balance, savings: points, credits: credits)
        case .credits:
            LightweightEvolutionTable(balance: balance, savings: savings, credits: points)
        }
    }
}

private enum AnalyticsHistoryFilterMode: String, CaseIterable, Identifiable {
    case month
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month:
            "Mês"
        case .custom:
            "Intervalo"
        }
    }
}

private enum AnalyticsSidebarTab: CaseIterable, Identifiable {
    case overview
    case monthYear
    case summaries
    case savingsCredits
    case history

    var id: Self { self }

    var title: String {
        switch self {
        case .overview:
            AppStrings.text(.analyticsOverview)
        case .monthYear:
            AppStrings.text(.analyticsMonthYear)
        case .summaries:
            AppStrings.text(.analyticsSummaries)
        case .savingsCredits:
            AppStrings.text(.analyticsSavingsCredits)
        case .history:
            AppStrings.text(.movementHistory)
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            "chart.pie"
        case .monthYear:
            "calendar"
        case .summaries:
            "list.bullet.rectangle"
        case .savingsCredits:
            "target"
        case .history:
            "clock.arrow.circlepath"
        }
    }
}

private enum CurrentAccountSidebarTab: CaseIterable, Identifiable {
    case monthlyList
    case calendar

    var id: Self { self }

    var title: String {
        switch self {
        case .monthlyList:
            AppStrings.text(.currentAccountMonthlyList)
        case .calendar:
            AppStrings.text(.currentAccountCalendar)
        }
    }

    var systemImage: String {
        switch self {
        case .monthlyList:
            "list.bullet.rectangle"
        case .calendar:
            "calendar"
        }
    }
}

private enum ManagementSidebarTab: CaseIterable, Identifiable, Hashable {
    case accounts
    case recurringExpenses
    case recurringIncome
    case savings
    case credits

    var id: Self { self }

    var title: String {
        switch self {
        case .accounts:
            AppStrings.text(.accounts)
        case .recurringExpenses:
            AppStrings.text(.recurringExpenses)
        case .recurringIncome:
            AppStrings.text(.recurringIncome)
        case .savings:
            SavingsStrings.text(.settingsTitle)
        case .credits:
            CreditStrings.text(.settingsTitle)
        }
    }

    var systemImage: String {
        switch self {
        case .accounts:
            "wallet.pass.fill"
        case .recurringExpenses:
            "arrow.triangle.2.circlepath"
        case .recurringIncome:
            "banknote"
        case .savings:
            "target"
        case .credits:
            "creditcard.fill"
        }
    }
}

enum CurrentAccountPaymentFilter: String, CaseIterable, Identifiable {
    case all
    case paid
    case unpaid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            AppStrings.text(.all)
        case .paid:
            AppStrings.text(.paidPlural)
        case .unpaid:
            AppStrings.text(.unpaidPlural)
        }
    }
}

private struct ExpenseNoticeItem {
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?

    var day: Int {
        occurrenceDay ?? transaction.effectiveDay(in: month)
    }
}

private enum AnalyticsListTab: String, CaseIterable, Identifiable {
    case subscriptions
    case savings
    case incomeVsExpenses

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subscriptions:
            AppStrings.text(.subscriptionsThisMonth)
        case .savings:
            AppStrings.text(.yearSavings)
        case .incomeVsExpenses:
            AppStrings.text(.incomeVsExpenses)
        }
    }
}

private enum SubscriptionAnalysisScope: String, CaseIterable, Identifiable {
    case monthly
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            AppStrings.text(.monthlyRecurrence)
        case .all:
            AppStrings.text(.all)
        }
    }
}

private struct ExpenseNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct PaymentEditorRequest: Identifiable {
    let id = UUID()
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?
    let initialAmount: Double
}

private struct CalendarTransactionRequest: Identifiable {
    let transaction: MoneyTransaction
    let month: Date
    let occurrenceDay: Int?

    var id: String { "\(transaction.id.uuidString)-\(month.notificationIdentifierDate)-\(occurrenceDay ?? 0)" }
}

private struct CalendarDayRequest: Identifiable {
    let day: Int
    let month: Date
    let anchor: String

    var id: String { "\(month.notificationIdentifierDate)-\(day)-\(anchor)" }
}

private struct SavingsHistoryRequest: Identifiable {
    let month: Date

    var id: Date { month }
}

private struct SavingsHistoryLine: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: Double
    let icon: String
}

private struct AnalyticsHistoryLine: Identifiable {
    let id: String
    let date: Date
    let name: String
    let type: String
    let note: String
    let amount: Double
    let amountText: String
    let amountColor: Color
    let icon: String
    let tint: Color
}

private struct AnalyticsQuickSummaryCards: View {
    let savingSubtitle: String
    let savingValue: String
    let creditIcon: String
    let creditSubtitle: String
    let creditValue: String
    let savingsAction: () -> Void
    let creditsAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AnalyticsQuickSummaryCardView(
                icon: "leaf.fill",
                title: "Maior poupança",
                subtitle: savingSubtitle,
                value: savingValue,
                tint: AppPalette.savings,
                action: savingsAction
            )

            AnalyticsQuickSummaryCardView(
                icon: creditIcon,
                title: "Maior crédito",
                subtitle: creditSubtitle,
                value: creditValue,
                tint: AppPalette.primary,
                action: creditsAction
            )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AnalyticsQuickSummaryCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.14), in: Circle())

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func phoneTabRootStyle(title: String) -> some View {
        background {
            AppPalette.appBackground
                .ignoresSafeArea()
                .backgroundExtensionEffectIfAvailable()
        }
        .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    func analyticsDetailDestinations(
        saving: Binding<SavingAccount?>,
        credit: Binding<CreditAccount?>
    ) -> some View {
        navigationDestination(item: saving) { saving in
            SavingDetailView(saving: saving)
        }
        .navigationDestination(item: credit) { credit in
            CreditDetailView(credit: credit)
        }
    }
}

struct ReceiptScanResult {
    var title: String
    var amount: Double?
    var date: Date?
    var category: ExpenseCategory
    var expenseName: String
    var recognizedText: String
}

struct ReceiptScannerView: UIViewControllerRepresentable {
    let onComplete: (ReceiptScanResult) -> Void
    let onCancel: () -> Void
    let onFailure: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel, onFailure: onFailure)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (ReceiptScanResult) -> Void
        let onCancel: () -> Void
        let onFailure: (String) -> Void

        init(
            onComplete: @escaping (ReceiptScanResult) -> Void,
            onCancel: @escaping () -> Void,
            onFailure: @escaping (String) -> Void
        ) {
            self.onComplete = onComplete
            self.onCancel = onCancel
            self.onFailure = onFailure
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            Task {
                let lines = Self.recognizeText(in: scan)
                let result = ReceiptParser.parse(lines: lines)
                self.onComplete(result)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
            onFailure(error.localizedDescription)
        }

        private static func recognizeText(in scan: VNDocumentCameraScan) -> [String] {
            var lines: [String] = []

            for pageIndex in 0..<scan.pageCount {
                guard let cgImage = scan.imageOfPage(at: pageIndex).cgImage else { continue }

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["pt-PT", "en-US"]

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let recognizedLines = request.results?.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    } ?? []
                    lines.append(contentsOf: recognizedLines)
                } catch {
                    continue
                }
            }

            return lines
        }
    }
}

enum ReceiptParser {
    static func parse(lines: [String]) -> ReceiptScanResult {
        let normalizedLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let title = merchantName(from: normalizedLines)
        let amount = totalAmount(from: normalizedLines)
        let date = receiptDate(from: normalizedLines)
        let suggestion = categorySuggestion(for: title, lines: normalizedLines)

        return ReceiptScanResult(
            title: title.isEmpty ? "Fatura" : title,
            amount: amount,
            date: date,
            category: suggestion.category,
            expenseName: suggestion.expenseName,
            recognizedText: normalizedLines.joined(separator: "\n")
        )
    }

    private static func merchantName(from lines: [String]) -> String {
        for line in lines.prefix(8) {
            let cleanedLine = line
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleanedLine.count >= 3,
                  cleanedLine.filter({ $0.isLetter }).count >= 3 else {
                continue
            }

            return cleanedLine
        }

        return "Fatura"
    }

    private static func totalAmount(from lines: [String]) -> Double? {
        if let amountAfterTotal = amountAfterTotalKeyword(from: lines) {
            return amountAfterTotal
        }

        var bestCandidate: (amount: Double, score: Int)?
        let totalKeywords = ["total", "valor pago", "pago", "importancia", "montante", "a pagar", "eur"]
        let negativeKeywords = ["troco", "nif", "contribuinte", "iva", "taxa", "subtotal", "desconto"]

        for (index, line) in lines.enumerated() {
            let normalizedLine = normalized(line)
            let amounts = amounts(in: line)
            guard !amounts.isEmpty else { continue }

            var score = 0
            if totalKeywords.contains(where: { normalizedLine.contains($0) }) { score += 20 }
            if negativeKeywords.contains(where: { normalizedLine.contains($0) }) { score -= 12 }
            score += max(0, 8 - index)

            for amount in amounts where amount > 0 && amount < 100_000 {
                let candidateScore = score + Int(min(amount, 999) / 100)
                if bestCandidate == nil || candidateScore > bestCandidate!.score || (candidateScore == bestCandidate!.score && amount > bestCandidate!.amount) {
                    bestCandidate = (amount, candidateScore)
                }
            }
        }

        return bestCandidate?.amount
    }

    private static func amountAfterTotalKeyword(from lines: [String]) -> Double? {
        for (index, line) in lines.enumerated() {
            let normalizedLine = normalized(line)
            guard hasStandaloneTotalKeyword(in: normalizedLine) else { continue }

            let totalRange = line.range(of: "total", options: [.caseInsensitive, .diacriticInsensitive])
            let textAfterTotal: String
            if let totalRange {
                textAfterTotal = String(line[totalRange.upperBound...])
            } else {
                textAfterTotal = line
            }

            if let amount = amounts(in: textAfterTotal).last(where: { $0 > 0 && $0 < 100_000 }) {
                return amount
            }

            if lines.indices.contains(index + 1),
               let amount = amounts(in: lines[index + 1]).last(where: { $0 > 0 && $0 < 100_000 }) {
                return amount
            }
        }

        return nil
    }

    private static func hasStandaloneTotalKeyword(in line: String) -> Bool {
        let tokens = line.components(separatedBy: CharacterSet.letters.inverted)
        return tokens.contains("total")
    }

    private static func amounts(in line: String) -> [Double] {
        let pattern = #"(?<!\d)(\d{1,4}(?:[ .]\d{3})*[,.]\d{2})(?!\d)|(?<!\d)(\d{1,5})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)

        return regex.matches(in: line, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: line) else { return nil }
            let rawValue = String(line[range])
            return decimalValue(from: rawValue)
        }
    }

    private static func decimalValue(from rawValue: String) -> Double? {
        var value = rawValue.replacingOccurrences(of: " ", with: "")

        if value.contains(",") {
            value = value.replacingOccurrences(of: ".", with: "")
            value = value.replacingOccurrences(of: ",", with: ".")
        }

        return Double(value)
    }

    private static func receiptDate(from lines: [String]) -> Date? {
        let text = lines.joined(separator: " ")
        let pattern = #"\b(\d{1,2})[\-/\.](\d{1,2})[\-/\.](\d{2,4})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)),
              let dayRange = Range(match.range(at: 1), in: text),
              let monthRange = Range(match.range(at: 2), in: text),
              let yearRange = Range(match.range(at: 3), in: text),
              let day = Int(text[dayRange]),
              let month = Int(text[monthRange]),
              var year = Int(text[yearRange]) else {
            return nil
        }

        if year < 100 { year += 2000 }
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    private static func categorySuggestion(for merchant: String, lines: [String]) -> (category: ExpenseCategory, expenseName: String) {
        let text = normalized(([merchant] + lines).joined(separator: " "))

        if containsAny(text, ["continente", "pingo doce", "lidl", "aldi", "auchan", "mercadona", "intermarche", "supermerc", "mini preco", "mercearia"]) {
            return (.needs, expenseName(in: .needs, index: 2, fallback: "Alimentação: compras de supermercado"))
        }

        if containsAny(text, ["uber", "bolt", "cp", "metro", "comboio", "bus", "autocarro", "galp", "bp", "repsol", "prio", "combustivel"]) {
            return (.needs, expenseName(in: .needs, index: 1, fallback: "Transportes: transporte público, prestações e combustível"))
        }

        if containsAny(text, ["restaurante", "cafe", "pastelaria", "pizz", "burger", "glovo", "ubereats", "takeaway", "snack"]) {
            return (.wants, expenseName(in: .wants, index: 0, fallback: "Refeições fora de casa"))
        }

        if containsAny(text, ["cinema", "teatro", "netflix", "spotify", "bilhete", "lazer"]) {
            return (.wants, expenseName(in: .wants, index: 2, fallback: "Atividades de lazer e entretenimento"))
        }

        if containsAny(text, ["zara", "hm", "primark", "worten", "fnac", "amazon", "loja", "moda"]) {
            return (.wants, expenseName(in: .wants, index: 4, fallback: "Roupa e acessórios"))
        }

        return (.wants, expenseName(in: .wants, index: 5, fallback: "Outros"))
    }

    private static func expenseName(in category: ExpenseCategory, index: Int, fallback: String) -> String {
        category.names.indices.contains(index) ? category.names[index] : fallback
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private static func normalized(_ text: String) -> String {
        text
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
}

private struct ExpensePaymentReminder: Sendable {
    let identifier: String
    let title: String
    let body: String
    let fireDate: Date
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [MoneyTransaction]
    @Query private var payments: [ExpensePayment]
    @Query private var paymentHistory: [PaymentHistoryEntry]
    @Query private var exclusions: [RecurrenceExclusion]
    @Query private var creditAccounts: [CreditAccount]
    @Query private var creditMovements: [CreditMovement]
    @Query private var savingAccounts: [SavingAccount]
    @Query private var savingMovements: [SavingMovement]
    @Query private var spendAccounts: [SpendAccount]
    @Query private var accountMovements: [AccountMovement]
    @Query private var auditLogEntries: [AuditLogEntry]

    @AppStorage(AppPreferences.selectedCurrencyCodeKey) private var selectedCurrencyCode = ""
    @AppStorage(AppPreferences.notificationsEnabledKey) private var notificationsEnabled = true
    @AppStorage(AppPreferences.launchPaymentReminderEnabledKey) private var launchPaymentReminderEnabled = true
    @AppStorage("currentAccountPaymentFilter") private var storedPaymentFilter = CurrentAccountPaymentFilter.all.rawValue
    @AppStorage("currentAccountFilteredCategories") private var storedFilteredCategories = ""
    @AppStorage("currentAccountFilteredExpenseType") private var storedFilteredExpenseType = ""
    @AppStorage("currentAccountFreeTextFilter") private var storedFreeTextFilter = ""
    @State private var selectedMonthOffset = 0
    @State private var monthNavigationDirection = 1
    @State private var selectedTab: MainTab = .currentAccount
    @State private var selectedPhoneTab: PhoneTab = .currentAccount
    @State private var managementNavigationResetID = UUID()
    @State private var showsPhoneAccountsManagement = false
    @State private var selectedCurrentAccountSidebarTab: CurrentAccountSidebarTab = .monthlyList
    @State private var selectedAnalyticsSidebarTab: AnalyticsSidebarTab = .overview
    @State private var selectedManagementSidebarTab: ManagementSidebarTab = .accounts
    @State private var selectedAnalyticsExpenseTab: AnalyticsExpenseTab = .whereSpent
    @State private var selectedAnalyticsPeriod: AnalyticsPeriod = .month
    @State private var selectedAnalyticsMonthOffset = 0
    @State private var selectedAnalyticsListTab: AnalyticsListTab = .subscriptions
    @State private var selectedSubscriptionAnalysisScope: SubscriptionAnalysisScope = .monthly
    @State private var selectedAnalyticsHistoryFilterMode: AnalyticsHistoryFilterMode = .month
    @State private var selectedAnalyticsHistoryMonthOffset = 0
    @State private var analyticsHistoryStartDate = Date().monthStart
    @State private var analyticsHistoryEndDate = Date()
    @State private var selectedLightweightEvolutionKind: LightweightEvolutionKind = .balance
    @State private var selectedAnalyticsSavingDetail: SavingAccount?
    @State private var selectedAnalyticsCreditDetail: CreditAccount?
    @State private var lightweightEvolutionTable: LightweightEvolutionTable = .empty
    @State private var lightweightEvolutionSignatureSnapshot = ""
    @State private var isLightweightEvolutionLoading = false
    @State private var expandedLightweightEvolutionMarkerID: Date?
    @State private var selectedAdviceIndex = 0
    @State private var editorRequest: TransactionEditorRequest?
    @State private var paymentEditorRequest: PaymentEditorRequest?
    @State private var currentAccountCreditMovementRequest: CurrentAccountCreditMovementRequest?
    @State private var calendarTransactionRequest: CalendarTransactionRequest?
    @State private var calendarPopoverRequest: CalendarTransactionRequest?
    @State private var calendarDayRequest: CalendarDayRequest?
    @State private var calendarDayExpandedTransactionID: UUID?
    @State private var showsSettings = false
    @State private var settingsInitialTab: SettingsTab = .budget
    @State private var showsQuickActions = false
    @State private var showsRecurringQuickActions = false
    @State private var showsReceiptScanner = false
    @State private var showsFilters = false
    @State private var showsUnpaidExpensesBreakdown = false
    @State private var paymentFilter: CurrentAccountPaymentFilter = .all
    @State private var filteredCategories: Set<ExpenseCategory> = []
    @State private var filteredExpenseType = ""
    @State private var freeTextFilter = ""
    @State private var expenseNotice: ExpenseNotice?
    @State private var savingsHistoryRequest: SavingsHistoryRequest?
    @State private var didLoadStoredFilters = false
    @State private var didCheckOverdueExpenses = false
    @State private var didRunStartupMaintenance = false

    private let monthOffsets = Array(-12...12)
    private var selectedMonth: Date { Calendar.current.date(byAdding: .month, value: selectedMonthOffset, to: Date().monthStart) ?? Date().monthStart }
    private var currentMonth: Date { Date().monthStart }
    private var managementRecurringMonthlyBalance: Double {
        let currentMonthIncome = transactions
            .filter { $0.kind == TransactionKind.income.rawValue && $0.isRecurring && $0.isActiveForSettingsList && $0.recurrence == .monthly }
            .reduce(0) { $0 + $1.scheduledAmount(in: currentMonth) }
        let currentMonthExpenses = transactions
            .filter { $0.kind == TransactionKind.expense.rawValue && $0.isRecurring && $0.isActiveForSettingsList && $0.recurrence == .monthly }
            .reduce(0) { $0 + $1.scheduledAmount(in: currentMonth) }
        return currentMonthIncome - currentMonthExpenses
    }
    private var managementTotalSaved: Double {
        savingAccounts
            .filter { $0.savingStatus == .active }
            .reduce(0) { $0 + $1.balance(with: savingMovements) }
    }
    private var managementTotalDebt: Double {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .reduce(0) { $0 + $1.balance(with: creditMovements) }
    }
    private var primarySpendAccount: SpendAccount? {
        spendAccounts.first(where: \.isPrimary) ?? spendAccounts.first
    }
    private var totalSpendAccountsBalance: Double {
        spendAccounts.reduce(0) { $0 + $1.balance(with: accountMovements) }
    }
    private var primarySpendAccountBalance: Double? {
        primarySpendAccount?.balance(with: accountMovements)
    }
    private var hasMultipleSpendAccounts: Bool {
        spendAccounts.count > 1
    }
    private var selectedMonthShowsCurrentDay: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }
    private var currentDayNumber: Int {
        Calendar.current.component(.day, from: Date())
    }
    private var calculator: MoneyCalculationService {
        MoneyCalculationService(transactions: transactions, payments: payments, exclusions: exclusions)
    }
    private var selectedTransactions: [MoneyTransaction] { calculator.visibleTransactions(in: selectedMonth) }
    private var selectedFilteredTransactions: [MoneyTransaction] { filteredTransactions(in: selectedMonth) }
    private var currentMonthTransactions: [MoneyTransaction] { calculator.visibleTransactions(in: currentMonth) }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentYearMonths: [Date] {
        MoneyCalculationService.monthsInYear(currentYear)
    }
    private var notificationScheduleSignature: String {
        let transactionSignature = transactions
            .map { transaction in
                [
                    transaction.id.uuidString,
                    transaction.title,
                    transaction.displayName,
                    transaction.kind,
                    transaction.expenseCategory ?? "",
                    "\(transaction.day)",
                    "\(transaction.amount)",
                    transaction.monthStart.ISO8601Format(),
                    transaction.recurrenceType ?? "",
                    "\(transaction.recurrenceMonth)",
                    transaction.recurrenceEndMonthStart?.ISO8601Format() ?? ""
                ].joined(separator: "|")
            }
            .sorted()
            .joined(separator: ";")
        let paymentSignature = payments
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())|\($0.amountPaid ?? -1)" }
            .sorted()
            .joined(separator: ";")
        let exclusionSignature = exclusions
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())" }
            .sorted()
            .joined(separator: ";")

        return [transactionSignature, paymentSignature, exclusionSignature].joined(separator: "#")
    }

    private var activeFilterCount: Int {
        var count = 0
        if paymentFilter != .all { count += 1 }
        if !filteredCategories.isEmpty { count += 1 }
        if !filteredExpenseType.isEmpty { count += 1 }
        if !freeTextFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        return count
    }
    private var selectedMonthExpenseTypeOptions: [ExpenseTypePoint] {
        var options: [String: ExpenseTypePoint] = [:]

        selectedTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .forEach { transaction in
                guard !transaction.displayName.isEmpty,
                      let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? "")
                else { return }

                let key = "\(category.rawValue)-\(transaction.displayName)"
                options[key] = ExpenseTypePoint(title: transaction.displayName, category: category, amount: 0)
            }

        return options.values.sorted { first, second in
            first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
        }
    }
    private var accountOccurrencesUntilToday: [TransactionOccurrence] {
        calculator.accountOccurrencesUntilToday(now: Date())
    }
    private var accountSummary: AccountSummary {
        calculator.accountSummary(until: Date())
    }
    private var futureBudgetReservations: [ReservedIncomeSummary] {
        accountSummary.reservedForFutureBudgets
    }
    private var firstFutureBudgetReservation: ReservedIncomeSummary? {
        futureBudgetReservations.first
    }
    private var futureBudgetReservationTotal: Double {
        accountSummary.reservedForFutureBudgetsTotal
    }
    private var futureBudgetReservationFootnote: String {
        guard let firstFutureBudgetReservation else { return "" }
        let total = futureBudgetReservationTotal
        return String(
            format: AppStrings.text(.reservedForBudgetSummary),
            total.currencyText,
            firstFutureBudgetReservation.budgetMonth.monthTitle
        )
    }
    private var balanceCardFootnote: String {
        var parts: [String] = []
        if hasMultipleSpendAccounts {
            parts.append(String(format: AppStrings.text(.totalAllAccountsSummary), totalSpendAccountsBalance.currencyText))
        }
        if !futureBudgetReservationFootnote.isEmpty {
            parts.append(futureBudgetReservationFootnote)
        }
        return parts.joined(separator: "\n")
    }
    private var balanceHelpText: String {
        guard let firstFutureBudgetReservation, futureBudgetReservationTotal > 0 else {
            return AppStrings.text(.balanceThisMonthHelp)
        }

        return String(
            format: AppStrings.text(.reservedBalanceHelpMessage),
            inAccount.currencyText,
            futureBudgetReservationTotal.currencyText,
            firstFutureBudgetReservation.budgetMonth.monthTitle,
            currentMonth.monthTitle
        )
    }

    private var monthUnpaidExpenses: Double {
        guard activeFilterCount > 0 else {
            return unpaidExpenses(in: selectedMonth)
        }

        return selectedFilteredTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .reduce(0) { total, transaction in
                total + filteredUnpaidAmount(for: transaction, in: selectedMonth)
            }
    }

    private func filteredUnpaidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        transaction.occurrenceDays(in: month, exclusions: exclusions).reduce(0) { total, day in
            let occurrenceDay = transaction.recurrence == .weekly ? day : nil
            let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
            let paidAmount = paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
            let isPaid = paidAmount >= scheduledAmount

            if paymentFilter == .paid && !isPaid { return total }
            if paymentFilter == .unpaid && isPaid { return total }

            return total + max(scheduledAmount - paidAmount, 0)
            }
    }

    private func unpaidExpenses(in month: Date) -> Double {
        calculator.monthSummary(in: month).unpaidExpenses
    }

    private var unpaidExpenseLines: [UnpaidExpenseLine] {
        let sourceTransactions = activeFilterCount > 0 ? selectedFilteredTransactions : selectedTransactions

        return sourceTransactions
            .filter { $0.kind == TransactionKind.expense.rawValue }
            .flatMap { transaction in
                transaction.occurrenceDays(in: selectedMonth, exclusions: exclusions).compactMap { day -> UnpaidExpenseLine? in
                    let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                    let scheduledAmount = transaction.scheduledAmount(in: selectedMonth, occurrenceDay: occurrenceDay)
                    let paidAmount = paidAmount(for: transaction, in: selectedMonth, occurrenceDay: occurrenceDay)
                    let remainingAmount = max(scheduledAmount - paidAmount, 0)
                    guard remainingAmount > 0.005 else { return nil }

                    return UnpaidExpenseLine(
                        title: unpaidExpenseTitle(for: transaction),
                        subtitle: unpaidExpenseSubtitle(for: transaction, day: day),
                        day: day,
                        scheduledAmount: scheduledAmount,
                        paidAmount: paidAmount,
                        remainingAmount: remainingAmount,
                        isWeekly: transaction.recurrence == .weekly
                    )
                }
            }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    private var unpaidExpenseLinesTotal: Double {
        unpaidExpenseLines.reduce(0) { $0 + $1.remainingAmount }
    }

    private func unpaidExpenseTitle(for transaction: MoneyTransaction) -> String {
        let title = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? transaction.displayName : title
    }

    private func unpaidExpenseSubtitle(for transaction: MoneyTransaction, day: Int) -> String {
        var parts = ["Dia \(day)"]

        if transaction.recurrence == .weekly {
            parts.append(AppStrings.text(.weeklyRecurrence))
        }

        if !transaction.displayName.isEmpty, transaction.displayName != transaction.title {
            parts.append(transaction.displayName)
        }

        return parts.joined(separator: " - ")
    }

    private var monthIncome: Double {
        calculator.monthSummary(in: selectedMonth).income
    }

    private var monthExpenses: Double {
        calculator.monthSummary(in: selectedMonth).expenses
    }

    private var incomeUntilToday: Double {
        accountSummary.incomeUntilToday
    }

    private var paidExpensesUntilToday: Double {
        accountSummary.paidExpensesUntilToday
    }

    private var inAccount: Double { primarySpendAccountBalance ?? accountSummary.availableBalance }
    private var totalAvailableBalance: Double {
        spendAccounts.isEmpty ? accountSummary.availableBalance : totalSpendAccountsBalance
    }

    private func auditBalanceAfter(delta: Double = 0) -> Double {
        totalAvailableBalance + delta
    }

    private func insertAuditLog(
        action: AuditLogAction,
        title: String,
        details: String = "",
        note: String = "",
        amount: Double = 0,
        balanceAfter: Double? = nil,
        accountID: UUID? = nil,
        relatedAccountID: UUID? = nil,
        transactionID: UUID? = nil,
        paymentHistoryID: UUID? = nil,
        creditID: UUID? = nil,
        savingID: UUID? = nil,
        date: Date = Date()
    ) {
        modelContext.insert(AuditLogEntry(
            date: date,
            action: action.rawValue,
            title: title,
            details: details,
            note: note,
            amount: amount,
            balanceAfter: balanceAfter ?? auditBalanceAfter(),
            accountID: accountID,
            relatedAccountID: relatedAccountID,
            transactionID: transactionID,
            paymentHistoryID: paymentHistoryID,
            creditID: creditID,
            savingID: savingID
        ))
    }
    private var isSelectedMonthInSpendableWindow: Bool {
        guard let maximumMonth = Calendar.current.date(byAdding: .month, value: 2, to: currentMonth) else {
            return Calendar.current.isDate(selectedMonth, equalTo: currentMonth, toGranularity: .month)
        }

        return selectedMonth >= currentMonth && selectedMonth <= maximumMonth.monthStart
    }
    private var monthRemaining: Double? {
        guard isSelectedMonthInSpendableWindow else { return nil }

        let calendar = Calendar.current
        let selectedMonthStart = selectedMonth.monthStart
        let currentMonthStart = currentMonth.monthStart
        var projectedRemaining = totalAvailableBalance - unpaidExpenses(in: currentMonthStart)

        guard selectedMonthStart > currentMonthStart else {
            return activeFilterCount > 0 ? totalAvailableBalance - monthUnpaidExpenses : projectedRemaining
        }

        var projectedMonth = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)?.monthStart
        while let month = projectedMonth, month <= selectedMonthStart {
            let summary = calculator.monthSummary(in: month)
            projectedRemaining += summary.income - summary.unpaidExpenses
            projectedMonth = calendar.date(byAdding: .month, value: 1, to: month)?.monthStart
        }

        return projectedRemaining
    }
    private var selectedAnalyticsMonth: Date {
        Calendar.current.date(byAdding: .month, value: selectedAnalyticsMonthOffset, to: Date().monthStart) ?? Date().monthStart
    }
    private var analyticsMonths: [Date] {
        selectedAnalyticsPeriod == .month ? [selectedAnalyticsMonth] : currentYearMonths
    }
    private var analyticsCategoryExpenses: [CategoryExpensePoint] {
        calculator.categoryExpenses(in: analyticsMonths, paidOnly: false)
            .map { CategoryExpensePoint(category: $0.category, amount: sanitizedChartAmount($0.amount)) }
    }
    private var analyticsExpenseTotal: Double {
        analyticsCategoryExpenses.reduce(0) { $0 + $1.amount }
    }
    private var analyticsExpenseTypePoints: [ExpenseTypePoint] {
        expenseTypePoints(in: analyticsMonths)
            .map { ExpenseTypePoint(title: $0.title, category: $0.category, amount: sanitizedChartAmount($0.amount)) }
            .filter { $0.amount > 0 }
    }
    private var budgetReferencePoints: [CategoryExpensePoint] {
        [
            CategoryExpensePoint(category: .needs, amount: 50),
            CategoryExpensePoint(category: .wants, amount: 30),
            CategoryExpensePoint(category: .savingsAndDebt, amount: 20)
        ]
    }
    private var annualBalancePoints: [MonthlyBalancePoint] {
        calculator.annualBalancePoints(in: currentYearMonths, paidOnly: true)
    }
    private var annualBalanceTotal: Double {
        annualBalancePoints.reduce(0) { $0 + $1.balance }
    }
    private var configuredSubscriptions: [MoneyTransaction] {
        return transactions
            .filter { transaction in
                transaction.kind == TransactionKind.expense.rawValue
                    && transaction.isRecurring
                    && transaction.isActiveForSettingsList
                    && normalized(transaction.displayName).contains("subscr")
            }
            .sorted { first, second in
                if first.displayName != second.displayName {
                    return first.displayName.localizedCaseInsensitiveCompare(second.displayName) == .orderedAscending
                }
                return first.monthStart < second.monthStart
            }
    }
    private var displayedConfiguredSubscriptions: [MoneyTransaction] {
        switch selectedSubscriptionAnalysisScope {
        case .monthly:
            configuredSubscriptions.filter { $0.recurrence == .monthly }
        case .all:
            configuredSubscriptions
        }
    }
    private var yearSavingsPoints: [MonthlyBalancePoint] {
        let currentAccountPoints = calculator.yearSavingsPoints(in: currentYearMonths)

        return currentAccountPoints.map { point in
            MonthlyBalancePoint(
                month: point.month,
                income: point.income,
                expenses: point.expenses + directSavingsAmount(in: point.month)
            )
        }
    }

    private var linkedSavingMovementIDs: Set<UUID> {
        Set(transactions.compactMap(\.linkedSavingMovementID))
    }

    private func directSavingsAmount(in month: Date) -> Double {
        let initialAmounts = savingAccounts
            .filter { Calendar.current.isDate($0.createdAt, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + max($1.initialAmount, 0) }

        let directDeposits = savingMovements
            .filter { movement in
                Calendar.current.isDate(movement.date, equalTo: month, toGranularity: .month)
                    && movement.kind == .deposit
                    && !linkedSavingMovementIDs.contains(movement.id)
            }
            .reduce(0) { $0 + abs($1.amount) }

        return initialAmounts + directDeposits
    }

    private func savingsHistoryAmount(in month: Date) -> Double {
        savingsHistoryLines(in: month).reduce(0) { $0 + $1.amount }
    }

    private func savingsHistoryLines(in month: Date) -> [SavingsHistoryLine] {
        let currentAccountLines = calculator.visibleTransactions(in: month)
            .filter { transaction in
                guard transaction.kind == TransactionKind.expense.rawValue else { return false }
                let searchableText = normalized("\(transaction.displayName) \(transaction.title)")
                return searchableText.contains("poup") || searchableText.contains("saving")
            }
            .map { transaction in
                SavingsHistoryLine(
                    title: analyticsTransactionTitle(for: transaction),
                    subtitle: "\(AppStrings.text(.currentAccountSavingSource)) · \(transaction.dayDescription(in: month))",
                    amount: transaction.amount,
                    icon: "list.bullet.rectangle"
                )
            }

        let initialLines = savingAccounts
            .filter { Calendar.current.isDate($0.createdAt, equalTo: month, toGranularity: .month) && $0.initialAmount > 0 }
            .map { saving in
                SavingsHistoryLine(
                    title: saving.displayName,
                    subtitle: AppStrings.text(.initialSavingAmount),
                    amount: saving.initialAmount,
                    icon: "target"
                )
            }

        let directDepositLines = savingMovements
            .filter { movement in
                Calendar.current.isDate(movement.date, equalTo: month, toGranularity: .month)
                    && movement.kind == .deposit
                    && !linkedSavingMovementIDs.contains(movement.id)
            }
            .map { movement in
                SavingsHistoryLine(
                    title: movement.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? savingName(for: movement.savingID) : movement.note,
                    subtitle: "\(AppStrings.text(.directSavingMovement)) · \(movement.date.formatted(.dateTime.day().month(.abbreviated)))",
                    amount: abs(movement.amount),
                    icon: "banknote.fill"
                )
            }

        return (currentAccountLines + initialLines + directDepositLines)
            .sorted { first, second in
                if first.amount != second.amount { return first.amount > second.amount }
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
    }

    private func savingName(for id: UUID) -> String {
        savingAccounts.first { $0.id == id }?.name ?? SavingsStrings.text(.saving)
    }
    private var analyticsAnalysisTitle: String {
        switch selectedAnalyticsPeriod {
        case .month:
            "\(AppStrings.text(.monthAnalysis)) \(selectedAnalyticsMonth.monthTitle)"
        case .year:
            "\(AppStrings.text(.annualBalance)) \(currentYear)"
        }
    }
    private var currentAdvice: (title: String, message: String) {
        let adviceCards = AppStrings.analyticsAdviceCards
        guard !adviceCards.isEmpty else { return ("", "") }
        let index = abs(selectedAdviceIndex) % adviceCards.count
        return adviceCards[index]
    }
    private var navigationTitle: String {
        switch selectedTab {
        case .currentAccount:
            usesSidebarNavigation ? selectedCurrentAccountSidebarTab.title : AppStrings.text(.appName)
        case .credits:
            usesSidebarNavigation ? selectedAnalyticsSidebarTab.title : AppStrings.text(.credits)
        case .management:
            usesSidebarNavigation ? selectedManagementSidebarTab.title : AppStrings.text(.management)
        }
    }

    private func categoryExpenses(in month: Date) -> [CategoryExpensePoint] {
        calculator.categoryExpenses(in: month)
    }

    private func expenseTypePoints(in months: [Date]) -> [ExpenseTypePoint] {
        calculator.expenseTypePoints(in: months, fallbackTitle: AppStrings.text(.expense), paidOnly: false)
    }

    private func sanitizedChartAmount(_ amount: Double) -> Double {
        amount.isFinite ? max(amount, 0) : 0
    }

    private func incomeTotal(in month: Date) -> Double {
        calculator.incomeTotal(in: month)
    }

    private func paidExpenseTotal(in month: Date) -> Double {
        calculator.paidExpenseTotal(in: month)
    }

    private func categoryAmount(in month: Date, category: ExpenseCategory, paidOnly: Bool) -> Double {
        calculator.categoryAmount(in: month, category: category, paidOnly: paidOnly)
    }

    private func expenseAmount(in month: Date, matching keywords: [String], paidOnly: Bool) -> Double {
        calculator.expenseAmount(in: month, matching: keywords, paidOnly: paidOnly)
    }

    private func normalized(_ value: String) -> String {
        MoneyCalculationService.normalized(value)
    }

    private func filteredTransactions(in month: Date) -> [MoneyTransaction] {
        calculator
            .visibleTransactions(in: month)
            .filter { transactionMatchesCurrentAccountFilters($0, in: month) }
    }

    private func transactionMatchesCurrentAccountFilters(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        if paymentFilter != .all {
            guard transaction.kind == TransactionKind.expense.rawValue else { return false }
            guard transactionHasOccurrenceMatchingPaymentFilter(transaction, in: month) else { return false }
        }

        if !filteredCategories.isEmpty {
            guard transaction.kind == TransactionKind.expense.rawValue,
                  let category = ExpenseCategory(rawValue: transaction.expenseCategory ?? ""),
                  filteredCategories.contains(category)
            else { return false }
        }

        if !filteredExpenseType.isEmpty {
            guard transaction.kind == TransactionKind.expense.rawValue,
                  transaction.displayName == filteredExpenseType
            else { return false }
        }

        let searchText = normalized(freeTextFilter.trimmingCharacters(in: .whitespacesAndNewlines))
        if !searchText.isEmpty {
            let transactionText = normalized("\(transaction.displayName) \(transaction.title) \(transaction.detailText(in: month))")
            guard transactionText.contains(searchText) else { return false }
        }

        return true
    }

    private func transactionHasOccurrenceMatchingPaymentFilter(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        transaction.occurrenceDays(in: month, exclusions: exclusions).contains { day in
            let occurrenceDay = transaction.recurrence == .weekly ? day : nil
            let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
            let paidAmount = paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
            let isPaid = paidAmount >= scheduledAmount

            switch paymentFilter {
            case .all:
                return true
            case .paid:
                return isPaid
            case .unpaid:
                return !isPaid
            }
        }
    }

    private func clearCurrentAccountFilters() {
        paymentFilter = .all
        filteredCategories = []
        filteredExpenseType = ""
        freeTextFilter = ""
    }

    var body: some View {
        Group {
            if usesSidebarNavigation {
                sidebarNavigation
            } else {
                phoneNavigation
            }
        }
        .sheet(item: $editorRequest) { request in
            TransactionEditor(request: request)
        }
        .sheet(item: $paymentEditorRequest) { request in
            let occurrenceDay = normalizedPaymentOccurrenceDay(for: request.transaction, occurrenceDay: request.occurrenceDay)
            PaymentAmountPicker(
                title: request.transaction.displayName,
                totalAmount: request.transaction.scheduledAmount(in: request.month, occurrenceDay: occurrenceDay),
                initialAmount: request.initialAmount,
                paymentDate: request.month.date(day: request.occurrenceDay ?? request.transaction.effectiveDay(in: request.month)),
                futureFlexiblePaymentMonth: request.transaction.isWholeMonthExpense ? request.month.monthTitle : nil,
                history: paymentHistoryEntries(for: request.transaction, in: request.month, occurrenceDay: occurrenceDay),
                accounts: spendAccounts,
                accountMovements: accountMovements,
                transactionAccountID: request.transaction.accountID,
                onConfirm: { amount, note, accountID in
                    addPaymentAmount(request.transaction, in: request.month, occurrenceDay: occurrenceDay, amount: amount, note: note, accountID: accountID)
                },
                onDeleteHistoryEntry: { entry in
                    deletePaymentHistoryEntry(entry, for: request.transaction, in: request.month, occurrenceDay: occurrenceDay)
                }
            )
        }
        .sheet(item: $currentAccountCreditMovementRequest) { request in
            CurrentAccountCreditMovementEditor(request: request)
        }
        .sheet(item: $calendarTransactionRequest) { request in
            calendarTransactionDetailSheet(for: request)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsEditor(openingTab: settingsInitialTab)
        }
        .sheet(isPresented: $showsFilters) {
            CurrentAccountFilterView(
                paymentFilter: $paymentFilter,
                filteredCategories: $filteredCategories,
                filteredExpenseType: $filteredExpenseType,
                freeTextFilter: $freeTextFilter,
                expenseTypeOptions: selectedMonthExpenseTypeOptions,
                onClear: clearCurrentAccountFilters
            )
        }
        .sheet(isPresented: $showsUnpaidExpensesBreakdown) {
            UnpaidExpensesBreakdownSheet(
                month: selectedMonth,
                lines: unpaidExpenseLines,
                total: unpaidExpenseLinesTotal
            )
        }
        .sheet(isPresented: $showsReceiptScanner) {
            receiptScannerSheet
        }
        .sheet(item: $savingsHistoryRequest) { request in
            SavingsHistorySheet(
                month: request.month,
                lines: savingsHistoryLines(in: request.month),
                total: savingsHistoryAmount(in: request.month)
            )
        }
        .alert(item: $expenseNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(AppStrings.text(.ok)))
            )
        }
        .task {
            await handleStartupMaintenance()
        }
        .task(id: "\(notificationScheduleSignature)#notifications=\(notificationsEnabled)") {
            await refreshExpensePaymentNotifications()
        }
        .onChange(of: paymentFilter) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: filteredCategories) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: filteredExpenseType) { _, _ in persistCurrentAccountFilters() }
        .onChange(of: freeTextFilter) { _, _ in persistCurrentAccountFilters() }
        .id(selectedCurrencyCode)
    }

    private var receiptScannerSheet: some View {
        ReceiptScannerView(
            onComplete: handleReceiptScanResult,
            onCancel: { showsReceiptScanner = false },
            onFailure: handleReceiptScanFailure
        )
    }

    private var usesSidebarNavigation: Bool {
        UIDevice.current.userInterfaceIdiom != .phone
    }

    private var phoneTabSelection: Binding<PhoneTab> {
        Binding(
            get: { selectedPhoneTab },
            set: { newValue in
                selectedPhoneTab = newValue
                handlePhoneTabSelection(newValue)
            }
        )
    }

    private var phoneNavigation: some View {
        TabView(selection: phoneTabSelection) {
            phoneCurrentAccountNavigation
            .tabItem {
                Label(MainTab.currentAccount.title, systemImage: MainTab.currentAccount.systemImage)
            }
            .tag(PhoneTab.currentAccount)

            phoneCreditsNavigation
            .tabItem {
                Label(MainTab.credits.title, systemImage: MainTab.credits.systemImage)
            }
            .tag(PhoneTab.credits)

            phoneManagementNavigation
            .id(managementNavigationResetID)
            .tabItem {
                Label(MainTab.management.title, systemImage: MainTab.management.systemImage)
            }
            .tag(PhoneTab.management)

        }
        .tint(selectedPhoneTabTint)
        .minimizeTabBarOnScrollDownIfAvailable()
        .overlay {
            if selectedPhoneTab == .currentAccount && showsQuickActions {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.82)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) {
                            showsQuickActions = false
                        }
                    }
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedPhoneTab == .currentAccount {
                phoneBottomAddButton
                    .padding(.trailing, 18)
                    .padding(.bottom, 82)
            }
        }
    }

    private var showsPhoneAnalyticsBackButton: Bool {
        selectedAnalyticsSidebarTab == .savingsCredits || selectedAnalyticsSidebarTab == .history
    }

    private var selectedPhoneTabTint: Color {
        switch selectedPhoneTab {
        case .currentAccount, .filters:
            MainTab.currentAccount.bannerColor
        case .credits:
            MainTab.credits.bannerColor
        case .management:
            MainTab.management.bannerColor
        }
    }

    private func phoneNavigationTitle(for tab: MainTab) -> String {
        switch tab {
        case .currentAccount:
            AppStrings.text(.appName)
        case .credits:
            AppStrings.text(.credits)
        case .management:
            AppStrings.text(.management)
        }
    }

    private var phoneActionPlaceholder: some View {
        Color.clear
            .background(AppPalette.appBackground.ignoresSafeArea())
    }

    private func handlePhoneTabSelection(_ tab: PhoneTab) {
        if let mainTab = tab.mainTab {
            if tab == .credits && selectedTab != .credits {
                selectedAnalyticsSidebarTab = .overview
            }
            if tab == .management && selectedTab != .management {
                managementNavigationResetID = UUID()
            }
            selectMainTab(mainTab)
        } else {
            guard selectedTab == .currentAccount else {
                selectedPhoneTab = phoneTab(for: selectedTab)
                return
            }

            selectedPhoneTab = .currentAccount
            selectMainTab(.currentAccount)
            showsFilters = true
        }
    }

    private func phoneTab(for tab: MainTab) -> PhoneTab {
        switch tab {
        case .currentAccount:
            .currentAccount
        case .credits:
            .credits
        case .management:
            .management
        }
    }

    private var phoneCurrentAccountNavigation: some View {
        NavigationStack {
            Group {
                if selectedPhoneTab == .currentAccount || selectedPhoneTab == .filters {
                    currentAccountView
                } else {
                    phoneActionPlaceholder
                }
            }
            .phoneTabRootStyle(title: phoneNavigationTitle(for: .currentAccount))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    appIcon
                }
                ToolbarItem(placement: .topBarTrailing) {
                    settingsToolbarButton
                }
            }
        }
    }

    private var phoneCreditsNavigation: some View {
        NavigationStack {
            Group {
                if selectedPhoneTab == .credits {
                    creditsView
                } else {
                    phoneActionPlaceholder
                }
            }
            .phoneTabRootStyle(title: phoneNavigationTitle(for: .credits))
            .analyticsDetailDestinations(
                saving: $selectedAnalyticsSavingDetail,
                credit: $selectedAnalyticsCreditDetail
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if showsPhoneAnalyticsBackButton {
                        analyticsBackButton
                    } else {
                        appIcon
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    settingsToolbarButton
                }
            }
        }
    }

    private var phoneManagementNavigation: some View {
        NavigationStack {
            Group {
                if selectedPhoneTab == .management {
                    managementView
                } else {
                    phoneActionPlaceholder
                }
            }
            .phoneTabRootStyle(title: phoneNavigationTitle(for: .management))
            .navigationDestination(isPresented: $showsPhoneAccountsManagement) {
                AccountsSettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    appIcon
                }
                ToolbarItem(placement: .topBarTrailing) {
                    settingsToolbarButton
                }
            }
        }
    }

    private var sidebarNavigation: some View {
        NavigationSplitView {
            sidebarMenu
        } detail: {
            NavigationStack {
                mainContent
                    .safeAreaInset(edge: .bottom) {
                        sidebarQuickActionsArea
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var mainContent: some View {
        Group {
            switch selectedTab {
            case .currentAccount:
                currentAccountView
            case .credits:
                creditsView
            case .management:
                managementView
            }
        }
        .background {
            AppPalette.appBackground
                .ignoresSafeArea()
                .backgroundExtensionEffectIfAvailable()
        }
        .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .analyticsDetailDestinations(
            saving: $selectedAnalyticsSavingDetail,
            credit: $selectedAnalyticsCreditDetail
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                appIcon
            }
            ToolbarItem(placement: .topBarTrailing) {
                settingsToolbarButton
            }
        }
    }

    private var sidebarMenu: some View {
        List {
            Section {
                ForEach(CurrentAccountSidebarTab.allCases) { tab in
                    currentAccountSidebarMenuButton(for: tab)
                }
            } header: {
                currentAccountSidebarHeader
            }

            Section {
                sidebarSummaryTiles
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(AnalyticsSidebarTab.allCases) { tab in
                    analyticsSidebarMenuButton(for: tab)
                }
            } header: {
                sidebarSectionHeader(title: AppStrings.text(.analyticsMenuTitle), systemImage: MainTab.credits.systemImage)
            }

            Section {
                managementSidebarMenuButton(for: .accounts)
                managementSidebarMenuButton(for: .recurringExpenses)
                managementSidebarMenuButton(for: .recurringIncome)
            } header: {
                recurringSidebarHeader
            }

            Section {
                ForEach([ManagementSidebarTab.savings, ManagementSidebarTab.credits]) { tab in
                    managementSidebarMenuButton(for: tab)
                }
            } header: {
                sidebarSectionHeader(title: AppStrings.text(.management), systemImage: MainTab.management.systemImage)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppPalette.appBackground)
        .navigationTitle(AppStrings.text(.appName))
    }

    private func sidebarMenuButton(for tab: MainTab) -> some View {
        Button {
            selectMainTab(tab)
        } label: {
            Label(tab.title, systemImage: tab.systemImage)
                .font(.body.weight(selectedTab == tab ? .semibold : .regular))
                .foregroundStyle(selectedTab == tab ? AppPalette.primary : AppPalette.background)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedTab == tab ? AppPalette.paleOrange.opacity(0.55) : Color.clear)
    }

    private var currentAccountSidebarHeader: some View {
        HStack(spacing: 8) {
            Label(AppStrings.text(.currentAccount), systemImage: MainTab.currentAccount.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.background)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                sidebarFilterButton
                sidebarAddButton
            }
        }
    }

    private var recurringSidebarHeader: some View {
        HStack(spacing: 8) {
            Label(AppStrings.text(.budgetSettings), systemImage: "arrow.triangle.2.circlepath")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.background)
                .labelStyle(.titleAndIcon)

            Spacer(minLength: 8)

            sidebarRecurringAddButton
        }
    }

    private func sidebarSectionHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppPalette.background)
            .labelStyle(.titleAndIcon)
    }

    private var sidebarFilterButton: some View {
        Button {
            selectMainTab(.currentAccount)
            showsFilters = true
        } label: {
            sidebarHeaderIcon(
                systemImage: "line.3.horizontal.decrease",
                badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppStrings.text(.filters))
    }

    private var sidebarAddButton: some View {
        Button {
            selectMainTab(.currentAccount)
            withAnimation(.snappy) {
                showsRecurringQuickActions = false
                showsQuickActions.toggle()
            }
        } label: {
            sidebarHeaderIcon(systemImage: showsQuickActions ? "xmark" : "plus")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppStrings.text(.add))
    }

    private var sidebarRecurringAddButton: some View {
        Button {
            selectedManagementSidebarTab = .recurringExpenses
            selectMainTab(.management)
            withAnimation(.snappy) {
                showsQuickActions = false
                showsRecurringQuickActions.toggle()
            }
        } label: {
            sidebarHeaderIcon(systemImage: showsRecurringQuickActions ? "xmark" : "plus")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppStrings.text(.add))
    }

    private func sidebarHeaderIcon(systemImage: String, badge: String? = nil) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppPalette.background)
                .frame(width: 28, height: 28)
                .background(AppPalette.surface.opacity(0.95), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(AppPalette.background.opacity(0.12), lineWidth: 1)
                }

            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 14, height: 14)
                    .background(AppPalette.primary, in: Circle())
                    .offset(x: 2, y: -2)
            }
        }
        .contentShape(Circle())
    }

    private func currentAccountSidebarMenuButton(for tab: CurrentAccountSidebarTab) -> some View {
        let isSelected = selectedTab == .currentAccount && selectedCurrentAccountSidebarTab == tab

        return Button {
            selectedCurrentAccountSidebarTab = tab
            selectMainTab(.currentAccount)
        } label: {
            sidebarSubmenuLabel(title: tab.title, systemImage: tab.systemImage, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 10))
        .listRowBackground(Color.clear)
    }

    private func analyticsSidebarMenuButton(for tab: AnalyticsSidebarTab) -> some View {
        let isSelected = selectedTab == .credits && selectedAnalyticsSidebarTab == tab

        return Button {
            selectedAnalyticsSidebarTab = tab
            selectMainTab(.credits)
        } label: {
            sidebarSubmenuLabel(title: tab.title, systemImage: tab.systemImage, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 10))
        .listRowBackground(Color.clear)
    }

    private func managementSidebarMenuButton(for tab: ManagementSidebarTab) -> some View {
        let isSelected = selectedTab == .management && selectedManagementSidebarTab == tab

        return Button {
            selectedManagementSidebarTab = tab
            selectMainTab(.management)
        } label: {
            sidebarSubmenuLabel(title: tab.title, systemImage: tab.systemImage, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 10))
        .listRowBackground(Color.clear)
    }

    private func sidebarSubmenuLabel(title: String, systemImage: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isSelected ? AppPalette.primary : AppPalette.separator)
                .frame(width: 4, height: 28)

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.mutedText)
                .frame(width: 24, height: 24)
                .background(isSelected ? AppPalette.paleOrange : AppPalette.surface.opacity(0.7), in: Circle())

            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppPalette.background : AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? AppPalette.paleOrange.opacity(0.48) : AppPalette.surface.opacity(0.38), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sidebarSummaryTiles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resumo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.mutedText)

            VStack(spacing: 8) {
                SidebarSummaryRow(
                    title: AppStrings.text(.balanceThisMonth),
                    value: inAccount,
                    indicatorColor: inAccount < 0 ? AppPalette.primary : AppPalette.secondary,
                    helpText: balanceHelpText,
                    footnote: futureBudgetReservationFootnote,
                    helpTitle: futureBudgetReservationTotal > 0 ? AppStrings.text(.reservedBalanceHelpTitle) : nil
                )

                SidebarSummaryRow(
                    title: AppStrings.text(.monthUnpaid),
                    value: monthUnpaidExpenses,
                    indicatorColor: AppPalette.primary,
                    helpText: AppStrings.text(.monthUnpaidHelp),
                    onTap: { showsUnpaidExpensesBreakdown = true }
                )

                if let monthRemaining {
                    SidebarSummaryRow(
                        title: monthRemaining < 0 ? AppStrings.text(.monthBudgetExceeded) : AppStrings.text(.monthRemaining),
                        value: monthRemaining,
                        indicatorColor: monthRemaining < 0 ? AppPalette.primary : AppPalette.positive,
                        helpText: AppStrings.text(.monthRemainingHelp),
                        boldHelpNote: AppStrings.text(.monthRemainingHelpNote)
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(AppPalette.surface.opacity(0.38), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var sidebarQuickActionsArea: some View {
        Group {
            if showsQuickActions && selectedTab == .currentAccount {
                quickActionsBar
                    .padding(.vertical, 8)
                    .background(AppPalette.appBackground)
            } else if showsRecurringQuickActions && selectedTab == .management {
                recurringQuickActionsBar
                    .padding(.vertical, 8)
                    .background(AppPalette.appBackground)
            }
        }
    }


    @ViewBuilder
    private var currentAccountView: some View {
        if usesSidebarNavigation && selectedCurrentAccountSidebarTab == .calendar {
            currentAccountCalendarView
        } else {
            currentAccountMonthlyListView
        }
    }

    private var currentAccountMonthlyListView: some View {
        VStack(spacing: 0) {
            areaHeroImage(
                localizedHeroAsset(portuguese: "CurrentAccountHero", english: "CurrentAccountHeroEnglish"),
                aspectRatio: currentAccountHeroAspectRatio
            )

            if !usesSidebarNavigation {
                summaryBar
            }

            monthHeader

            MonthPage(
                month: selectedMonth,
                transactions: filteredTransactions(in: selectedMonth),
                payments: payments,
                paymentHistory: paymentHistory,
                exclusions: exclusions,
                paymentFilter: paymentFilter,
                hasActiveFilters: activeFilterCount > 0,
                creditAccounts: creditAccounts,
                savingAccounts: savingAccounts,
                onPay: { transaction, month, occurrenceDay, initialAmount in
                    paymentEditorRequest = PaymentEditorRequest(transaction: transaction, month: month, occurrenceDay: occurrenceDay, initialAmount: initialAmount)
                },
                onEdit: { editorRequest = TransactionEditorRequest(transaction: $0, month: selectedMonth, editScope: $0.isRecurring ? .singleMonth : .normal) },
                onDelete: { deleteTransaction($0, in: selectedMonth, occurrenceDay: $1) }
            )
            .id(selectedMonthOffset)
            .transition(monthPageTransition)
            .animation(.snappy, value: selectedMonthOffset)
        }
    }

    private var currentAccountCalendarView: some View {
        VStack(spacing: 0) {
            areaHeroImage(
                localizedHeroAsset(portuguese: "CurrentAccountHero", english: "CurrentAccountHeroEnglish"),
                aspectRatio: currentAccountHeroAspectRatio
            )

            if !usesSidebarNavigation {
                summaryBar
            }

            monthHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    calendarWeekdayHeader

                    LazyVGrid(columns: calendarColumns, spacing: 8) {
                        ForEach(Array(monthCalendarDays.enumerated()), id: \.offset) { _, day in
                            calendarDayCell(day)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 18)
            }
            .id(selectedMonthOffset)
            .transition(monthPageTransition)
            .animation(.snappy, value: selectedMonthOffset)
        }
    }

    private var calendarColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private var calendarWeekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let startIndex = max(Calendar.current.firstWeekday - 1, 0)
        return Array(symbols[startIndex..<symbols.count]) + Array(symbols[0..<startIndex])
    }

    private var calendarWeekdayHeader: some View {
        HStack(spacing: 8) {
            ForEach(calendarWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(AppPalette.mutedText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthCalendarDays: [Int?] {
        let firstDay = selectedMonth.monthStart
        let firstWeekday = Calendar.current.component(.weekday, from: firstDay)
        let leadingEmptyDays = (firstWeekday - Calendar.current.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leadingEmptyDays) + (1...selectedMonth.daysInMonth).map { Optional($0) }
    }

    @ViewBuilder
    private func calendarDayCell(_ day: Int?) -> some View {
        if let day {
            let dayTransactions = calendarTransactions(for: day)

            VStack(alignment: .leading, spacing: 5) {
                calendarDayNumberButton(day, transactions: dayTransactions)

                LazyVGrid(columns: calendarIconColumns, alignment: .leading, spacing: 6) {
                    ForEach(dayTransactions.prefix(9)) { transaction in
                        calendarTransactionPill(transaction, day: day)
                    }

                    if dayTransactions.count > 9 {
                        calendarDayMoreButton(day, hiddenCount: dayTransactions.count - 9, transactions: dayTransactions)
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

    private var calendarIconColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(24), spacing: 6), count: 3)
    }

    private func calendarDayNumberButton(_ day: Int, transactions: [MoneyTransaction]) -> some View {
        let request = CalendarDayRequest(day: day, month: selectedMonth, anchor: "day")

        return Button {
            calendarDayExpandedTransactionID = nil
            calendarDayRequest = request
        } label: {
            Text("\(day)")
                .font(.caption.bold())
                .foregroundStyle(isToday(day) ? AppPalette.surface : AppPalette.background)
                .frame(width: 24, height: 24)
                .background(isToday(day) ? AppPalette.primary : Color.clear, in: Circle())
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: Binding(
                get: { calendarDayRequest?.id == request.id },
                set: { isPresented in
                    if !isPresented && calendarDayRequest?.id == request.id {
                        calendarDayRequest = nil
                    }
                }
            ),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            calendarDayPopover(for: request, transactions: transactions)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func calendarDayMoreButton(_ day: Int, hiddenCount: Int, transactions: [MoneyTransaction]) -> some View {
        let request = CalendarDayRequest(day: day, month: selectedMonth, anchor: "more")

        return Button {
            calendarDayExpandedTransactionID = nil
            calendarDayRequest = request
        } label: {
            Text("+\(hiddenCount)")
                .font(.caption2.bold())
                .foregroundStyle(AppPalette.mutedText)
                .frame(width: 24, height: 24)
                .background(AppPalette.separator.opacity(0.7), in: Circle())
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: Binding(
                get: { calendarDayRequest?.id == request.id },
                set: { isPresented in
                    if !isPresented && calendarDayRequest?.id == request.id {
                        calendarDayRequest = nil
                    }
                }
            ),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            calendarDayPopover(for: request, transactions: transactions)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func calendarTransactionPill(_ transaction: MoneyTransaction, day: Int) -> some View {
        let request = CalendarTransactionRequest(
            transaction: transaction,
            month: selectedMonth,
            occurrenceDay: transaction.recurrence == .weekly ? day : nil
        )

        return Button {
            calendarPopoverRequest = request
        } label: {
            Image(systemName: calendarTransactionIcon(for: transaction))
                .font(.caption.weight(.bold))
                .foregroundStyle(calendarTransactionTextColor(for: transaction))
                .frame(width: 24, height: 24)
                .background(calendarTransactionBackground(for: transaction), in: Circle())
                .overlay {
                    Circle()
                        .stroke(calendarTransactionTextColor(for: transaction).opacity(0.24), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(calendarTransactionStatusColor(for: transaction, day: day))
                        .frame(width: 7, height: 7)
                        .overlay {
                            Circle()
                                .stroke(AppPalette.surface, lineWidth: 1.5)
                        }
                        .offset(x: 1, y: -1)
                }
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: Binding(
                get: { calendarPopoverRequest?.id == request.id },
                set: { isPresented in
                    if !isPresented && calendarPopoverRequest?.id == request.id {
                        calendarPopoverRequest = nil
                    }
                }
            ),
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            calendarTransactionPopover(for: request)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func calendarTransactions(for day: Int) -> [MoneyTransaction] {
        filteredTransactions(in: selectedMonth)
            .filter { transaction in
                if transaction.recurrence == .weekly {
                    return transaction.occurrenceDays(in: selectedMonth, exclusions: exclusions).contains(day)
                }

                return transaction.effectiveDay(in: selectedMonth) == day
            }
            .sorted { first, second in
                if first.kind != second.kind {
                    return first.kind == TransactionKind.income.rawValue
                }
                if first.amount != second.amount { return first.amount > second.amount }
                return calendarTransactionTitle(for: first).localizedCaseInsensitiveCompare(calendarTransactionTitle(for: second)) == .orderedAscending
            }
    }

    private func calendarTransactionTitle(for transaction: MoneyTransaction) -> String {
        let freeText = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !freeText.isEmpty {
            return freeText
        }
        return transaction.displayName
    }

    private func calendarTransactionIcon(for transaction: MoneyTransaction) -> String {
        if transaction.kind == TransactionKind.income.rawValue {
            return "banknote.fill"
        }
        return ExpenseTypeIcon.name(for: transaction.displayName)
    }

    private func calendarTransactionBackground(for transaction: MoneyTransaction) -> Color {
        if transaction.kind == TransactionKind.income.rawValue {
            return AppPalette.mintSurface
        }
        return calendarExpenseCategoryColor(for: transaction).opacity(0.18)
    }

    private func calendarTransactionTextColor(for transaction: MoneyTransaction) -> Color {
        if transaction.kind == TransactionKind.income.rawValue {
            return AppPalette.positive
        }
        return calendarExpenseCategoryColor(for: transaction)
    }

    private func calendarTransactionStatusColor(for transaction: MoneyTransaction, day: Int) -> Color {
        if transaction.kind == TransactionKind.income.rawValue {
            return AppPalette.positive
        }
        return isPaid(transaction, in: selectedMonth, occurrenceDay: transaction.recurrence == .weekly ? day : nil) ? AppPalette.positive : AppPalette.primary
    }

    private func calendarExpenseCategoryColor(for transaction: MoneyTransaction) -> Color {
        ExpenseCategory(rawValue: transaction.expenseCategory ?? "")?.color ?? AppPalette.primary
    }

    private func calendarDayPopover(for request: CalendarDayRequest, transactions: [MoneyTransaction]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(calendarDayTitle(for: request))
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Text("\(transactions.count) \(transactions.count == 1 ? "registo" : "registos")")
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }

            if transactions.isEmpty {
                ContentUnavailableView(
                    AppStrings.text(.noTransactions),
                    systemImage: "calendar",
                    description: Text(AppStrings.text(.noTransactionsDescription))
                )
                .frame(width: 360, height: 180)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(transactions) { transaction in
                            TransactionCard(
                                transaction: transaction,
                                month: request.month,
                                displayDay: transaction.recurrence == .weekly ? request.day : nil,
                                amountPaid: paidAmount(for: transaction, in: request.month, occurrenceDay: transaction.recurrence == .weekly ? request.day : nil),
                                hasPaymentHistory: hasPaymentHistory(for: transaction, in: request.month, occurrenceDay: transaction.recurrence == .weekly ? request.day : nil),
                                creditAccounts: creditAccounts,
                                savingAccounts: savingAccounts,
                                isExpanded: calendarDayExpandedTransactionID == transaction.id,
                                onExpansionChange: { isExpanded in
                                    calendarDayExpandedTransactionID = isExpanded ? transaction.id : nil
                                },
                                onPay: {
                                    calendarDayRequest = nil
                                    paymentEditorRequest = PaymentEditorRequest(
                                        transaction: transaction,
                                        month: request.month,
                                        occurrenceDay: transaction.recurrence == .weekly ? request.day : nil,
                                        initialAmount: paidAmount(for: transaction, in: request.month, occurrenceDay: transaction.recurrence == .weekly ? request.day : nil)
                                    )
                                },
                                onEdit: {
                                    calendarDayRequest = nil
                                    editorRequest = TransactionEditorRequest(
                                        transaction: transaction,
                                        month: request.month,
                                        editScope: transaction.isRecurring ? .singleMonth : .normal
                                    )
                                },
                                onDelete: {
                                    calendarDayRequest = nil
                                    deleteTransaction(transaction, in: request.month, occurrenceDay: transaction.recurrence == .weekly ? request.day : nil)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(width: 420, height: min(CGFloat(transactions.count) * 118 + 16, 520))
            }
        }
        .padding(14)
        .background(AppPalette.appBackground)
    }

    private func calendarDayTitle(for request: CalendarDayRequest) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: request.month.date(day: request.day))
    }

    private func calendarTransactionPopover(for request: CalendarTransactionRequest) -> some View {
        TransactionCard(
            transaction: request.transaction,
            month: request.month,
            displayDay: request.occurrenceDay,
            amountPaid: paidAmount(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
            hasPaymentHistory: hasPaymentHistory(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
            creditAccounts: creditAccounts,
            savingAccounts: savingAccounts,
            isExpanded: true,
            onExpansionChange: { _ in },
            onPay: {
                calendarPopoverRequest = nil
                paymentEditorRequest = PaymentEditorRequest(
                    transaction: request.transaction,
                    month: request.month,
                    occurrenceDay: request.occurrenceDay,
                    initialAmount: paidAmount(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay)
                )
            },
            onEdit: {
                calendarPopoverRequest = nil
                editorRequest = TransactionEditorRequest(
                    transaction: request.transaction,
                    month: request.month,
                    editScope: request.transaction.isRecurring ? .singleMonth : .normal
                )
            },
            onDelete: {
                calendarPopoverRequest = nil
                deleteTransaction(request.transaction, in: request.month, occurrenceDay: request.occurrenceDay)
            }
        )
        .padding(14)
        .frame(width: 420)
        .background(AppPalette.appBackground)
    }

    private func isToday(_ day: Int) -> Bool {
        Calendar.current.isDate(selectedMonth.date(day: day), inSameDayAs: Date())
    }

    private func calendarTransactionDetailSheet(for request: CalendarTransactionRequest) -> some View {
        NavigationStack {
            ScrollView {
                TransactionCard(
                    transaction: request.transaction,
                    month: request.month,
                    displayDay: request.occurrenceDay,
                    amountPaid: paidAmount(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
                    hasPaymentHistory: hasPaymentHistory(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay),
                    creditAccounts: creditAccounts,
                    savingAccounts: savingAccounts,
                    isExpanded: true,
                    onExpansionChange: { _ in },
                    onPay: {
                        calendarTransactionRequest = nil
                        paymentEditorRequest = PaymentEditorRequest(
                            transaction: request.transaction,
                            month: request.month,
                            occurrenceDay: request.occurrenceDay,
                            initialAmount: paidAmount(for: request.transaction, in: request.month, occurrenceDay: request.occurrenceDay)
                        )
                    },
                    onEdit: {
                        calendarTransactionRequest = nil
                        editorRequest = TransactionEditorRequest(
                            transaction: request.transaction,
                            month: request.month,
                            editScope: request.transaction.isRecurring ? .singleMonth : .normal
                        )
                    },
                    onDelete: {
                        calendarTransactionRequest = nil
                        deleteTransaction(request.transaction, in: request.month, occurrenceDay: request.occurrenceDay)
                    }
                )
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(calendarTransactionTitle(for: request.transaction))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) {
                        calendarTransactionRequest = nil
                    }
                    .liquidGlassButtonStyle()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var monthPageTransition: AnyTransition {
        let insertionEdge: Edge = monthNavigationDirection > 0 ? .trailing : .leading
        let removalEdge: Edge = monthNavigationDirection > 0 ? .leading : .trailing

        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var monthHeader: some View {
        HStack(spacing: usesSidebarNavigation ? 16 : 10) {
            monthArrowButton(systemImage: "chevron.left") {
                moveMonth(by: -1)
            }
            .disabled(selectedMonthOffset <= (monthOffsets.first ?? 0))
            .opacity(selectedMonthOffset <= (monthOffsets.first ?? 0) ? 0.35 : 1)

            VStack(alignment: .center, spacing: 2) {
                Text(selectedMonth.monthTitle)
                    .font((usesSidebarNavigation ? Font.title : Font.title2).bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if selectedMonthShowsCurrentDay {
                    Text("\(AppStrings.text(.day)) \(currentDayNumber)")
                        .font(usesSidebarNavigation ? .title3 : .subheadline)
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            monthArrowButton(systemImage: "chevron.right") {
                moveMonth(by: 1)
            }
            .disabled(selectedMonthOffset >= (monthOffsets.last ?? 0))
            .opacity(selectedMonthOffset >= (monthOffsets.last ?? 0) ? 0.35 : 1)
        }
        .padding(.horizontal, usesSidebarNavigation ? 28 : 22)
        .padding(.top, usesSidebarNavigation ? 8 : 2)
        .padding(.bottom, usesSidebarNavigation ? 6 : 2)
        .background(AppPalette.appBackground)
    }

    private func moveMonth(by value: Int) {
        monthNavigationDirection = value
        let nextOffset = selectedMonthOffset + value
        selectedMonthOffset = min(max(nextOffset, monthOffsets.first ?? 0), monthOffsets.last ?? 0)
    }

    private func monthArrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font((usesSidebarNavigation ? Font.title3 : Font.body).weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: usesSidebarNavigation ? 44 : 38, height: usesSidebarNavigation ? 44 : 38)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, AppPalette.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 1)
                        }
                        .shadow(color: AppPalette.background.opacity(0.12), radius: 10, y: 5)
                        .shadow(color: .white.opacity(0.85), radius: 2, x: -1, y: -1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var monthNavigationBar: some View {
        BudgetStatusCard(
            month: selectedMonth,
            transactions: selectedTransactions,
            payments: payments,
            budgetIncome: monthIncome,
            isCompact: true
        )
    }

    private var sidebarMonthFooterBar: some View {
        monthNavigationBar
    }

    private func areaHeroImage(
        _ name: String,
        aspectRatio: CGFloat,
        horizontalPadding: CGFloat? = nil
    ) -> some View {
        let sidePadding = horizontalPadding ?? 12
        let effectiveAspectRatio = usesSidebarNavigation ? aspectRatio / 0.8 : aspectRatio

        return Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(effectiveAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppPalette.background.opacity(0.10), radius: 18, y: 8)
            .padding(.horizontal, sidePadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
    }

    private func localizedHeroAsset(portuguese: String, english: String) -> String {
        AppStrings.currentLanguage == .portuguese ? portuguese : english
    }

    private func localizedAreaHeroImage(
        imageName: String,
        title: String,
        subtitle: String,
        aspectRatio: CGFloat,
        horizontalPadding: CGFloat? = nil
    ) -> some View {
        let sidePadding = horizontalPadding ?? 12
        let effectiveAspectRatio = usesSidebarNavigation ? aspectRatio / 0.8 : aspectRatio
        let textMaxWidth: CGFloat = usesSidebarNavigation ? 500 : 235
        let textLeadingPadding: CGFloat = usesSidebarNavigation ? 54 : 28

        return ZStack(alignment: .leading) {
            Image(imageName)
                .resizable()
                .scaledToFill()

            VStack(alignment: .leading, spacing: usesSidebarNavigation ? 14 : 10) {
                Text(title)
                    .font(.system(size: usesSidebarNavigation ? 42 : 28, weight: .bold))
                    .foregroundStyle(AppPalette.surface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(subtitle)
                    .font(.system(size: usesSidebarNavigation ? 24 : 16, weight: .regular))
                    .foregroundStyle(AppPalette.surface)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: textMaxWidth, alignment: .leading)
            .padding(.leading, textLeadingPadding)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(effectiveAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppPalette.background.opacity(0.10), radius: 18, y: 8)
        .padding(.horizontal, sidePadding)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var currentAccountHeroAspectRatio: CGFloat {
        usesSidebarNavigation ? 1334.0 / 310.0 : 1334.0 / 250.0
    }

    @ViewBuilder
    private var creditsView: some View {
        if usesSidebarNavigation {
            sidebarCreditsView
        } else {
            phoneCreditsView
        }
    }

    private var sidebarCreditsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                areaHeroImage(
                    localizedHeroAsset(portuguese: "AnalyticsHero", english: "AnalyticsHeroEnglish"),
                    aspectRatio: 1334.0 / 298.0,
                    horizontalPadding: 0
                )
                .padding(.top, -8)
                .padding(.bottom, -8)

                selectedAnalyticsSidebarContent
            }
            .padding()
        }
        .background(AppPalette.appBackground)
    }

    private var phoneCreditsView: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 22
            let contentWidth = max(proxy.size.width - (horizontalPadding * 2), 0)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    areaHeroImage(
                        localizedHeroAsset(portuguese: "AnalyticsHero", english: "AnalyticsHeroEnglish"),
                        aspectRatio: 1334.0 / 298.0,
                        horizontalPadding: 0
                    )
                    .padding(.top, -8)
                    .padding(.bottom, -8)
                    .frame(width: contentWidth)

                    phoneAnalyticsTabPicker
                        .frame(width: contentWidth, alignment: .leading)
                    selectedPhoneAnalyticsContent
                        .frame(width: contentWidth, alignment: .leading)
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
            }
            .background(AppPalette.appBackground)
        }
        .onAppear {
            normalizePhoneAnalyticsTabIfNeeded()
        }
    }

    private var phoneAnalyticsTabs: [AnalyticsSidebarTab] {
        [.overview, .monthYear, .summaries]
    }

    private var phoneRenderableAnalyticsTabs: [AnalyticsSidebarTab] {
        phoneAnalyticsTabs + [.savingsCredits, .history]
    }

    private func phoneAnalyticsTabTitle(for tab: AnalyticsSidebarTab) -> String {
        switch tab {
        case .summaries:
            "Insights"
        default:
            tab.title
        }
    }

    private var phoneAnalyticsTabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(phoneAnalyticsTabs) { tab in
                    let isSelected = selectedAnalyticsSidebarTab == tab

                    Button {
                        selectedAnalyticsSidebarTab = tab
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.systemImage)
                                .font(.caption.weight(.bold))

                            Text(phoneAnalyticsTabTitle(for: tab))
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(
                            isSelected ? AppPalette.background : AppPalette.surface,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppPalette.separator.opacity(isSelected ? 0 : 0.7), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var selectedPhoneAnalyticsContent: AnyView {
        switch selectedAnalyticsSidebarTab {
        case .overview:
            AnyView(analyticsOverviewContent)
        case .monthYear:
            AnyView(analyticsMonthYearCard)
        case .summaries:
            AnyView(analyticsSummariesContent)
        case .savingsCredits:
            AnyView(analyticsSavingsCreditsContent)
        case .history:
            AnyView(analyticsHistoryCard)
        }
    }

    private func normalizePhoneAnalyticsTabIfNeeded() {
        guard !usesSidebarNavigation,
              !phoneRenderableAnalyticsTabs.contains(selectedAnalyticsSidebarTab)
        else { return }

        selectedAnalyticsSidebarTab = .overview
    }

    private func openAnalyticsTab(_ tab: AnalyticsSidebarTab) {
        selectedAnalyticsSidebarTab = usesSidebarNavigation || phoneRenderableAnalyticsTabs.contains(tab) ? tab : .overview
        selectedPhoneTab = .credits
        selectMainTab(.credits)
    }

    @ViewBuilder
    private var selectedAnalyticsSidebarContent: some View {
        switch selectedAnalyticsSidebarTab {
        case .overview:
            analyticsOverviewContent
        case .monthYear:
            analyticsMonthYearCard
        case .summaries:
            analyticsSummariesContent
        case .savingsCredits:
            analyticsSavingsCreditsContent
        case .history:
            analyticsHistoryCard
        }
    }

    @ViewBuilder
    private var analyticsOverviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            analyticsNetWorthCard

            VStack(spacing: 10) {
                analyticsOverviewMetricRow(
                    icon: "list.bullet.rectangle",
                    title: AppStrings.text(.currentAccount),
                    subtitle: AppStrings.text(.availableBalanceSummary),
                    value: inAccount.currencyText,
                    tint: AppPalette.background
                ) {
                    selectedPhoneTab = .currentAccount
                    selectMainTab(.currentAccount)
                }

                analyticsOverviewMetricRow(
                    icon: "leaf.fill",
                    title: SavingsStrings.text(.settingsTitle),
                    subtitle: AppStrings.text(.totalSavedSummary),
                    value: analyticsSavingsTotal.currencyText,
                    tint: AppPalette.savings
                ) {
                    openAnalyticsTab(.savingsCredits)
                }

                analyticsOverviewMetricRow(
                    icon: "creditcard",
                    title: CreditStrings.text(.settingsTitle),
                    subtitle: AppStrings.text(.totalDebtSummary),
                    value: (-analyticsCreditDebtTotal).currencyText,
                    tint: AppPalette.primary
                ) {
                    openAnalyticsTab(.savingsCredits)
                }
            }
            .frame(maxWidth: .infinity)

            analyticsQuickSummarySection

            analyticsHistoryAccessCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var analyticsMonthYearCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            analyticsMonthYearExpenseCard

            if usesSidebarNavigation {
                lightweightEvolutionSection
            } else {
                // Fallback used while isolating EXC_BAD_ACCESS in "Analise Mes e Ano"
                // on physical iPhone devices. The original section remains intact above.
                lightweightEvolutionUnavailableSection
            }
        }
    }

    private var lightweightEvolutionUnavailableSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evolução temporal")
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

            Text("Esta secção está temporariamente indisponível.")
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }

    private var analyticsMonthYearExpenseCard: some View {
        chartCard(
            title: analyticsAnalysisTitle,
            total: analyticsExpenseTotal
        ) {
            analyticsMonthYearExpenseContent
        }
    }

    private var analyticsMonthYearExpenseContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            analyticsPeriodControls
            analyticsExpenseTabPicker
            analyticsExpenseTabContent
        }
    }

    private var analyticsExpenseTabPicker: some View {
        Picker("", selection: $selectedAnalyticsExpenseTab) {
            Text(AppStrings.text(.whereSpent)).tag(AnalyticsExpenseTab.whereSpent)
            Text(AppStrings.text(.budgetRule)).tag(AnalyticsExpenseTab.budgetRule)
        }
        .pickerStyle(.segmented)
        .tint(AppPalette.background)
    }

    @ViewBuilder
    private var analyticsExpenseTabContent: some View {
        switch selectedAnalyticsExpenseTab {
        case .whereSpent:
            expenseTypePieChart(points: analyticsExpenseTypePoints, total: analyticsExpenseTotal)
        case .budgetRule:
            analyticsBudgetRuleComparison
        }
    }

    private var analyticsBudgetRuleComparison: some View {
        HStack(alignment: .top, spacing: 16) {
            pieChartColumn(
                title: AppStrings.text(.actualExpenses),
                points: analyticsCategoryExpenses,
                total: analyticsExpenseTotal
            )

            pieChartColumn(
                title: AppStrings.text(.reference503020),
                points: budgetReferencePoints,
                total: 100
            )
        }
    }

    private var lightweightEvolutionSection: some View {
        let points = sanitizedLightweightEvolutionPoints(lightweightEvolutionTable.points(for: selectedLightweightEvolutionKind))
        let shouldShowLoading = isLightweightEvolutionLoading || points.isEmpty
        let currentValue = currentLightweightEvolutionValue(for: selectedLightweightEvolutionKind)
        let maxValue = points.map(\.value).max() ?? 0
        let monthEndValue = points.last(where: { Calendar.current.isDate($0.month, equalTo: Date(), toGranularity: .month) })?.value ?? currentValue

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Evolução temporal")
                    .font(.headline.bold())
                    .foregroundStyle(AppPalette.background)

                Text("30 dias visíveis, com histórico e previsão")
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }

            HStack(spacing: 8) {
                ForEach(LightweightEvolutionKind.allCases) { kind in
                    lightweightEvolutionSegment(kind)
                }
            }

            if shouldShowLoading {
                lightweightEvolutionLoadingView
            } else {
                HStack(alignment: .top, spacing: 14) {
                    lightweightEvolutionMetric(
                        icon: selectedLightweightEvolutionKind.systemImage,
                        title: selectedLightweightEvolutionKind.currentMetricTitle,
                        value: displayedLightweightEvolutionRoundedValue(currentValue, for: selectedLightweightEvolutionKind),
                        tint: selectedLightweightEvolutionKind.tint
                    )
                    lightweightEvolutionMetric(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Máximo",
                        value: displayedLightweightEvolutionRoundedValue(maxValue, for: selectedLightweightEvolutionKind),
                        tint: selectedLightweightEvolutionKind.tint
                    )
                    lightweightEvolutionMetric(
                        icon: "calendar.badge.clock",
                        title: "Previsto fim mês",
                        value: displayedLightweightEvolutionRoundedValue(monthEndValue, for: selectedLightweightEvolutionKind),
                        tint: selectedLightweightEvolutionKind.tint
                    )
                }

                if points.contains(where: { abs($0.value) > 0.009 }) {
                    lightweightEvolutionLegend(kind: selectedLightweightEvolutionKind)

                    lightweightEvolutionChart(points: points, kind: selectedLightweightEvolutionKind)
                        .id(selectedLightweightEvolutionKind)
                        .frame(height: 220)

                    if !lightweightEvolutionTable.savings.isEmpty && !lightweightEvolutionTable.credits.isEmpty {
                        lightweightEvolutionMiniSummaries
                    }
                } else {
                    Text("Ainda não existem dados suficientes para apresentar a evolução.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }

    private var lightweightEvolutionLoadingView: some View {
        VStack(spacing: 12) {
            if isLightweightEvolutionLoading {
                ProgressView()
                    .tint(selectedLightweightEvolutionKind.tint)
                Text("A preparar evolução temporal...")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
            } else {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(selectedLightweightEvolutionKind.tint)
                    .frame(width: 42, height: 42)
                    .background(selectedLightweightEvolutionKind.tint.opacity(0.12), in: Circle())

                Button {
                    scheduleLightweightEvolutionTableRefreshIfNeeded()
                } label: {
                    Text("Carregar gráfico")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.surface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedLightweightEvolutionKind.tint, in: Capsule())
                }
                .buttonStyle(.plain)

                Text("A página continua disponível enquanto os dados são preparados.")
                    .font(.caption2)
                    .foregroundStyle(AppPalette.mutedText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    private func lightweightEvolutionSegment(_ kind: LightweightEvolutionKind) -> some View {
        let isSelected = selectedLightweightEvolutionKind == kind

        return Button {
            withAnimation(.snappy) {
                selectedLightweightEvolutionKind = kind
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: kind.systemImage)
                    .font(.caption.weight(.bold))
                Text(kind.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(isSelected ? kind.tint : AppPalette.appBackground.opacity(0.72), in: Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func lightweightEvolutionMetric(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
                Text(value)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 34, alignment: .topLeading)
    }

    private func lightweightEvolutionChart(points: [LightweightEvolutionPoint], kind: LightweightEvolutionKind) -> some View {
        GeometryReader { geometry in
            let axisWidth: CGFloat = 52
            let plotWidth = max(geometry.size.width - axisWidth - 6, 1)
            let plotHeight = max(geometry.size.height - 34, 1)
            let chartFrame = CGRect(
                x: axisWidth,
                y: 12,
                width: plotWidth,
                height: plotHeight
            )
            let axisValues = lightweightEvolutionAxisValues(points)

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppPalette.appBackground.opacity(0.58))

                ForEach(Array(axisValues.enumerated()), id: \.offset) { _, value in
                    let y = lightweightEvolutionAxisY(value, axisValues: axisValues, in: chartFrame)

                    Text(lightweightEvolutionAxisLabel(value, for: kind))
                        .font(.caption2)
                        .foregroundStyle(AppPalette.mutedText)
                        .opacity(0.82)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 46, alignment: .trailing)
                        .position(x: 23, y: y)
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        lightweightEvolutionScrollablePlot(
                            points: points,
                            kind: kind,
                            axisValues: axisValues,
                            viewportWidth: plotWidth,
                            plotHeight: plotHeight
                        )
                    }
                    .onAppear {
                        scrollLightweightEvolutionToToday(points: points, proxy: proxy)
                    }
                    .onChange(of: kind) {
                        scrollLightweightEvolutionToToday(points: points, proxy: proxy)
                    }
                    .onChange(of: points.count) {
                        scrollLightweightEvolutionToToday(points: points, proxy: proxy)
                    }
                }
                .frame(width: plotWidth, height: geometry.size.height)
                .position(x: axisWidth + plotWidth / 2, y: geometry.size.height / 2)
            }
        }
    }

    private func lightweightEvolutionScrollablePlot(
        points: [LightweightEvolutionPoint],
        kind: LightweightEvolutionKind,
        axisValues: [Double],
        viewportWidth: CGFloat,
        plotHeight: CGFloat
    ) -> some View {
        let visibleDayCount = 26.0
        let contentWidth = max(viewportWidth, viewportWidth * CGFloat(max(Double(points.count) / visibleDayCount, 1)))
        let plotRect = CGRect(x: 0, y: 12, width: contentWidth, height: plotHeight)
        let chartPoints = normalizedLightweightChartPoints(points, in: plotRect)
        let currentIndex = points.firstIndex { Calendar.current.isDate($0.month, inSameDayAs: Date()) } ?? min(60, max(points.count - 1, 0))
        let historyPoints = Array(chartPoints.prefix(currentIndex + 1))
        let futurePoints = chartPoints.indices.contains(currentIndex) ? Array(chartPoints.suffix(from: currentIndex)) : []

        return ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                ForEach(points) { point in
                    Color.clear
                        .frame(width: contentWidth / CGFloat(max(points.count, 1)), height: 1)
                        .id(point.id)
                }
            }
            .frame(width: contentWidth, height: 1)

            ForEach(Array(axisValues.enumerated()), id: \.offset) { _, value in
                let y = lightweightEvolutionAxisY(value, axisValues: axisValues, in: plotRect)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: contentWidth, y: y))
                }
                .stroke(AppPalette.mutedText.opacity(0.22), lineWidth: 0.5)
            }

            Path { path in
                guard let first = historyPoints.first, let last = historyPoints.last else { return }
                path.move(to: CGPoint(x: first.x, y: plotRect.maxY))
                path.addLine(to: first)
                addSmoothLine(to: &path, points: historyPoints, movesToFirstPoint: false)
                path.addLine(to: CGPoint(x: last.x, y: plotRect.maxY))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [kind.tint.opacity(0.12), kind.tint.opacity(0.01)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Path { path in
                addSmoothLine(to: &path, points: historyPoints)
            }
            .stroke(
                LinearGradient(
                    colors: [kind.tint.opacity(0.62), kind.tint.opacity(0.9), kind.tint.opacity(0.62)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            )

            Path { path in
                addSmoothLine(to: &path, points: futurePoints)
            }
            .stroke(kind.tint.opacity(0.34), style: StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round, dash: [6, 8]))

            if chartPoints.indices.contains(currentIndex) {
                Path { path in
                    let x = chartPoints[currentIndex].x
                    path.move(to: CGPoint(x: x, y: plotRect.minY - 12))
                    path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                }
                .stroke(AppPalette.mutedText.opacity(0.24), lineWidth: 1)

                Text("Hoje")
                    .font(.caption2.bold())
                    .foregroundStyle(AppPalette.background)
                    .position(x: chartPoints[currentIndex].x, y: plotRect.minY - 16)
            }

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                if chartPoints.indices.contains(index) {
                    let isCurrent = Calendar.current.isDate(point.month, inSameDayAs: Date())
                    let pointColor = isCurrent ? AppPalette.background : (index > currentIndex ? kind.tint.opacity(0.62) : kind.tint)

                    if isCurrent || point.markerTitle != nil {
                        Circle()
                            .fill(pointColor)
                            .frame(width: isCurrent ? 7 : 4.5, height: isCurrent ? 7 : 4.5)
                            .overlay(Circle().stroke(AppPalette.surface, lineWidth: 1.5))
                            .position(chartPoints[index])
                    }

                    if let markerTitle = point.markerTitle,
                       let markerIcon = point.markerIcon,
                       let markerTint = point.markerTint {
                        lightweightEvolutionMarkerView(
                            id: point.id,
                            title: markerTitle,
                            icon: markerIcon,
                            tint: markerTint
                        )
                        .position(
                            x: min(max(chartPoints[index].x, 32), contentWidth - 32),
                            y: max(chartPoints[index].y - 28, plotRect.minY + 14)
                        )
                    }
                }
            }

            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                if chartPoints.indices.contains(index), lightweightEvolutionShouldShowDateLabel(at: index, point: point, totalCount: points.count) {
                    Text(lightweightEvolutionMonthTitle(point.month))
                        .font(.caption2)
                        .foregroundStyle(Calendar.current.isDate(point.month, inSameDayAs: Date()) ? AppPalette.background : AppPalette.mutedText)
                        .position(x: chartPoints[index].x, y: plotRect.maxY + 18)
                }
            }
        }
        .frame(width: contentWidth, height: plotRect.maxY + 34)
    }

    private func lightweightEvolutionMarkerView(id: Date, title: String, icon: String, tint: Color) -> some View {
        let isExpanded = expandedLightweightEvolutionMarkerID == id

        return Button {
            withAnimation(.snappy) {
                expandedLightweightEvolutionMarkerID = isExpanded ? nil : id
            }
        } label: {
            VStack(spacing: 3) {
                if isExpanded {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(AppPalette.surface.opacity(0.94), in: Capsule())
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                Image(systemName: icon)
                    .font(.caption2.bold())
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                    .background(AppPalette.surface.opacity(0.95), in: Circle())
                    .overlay(Circle().stroke(tint.opacity(0.26), lineWidth: 1))
                    .shadow(color: tint.opacity(0.18), radius: 5, y: 3)

                Rectangle()
                    .fill(tint.opacity(0.55))
                    .frame(width: 1, height: 18)
            }
            .frame(width: 92)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func lightweightEvolutionLegend(kind: LightweightEvolutionKind) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Capsule()
                    .fill(kind.tint)
                    .frame(width: 26, height: 3)
                Text("Histórico")
            }

            HStack(spacing: 4) {
                Capsule()
                    .fill(kind.tint.opacity(0.55))
                    .frame(width: 8, height: 3)
                Capsule()
                    .fill(kind.tint.opacity(0.55))
                    .frame(width: 8, height: 3)
                Text("Previsto")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppPalette.mutedText)
    }

    private var lightweightEvolutionMiniSummaries: some View {
        HStack(spacing: 12) {
            lightweightEvolutionMiniSummaryCard(kind: .savings)
            lightweightEvolutionMiniSummaryCard(kind: .credits)
        }
    }

    private func lightweightEvolutionMiniSummaryCard(kind: LightweightEvolutionKind) -> some View {
        let points = lightweightEvolutionTable.points(for: kind)
        let current = currentLightweightEvolutionValue(for: kind)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: kind.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(kind.tint)
                    .frame(width: 28, height: 28)
                    .background(kind.tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(kind.title)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                    Text(displayedLightweightEvolutionValue(current, for: kind))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(kind.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            GeometryReader { geometry in
                let chartPoints = normalizedLightweightChartPoints(points, in: geometry.size)
                Path { path in
                    addSmoothLine(to: &path, points: chartPoints)
                }
                .stroke(kind.tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 34)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    private func lightweightEvolutionMonthDetails(points: [LightweightEvolutionPoint], kind: LightweightEvolutionKind) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                let previousValue = index > 0 ? points[index - 1].value : point.value
                let delta = point.value - previousValue

                HStack(spacing: 10) {
                    Image(systemName: Calendar.current.isDate(point.month, equalTo: currentMonth, toGranularity: .month) ? "smallcircle.filled.circle" : kind.systemImage)
                        .font(.caption.bold())
                        .foregroundStyle(Calendar.current.isDate(point.month, equalTo: currentMonth, toGranularity: .month) ? AppPalette.background : kind.tint)
                        .frame(width: 28, height: 28)
                        .background((Calendar.current.isDate(point.month, equalTo: currentMonth, toGranularity: .month) ? AppPalette.background : kind.tint).opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text(lightweightEvolutionDetailedMonthTitle(point.month))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.background)
                            .lineLimit(1)

                        Text(lightweightEvolutionMonthStatus(point.month))
                            .font(.caption2)
                            .foregroundStyle(AppPalette.mutedText)

                        if index > 0 {
                            Text(lightweightEvolutionDeltaText(delta, for: kind))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(lightweightEvolutionDeltaColor(delta, for: kind))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(displayedLightweightEvolutionValue(point.value, for: kind))
                        .font(.caption.bold())
                        .foregroundStyle(kind.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(9)
                .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private var analyticsSavingsCreditsContent: some View {
        analyticsSavingsCard

        analyticsCreditsCard
    }

    private var analyticsBackButton: some View {
        topToolbarIconButton(
            systemImage: "chevron.left",
            accessibilityLabel: "Voltar"
        ) {
            selectedAnalyticsSidebarTab = .overview
        }
    }

    @ViewBuilder
    private var managementView: some View {
        if usesSidebarNavigation {
            VStack(spacing: 0) {
                areaHeroImage(
                    localizedHeroAsset(portuguese: "ManagementHero", english: "ManagementHeroEnglish"),
                    aspectRatio: 1334.0 / 295.0
                )
                selectedManagementSidebarContent
            }
        } else {
            managementCardsView
        }
    }

    @ViewBuilder
    private var selectedManagementSidebarContent: some View {
        switch selectedManagementSidebarTab {
        case .accounts:
            AccountsSettingsView()
        case .recurringExpenses:
            BudgetSettingsView(openingList: 0, showsListControls: false)
        case .recurringIncome:
            BudgetSettingsView(openingList: 1, showsListControls: false)
        case .savings:
            SavingsSettingsView()
                .navigationTitle(SavingsStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        case .credits:
            CreditsSettingsView()
                .navigationTitle(CreditStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var managementCardsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                areaHeroImage(
                    localizedHeroAsset(portuguese: "ManagementHero", english: "ManagementHeroEnglish"),
                    aspectRatio: 1334.0 / 295.0,
                    horizontalPadding: 0
                )
                .padding(.top, -10)
                .padding(.bottom, -8)

                VStack(spacing: 14) {
                    managementCard(
                        title: AppStrings.text(.budgetSettings),
                        subtitle: AppStrings.text(.managementBudgetDescription),
                        imageName: "ManagementRecorrentesIcon",
                        summaryTitle: "Saldo recorrente",
                        summaryValue: managementRecurringMonthlyBalance,
                        summaryTint: managementRecurringMonthlyBalance < 0 ? AppPalette.primary : AppPalette.positive,
                        route: .recurringExpenses
                    )

                    managementCard(
                        title: AppStrings.text(.accounts),
                        subtitle: AppStrings.text(.accountsSubtitle),
                        imageName: "ManagementContasIcon",
                        summaryTitle: "\(spendAccounts.count) \(spendAccounts.count == 1 ? AppStrings.text(.accountSingular) : AppStrings.text(.accountPlural)) · \(AppStrings.text(.totalSummaryLabel))",
                        summaryValue: totalSpendAccountsBalance,
                        summaryTint: AppPalette.mediumBlue,
                        route: .accounts
                    )

                    managementCard(
                        title: SavingsStrings.text(.settingsTitle),
                        subtitle: AppStrings.text(.managementSavingsDescription),
                        imageName: "QuickActionPoupanca",
                        summaryTitle: "Total poupado",
                        summaryValue: managementTotalSaved,
                        summaryTint: AppPalette.savings,
                        route: .savings
                    )

                    managementCard(
                        title: CreditStrings.text(.settingsTitle),
                        subtitle: AppStrings.text(.managementCreditsDescription),
                        imageName: "QuickActionCredito",
                        summaryTitle: "Total em dívida",
                        summaryValue: -managementTotalDebt,
                        summaryTint: AppPalette.primary,
                        route: .credits
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
        }
        .navigationDestination(for: ManagementSidebarTab.self) { tab in
            managementDestination(for: tab)
        }
        .background(AppPalette.appBackground)
    }

    @ViewBuilder
    private func managementDestination(for tab: ManagementSidebarTab) -> some View {
        switch tab {
        case .accounts:
            AccountsSettingsView()
        case .recurringExpenses:
            BudgetSettingsView()
        case .recurringIncome:
            BudgetSettingsView(openingList: 1, showsListControls: false)
        case .savings:
            SavingsSettingsView()
                .navigationTitle(SavingsStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        case .credits:
            CreditsSettingsView()
                .navigationTitle(CreditStrings.text(.settingsTitle))
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func managementCard(
        title: String,
        subtitle: String,
        imageName: String,
        summaryTitle: String,
        summaryValue: Double,
        summaryTint: Color,
        route: ManagementSidebarTab
    ) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 68)
                    .shadow(color: AppPalette.background.opacity(0.08), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(summaryTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.mutedText)
                            .lineLimit(1)
                        Text(summaryValue.currencyText)
                            .font(.subheadline.bold())
                            .foregroundStyle(summaryTint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: AppPalette.background.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var analyticsPeriodControls: some View {
        VStack(spacing: 10) {
            Picker("", selection: $selectedAnalyticsPeriod) {
                Text(AppStrings.text(.month)).tag(AnalyticsPeriod.month)
                Text(AppStrings.text(.year)).tag(AnalyticsPeriod.year)
            }
            .pickerStyle(.segmented)
            .tint(AppPalette.background)

            if selectedAnalyticsPeriod == .month {
                HStack(spacing: 12) {
                    analyticsMonthArrowButton(systemImage: "chevron.left") {
                        moveAnalyticsMonth(by: -1)
                    }
                    .disabled(selectedAnalyticsMonthOffset <= (monthOffsets.first ?? 0))
                    .opacity(selectedAnalyticsMonthOffset <= (monthOffsets.first ?? 0) ? 0.35 : 1)

                    Text(selectedAnalyticsMonth.monthTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity)

                    analyticsMonthArrowButton(systemImage: "chevron.right") {
                        moveAnalyticsMonth(by: 1)
                    }
                    .disabled(selectedAnalyticsMonthOffset >= (monthOffsets.last ?? 0))
                    .opacity(selectedAnalyticsMonthOffset >= (monthOffsets.last ?? 0) ? 0.35 : 1)
                }
            }
        }
    }

    private func analyticsMonthArrowButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 38, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func moveAnalyticsMonth(by value: Int) {
        let nextOffset = selectedAnalyticsMonthOffset + value
        let clampedOffset = min(max(nextOffset, monthOffsets.first ?? 0), monthOffsets.last ?? 0)
        withAnimation(.snappy) {
            selectedAnalyticsMonthOffset = clampedOffset
        }
    }

    private func moveAnalyticsHistoryMonth(by value: Int) {
        let nextOffset = selectedAnalyticsHistoryMonthOffset + value
        let clampedOffset = min(max(nextOffset, monthOffsets.first ?? 0), monthOffsets.last ?? 0)
        withAnimation(.snappy) {
            selectedAnalyticsHistoryMonthOffset = clampedOffset
        }
    }

    @ViewBuilder
    private var analyticsSummariesContent: some View {
        adviceCarouselCard
        analyticsListsCard
    }

    private var analyticsListsCard: some View {
        chartCard(
            title: selectedAnalyticsListTab.title,
            total: analyticsListTotal(for: selectedAnalyticsListTab)
        ) {
            if selectedAnalyticsListTab == .subscriptions {
                subscriptionScopePicker
            }
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                Picker("", selection: $selectedAnalyticsListTab) {
                    ForEach(AnalyticsListTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AppPalette.background)

                switch selectedAnalyticsListTab {
                case .subscriptions:
                    subscriptionList(displayedConfiguredSubscriptions, emptySystemImage: "play.rectangle")
                case .savings:
                    yearlySavingsList
                case .incomeVsExpenses:
                    incomeVsExpensesList
                }
            }
        }
    }

    private func analyticsListTotal(for tab: AnalyticsListTab) -> Double {
        switch tab {
        case .subscriptions:
            displayedConfiguredSubscriptions.reduce(0) { $0 + $1.amount }
        case .savings:
            yearSavingsPoints.reduce(0) { $0 + $1.expenses }
        case .incomeVsExpenses:
            annualBalancePoints.reduce(0) { $0 + $1.balance }
        }
    }

    private var subscriptionScopePicker: some View {
        Picker("", selection: $selectedSubscriptionAnalysisScope) {
            ForEach(SubscriptionAnalysisScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .tint(AppPalette.background)
        .frame(width: 150)
    }

    private var analyticsNetWorthCard: some View {
        GeometryReader { proxy in
            let safeWidth = max(proxy.size.width, 0)

            ZStack(alignment: .leading) {
                Image("NetWorthOverviewHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: safeWidth, height: usesSidebarNavigation ? 230 : 205)
                    .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppStrings.text(.netWorthTitle))
                        .font((usesSidebarNavigation ? Font.title2 : Font.title3).bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)

                    Text(AppStrings.text(.netWorthAccountsFormula))
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(analyticsNetWorthTotal.currencyText)
                        .font(.system(size: usesSidebarNavigation ? 46 : 36, weight: .bold, design: .rounded))
                        .foregroundStyle(analyticsNetWorthTotal < 0 ? AppPalette.primary : AppPalette.savings)
                        .lineLimit(1)
                        .minimumScaleFactor(0.48)
                        .frame(maxWidth: usesSidebarNavigation ? 360 : 230, alignment: .leading)
                        .padding(.top, 2)

                    if let trend = analyticsNetWorthVariationRatio {
                        HStack(spacing: 6) {
                            Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
                            Text(percentageText(abs(trend), total: 1))
                            Text(AppStrings.text(.previousMonthComparison))
                                .foregroundStyle(AppPalette.mutedText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            HelpIconButton(
                                title: AppStrings.text(.netWorthVariationTitle),
                                message: analyticsNetWorthTrendHelpMessage,
                                arrowEdge: .bottom
                            )
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trend >= 0 ? AppPalette.savings : AppPalette.primary)
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                        .padding(.vertical, 6)
                        .background(AppPalette.surface.opacity(0.72), in: Capsule())
                    }
                }
                .padding(usesSidebarNavigation ? 28 : 22)
                .frame(maxWidth: usesSidebarNavigation ? 420 : 245, alignment: .leading)
            }
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppPalette.background.opacity(0.08), radius: 16, y: 8)
        }
        .frame(height: usesSidebarNavigation ? 230 : 205)
    }

    private func analyticsOverviewMetricRow(
        icon: String,
        title: String,
        subtitle: String,
        value: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        GeometryReader { proxy in
            let safeWidth = max(proxy.size.width, 0)

            Button(action: action) {
                Group {
                    if usesSidebarNavigation {
                        HStack(spacing: 14) {
                            Image(systemName: icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(tint)
                                .frame(width: 46, height: 46)
                                .background(tint.opacity(0.14), in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(title)
                                    .font(.headline.bold())
                                    .foregroundStyle(AppPalette.background)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(AppPalette.mutedText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)
                            }
                            .layoutPriority(1)

                            Spacer(minLength: 10)

                            Text(value)
                                .font(.headline.bold())
                                .foregroundStyle(tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)
                                .frame(maxWidth: 170, alignment: .trailing)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: icon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(tint)
                                .frame(width: 42, height: 42)
                                .background(tint.opacity(0.14), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppPalette.background)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.68)

                                    Spacer(minLength: 4)

                                    Text(value)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(tint)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.42)
                                        .frame(maxWidth: 116, alignment: .trailing)
                                        .layoutPriority(1)
                                }

                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AppPalette.mutedText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(usesSidebarNavigation ? 14 : 12)
                .frame(width: safeWidth, height: usesSidebarNavigation ? 74 : 72)
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(height: usesSidebarNavigation ? 74 : 72)
    }

    private var analyticsQuickSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppStrings.text(.quickSummary))
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                Button {
                    openAnalyticsTab(.savingsCredits)
                } label: {
                    HStack(spacing: 4) {
                        Text(AppStrings.text(.seeAll))
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                }
                .buttonStyle(.plain)
                .layoutPriority(1)
            }

            analyticsQuickSummaryCardsGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var analyticsQuickSummaryCardsGrid: some View {
        AnalyticsQuickSummaryCards(
            savingSubtitle: largestSaving?.displayName ?? AppStrings.text(.noSavings),
            savingValue: largestSaving.map { $0.balance(with: savingMovements).currencyText } ?? Double.zero.currencyText,
            creditIcon: largestCredit?.creditType.iconName ?? "creditcard",
            creditSubtitle: largestCredit?.displayName ?? AppStrings.text(.noCredits),
            creditValue: largestCredit.map { (-$0.balance(with: creditMovements)).currencyText } ?? Double.zero.currencyText,
            savingsAction: {
                if let largestSaving {
                    selectedAnalyticsSavingDetail = largestSaving
                }
            },
            creditsAction: {
                if let largestCredit {
                    selectedAnalyticsCreditDetail = largestCredit
                }
            }
        )
        .frame(maxWidth: .infinity)
    }

    private var analyticsHistoryAccessCard: some View {
        Button {
            openAnalyticsTab(.history)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 46, height: 46)
                    .background(AppPalette.background.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppStrings.text(.movementHistory))
                        .font(.headline.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)

                    Text(AppStrings.text(.movementHistoryDescription))
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText.opacity(0.55))
            }
            .padding(14)
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var analyticsSavingsCard: some View {
        chartCard(title: SavingsStrings.text(.settingsTitle), total: analyticsSavingsTotal) {
            VStack(alignment: .leading, spacing: 10) {
                if analyticsSavingAccounts.isEmpty {
                    analyticsEmptyRow(systemImage: "leaf.fill")
                } else {
                    ForEach(analyticsSavingAccounts) { saving in
                        NavigationLink {
                            SavingDetailView(saving: saving)
                        } label: {
                            analyticsRow(
                                icon: saving.purposeIconName,
                                title: saving.displayName,
                                subtitle: analyticsSavingSubtitle(for: saving),
                                value: saving.balance(with: savingMovements).currencyText,
                                tint: AppPalette.savings
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var analyticsCreditsCard: some View {
        chartCard(title: CreditStrings.text(.settingsTitle), total: analyticsCreditDebtTotal) {
            VStack(alignment: .leading, spacing: 10) {
                if analyticsCreditAccounts.isEmpty {
                    analyticsEmptyRow(systemImage: "creditcard")
                } else {
                    ForEach(analyticsCreditAccounts) { credit in
                        NavigationLink {
                            CreditDetailView(credit: credit)
                        } label: {
                            analyticsRow(
                                icon: credit.creditType.iconName,
                                title: credit.displayName,
                                subtitle: analyticsCreditSubtitle(for: credit),
                                value: credit.balance(with: creditMovements).currencyText,
                                tint: AppPalette.primary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var analyticsHistoryCard: some View {
        chartCard(
            title: AppStrings.text(.movementHistory),
            total: analyticsHistoryTotal
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("", selection: $selectedAnalyticsHistoryFilterMode) {
                    ForEach(AnalyticsHistoryFilterMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .tint(AppPalette.background)

                if selectedAnalyticsHistoryFilterMode == .month {
                    HStack(spacing: 12) {
                        adviceNavigationButton(systemImage: "chevron.left") {
                            moveAnalyticsHistoryMonth(by: -1)
                        }

                        Text(selectedAnalyticsHistoryMonth.monthTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)
                            .frame(maxWidth: .infinity)

                        adviceNavigationButton(systemImage: "chevron.right") {
                            moveAnalyticsHistoryMonth(by: 1)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        DatePicker("Início", selection: $analyticsHistoryStartDate, displayedComponents: .date)
                        DatePicker("Fim", selection: $analyticsHistoryEndDate, displayedComponents: .date)
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.background)
                }

                let displayedHistoryLines = analyticsHistoryLines
                if displayedHistoryLines.isEmpty {
                    analyticsEmptyRow(systemImage: "clock.arrow.circlepath")
                } else {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(displayedHistoryLines) { line in
                            analyticsHistoryRow(line)
                        }
                    }
                }
            }
        }
    }

    private var analyticsSavingAccounts: [SavingAccount] {
        savingAccounts
            .filter { $0.savingStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var analyticsCreditAccounts: [CreditAccount] {
        creditAccounts
            .filter { $0.creditStatus == .active }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var analyticsSavingsTotal: Double {
        analyticsSavingAccounts.reduce(0) { $0 + $1.balance(with: savingMovements) }
    }

    private var analyticsCreditDebtTotal: Double {
        analyticsCreditAccounts.reduce(0) { $0 + $1.balance(with: creditMovements) }
    }

    private var analyticsNetWorthTotal: Double {
        totalSpendAccountsBalance + analyticsSavingsTotal - analyticsCreditDebtTotal
    }

    private var previousAnalyticsNetWorthTotal: Double? {
        let previousAccountBalance = spendAccounts.reduce(0) { total, account in
            let movements = accountMovements.filter { $0.accountID == account.id && $0.date < currentMonth }
            return total + account.balance(with: movements)
        }
        let previousSavingsTotal = analyticsSavingAccounts.reduce(0) { total, saving in
            let movements = savingMovements.filter { $0.savingID == saving.id && $0.date < currentMonth }
            return total + saving.balance(with: movements)
        }
        let previousCreditDebtTotal = analyticsCreditAccounts.reduce(0) { total, credit in
            let movements = creditMovements.filter { $0.creditID == credit.id && $0.date < currentMonth }
            return total + credit.balance(with: movements)
        }

        return previousAccountBalance + previousSavingsTotal - previousCreditDebtTotal
    }

    private var analyticsNetWorthVariationRatio: Double? {
        guard let previousTotal = previousAnalyticsNetWorthTotal, abs(previousTotal) > 0.01 else { return nil }
        return (analyticsNetWorthTotal - previousTotal) / abs(previousTotal)
    }

    private var analyticsNetWorthTrendHelpMessage: String {
        guard let previousTotal = previousAnalyticsNetWorthTotal,
              let ratio = analyticsNetWorthVariationRatio
        else {
            return "Ainda não existe valor do mês anterior suficiente para calcular a variação."
        }

        let difference = analyticsNetWorthTotal - previousTotal
        return "Património atual: \(analyticsNetWorthTotal.currencyText)\nPatrimónio do mês anterior: \(previousTotal.currencyText)\nDiferença: \(difference.currencyText)\nPercentagem: \(difference.currencyText) ÷ \(abs(previousTotal).currencyText) = \(percentageText(abs(ratio), total: 1))"
    }

    private var largestSaving: SavingAccount? {
        analyticsSavingAccounts.max { first, second in
            first.balance(with: savingMovements) < second.balance(with: savingMovements)
        }
    }

    private var largestCredit: CreditAccount? {
        analyticsCreditAccounts.max { first, second in
            first.balance(with: creditMovements) < second.balance(with: creditMovements)
        }
    }

    private var lightweightEvolutionSignature: String {
        let transactionSignature = transactions
            .map { transaction in
                [
                    transaction.id.uuidString,
                    transaction.title,
                    transaction.displayName,
                    transaction.kind,
                    "\(transaction.day)",
                    "\(transaction.amount)",
                    transaction.monthStart.ISO8601Format(),
                    transaction.recurrenceType ?? "",
                    "\(transaction.recurrenceMonth)",
                    transaction.recurrenceEndMonthStart?.ISO8601Format() ?? "",
                    transaction.budgetAllocationType ?? "",
                    transaction.budgetMonthStart?.ISO8601Format() ?? ""
                ].joined(separator: "|")
            }
            .sorted()
            .joined(separator: ";")
        let paymentSignature = payments
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())|\($0.occurrenceDay ?? -1)|\($0.amountPaid ?? -1)" }
            .sorted()
            .joined(separator: ";")
        let exclusionSignature = exclusions
            .map { "\($0.transactionID.uuidString)|\($0.monthStart.ISO8601Format())|\($0.occurrenceDay ?? -1)" }
            .sorted()
            .joined(separator: ";")
        let savingSignature = savingAccounts
            .map { "\($0.id.uuidString)|\($0.name)|\($0.initialAmount)|\($0.createdAt.ISO8601Format())|\($0.status)" }
            .sorted()
            .joined(separator: ";")
        let savingMovementSignature = savingMovements
            .map { "\($0.id.uuidString)|\($0.savingID.uuidString)|\($0.date.ISO8601Format())|\($0.type)|\($0.amount)" }
            .sorted()
            .joined(separator: ";")
        let creditSignature = creditAccounts
            .map { "\($0.id.uuidString)|\($0.name)|\($0.initialDebt)|\($0.createdAt.ISO8601Format())|\($0.status)" }
            .sorted()
            .joined(separator: ";")
        let creditMovementSignature = creditMovements
            .map { "\($0.id.uuidString)|\($0.creditID.uuidString)|\($0.date.ISO8601Format())|\($0.type)|\($0.amount)" }
            .sorted()
            .joined(separator: ";")

        return [
            transactionSignature,
            paymentSignature,
            exclusionSignature,
            savingSignature,
            savingMovementSignature,
            creditSignature,
            creditMovementSignature
        ].joined(separator: "#")
    }

    private func refreshLightweightEvolutionTableIfNeeded() {
        let signature = lightweightEvolutionSignature
        guard lightweightEvolutionSignatureSnapshot != signature || lightweightEvolutionTable.balance.isEmpty else { return }

        lightweightEvolutionTable = buildLightweightEvolutionTable()
        lightweightEvolutionSignatureSnapshot = signature
    }

    private func scheduleLightweightEvolutionTableRefreshIfNeeded() {
        guard !isLightweightEvolutionLoading else { return }
        let kind = selectedLightweightEvolutionKind
        guard lightweightEvolutionTable.points(for: kind).isEmpty else { return }

        isLightweightEvolutionLoading = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            let points = await buildLightweightEvolutionPoints(for: kind)
            lightweightEvolutionTable = lightweightEvolutionTable.replacing(points, for: kind)
            isLightweightEvolutionLoading = false

            if lightweightEvolutionTable.points(for: selectedLightweightEvolutionKind).isEmpty {
                scheduleLightweightEvolutionTableRefreshIfNeeded()
            }
        }
    }

    private func buildLightweightEvolutionPoints(for kind: LightweightEvolutionKind) async -> [LightweightEvolutionPoint] {
        switch kind {
        case .balance:
            return await lightweightBalanceEvolutionPoints()
        case .savings, .credits:
            return await lightweightAssetEvolutionPoints(for: kind)
        }
    }

    private func buildLightweightEvolutionTable() -> LightweightEvolutionTable {
        LightweightEvolutionTable(
            balance: lightweightEvolutionTable.balance,
            savings: lightweightEvolutionPoints(for: .savings),
            credits: lightweightEvolutionPoints(for: .credits)
        )
    }

    private func currentLightweightEvolutionValue(for kind: LightweightEvolutionKind) -> Double {
        switch kind {
        case .balance:
            inAccount
        case .savings:
            analyticsSavingsTotal
        case .credits:
            analyticsCreditDebtTotal
        }
    }

    private func lightweightEvolutionPoints(for kind: LightweightEvolutionKind) -> [LightweightEvolutionPoint] {
        let today = Calendar.current.startOfDay(for: Date())

        return (-60...90).compactMap { offset in
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: today) else { return nil }
            let value: Double

            switch kind {
            case .balance:
                value = projectedAccountBalance(until: day)
            case .savings:
                value = savingsBalance(until: day)
            case .credits:
                value = creditDebt(until: day)
            }

            let marker = lightweightEvolutionPreparedMarker(on: day, kind: kind)
            return LightweightEvolutionPoint(
                month: day,
                value: value,
                markerTitle: marker?.title,
                markerIcon: marker?.icon,
                markerTint: marker?.tint
            )
        }
    }

    private func lightweightAssetEvolutionPoints(for kind: LightweightEvolutionKind) async -> [LightweightEvolutionPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var points = [LightweightEvolutionPoint]()
        points.reserveCapacity(151)

        for offset in -60...90 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let value = kind == .savings ? savingsBalance(until: day) : creditDebt(until: day)
            points.append(
                LightweightEvolutionPoint(
                    month: day,
                    value: value,
                    markerTitle: nil,
                    markerIcon: nil,
                    markerTint: nil
                )
            )

            if abs(offset).isMultiple(of: 10) {
                await Task.yield()
            }
        }

        return points
    }

    private func lightweightBalanceEvolutionPoints() async -> [LightweightEvolutionPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var valuesByDay = [Date: Double]()
        valuesByDay[today] = inAccount

        var futureBalance = inAccount
        for offset in 1...90 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            futureBalance += lightweightAccountBalanceEffect(on: day)
            valuesByDay[day] = futureBalance

            if offset.isMultiple(of: 10) {
                await Task.yield()
            }
        }

        var pastBalance = inAccount
        for offset in stride(from: -1, through: -60, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let nextDay = calendar.date(byAdding: .day, value: 1, to: day)
            else { continue }

            pastBalance -= lightweightAccountBalanceEffect(on: nextDay)
            valuesByDay[day] = pastBalance

            if abs(offset).isMultiple(of: 10) {
                await Task.yield()
            }
        }

        return (-60...90).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let value = valuesByDay[day]
            else { return nil }

            let marker = lightweightEvolutionPreparedMarker(on: day, kind: .balance)
            return LightweightEvolutionPoint(
                month: day,
                value: value,
                markerTitle: marker?.title,
                markerIcon: marker?.icon,
                markerTint: marker?.tint
            )
        }
    }

    private func lightweightAccountBalanceEffect(on day: Date) -> Double {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: day)
        let month = targetDay.monthStart
        let dayNumber = calendar.component(.day, from: targetDay)
        let today = calendar.startOfDay(for: Date())
        var total = 0.0

        for transaction in calculator.visibleTransactions(in: month) {
            let occurrenceDays = transaction.occurrenceDays(in: month, exclusions: exclusions)
            guard occurrenceDays.contains(dayNumber) else { continue }

            let occurrenceDay = transaction.recurrence == .weekly ? dayNumber : nil
            if transaction.kind == TransactionKind.income.rawValue {
                let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                guard scheduledAmount.isFinite else { continue }
                total += scheduledAmount
            } else if targetDay <= today {
                let paidAmount = calculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
                guard paidAmount.isFinite else { continue }
                total -= paidAmount
            } else {
                let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                guard scheduledAmount.isFinite else { continue }
                total -= scheduledAmount
            }
        }

        return total
    }

    private func projectedAccountBalance(until date: Date) -> Double {
        let targetDate = Calendar.current.startOfDay(for: date)
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min() else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())

        return MoneyCalculationService.months(from: firstMonth, through: targetDate.monthStart).reduce(0) { total, month in
            let monthTotal = calculator.visibleTransactions(in: month).reduce(0) { monthResult, transaction in
                let occurrenceTotal = transaction.occurrenceDays(in: month, exclusions: exclusions).reduce(0) { dayResult, day in
                    let occurrenceDate = Calendar.current.startOfDay(for: month.date(day: day))
                    guard occurrenceDate <= targetDate else { return dayResult }

                    let occurrenceDay = transaction.recurrence == .weekly ? day : nil
                    if transaction.kind == TransactionKind.income.rawValue {
                        let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                        guard scheduledAmount.isFinite else { return dayResult }
                        return dayResult + scheduledAmount
                    }

                    if occurrenceDate <= today {
                        let paidAmount = calculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
                        guard paidAmount.isFinite else { return dayResult }
                        return dayResult - paidAmount
                    }

                    let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                    guard scheduledAmount.isFinite else { return dayResult }
                    return dayResult - scheduledAmount
                }

                return monthResult + occurrenceTotal
            }

            return total + monthTotal
        }
    }

    private func savingsBalance(until date: Date) -> Double {
        let targetDate = Calendar.current.startOfDay(for: date)
        return analyticsSavingAccounts.reduce(0) { total, saving in
            let initialAmount = Calendar.current.startOfDay(for: saving.createdAt) <= targetDate ? saving.initialAmount : 0
            let movementAmount = savingMovements
                .filter { $0.savingID == saving.id && Calendar.current.startOfDay(for: $0.date) <= targetDate }
                .reduce(0) { $0 + $1.balanceEffect }
            return total + max(initialAmount + movementAmount, 0)
        }
    }

    private func creditDebt(until date: Date) -> Double {
        let targetDate = Calendar.current.startOfDay(for: date)
        return analyticsCreditAccounts.reduce(0) { total, credit in
            let initialDebt = Calendar.current.startOfDay(for: credit.createdAt) <= targetDate ? credit.initialDebt : 0
            let movementAmount = creditMovements
                .filter { $0.creditID == credit.id && Calendar.current.startOfDay(for: $0.date) <= targetDate }
                .reduce(0) { $0 + $1.balanceEffect }
            return total + max(initialDebt + movementAmount, 0)
        }
    }

    private func normalizedLightweightChartPoints(_ points: [LightweightEvolutionPoint], in size: CGSize) -> [CGPoint] {
        let points = sanitizedLightweightEvolutionPoints(points)
        guard points.count > 1 else { return [] }

        let values = points.map(\.value)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let range = max(maximum - minimum, 1)
        guard minimum.isFinite, maximum.isFinite, range.isFinite else { return [] }
        let horizontalPadding: CGFloat = 10
        let verticalPadding: CGFloat = 12
        let width = max(size.width - horizontalPadding * 2, 1)
        let height = max(size.height - verticalPadding * 2, 1)

        return points.enumerated().map { index, point in
            let x = horizontalPadding + width * CGFloat(index) / CGFloat(points.count - 1)
            let normalizedY = (point.value - minimum) / range
            let y = verticalPadding + height * CGFloat(1 - normalizedY)
            return CGPoint(x: x, y: y)
        }
    }

    private func normalizedLightweightChartPoints(_ points: [LightweightEvolutionPoint], in rect: CGRect) -> [CGPoint] {
        let points = sanitizedLightweightEvolutionPoints(points)
        guard points.count > 1 else { return [] }

        let values = points.map(\.value)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let range = max(maximum - minimum, 1)
        guard minimum.isFinite, maximum.isFinite, range.isFinite else { return [] }

        return points.enumerated().map { index, point in
            let x = rect.minX + rect.width * CGFloat(index) / CGFloat(points.count - 1)
            let normalizedY = (point.value - minimum) / range
            let y = rect.minY + rect.height * CGFloat(1 - normalizedY)
            return CGPoint(x: x, y: y)
        }
    }

    private func lightweightEvolutionAxisValues(_ points: [LightweightEvolutionPoint]) -> [Double] {
        let values = sanitizedLightweightEvolutionPoints(points).map(\.value)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 0
        let rawRange = max(maximum - minimum, 1)
        let step = lightweightEvolutionRoundedAxisStep(for: rawRange / 4)
        guard minimum.isFinite, maximum.isFinite, rawRange.isFinite, step.isFinite, step > 0 else { return [0] }
        let roundedMaximum = ceil(maximum / step) * step
        let roundedMinimum = minimum < -(step * 0.25) ? floor(minimum / step) * step : 0
        var axisValues: [Double] = []
        var value = roundedMaximum

        while value >= roundedMinimum, axisValues.count < 6 {
            axisValues.append(value)
            value -= step
        }

        if axisValues.last != roundedMinimum {
            axisValues.append(roundedMinimum)
        }
        return axisValues
    }

    private func lightweightEvolutionRoundedAxisStep(for rawStep: Double) -> Double {
        guard rawStep.isFinite, rawStep > 0 else { return 100 }

        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude
        let roundedNormalized: Double

        switch normalized {
        case ...1:
            roundedNormalized = 1
        case ...2:
            roundedNormalized = 2
        case ...5:
            roundedNormalized = 5
        default:
            roundedNormalized = 10
        }

        return roundedNormalized * magnitude
    }

    private func lightweightEvolutionAxisY(_ value: Double, axisValues: [Double], in rect: CGRect) -> CGFloat {
        guard let maximum = axisValues.first, let minimum = axisValues.last else { return rect.midY }
        let range = max(maximum - minimum, 1)
        guard value.isFinite, maximum.isFinite, minimum.isFinite, range.isFinite else { return rect.midY }
        let normalizedY = (value - minimum) / range
        return rect.minY + rect.height * CGFloat(1 - normalizedY)
    }

    private func lightweightEvolutionAxisLabel(_ value: Double, for kind: LightweightEvolutionKind) -> String {
        displayedLightweightEvolutionRoundedValue(value, for: kind)
    }

    private func sanitizedLightweightEvolutionPoints(_ points: [LightweightEvolutionPoint]) -> [LightweightEvolutionPoint] {
        var seenDays = Set<Date>()
        let calendar = Calendar.current

        return points.compactMap { point in
            guard point.value.isFinite else { return nil }

            let normalizedDay = calendar.startOfDay(for: point.month)
            guard seenDays.insert(normalizedDay).inserted else { return nil }

            return LightweightEvolutionPoint(
                month: normalizedDay,
                value: point.value,
                markerTitle: point.markerTitle,
                markerIcon: point.markerIcon,
                markerTint: point.markerTint
            )
        }
    }

    private func scrollLightweightEvolutionToToday(points: [LightweightEvolutionPoint], proxy: ScrollViewProxy) {
        guard let todayID = points.first(where: { Calendar.current.isDate($0.month, inSameDayAs: Date()) })?.id else { return }

        Task { @MainActor in
            await Task.yield()
            proxy.scrollTo(todayID, anchor: UnitPoint(x: 0.28, y: 0.5))
        }
    }

    private func lightweightEvolutionShouldShowDateLabel(at index: Int, point: LightweightEvolutionPoint, totalCount: Int) -> Bool {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: point.month)
        let lastDay = calendar.range(of: .day, in: .month, for: point.month)?.count ?? 30
        let middleDay = max(1, Int(ceil(Double(lastDay) / 2)))

        return day == 1
            || day == middleDay
            || day == lastDay
            || index == 0
            || index == totalCount - 1
    }

    private func lightweightEvolutionPreparedMarker(on day: Date, kind: LightweightEvolutionKind) -> (title: String, icon: String, tint: Color)? {
        guard kind == .balance else { return nil }

        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: day)
        let dayNumber = calendar.component(.day, from: targetDay)
        let today = calendar.startOfDay(for: Date())
        var selectedTitle = ""
        var selectedIcon = "banknote"
        var selectedTint = AppPalette.savings
        var selectedAmount = 0.0
        let minimumMarkerAmount = 100.0

        for transaction in calculator.visibleTransactions(in: targetDay.monthStart) {
            guard !transaction.isWholeMonthExpense else { continue }

            let occurrenceDays = transaction.occurrenceDays(in: targetDay.monthStart, exclusions: exclusions)
            guard occurrenceDays.contains(dayNumber) else { continue }

            let occurrenceDay = transaction.recurrence == .weekly ? dayNumber : nil
            let title = transaction.displayName.isEmpty ? transaction.title : transaction.displayName
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let amount: Double

            if transaction.kind == TransactionKind.expense.rawValue && targetDay <= today {
                amount = abs(calculator.paidAmount(for: transaction, in: targetDay.monthStart, occurrenceDay: occurrenceDay))
            } else {
                amount = abs(transaction.scheduledAmount(in: targetDay.monthStart, occurrenceDay: occurrenceDay))
            }

            guard !cleanTitle.isEmpty, amount >= minimumMarkerAmount, amount > selectedAmount else { continue }

            if transaction.kind == TransactionKind.income.rawValue {
                selectedTitle = cleanTitle
                selectedIcon = "banknote"
                selectedTint = AppPalette.savings
            } else {
                selectedTitle = cleanTitle
                selectedIcon = ExpenseTypeIcon.name(for: cleanTitle)
                selectedTint = AppPalette.primary
            }

            selectedAmount = amount
        }

        return selectedAmount > 0 ? (selectedTitle, selectedIcon, selectedTint) : nil
    }

    private func addSmoothLine(to path: inout Path, points: [CGPoint], movesToFirstPoint: Bool = true) {
        guard let first = points.first else { return }
        if movesToFirstPoint {
            path.move(to: first)
        }

        guard points.count > 1 else { return }

        for index in 1..<points.count {
            let p0 = points[max(index - 2, 0)]
            let p1 = points[index - 1]
            let p2 = points[index]
            let p3 = points[min(index + 1, points.count - 1)]
            let tension: CGFloat = 0.42
            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension / 3,
                y: p1.y + (p2.y - p0.y) * tension / 3
            )
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension / 3,
                y: p2.y - (p3.y - p1.y) * tension / 3
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }
    }

    private func displayedLightweightEvolutionValue(_ value: Double, for kind: LightweightEvolutionKind) -> String {
        kind == .credits ? (-value).currencyText : value.currencyText
    }

    private func displayedLightweightEvolutionRoundedValue(_ value: Double, for kind: LightweightEvolutionKind) -> String {
        let displayedValue = kind == .credits ? -value : value
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        return formatter.string(from: NSNumber(value: displayedValue)) ?? displayedValue.currencyText
    }

    private func lightweightEvolutionDeltaText(_ delta: Double, for kind: LightweightEvolutionKind) -> String {
        let displayedDelta = kind == .credits ? -delta : delta
        if abs(displayedDelta) < 0.01 {
            return AppStrings.text(.noVariation)
        }

        let prefix = displayedDelta > 0 ? "+" : ""
        return "\(prefix)\(displayedDelta.currencyText) \(AppStrings.text(.previousMonthComparison))"
    }

    private func lightweightEvolutionDeltaColor(_ delta: Double, for kind: LightweightEvolutionKind) -> Color {
        guard abs(delta) >= 0.01 else { return AppPalette.mutedText }

        switch kind {
        case .balance, .savings:
            return delta >= 0 ? AppPalette.savings : AppPalette.primary
        case .credits:
            return delta <= 0 ? AppPalette.savings : AppPalette.primary
        }
    }

    private func lightweightEvolutionMonthTitle(_ month: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: month)
        let lastDay = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        let middleDay = max(1, Int(ceil(Double(lastDay) / 2)))

        if day == middleDay {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
            formatter.setLocalizedDateFormatFromTemplate("MMM")
            return formatter.string(from: month).capitalized
        }

        return "\(day)"
    }

    private func lightweightEvolutionDetailedMonthTitle(_ month: Date) -> String {
        if Calendar.current.isDate(month, inSameDayAs: Date()) {
            return "\(Date().monthTitle) · dia \(Calendar.current.component(.day, from: Date()))"
        }

        return month.monthTitle
    }

    private func lightweightEvolutionMonthStatus(_ month: Date) -> String {
        if Calendar.current.isDate(month, equalTo: currentMonth, toGranularity: .month) {
            return "Valor atual neste mês"
        }

        return month < currentMonth ? "Histórico fechado" : "Previsão com dados registados"
    }

    private var selectedAnalyticsHistoryMonth: Date {
        Calendar.current.date(byAdding: .month, value: selectedAnalyticsHistoryMonthOffset, to: Date().monthStart) ?? Date().monthStart
    }

    private var analyticsHistoryDateBounds: (start: Date, endExclusive: Date) {
        if selectedAnalyticsHistoryFilterMode == .month {
            return (selectedAnalyticsHistoryMonth.monthStart, selectedAnalyticsHistoryMonth.nextMonthStart)
        }

        let firstDate = min(analyticsHistoryStartDate, analyticsHistoryEndDate)
        let lastDate = max(analyticsHistoryStartDate, analyticsHistoryEndDate)
        let start = Calendar.current.startOfDay(for: firstDate)
        let endStart = Calendar.current.startOfDay(for: lastDate)
        let endExclusive = Calendar.current.date(byAdding: .day, value: 1, to: endStart) ?? endStart.addingTimeInterval(86_400)
        return (start, endExclusive)
    }

    private var analyticsHistoryLines: [AnalyticsHistoryLine] {
        let bounds = analyticsHistoryDateBounds
        let auditLines = auditLogEntries.compactMap { entry -> AnalyticsHistoryLine? in
            guard entry.date >= bounds.start, entry.date < bounds.endExclusive else { return nil }
            let action = entry.auditAction
            let balanceText = AppStrings.currentLanguage == .portuguese
                ? "Saldo total na altura: \(entry.balanceAfter.currencyText)"
                : "Total balance at the time: \(entry.balanceAfter.currencyText)"
            let note = [entry.details, entry.note, balanceText]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            return AnalyticsHistoryLine(
                id: "audit-\(entry.id.uuidString)",
                date: entry.date,
                name: entry.title,
                type: action.title,
                note: note,
                amount: entry.amount,
                amountText: entry.amount.currencyText,
                amountColor: entry.amount >= 0 ? AppPalette.positive : AppPalette.primary,
                icon: action.iconName,
                tint: action.tint
            )
        }

        if !auditLines.isEmpty {
            return auditLines.sorted { first, second in
                if first.date != second.date { return first.date > second.date }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
        }

        let transactionByID = transactions.reduce(into: [UUID: MoneyTransaction]()) { result, transaction in
            result[transaction.id] = transaction
        }
        let creditByID = creditAccounts.reduce(into: [UUID: CreditAccount]()) { result, credit in
            result[credit.id] = credit
        }
        let savingByID = savingAccounts.reduce(into: [UUID: SavingAccount]()) { result, saving in
            result[saving.id] = saving
        }
        let accountByID = spendAccounts.reduce(into: [UUID: SpendAccount]()) { result, account in
            result[account.id] = account
        }

        let paymentLines = paymentHistory.compactMap { entry -> AnalyticsHistoryLine? in
            guard entry.paidAt >= bounds.start, entry.paidAt < bounds.endExclusive else { return nil }
            guard let transaction = transactionByID[entry.transactionID] else { return nil }
            let title = analyticsTransactionTitle(for: transaction)
            let type = transaction.kind == TransactionKind.income.rawValue
                ? AppStrings.text(.income)
                : transaction.displayName
            let tint = transaction.kind == TransactionKind.income.rawValue
                ? AppPalette.savings
                : (ExpenseCategory(rawValue: transaction.expenseCategory ?? "")?.color ?? AppPalette.primary)
            let amount = transaction.kind == TransactionKind.income.rawValue ? abs(entry.amount) : -abs(entry.amount)

            return AnalyticsHistoryLine(
                id: "payment-\(entry.id.uuidString)",
                date: entry.paidAt,
                name: title,
                type: "\(AppStrings.text(.currentAccount)) · \(type)",
                note: transaction.detailText(in: entry.monthStart),
                amount: amount,
                amountText: amount.currencyText,
                amountColor: amount >= 0 ? AppPalette.savings : AppPalette.primary,
                icon: transaction.kind == TransactionKind.income.rawValue ? "tray.and.arrow.down.fill" : ExpenseTypeIcon.name(for: transaction.displayName),
                tint: tint
            )
        }

        let creditLines = creditMovements.compactMap { movement -> AnalyticsHistoryLine? in
            guard movement.date >= bounds.start, movement.date < bounds.endExclusive else { return nil }
            let creditName = creditByID[movement.creditID]?.displayName ?? CreditStrings.text(.credit)

            return AnalyticsHistoryLine(
                id: "credit-\(movement.id.uuidString)",
                date: movement.date,
                name: creditName,
                type: "\(CreditStrings.text(.settingsTitle)) · \(movement.kind.title)",
                note: movement.note,
                amount: movement.balanceEffect,
                amountText: movement.signedAmountText,
                amountColor: movement.balanceEffect <= 0 ? AppPalette.positive : AppPalette.primary,
                icon: movement.kind.iconName,
                tint: movement.kind.tint
            )
        }

        let savingLines = savingMovements.compactMap { movement -> AnalyticsHistoryLine? in
            guard movement.date >= bounds.start, movement.date < bounds.endExclusive else { return nil }
            let savingName = savingByID[movement.savingID]?.displayName ?? SavingsStrings.text(.saving)

            return AnalyticsHistoryLine(
                id: "saving-\(movement.id.uuidString)",
                date: movement.date,
                name: savingName,
                type: "\(SavingsStrings.text(.settingsTitle)) · \(movement.kind.title)",
                note: movement.note,
                amount: movement.balanceEffect,
                amountText: movement.signedAmountText,
                amountColor: movement.balanceEffect >= 0 ? AppPalette.positive : AppPalette.primary,
                icon: movement.kind.iconName,
                tint: movement.kind.tint
            )
        }

        let accountLines = accountMovements.compactMap { movement -> AnalyticsHistoryLine? in
            guard movement.date >= bounds.start, movement.date < bounds.endExclusive else { return nil }
            guard movement.kind != .expensePayment else { return nil }

            let accountName = accountByID[movement.accountID]?.displayName ?? AppStrings.text(.accounts)
            var typeParts = [AppStrings.text(.accounts), movement.kind.title]
            if let relatedAccountID = movement.relatedAccountID,
               let relatedAccountName = accountByID[relatedAccountID]?.displayName {
                typeParts.append(relatedAccountName)
            }

            return AnalyticsHistoryLine(
                id: "account-\(movement.id.uuidString)",
                date: movement.date,
                name: accountName,
                type: typeParts.joined(separator: " · "),
                note: movement.note,
                amount: movement.amount,
                amountText: movement.signedAmountText,
                amountColor: movement.amount >= 0 ? AppPalette.positive : AppPalette.primary,
                icon: movement.kind.iconName,
                tint: movement.kind.tint
            )
        }

        return (paymentLines + creditLines + savingLines + accountLines)
            .sorted { first, second in
                if first.date != second.date { return first.date > second.date }
                return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            }
    }

    private var analyticsHistoryTotal: Double {
        analyticsHistoryLines.reduce(0) { $0 + abs($1.amount) }
    }

    private func analyticsSavingSubtitle(for saving: SavingAccount) -> String {
        let variation = saving.monthVariation(in: currentMonth, movements: savingMovements)
        var parts = ["\(SavingsStrings.text(.monthVariation)): \(variation.currencyText)"]
        if let target = saving.targetAmount, target > 0 {
            parts.append("\(SavingsStrings.text(.targetProgress)): \(percentageText(saving.balance(with: savingMovements), total: target))")
        }
        return parts.joined(separator: " · ")
    }

    private func analyticsCreditSubtitle(for credit: CreditAccount) -> String {
        let balance = credit.balance(with: creditMovements)
        let variation = credit.monthVariation(in: currentMonth, movements: creditMovements)
        var parts = [credit.creditType.title, "\(CreditStrings.text(.monthVariation)): \(variation.currencyText)"]
        if let limit = credit.creditLimit, limit > 0 {
            parts.append("\(CreditStrings.text(.usedPercentage)): \(percentageText(balance, total: limit))")
        }
        return parts.joined(separator: " · ")
    }

    private func subscriptionList(_ transactions: [MoneyTransaction], emptySystemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if transactions.isEmpty {
                analyticsEmptyRow(systemImage: emptySystemImage)
            } else {
                ForEach(transactions) { transaction in
                    analyticsRow(
                        icon: ExpenseTypeIcon.name(for: transaction.displayName),
                        title: analyticsTransactionTitle(for: transaction),
                        subtitle: analyticsConfiguredSubscriptionSubtitle(for: transaction),
                        value: transaction.amount.currencyText,
                        tint: AppPalette.primary
                    )
                }
            }
        }
    }

    private var yearlySavingsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            let visiblePoints = yearSavingsPoints.filter { $0.expenses > 0 }
            if visiblePoints.isEmpty {
                analyticsEmptyRow(systemImage: "leaf.fill")
            } else {
                ForEach(visiblePoints) { point in
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.caption.bold())
                            .foregroundStyle(AppPalette.savings)
                            .frame(width: 30, height: 30)
                            .background(AppPalette.savings.opacity(0.14), in: Circle())

                        Text(point.month.monthTitle)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.background)

                        Spacer(minLength: 8)

                        Text(point.expenses.currencyText)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppPalette.savings)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Button {
                            savingsHistoryRequest = SavingsHistoryRequest(month: point.month)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppPalette.background)
                                .frame(width: 34, height: 34)
                                .background(AppPalette.surface, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppStrings.text(.savingsHistoryTitle))
                    }
                    .padding(10)
                    .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func monthlyAmountList(points: [MonthlyBalancePoint], value: @escaping (MonthlyBalancePoint) -> Double, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            let visiblePoints = points.filter { value($0) > 0 }
            if visiblePoints.isEmpty {
                analyticsEmptyRow(systemImage: systemImage)
            } else {
                ForEach(visiblePoints) { point in
                    analyticsRow(
                        icon: systemImage,
                        title: point.month.monthTitle,
                        subtitle: "",
                        value: value(point).currencyText,
                        tint: AppPalette.savings
                    )
                }
            }
        }
    }

    private func analyticsEmptyRow(systemImage: String) -> some View {
        ContentUnavailableView(AppStrings.text(.noListData), systemImage: "list.bullet.rectangle")
            .foregroundStyle(AppPalette.background)
            .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func analyticsTransactionTitle(for transaction: MoneyTransaction) -> String {
        let trimmedTitle = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? transaction.displayName : trimmedTitle
    }

    private func analyticsConfiguredSubscriptionSubtitle(for transaction: MoneyTransaction) -> String {
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

    private var incomeVsExpensesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(annualBalancePoints) { point in
                analyticsRow(
                    icon: "arrow.left.arrow.right",
                    title: point.month.monthTitle,
                    subtitle: "\(AppStrings.text(.chartIncome)): \(point.income.currencyText)\n\(AppStrings.text(.chartExpenses)): \(point.expenses.currencyText)",
                    value: point.balance.currencyText,
                    tint: point.balance >= 0 ? AppPalette.savings : AppPalette.primary
                )
            }
        }
    }

    private func analyticsRow(icon: String, title: String, subtitle: String, freeText: String = "", value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !freeText.isEmpty {
                    Text(freeText)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func analyticsHistoryRow(_ line: AnalyticsHistoryLine) -> some View {
        HStack(spacing: 12) {
            Image(systemName: line.icon)
                .font(.caption.bold())
                .foregroundStyle(line.tint)
                .frame(width: 30, height: 30)
                .background(line.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                Text(line.type)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)

                Text(line.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)

                if !line.note.isEmpty {
                    Text(line.note)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(4)
                }
            }

            Spacer(minLength: 8)

            Text(line.amountText)
                .font(.subheadline.bold())
                .foregroundStyle(line.amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var adviceCarouselCard: some View {
        let adviceCards = AppStrings.analyticsAdviceCards
        if !adviceCards.isEmpty {
            HStack(spacing: 12) {
                adviceNavigationButton(systemImage: "chevron.left") {
                    moveAdvice(by: -1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentAdvice.title)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.primary)
                        .lineLimit(1)

                    Text(currentAdvice.message)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .id(selectedAdviceIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer(minLength: 0)

                adviceNavigationButton(systemImage: "chevron.right") {
                    moveAdvice(by: 1)
                }
            }
            .padding(14)
            .background(AppPalette.mintSurface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppPalette.secondary.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let adviceCount = AppStrings.analyticsAdviceCards.count
                        guard adviceCount > 1, abs(value.translation.width) > 36 else { return }
                        moveAdvice(by: value.translation.width < 0 ? 1 : -1)
                    }
            )
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(25))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        moveAdvice(by: 1)
                    }
                }
            }
        }
    }

    private func adviceNavigationButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.background)
                .frame(width: 34, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func moveAdvice(by offset: Int) {
        let adviceCount = AppStrings.analyticsAdviceCards.count
        guard adviceCount > 0 else { return }

        withAnimation(.snappy) {
            selectedAdviceIndex = (selectedAdviceIndex + offset + adviceCount) % adviceCount
        }
    }

    private func chartCard<Content: View>(title: String, total: Double, @ViewBuilder content: () -> Content) -> some View {
        chartCard(title: title, total: total) {
            EmptyView()
        } content: {
            content()
        }
    }

    private func chartCard<HeaderAccessory: View, Content: View>(
        title: String,
        total: Double,
        @ViewBuilder headerAccessory: () -> HeaderAccessory,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                headerAccessory()

                Text(total.currencyText)
                    .font(.subheadline.bold())
                    .foregroundStyle(total < 0 ? AppPalette.primary : AppPalette.background)
            }

            content()
        }
        .padding()
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }

    private func pieChartColumn(title: String, points: [CategoryExpensePoint], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            if total > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points) { point in
                        analyticsDistributionBar(
                            title: categoryShortTitle(point.category),
                            amount: point.amount,
                            total: total,
                            tint: point.category.color
                        )
                    }
                }
            } else {
                ContentUnavailableView(AppStrings.text(.noTransactions), systemImage: "chart.pie")
                    .foregroundStyle(AppPalette.background)
                    .frame(height: 150)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func expenseTypePieChart(points: [ExpenseTypePoint], total: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if total > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(points.filter { $0.amount > 0 }) { point in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 10) {
                                Image(systemName: ExpenseTypeIcon.name(for: point.title))
                                    .font(.caption.bold())
                                    .foregroundStyle(point.category.color)
                                    .frame(width: 28, height: 28)
                                    .background(point.category.color.opacity(0.14), in: Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(point.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(AppPalette.background)
                                        .lineLimit(2)

                                    Text(point.category.title)
                                        .font(.caption2)
                                        .foregroundStyle(AppPalette.mutedText)
                                }

                                Spacer(minLength: 8)

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(percentageText(point.amount, total: total))
                                        .font(.caption.bold())
                                        .foregroundStyle(AppPalette.background)

                                    Text(point.amount.currencyText)
                                        .font(.caption2)
                                        .foregroundStyle(AppPalette.mutedText)
                                }
                            }

                            analyticsDistributionBarFill(amount: point.amount, total: total, tint: point.category.color)
                        }
                    }
                }
            } else {
                ContentUnavailableView(AppStrings.text(.noTransactions), systemImage: "chart.pie")
                    .foregroundStyle(AppPalette.background)
                    .frame(height: 180)
            }
        }
    }

    private func analyticsDistributionBar(title: String, amount: Double, total: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 24, alignment: .leading)

                Text(percentageText(amount, total: total))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.mutedText)

                Spacer(minLength: 4)

                Text(amount.currencyText)
                    .font(.caption2.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            analyticsDistributionBarFill(amount: amount, total: total, tint: tint)
        }
    }

    private func analyticsDistributionBarFill(amount: Double, total: Double, tint: Color) -> some View {
        GeometryReader { proxy in
            let safeWidth = max(proxy.size.width, 0)
            let ratio = total > 0 ? amount / total : 0
            let safeRatio = min(max(ratio.isFinite ? ratio : 0, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppPalette.separator.opacity(0.65))

                Capsule()
                    .fill(tint)
                    .frame(width: safeWidth * safeRatio)
            }
        }
        .frame(height: 8)
    }

    private func categoryShortTitle(_ category: ExpenseCategory) -> String {
        switch category {
        case .needs:
            "50"
        case .wants:
            "30"
        case .savingsAndDebt:
            "20"
        }
    }

    private func percentageText(_ amount: Double, total: Double) -> String {
        guard total > 0 else { return "0%" }
        return (amount / total).formatted(.percent.precision(.fractionLength(0)))
    }

    private var appIcon: some View {
        Image("SpendWiseIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 34)
    }

    private var settingsToolbarButton: some View {
        topToolbarIconButton(
            systemImage: "gearshape",
            accessibilityLabel: AppStrings.text(.settings)
        ) {
            settingsInitialTab = .budget
            showsSettings = true
        }
    }

    private var compactFilterButton: some View {
        topToolbarIconButton(
            systemImage: "line.3.horizontal.decrease",
            badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil,
            accessibilityLabel: AppStrings.text(.filters)
        ) {
            showsFilters = true
        }
    }

    private var phoneBottomAddButton: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showsQuickActions {
                phoneVerticalQuickActions
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            phoneBottomActionButton(
                systemImage: showsQuickActions ? "xmark" : "plus",
                accessibilityLabel: AppStrings.text(.add)
            ) {
                selectedPhoneTab = .currentAccount
                selectMainTab(.currentAccount)
                withAnimation(.snappy) {
                    showsQuickActions.toggle()
                }
            }

            phoneBottomActionButton(
                systemImage: "line.3.horizontal.decrease",
                badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil,
                accessibilityLabel: AppStrings.text(.filters)
            ) {
                selectedPhoneTab = .currentAccount
                selectMainTab(.currentAccount)
                showsQuickActions = false
                showsFilters = true
            }
        }
    }

    private var phoneVerticalQuickActions: some View {
        VStack(alignment: .trailing, spacing: 10) {
            phoneVerticalQuickActionButton(
                title: AppStrings.text(.expense),
                imageName: "QuickActionDespesa"
            ) {
                editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
                showsQuickActions = false
            }

            phoneVerticalQuickActionButton(
                title: AppStrings.text(.income),
                imageName: "QuickActionReceita"
            ) {
                editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
                showsQuickActions = false
            }

            if hasActiveSavings {
                phoneVerticalQuickActionButton(
                    title: SavingsStrings.text(.saving),
                    imageName: "QuickActionPoupanca"
                ) {
                    openPresetExpense(title: AppStrings.text(.newSavingExpense), expenseName: savingExpenseName)
                }
            }

            if hasActiveCredits {
                phoneVerticalQuickActionButton(
                    title: CreditStrings.text(.credit),
                    imageName: "QuickActionCredito"
                ) {
                    openCurrentAccountCreditMovement()
                }
            }

            phoneVerticalQuickActionButton(
                title: "Ler fatura",
                imageName: "QuickActionLerFatura"
            ) {
                openReceiptScanner()
            }
        }
    }

    private func phoneVerticalQuickActionButton(
        title: String,
        imageName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 124, height: 34)
                    .background(AppPalette.surface.opacity(0.98), in: Capsule())
                    .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func phoneBottomActionButton(
        systemImage: String,
        badge: String? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 50, height: 50)
                    .background(AppPalette.surface.opacity(0.98), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppPalette.background.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 18, height: 18)
                        .background(AppPalette.primary, in: Circle())
                        .offset(x: 1, y: -1)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private func topToolbarIconButton(
        systemImage: String,
        badge: String? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 40, height: 40)
                    .background(AppPalette.surface.opacity(0.96), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppPalette.background.opacity(0.12), lineWidth: 1)
                    }
                    .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 18, height: 18)
                        .background(AppPalette.primary, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var compactQuickActionsButton: some View {
        Button {
            withAnimation(.snappy) {
                showsQuickActions.toggle()
            }
        } label: {
            Image(systemName: showsQuickActions ? "xmark" : "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.background)
                .frame(width: 34, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppStrings.text(.add))
    }

    private func selectMainTab(_ tab: MainTab) {
        selectedTab = tab
        if tab != .currentAccount {
            showsQuickActions = false
        }
        if tab != .management {
            showsRecurringQuickActions = false
        }
    }

    private func openAccountsManagement() {
        selectedManagementSidebarTab = .accounts
        selectedPhoneTab = .management
        selectMainTab(.management)
        if !usesSidebarNavigation {
            showsPhoneAccountsManagement = true
        }
    }

    private var summaryBar: some View {
        VStack(spacing: 8) {
            SummaryTile(
                title: AppStrings.text(.balanceThisMonth),
                value: inAccount,
                helpText: balanceHelpText,
                iconImageName: "SaldoDisponivelIcon",
                footnote: balanceCardFootnote,
                helpTitle: futureBudgetReservationTotal > 0 ? AppStrings.text(.reservedBalanceHelpTitle) : nil,
                isCompact: !usesSidebarNavigation,
                onTap: openAccountsManagement
            )

            HStack(spacing: 8) {
                SummaryTile(
                    title: AppStrings.text(.monthUnpaid),
                    value: monthUnpaidExpenses,
                    helpText: AppStrings.text(.monthUnpaidHelp),
                    iconImageName: "FaltaPagarIcon",
                    helpArrowEdge: .bottom,
                    isCompact: !usesSidebarNavigation,
                    titleLineLimit: 1,
                    fixedHeight: usesSidebarNavigation ? nil : 82,
                    onTap: { showsUnpaidExpensesBreakdown = true }
                )
                if let monthRemaining {
                    SummaryTile(
                        title: monthRemaining < 0 ? AppStrings.text(.monthBudgetExceeded) : AppStrings.text(.monthRemaining),
                        value: monthRemaining,
                        helpText: AppStrings.text(.monthRemainingHelp),
                        iconImageName: "PodeGastarIcon",
                        boldHelpNote: AppStrings.text(.monthRemainingHelpNote),
                        isCompact: !usesSidebarNavigation,
                        titleLineLimit: 1,
                        fixedHeight: usesSidebarNavigation ? nil : 82
                    )
                }
            }
        }
        .padding(.horizontal, usesSidebarNavigation ? 16 : 12)
        .padding(.top, usesSidebarNavigation ? 4 : 0)
        .padding(.bottom, usesSidebarNavigation ? 12 : 4)
        .background(AppPalette.appBackground)
    }

    private var quickActionsBar: some View {
        Group {
            if hasActiveSavings && hasActiveCredits {
                HStack(spacing: 10) {
                    VStack(spacing: 10) {
                        savingQuickActionButton
                        creditQuickActionButton
                    }

                    VStack(spacing: 10) {
                        incomeQuickActionButton
                        expenseQuickActionButton
                        receiptQuickActionButton
                    }
                }
            } else if hasQuickSavingsOrCredits {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        incomeQuickActionButton
                        expenseQuickActionButton
                    }

                    receiptQuickActionButton

                    if hasActiveSavings {
                        savingQuickActionButton
                    }

                    if hasActiveCredits {
                        creditQuickActionButton
                    }
                }
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        incomeQuickActionButton
                        expenseQuickActionButton
                    }
                    receiptQuickActionButton
                }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var recurringQuickActionsBar: some View {
        VStack(spacing: 10) {
            recurringExpenseQuickActionButton
            recurringIncomeQuickActionButton
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var hasActiveSavings: Bool {
        savingAccounts.contains { $0.savingStatus == .active }
    }

    private var hasActiveCredits: Bool {
        creditAccounts.contains { $0.creditStatus == .active }
    }

    private var hasQuickSavingsOrCredits: Bool {
        hasActiveSavings || hasActiveCredits
    }

    private var savingQuickActionButton: some View {
        quickActionButton(
            title: SavingsStrings.text(.saving),
            imageName: "QuickActionPoupanca"
        ) {
            openPresetExpense(title: AppStrings.text(.newSavingExpense), expenseName: savingExpenseName)
        }
    }

    private var creditQuickActionButton: some View {
        quickActionButton(
            title: CreditStrings.text(.credit),
            imageName: "QuickActionCredito"
        ) {
            openCurrentAccountCreditMovement()
        }
    }

    private var incomeQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.income),
            imageName: "QuickActionReceita"
        ) {
            editorRequest = TransactionEditorRequest(mode: .income, month: selectedMonth)
            showsQuickActions = false
        }
    }

    private var recurringSavingQuickActionButton: some View {
        quickActionButton(
            title: SavingsStrings.text(.saving),
            imageName: "QuickActionPoupanca"
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newRecurringSavingExpense), expenseName: savingExpenseName)
        }
    }

    private var recurringCreditQuickActionButton: some View {
        quickActionButton(
            title: CreditStrings.text(.credit),
            imageName: "QuickActionCredito"
        ) {
            openPresetRecurringExpense(title: AppStrings.text(.newRecurringCreditPaymentExpense), expenseName: creditPaymentExpenseName)
        }
    }

    private var recurringIncomeQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.recurringIncome),
            imageName: "QuickActionReceita"
        ) {
            selectedManagementSidebarTab = .recurringIncome
            editorRequest = TransactionEditorRequest(mode: .salary, month: Date().monthStart)
            showsRecurringQuickActions = false
        }
    }

    private var expenseQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.expense),
            imageName: "QuickActionDespesa"
        ) {
            editorRequest = TransactionEditorRequest(mode: .expense, month: selectedMonth)
            showsQuickActions = false
        }
    }

    private var receiptQuickActionButton: some View {
        quickActionButton(
            title: "Ler fatura",
            imageName: "QuickActionLerFatura"
        ) {
            openReceiptScanner()
        }
    }

    private var recurringExpenseQuickActionButton: some View {
        quickActionButton(
            title: AppStrings.text(.recurringExpenses),
            imageName: "QuickActionDespesa"
        ) {
            selectedManagementSidebarTab = .recurringExpenses
            editorRequest = TransactionEditorRequest(mode: .monthlyExpense, month: Date().monthStart)
            showsRecurringQuickActions = false
        }
    }

    private func quickActionButton(title: String, imageName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 124, height: 34)
                    .background(AppPalette.surface.opacity(0.98), in: Capsule())
                    .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var savingExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalized(name)
            return normalizedName.contains("poup") || normalizedName.contains("saving")
        } ?? ""
    }

    private var creditPaymentExpenseName: String {
        ExpenseCategory.savingsAndDebt.names.first { name in
            let normalizedName = normalized(name)
            return normalizedName.contains("amort") || normalizedName.contains("divida") || normalizedName.contains("debt")
        } ?? ""
    }

    private func openPresetExpense(title: String, expenseName: String) {
        editorRequest = TransactionEditorRequest(
            mode: .expense,
            month: selectedMonth,
            titleOverride: title,
            initialExpenseCategory: .savingsAndDebt,
            initialExpenseName: expenseName
        )
        showsQuickActions = false
    }

    private func openCurrentAccountCreditMovement() {
        currentAccountCreditMovementRequest = CurrentAccountCreditMovementRequest(month: selectedMonth)
        showsQuickActions = false
    }

    private func openReceiptScanner() {
        selectMainTab(.currentAccount)
        showsQuickActions = false
        showsReceiptScanner = true
    }

    private func handleReceiptScanResult(_ result: ReceiptScanResult) {
        showsReceiptScanner = false
        let transactionDate = result.date ?? Date()
        let transactionMonth = transactionDate.monthStart
        editorRequest = TransactionEditorRequest(
            mode: .expense,
            month: transactionMonth,
            titleOverride: "Despesa por fatura",
            initialExpenseCategory: result.category,
            initialExpenseName: result.expenseName,
            initialTitle: result.title,
            initialAmount: result.amount,
            initialDate: transactionDate,
            startsMarkedAsPaid: true
        )

        if result.amount == nil {
            expenseNotice = ExpenseNotice(
                title: "Fatura lida",
                message: "Não foi possível detetar o valor total automaticamente. Confirma os dados antes de guardar."
            )
        }
    }

    private func handleReceiptScanFailure(_ message: String) {
        showsReceiptScanner = false
        expenseNotice = ExpenseNotice(
            title: "Não foi possível ler a fatura",
            message: message
        )
    }

    private func openPresetRecurringExpense(title: String, expenseName: String) {
        selectedManagementSidebarTab = .recurringExpenses
        editorRequest = TransactionEditorRequest(
            mode: .monthlyExpense,
            month: Date().monthStart,
            titleOverride: title,
            initialExpenseCategory: .savingsAndDebt,
            initialExpenseName: expenseName
        )
        showsRecurringQuickActions = false
    }

    @MainActor
    private func handleStartupMaintenance() async {
        guard !didRunStartupMaintenance else { return }
        didRunStartupMaintenance = true

        await Task.yield()
        try? await Task.sleep(nanoseconds: 350_000_000)
        handleAppear()
    }

    private func handleAppear() {
        migrateSpendAccountsIfNeeded()
        loadStoredCurrentAccountFilters()
        autoMarkDueRecurringExpensesAsPaid()
        checkOverdueExpenses()
    }

    private func migrateSpendAccountsIfNeeded() {
        var didChangeAccounts = false

        if spendAccounts.isEmpty {
            let primaryAccount = SpendAccount(
                name: AppStrings.text(.currentAccount),
                iconName: "wallet.pass.fill",
                colorName: SpendAccountColor.blue.rawValue,
                initialBalance: accountSummary.availableBalance,
                isPrimary: true
            )
            modelContext.insert(primaryAccount)
            transactions.forEach { $0.accountID = primaryAccount.id }
            paymentHistory.forEach { $0.accountID = primaryAccount.id }
            try? modelContext.save()
            return
        }

        let primaryAccounts = spendAccounts.filter(\.isPrimary)
        if primaryAccounts.isEmpty, let firstAccount = spendAccounts.first {
            firstAccount.isPrimary = true
            didChangeAccounts = true
        } else if let firstPrimary = primaryAccounts.first {
            spendAccounts
                .filter { $0.id != firstPrimary.id && $0.isPrimary }
                .forEach {
                    $0.isPrimary = false
                    didChangeAccounts = true
                }
        }

        guard let primaryAccount = spendAccounts.first(where: \.isPrimary) ?? spendAccounts.first else { return }
        let accountIDs = Set(spendAccounts.map(\.id))
        transactions
            .filter { $0.accountID.map { !accountIDs.contains($0) } ?? true }
            .forEach {
                $0.accountID = primaryAccount.id
                didChangeAccounts = true
            }
        paymentHistory
            .filter { $0.accountID.map { !accountIDs.contains($0) } ?? true }
            .forEach {
                $0.accountID = primaryAccount.id
                didChangeAccounts = true
            }

        if didChangeAccounts {
            try? modelContext.save()
        }
    }

    private func autoMarkDueRecurringExpensesAsPaid(now: Date = Date()) {
        let transactionSnapshot = Array(transactions)
        let paymentSnapshot = Array(payments)
        let exclusionSnapshot = Array(exclusions)
        let snapshotCalculator = MoneyCalculationService(
            transactions: transactionSnapshot,
            payments: paymentSnapshot,
            exclusions: exclusionSnapshot
        )
        guard let firstMonth = transactionSnapshot.map(\.monthStart.monthStart).min() else { return }
        let currentMonth = now.monthStart
        let todayDay = Calendar.current.component(.day, from: now)
        var paymentsToCreate: [(transaction: MoneyTransaction, month: Date, occurrenceDay: Int?, amount: Double, paidAt: Date)] = []

        months(from: firstMonth, through: currentMonth).forEach { month in
            let maxDay = Calendar.current.isDate(month, equalTo: currentMonth, toGranularity: .month)
                ? todayDay
                : month.daysInMonth

            transactionSnapshot
                .visible(in: month, payments: paymentSnapshot, exclusions: exclusionSnapshot)
                .filter { transaction in
                    transaction.kind == TransactionKind.expense.rawValue
                        && transaction.isRecurring
                        && transaction.autoMarkPaidOnDay
                        && !transaction.isWholeMonthExpense
                }
                .forEach { transaction in
                    if transaction.recurrence == .weekly {
                        transaction
                            .occurrenceDays(in: month, exclusions: exclusionSnapshot)
                            .filter { occurrenceDay in
                                occurrenceDay <= maxDay
                                    && snapshotCalculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay) < transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                            }
                            .forEach { occurrenceDay in
                                let scheduledAmount = transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
                                let remainingAmount = max(scheduledAmount - snapshotCalculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay), 0)
                                guard remainingAmount > 0 else { return }
                                paymentsToCreate.append((
                                    transaction: transaction,
                                    month: month,
                                    occurrenceDay: occurrenceDay,
                                    amount: remainingAmount,
                                    paidAt: month.date(day: occurrenceDay)
                                ))
                            }
                    } else {
                        let dueDay = transaction.effectiveDay(in: month)
                        guard dueDay <= maxDay && !snapshotCalculator.isPaid(transaction, in: month) else { return }
                        let scheduledAmount = transaction.scheduledAmount(in: month)
                        let remainingAmount = max(scheduledAmount - snapshotCalculator.paidAmount(for: transaction, in: month), 0)
                        guard remainingAmount > 0 else { return }
                        paymentsToCreate.append((
                            transaction: transaction,
                            month: month,
                            occurrenceDay: nil,
                            amount: remainingAmount,
                            paidAt: month.date(day: dueDay)
                        ))
                    }
                }
            }

        paymentsToCreate.forEach { payment in
            addPaymentAmount(
                payment.transaction,
                in: payment.month,
                occurrenceDay: payment.occurrenceDay,
                amount: payment.amount,
                paidAt: payment.paidAt
            )
        }
    }

    private func loadStoredCurrentAccountFilters() {
        guard !didLoadStoredFilters else { return }
        didLoadStoredFilters = true

        paymentFilter = CurrentAccountPaymentFilter(rawValue: storedPaymentFilter) ?? .all
        filteredCategories = Set(storedFilteredCategories
            .split(separator: ",")
            .compactMap { ExpenseCategory(rawValue: String($0)) })
        filteredExpenseType = storedFilteredExpenseType
        freeTextFilter = storedFreeTextFilter
    }

    private func persistCurrentAccountFilters() {
        storedPaymentFilter = paymentFilter.rawValue
        storedFilteredCategories = filteredCategories
            .map(\.rawValue)
            .sorted()
            .joined(separator: ",")
        storedFilteredExpenseType = filteredExpenseType
        storedFreeTextFilter = freeTextFilter
    }

    private func refreshExpensePaymentNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let existingReminderIDs = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix("spendwise-expense-due-") }
        center.removePendingNotificationRequests(withIdentifiers: existingReminderIDs)

        guard notificationsEnabled else { return }

        let reminders = upcomingExpensePaymentReminders()
        guard !reminders.isEmpty else { return }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        case .notDetermined:
            do {
                let isAllowed = try await center.requestAuthorization(options: [.alert, .sound])
                guard isAllowed else { return }
            } catch {
                return
            }
        case .denied:
            return
        @unknown default:
            return
        }

        for reminder in reminders.prefix(60) {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func upcomingExpensePaymentReminders() -> [ExpensePaymentReminder] {
        let now = Date()
        let calendar = Calendar.current
        let months = (0...4).compactMap { calendar.date(byAdding: .month, value: $0, to: currentMonth) }

        return months
            .flatMap { month in
                transactions
                    .visible(in: month, payments: payments, exclusions: exclusions)
                    .filter { transaction in
                        transaction.kind == TransactionKind.expense.rawValue && !isPaid(transaction, in: month)
                    }
                    .compactMap { reminder(for: $0, in: month, now: now) }
            }
            .filter { $0.fireDate > now }
            .sorted { $0.fireDate < $1.fireDate }
    }

    private func reminder(for transaction: MoneyTransaction, in month: Date, now: Date) -> ExpensePaymentReminder? {
        guard !transaction.isWholeMonthExpense else { return nil }

        let calendar = Calendar.current
        let dueDay = transaction.effectiveDay(in: month)
        guard let dueDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: month.date(day: dueDay)) else {
            return nil
        }
        guard let reminderDay = calendar.date(byAdding: .day, value: -1, to: dueDate) else {
            return nil
        }

        var fireDate = reminderDay
        if fireDate <= now, calendar.isDate(fireDate, inSameDayAs: now), dueDate > now {
            fireDate = now.addingTimeInterval(60)
        }

        guard fireDate > now else { return nil }

        let freeText = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let type = transaction.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryText = freeText.isEmpty ? type : freeText
        let body: String
        if freeText.isEmpty || type.isEmpty || freeText == type {
            body = String(format: AppStrings.text(.expenseDueTomorrowBody), primaryText, dueDay)
        } else {
            body = String(format: AppStrings.text(.expenseDueTomorrowBodyWithType), primaryText, dueDay, type)
        }

        let identifier = "spendwise-expense-due-\(transaction.id.uuidString)-\(month.notificationIdentifierDate)"
        return ExpensePaymentReminder(
            identifier: identifier,
            title: AppStrings.text(.expenseDueTomorrowTitle),
            body: body,
            fireDate: fireDate
        )
    }

    private func checkOverdueExpenses() {
        guard launchPaymentReminderEnabled else { return }
        guard !didCheckOverdueExpenses else { return }
        didCheckOverdueExpenses = true

        let todayDay = Calendar.current.component(.day, from: Date())
        let currentOverdueExpenses = unpaidExpenses(in: currentMonth, fromDay: 1, throughDay: todayDay - 1)
        let todayUnpaidExpenses = unpaidExpenses(in: currentMonth, fromDay: todayDay, throughDay: todayDay)
        var sections: [String] = []

        previousMonthsWithUnpaidExpenses().forEach { month, expenses in
            sections.append(expenseNoticeSection(
                prefix: "\(AppStrings.text(.pastMonthsUnpaidExpensesMessagePrefix)) \(month.monthTitle)",
                expenses: expenses
            ))
        }

        if !currentOverdueExpenses.isEmpty {
            sections.append(expenseNoticeSection(
                prefix: AppStrings.text(.overdueExpensesMessagePrefix),
                expenses: currentOverdueExpenses
            ))
        }

        if !todayUnpaidExpenses.isEmpty {
            sections.append(expenseNoticeSection(
                prefix: AppStrings.text(.dueTodayExpensesMessagePrefix),
                expenses: todayUnpaidExpenses
            ))
        }

        guard !sections.isEmpty else { return }

        expenseNotice = ExpenseNotice(
            title: AppStrings.text(.overdueExpensesTitle),
            message: sections.joined(separator: "\n\n")
        )
    }

    private func previousMonthsWithUnpaidExpenses() -> [(month: Date, expenses: [ExpenseNoticeItem])] {
        guard let firstMonth = transactions.map(\.monthStart.monthStart).min(),
              let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth),
              firstMonth <= previousMonth
        else { return [] }

        return months(from: firstMonth, through: previousMonth)
            .compactMap { month in
                let expenses = unpaidExpenses(in: month, throughDay: month.daysInMonth)
                return expenses.isEmpty ? nil : (month, expenses)
            }
    }

    private func unpaidExpenses(in month: Date, throughDay maxDay: Int) -> [ExpenseNoticeItem] {
        unpaidExpenses(in: month, fromDay: 1, throughDay: maxDay)
    }

    private func unpaidExpenses(in month: Date, fromDay minDay: Int, throughDay maxDay: Int) -> [ExpenseNoticeItem] {
        guard minDay <= maxDay else { return [] }

        return transactions
            .visible(in: month, payments: payments, exclusions: exclusions)
            .filter { $0.kind == TransactionKind.expense.rawValue && !$0.isWholeMonthExpense }
            .flatMap { transaction -> [ExpenseNoticeItem] in
                if transaction.recurrence == .weekly {
                    return transaction
                        .occurrenceDays(in: month, exclusions: exclusions)
                        .filter { day in
                            day >= minDay
                                && day <= maxDay
                                && !isPaid(transaction, in: month, occurrenceDay: day)
                        }
                        .map { ExpenseNoticeItem(transaction: transaction, month: month, occurrenceDay: $0) }
                }

                let day = transaction.effectiveDay(in: month)
                guard day >= minDay && day <= maxDay && !isPaid(transaction, in: month) else { return [] }
                return [ExpenseNoticeItem(transaction: transaction, month: month, occurrenceDay: nil)]
            }
            .sorted { first, second in
                if first.day != second.day { return first.day < second.day }
                return first.transaction.displayName < second.transaction.displayName
            }
    }

    private func expenseNoticeSection(prefix: String, expenses: [ExpenseNoticeItem]) -> String {
        let lines = expenses.map { item in
            let scheduledAmount = item.transaction.scheduledAmount(in: item.month, occurrenceDay: item.occurrenceDay)
            let remainingAmount = max(scheduledAmount - paidAmount(for: item.transaction, in: item.month, occurrenceDay: item.occurrenceDay), 0)
            return "\(item.transaction.displayName) - \(AppStrings.text(.day)) \(item.day) - falta \(remainingAmount.currencyText)"
        }

        return ([prefix] + lines).joined(separator: "\n")
    }

    private func months(from startMonth: Date, through endMonth: Date) -> [Date] {
        MoneyCalculationService.months(from: startMonth, through: endMonth)
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date) -> Bool {
        calculator.isPaid(transaction, in: month)
    }

    private func isPaid(_ transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Bool {
        paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay) >= transaction.scheduledAmount(in: month, occurrenceDay: occurrenceDay)
    }

    private func paidAmount(for transaction: MoneyTransaction, in month: Date) -> Double {
        calculator.paidAmount(for: transaction, in: month)
    }

    private func paidAmount(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Double {
        calculator.paidAmount(for: transaction, in: month, occurrenceDay: occurrenceDay)
    }

    private func paymentHistoryEntries(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) -> [PaymentHistoryEntry] {
        paymentHistory
            .filter { paymentHistoryEntry($0, matches: transaction, in: month, occurrenceDay: occurrenceDay) }
            .sorted { $0.paidAt > $1.paidAt }
    }

    private func hasPaymentHistory(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) -> Bool {
        paymentHistory.contains {
            paymentHistoryEntry($0, matches: transaction, in: month, occurrenceDay: occurrenceDay)
        }
    }

    private func addPaymentAmount(_ transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil, amount: Double, note: String? = nil, accountID selectedAccountID: UUID? = nil, paidAt: Date = Date()) {
        let paymentAmount = max(amount, 0)
        guard paymentAmount > 0 else { return }

        let monthStart = month.monthStart
        let normalizedOccurrenceDay = normalizedPaymentOccurrenceDay(for: transaction, occurrenceDay: occurrenceDay)
        let scheduledAmount = transaction.scheduledAmount(in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let matchingPayments = paymentRecords(for: transaction, in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let currentPaid = matchingPayments.reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
        let newPaidAmount = min(currentPaid + paymentAmount, scheduledAmount)

        if let existingPayment = matchingPayments.first {
            existingPayment.amountPaid = newPaidAmount
            existingPayment.occurrenceDay = normalizedOccurrenceDay
            matchingPayments.dropFirst().forEach { modelContext.delete($0) }
        } else {
            modelContext.insert(ExpensePayment(transactionID: transaction.id, monthStart: monthStart, amountPaid: newPaidAmount, occurrenceDay: normalizedOccurrenceDay))
        }

        let accountID = selectedAccountID ?? transaction.accountID ?? primarySpendAccount?.id
        transaction.accountID = accountID
        let historyEntry = PaymentHistoryEntry(
            transactionID: transaction.id,
            monthStart: monthStart,
            occurrenceDay: normalizedOccurrenceDay,
            amount: paymentAmount,
            paidAt: paidAt,
            note: note,
            accountID: accountID
        )
        modelContext.insert(historyEntry)
        if let accountID {
            modelContext.insert(AccountMovement(
                accountID: accountID,
                transactionID: transaction.id,
                paymentHistoryID: historyEntry.id,
                date: paidAt,
                type: AccountMovementKind.expensePayment.rawValue,
                amount: -paymentAmount,
                note: note ?? transaction.displayName
            ))
        }
        let accountName = accountID.flatMap { id in spendAccounts.first(where: { $0.id == id })?.displayName }
        insertAuditLog(
            action: .expensePaymentCreated,
            title: transaction.displayName,
            details: accountName.map { "Conta: \($0)" } ?? "",
            note: note ?? "",
            amount: -paymentAmount,
            balanceAfter: auditBalanceAfter(delta: -paymentAmount),
            accountID: accountID,
            transactionID: transaction.id,
            paymentHistoryID: historyEntry.id,
            date: paidAt
        )
        syncLinkedCreditPayment(for: transaction, in: month, paidAmount: newPaidAmount)
        syncLinkedSavingDeposit(for: transaction, in: month, paidAmount: newPaidAmount)
    }

    private func deletePaymentHistoryEntry(_ entry: PaymentHistoryEntry, for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) {
        guard entry.transactionID == transaction.id else { return }

        let monthStart = month.monthStart
        guard Calendar.current.isDate(entry.monthStart, equalTo: monthStart, toGranularity: .month) else { return }
        let normalizedOccurrenceDay = normalizedPaymentOccurrenceDay(for: transaction, occurrenceDay: occurrenceDay)
        if transaction.recurrence == .weekly {
            guard entry.occurrenceDay == normalizedOccurrenceDay else { return }
        }

        let matchingPayments = paymentRecords(for: transaction, in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let scheduledAmount = transaction.scheduledAmount(in: monthStart, occurrenceDay: normalizedOccurrenceDay)
        let currentPaidAmount = matchingPayments.reduce(0) { $0 + ($1.amountPaid ?? scheduledAmount) }
        let newPaidAmount = max(currentPaidAmount - entry.amount, 0)
        let accountName = entry.accountID.flatMap { id in spendAccounts.first(where: { $0.id == id })?.displayName }

        accountMovements
            .filter { $0.paymentHistoryID == entry.id }
            .forEach(modelContext.delete)
        modelContext.delete(entry)
        insertAuditLog(
            action: .expensePaymentDeleted,
            title: transaction.displayName,
            details: accountName.map { "Conta: \($0)" } ?? "",
            note: entry.note ?? "",
            amount: entry.amount,
            balanceAfter: auditBalanceAfter(delta: entry.amount),
            accountID: entry.accountID,
            transactionID: transaction.id,
            paymentHistoryID: entry.id
        )

        if let existingPayment = matchingPayments.first {
            if newPaidAmount <= 0 {
                matchingPayments.forEach { modelContext.delete($0) }
            } else {
                existingPayment.amountPaid = newPaidAmount
                existingPayment.occurrenceDay = normalizedOccurrenceDay
                matchingPayments.dropFirst().forEach { modelContext.delete($0) }
            }
        }

        syncLinkedCreditPayment(for: transaction, in: monthStart, paidAmount: newPaidAmount)
        syncLinkedSavingDeposit(for: transaction, in: monthStart, paidAmount: newPaidAmount)
    }

    private func normalizedPaymentOccurrenceDay(for transaction: MoneyTransaction, occurrenceDay: Int?) -> Int? {
        transaction.recurrence == .weekly ? occurrenceDay : nil
    }

    private func paymentRecords(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> [ExpensePayment] {
        payments.filter { payment in
            payment.transactionID == transaction.id
                && Calendar.current.isDate(payment.monthStart, equalTo: month.monthStart, toGranularity: .month)
                && (transaction.recurrence != .weekly || payment.occurrenceDay == occurrenceDay)
        }
    }

    private func paymentHistoryEntry(_ entry: PaymentHistoryEntry, matches transaction: MoneyTransaction, in month: Date, occurrenceDay: Int?) -> Bool {
        entry.transactionID == transaction.id
            && Calendar.current.isDate(entry.monthStart, equalTo: month.monthStart, toGranularity: .month)
            && (transaction.recurrence != .weekly || entry.occurrenceDay == occurrenceDay)
    }

    private func syncLinkedCreditPayment(for transaction: MoneyTransaction, in month: Date, paidAmount: Double) {
        guard let linkedCreditID = transaction.linkedCreditID else { return }

        if paidAmount <= 0 {
            if let linkedCreditMovementID = transaction.linkedCreditMovementID,
               let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
                modelContext.delete(movement)
            }
            transaction.linkedCreditMovementID = nil
            return
        }

        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let linkedCreditMovementID = transaction.linkedCreditMovementID,
           let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
            movement.creditID = linkedCreditID
            movement.date = month.date(day: transaction.effectiveDay(in: month))
            movement.type = CreditMovementKind.payment.rawValue
            movement.amount = paidAmount
            movement.note = note
        } else {
            let movement = CreditMovement(
                creditID: linkedCreditID,
                date: month.date(day: transaction.effectiveDay(in: month)),
                type: CreditMovementKind.payment.rawValue,
                amount: paidAmount,
                note: note
            )
            modelContext.insert(movement)
            transaction.linkedCreditMovementID = movement.id
        }
    }

    private func syncLinkedSavingDeposit(for transaction: MoneyTransaction, in month: Date, paidAmount: Double) {
        guard let linkedSavingID = transaction.linkedSavingID else { return }

        if paidAmount <= 0 {
            if let linkedSavingMovementID = transaction.linkedSavingMovementID,
               let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
                modelContext.delete(movement)
            }
            transaction.linkedSavingMovementID = nil
            return
        }

        let note = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? transaction.displayName
            : transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let linkedSavingMovementID = transaction.linkedSavingMovementID,
           let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
            movement.savingID = linkedSavingID
            movement.date = month.date(day: transaction.effectiveDay(in: month))
            movement.type = SavingMovementKind.deposit.rawValue
            movement.amount = paidAmount
            movement.note = note
        } else {
            let movement = SavingMovement(
                savingID: linkedSavingID,
                date: month.date(day: transaction.effectiveDay(in: month)),
                type: SavingMovementKind.deposit.rawValue,
                amount: paidAmount,
                note: note
            )
            modelContext.insert(movement)
            transaction.linkedSavingMovementID = movement.id
        }
    }

    private func deleteTransaction(_ transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) {
        if transaction.isRecurring {
            let normalizedOccurrenceDay = transaction.recurrence == .weekly ? occurrenceDay : nil
            let matchingHistoryEntries = paymentHistory.filter {
                $0.matches(transactionID: transaction.id, month: month, occurrenceDay: normalizedOccurrenceDay)
            }
            let removedMovements = accountMovements.filter { movement in
                guard movement.transactionID == transaction.id else { return false }

                if movement.kind == .income {
                    return Calendar.current.isDate(movement.date, equalTo: month.monthStart, toGranularity: .month)
                }

                guard let paymentHistoryID = movement.paymentHistoryID else { return false }
                return matchingHistoryEntries.contains { $0.id == paymentHistoryID }
            }
            let returnedBalance = -removedMovements.reduce(0) { $0 + $1.amount }
            insertAuditLog(
                action: transaction.kind == TransactionKind.income.rawValue ? .incomeDeleted : .expenseDeleted,
                title: analyticsTransactionTitle(for: transaction),
                details: transaction.detailText(in: month.monthStart),
                amount: returnedBalance,
                balanceAfter: auditBalanceAfter(delta: returnedBalance),
                accountID: transaction.accountID,
                transactionID: transaction.id
            )
            accountMovements
                .filter { movement in
                    guard movement.transactionID == transaction.id else { return false }

                    if movement.kind == .income {
                        return Calendar.current.isDate(movement.date, equalTo: month.monthStart, toGranularity: .month)
                    }

                    guard let paymentHistoryID = movement.paymentHistoryID else { return false }
                    return matchingHistoryEntries.contains { $0.id == paymentHistoryID }
                }
                .forEach(modelContext.delete)
            addExclusion(for: transaction, in: month, occurrenceDay: transaction.recurrence == .weekly ? occurrenceDay : nil)
            payments
                .filter { $0.matches(transactionID: transaction.id, month: month, occurrenceDay: transaction.recurrence == .weekly ? occurrenceDay : nil) }
                .forEach(modelContext.delete)
            matchingHistoryEntries.forEach(modelContext.delete)
        } else {
            let removedMovements = accountMovements.filter { $0.transactionID == transaction.id }
            let returnedBalance = -removedMovements.reduce(0) { $0 + $1.amount }
            insertAuditLog(
                action: transaction.kind == TransactionKind.income.rawValue ? .incomeDeleted : .expenseDeleted,
                title: analyticsTransactionTitle(for: transaction),
                details: transaction.detailText(in: transaction.monthStart),
                amount: returnedBalance,
                balanceAfter: auditBalanceAfter(delta: returnedBalance),
                accountID: transaction.accountID,
                transactionID: transaction.id
            )
            if let linkedCreditMovementID = transaction.linkedCreditMovementID,
               let movement = creditMovements.first(where: { $0.id == linkedCreditMovementID }) {
                modelContext.delete(movement)
            }
            if let linkedSavingMovementID = transaction.linkedSavingMovementID,
               let movement = savingMovements.first(where: { $0.id == linkedSavingMovementID }) {
                modelContext.delete(movement)
            }
            payments
                .filter { $0.transactionID == transaction.id }
                .forEach(modelContext.delete)
            paymentHistory
                .filter { $0.transactionID == transaction.id }
                .forEach(modelContext.delete)
            accountMovements
                .filter { $0.transactionID == transaction.id }
                .forEach(modelContext.delete)
            modelContext.delete(transaction)
        }
    }

    private func addExclusion(for transaction: MoneyTransaction, in month: Date, occurrenceDay: Int? = nil) {
        guard !exclusions.contains(where: { $0.matches(transactionID: transaction.id, month: month, occurrenceDay: occurrenceDay) }) else {
            return
        }

        modelContext.insert(RecurrenceExclusion(transactionID: transaction.id, monthStart: month.monthStart, occurrenceDay: occurrenceDay))
    }
}

private struct SavingsHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let month: Date
    let lines: [SavingsHistoryLine]
    let total: Double

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(month.monthTitle)
                            .font(.title2.bold())
                            .foregroundStyle(AppPalette.background)
                        Text(total.currencyText)
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppPalette.savings)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(lines) { line in
                            HStack(spacing: 12) {
                                Image(systemName: line.icon)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppPalette.savings)
                                    .frame(width: 30, height: 30)
                                    .background(AppPalette.savings.opacity(0.14), in: Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(line.title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppPalette.background)
                                        .lineLimit(2)
                                    Text(line.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AppPalette.mutedText)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 8)

                                Text(line.amount.currencyText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppPalette.savings)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .padding(10)
                            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .background(AppPalette.appBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.text(.savingsHistoryTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                        .liquidGlassButtonStyle()
                }
            }
        }
    }
}

private struct CurrentAccountFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var paymentFilter: CurrentAccountPaymentFilter
    @Binding var filteredCategories: Set<ExpenseCategory>
    @Binding var filteredExpenseType: String
    @Binding var freeTextFilter: String

    let expenseTypeOptions: [ExpenseTypePoint]
    let onClear: () -> Void

    private var visibleExpenseTypeOptions: [ExpenseTypePoint] {
        expenseTypeOptions.filter { option in
            filteredCategories.isEmpty || filteredCategories.contains(option.category)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.text(.paymentStatus)) {
                    Picker(AppStrings.text(.paymentStatus), selection: $paymentFilter) {
                        ForEach(CurrentAccountPaymentFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.categories)) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Toggle(category.title, isOn: Binding(
                            get: { filteredCategories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    filteredCategories.insert(category)
                                } else {
                                    filteredCategories.remove(category)
                                }

                                let visibleTypes = visibleExpenseTypeOptions.map(\.title)
                                if !filteredExpenseType.isEmpty && !visibleTypes.contains(filteredExpenseType) {
                                    filteredExpenseType = ""
                                }
                            }
                        ))
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.expenseTypeFilter)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            expenseTypeFilterButton(
                                title: AppStrings.text(.all),
                                systemImage: "square.grid.2x2.fill",
                                isSelected: filteredExpenseType.isEmpty
                            ) {
                                filteredExpenseType = ""
                            }

                            ForEach(visibleExpenseTypeOptions) { option in
                                expenseTypeFilterButton(
                                    title: option.title,
                                    systemImage: ExpenseTypeIcon.name(for: option.title),
                                    isSelected: filteredExpenseType == option.title
                                ) {
                                    filteredExpenseType = option.title
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(AppPalette.surface)

                Section(AppStrings.text(.freeTextFilter)) {
                    TextField(AppStrings.text(.searchPlaceholder), text: $freeTextFilter)
                        .textInputAutocapitalization(.never)
                }
                .listRowBackground(AppPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.appBackground)
            .foregroundStyle(AppPalette.background)
            .tint(AppPalette.background)
            .navigationTitle(AppStrings.text(.filters))
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.text(.clearFilters), action: onClear)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
    }

    private func expenseTypeFilterButton(title: String, systemImage: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.mutedText)
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(.caption2.weight(isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? AppPalette.background : AppPalette.mutedText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 82)
                    .frame(minHeight: 28)
            }
            .frame(width: 92)
            .frame(minHeight: 78)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

private struct UnpaidExpenseLine: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let day: Int
    let scheduledAmount: Double
    let paidAmount: Double
    let remainingAmount: Double
    let isWeekly: Bool
}

private struct UnpaidExpensesBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss

    let month: Date
    let lines: [UnpaidExpenseLine]
    let total: Double

    var body: some View {
        NavigationStack {
            Group {
                if lines.isEmpty {
                    ContentUnavailableView(
                        "Sem despesas por pagar",
                        systemImage: "checkmark.circle",
                        description: Text("Não há registos individuais a formar este valor.")
                    )
                    .foregroundStyle(AppPalette.background)
                } else {
                    List {
                        Section {
                            ForEach(lines) { line in
                                unpaidExpenseRow(line)
                            }
                        } footer: {
                            Text("Total detalhado: \(total.currencyText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.background)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(AppPalette.appBackground)
                }
            }
            .background(AppPalette.appBackground)
            .navigationTitle("Por pagar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func unpaidExpenseRow(_ line: UnpaidExpenseLine) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(line.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(2)

                    Text(line.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                }

                Spacer(minLength: 8)

                Text(line.remainingAmount.currencyText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.primary)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                unpaidAmountChip(title: "Previsto", value: line.scheduledAmount)
                unpaidAmountChip(title: "Pago", value: line.paidAmount)
                if line.isWeekly {
                    Text(AppStrings.text(.weeklyRecurrence))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(AppPalette.separator.opacity(0.65), in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(AppPalette.surface)
    }

    private func unpaidAmountChip(title: String, value: Double) -> some View {
        Text("\(title): \(value.currencyText)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppPalette.mutedText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AppPalette.separator.opacity(0.65), in: Capsule())
    }
}

private struct SidebarSummaryRow: View {
    let title: String
    let value: Double
    let indicatorColor: Color
    let helpText: String
    var boldHelpNote = ""
    var footnote = ""
    var helpTitle: String? = nil
    var onTap: (() -> Void)? = nil

    @State private var showsHelp = false

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if !footnote.isEmpty {
                    Text(footnote)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Spacer(minLength: 6)

            Text(value.currencyText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(value < 0 ? AppPalette.primary : AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()

            Button {
                showsHelp = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showsHelp, attachmentAnchor: .point(.center), arrowEdge: .leading) {
                InformationBubble(
                    title: helpTitle ?? title,
                    message: helpText,
                    boldNote: boldHelpNote,
                    footnote: footnote
                )
            }
        }
        .frame(minHeight: footnote.isEmpty ? 26 : 36)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

private extension Array where Element == String {
    func uniquedSorted() -> [String] {
        Array(Set(self)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}

private extension View {
    @ViewBuilder
    func backgroundExtensionEffectIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.backgroundExtensionEffect()
        } else {
            self
        }
    }

    @ViewBuilder
    func minimizeTabBarOnScrollDownIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MoneyTransaction.self, ExpensePayment.self, RecurrenceExclusion.self, SavingAccount.self, SavingMovement.self], inMemory: true)
}
