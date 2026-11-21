import Foundation
import SwiftUI

enum AnalyticsExpenseTab {
    case whereSpent
    case budgetRule
}

enum AnalyticsPeriod {
    case month
    case year
}

enum LightweightEvolutionKind: String, CaseIterable, Identifiable {
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

struct LightweightEvolutionPoint: Identifiable {
    let month: Date
    let value: Double
    let markerTitle: String?
    let markerIcon: String?
    let markerTint: Color?

    var id: Date { month }
    var label: String { month.formatted(.dateTime.month(.abbreviated)) }
}

struct LightweightEvolutionTable {
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

enum AnalyticsHistoryFilterMode: String, CaseIterable, Identifiable {
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

enum AnalyticsSidebarTab: CaseIterable, Identifiable {
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

enum AnalyticsSavingsCreditsFilter {
    case all
    case savings
    case credits
}

enum AnnualAllocationSimulationKind: String, Identifiable {
    case savings
    case credits

    var id: String { rawValue }
}

struct AnnualAllocationSimulationRow: Identifiable {
    let id: String
    let name: String
    let startingValue: Double
    let plannedRecurringPaymentValue: Double
    let allocatedValue: Double
    let projectedValue: Double
}

struct AnalyticsExpenseDetailRequest: Identifiable {
    let title: String
    let category: ExpenseCategory
    let months: [Date]
    let amount: Double
    let total: Double

    var id: String {
        let period = months.map(\.notificationIdentifierDate).joined(separator: "-")
        return "\(category.rawValue)-\(title)-\(period)"
    }
}

struct AnalyticsExpenseDetailLine: Identifiable {
    let id: String
    let name: String
    let date: Date
    let amount: Double
    let icon: String
    let tint: Color
}

struct AnalyticsExpenseDetailMonthSection: Identifiable {
    let month: Date
    let lines: [AnalyticsExpenseDetailLine]

    var id: Date { month.monthStart }
    var total: Double { lines.reduce(0) { $0 + $1.amount } }
}

struct AnalyticsExpenseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let request: AnalyticsExpenseDetailRequest
    let lines: [AnalyticsExpenseDetailLine]

    private var monthSections: [AnalyticsExpenseDetailMonthSection] {
        Dictionary(grouping: lines) { $0.date.monthStart }
            .map { month, lines in
                AnalyticsExpenseDetailMonthSection(
                    month: month,
                    lines: lines.sorted { first, second in
                        if first.date != second.date { return first.date < second.date }
                        return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                    }
                )
            }
            .sorted { $0.month < $1.month }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10, pinnedViews: request.months.count > 1 ? [.sectionHeaders] : []) {
                    AnalyticsExpenseDetailHeader(request: request)
                        .padding(.bottom, 4)

                    if request.months.count > 1 {
                        ForEach(monthSections) { section in
                            Section {
                                ForEach(section.lines) { line in
                                    AnalyticsExpenseDetailRow(line: line)
                                }
                            } header: {
                                AnalyticsExpenseDetailMonthHeader(section: section)
                            }
                        }
                    } else {
                        ForEach(lines) { line in
                            AnalyticsExpenseDetailRow(line: line)
                        }
                    }
                }
                .padding()
            }
            .background(AppPalette.appBackground)
            .navigationTitle(request.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.ok)) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct AnalyticsExpenseDetailMonthHeader: View {
    let section: AnalyticsExpenseDetailMonthSection

    var body: some View {
        HStack(spacing: 12) {
            Text(section.month.monthTitle)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            Spacer(minLength: 8)

            Text(section.total.currencyText)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppPalette.appBackground)
    }
}

struct AnalyticsExpenseDetailHeader: View {
    let request: AnalyticsExpenseDetailRequest

    private var ratio: Double {
        guard request.total > 0 else { return 0 }
        let value = request.amount / request.total
        return min(max(value.isFinite ? value : 0, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                Image(systemName: ExpenseTypeIcon.name(for: request.title))
                    .font(.caption.bold())
                    .foregroundStyle(request.category.color)
                    .frame(width: 28, height: 28)
                    .background(request.category.color.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(request.title)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(2)

                    Text(request.category.title)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.mutedText)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ratio.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)

                    Text(request.amount.currencyText)
                        .font(.caption2)
                        .foregroundStyle(AppPalette.mutedText)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppPalette.separator.opacity(0.65))

                    Capsule()
                        .fill(request.category.color)
                        .frame(width: max(proxy.size.width, 0) * ratio)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AnalyticsPeriodPicker: View {
    @Binding var selection: AnalyticsPeriod

    @State private var isSwitching = false
    @State private var switchRequestID = UUID()

    var body: some View {
        Picker("", selection: periodSelection) {
            Text(AppStrings.text(.month)).tag(AnalyticsPeriod.month)
            Text(AppStrings.text(.year)).tag(AnalyticsPeriod.year)
        }
        .pickerStyle(.segmented)
        .disabled(isSwitching)
        .tint(AppPalette.background)
        .fullScreenCover(isPresented: $isSwitching) {
            ZStack {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()

                HStack(spacing: 10) {
                    ProgressView()
                    Text(AppStrings.text(.updatingAnalysis))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppPalette.background)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(AppPalette.surface, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            }
            .presentationBackground(.clear)
            .interactiveDismissDisabled()
        }
    }

    private var periodSelection: Binding<AnalyticsPeriod> {
        Binding(
            get: { selection },
            set: { newPeriod in
                guard newPeriod != selection else { return }

                let requestID = UUID()
                switchRequestID = requestID
                isSwitching = true

                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    guard switchRequestID == requestID else { return }

                    selection = newPeriod
                    await Task.yield()
                    try? await Task.sleep(for: .milliseconds(80))

                    guard switchRequestID == requestID else { return }
                    isSwitching = false
                }
            }
        )
    }
}

struct AnalyticsExpenseDetailRow: View {
    let line: AnalyticsExpenseDetailLine

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: line.icon)
                .font(.caption.bold())
                .foregroundStyle(line.tint)
                .frame(width: 34, height: 34)
                .background(line.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(line.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                Text(line.date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }

            Spacer(minLength: 8)

            Text(line.amount.currencyText)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.primary)
                .lineLimit(1)
        }
        .padding(12)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AnalyticsHistoryLine: Identifiable {
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

struct AnalyticsQuickSummaryCards: View {
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

struct AnalyticsQuickSummaryCardView: View {
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
