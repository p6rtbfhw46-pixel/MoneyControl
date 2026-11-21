import SwiftUI

struct AnalyticsBudgetRuleComparison: View {
    let actualPoints: [CategoryExpensePoint]
    let referencePoints: [CategoryExpensePoint]
    let actualTotal: Double

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AnalyticsCategoryDistributionColumn(
                title: AppStrings.text(.actualExpenses),
                points: actualPoints,
                total: actualTotal
            )

            AnalyticsCategoryDistributionColumn(
                title: AppStrings.text(.reference503020),
                points: referencePoints,
                total: 100
            )
        }
    }
}

struct AnalyticsCategoryDistributionColumn: View {
    let title: String
    let points: [CategoryExpensePoint]
    let total: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(AppPalette.background)

            if total > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points) { point in
                        AnalyticsDistributionBar(
                            title: shortTitle(point.category),
                            amount: point.amount,
                            total: total,
                            tint: point.category.color
                        )
                    }
                }
            } else {
                ContentUnavailableView(
                    AppStrings.text(.noTransactions),
                    systemImage: "chart.pie"
                )
                .foregroundStyle(AppPalette.background)
                .frame(height: 150)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func shortTitle(_ category: ExpenseCategory) -> String {
        switch category {
        case .needs: "50"
        case .wants: "30"
        case .savingsAndDebt: "20"
        }
    }
}

struct AnalyticsExpenseTypeBreakdown: View {
    let points: [ExpenseTypePoint]
    let total: Double
    let onSelect: (ExpenseTypePoint) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if total > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(points) { point in
                        Button {
                            onSelect(point)
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(spacing: 10) {
                                    Image(systemName: ExpenseTypeIcon.name(for: point.title))
                                        .font(.caption.bold())
                                        .foregroundStyle(point.category.color)
                                        .frame(width: 28, height: 28)
                                        .background(
                                            point.category.color.opacity(0.14),
                                            in: Circle()
                                        )

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
                                        Text(distributionPercentageText(point.amount, total: total))
                                            .font(.caption.bold())
                                            .foregroundStyle(AppPalette.background)

                                        Text(point.amount.currencyText)
                                            .font(.caption2)
                                            .foregroundStyle(AppPalette.mutedText)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                        .foregroundStyle(AppPalette.mutedText)
                                }

                                AnalyticsDistributionBarFill(
                                    amount: point.amount,
                                    total: total,
                                    tint: point.category.color
                                )
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                ContentUnavailableView(
                    AppStrings.text(.noTransactions),
                    systemImage: "chart.pie"
                )
                .foregroundStyle(AppPalette.background)
                .frame(height: 180)
            }
        }
    }
}

private struct AnalyticsDistributionBar: View {
    let title: String
    let amount: Double
    let total: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 24, alignment: .leading)

                Text(distributionPercentageText(amount, total: total))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.mutedText)

                Spacer(minLength: 4)

                Text(amount.currencyText)
                    .font(.caption2.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            AnalyticsDistributionBarFill(
                amount: amount,
                total: total,
                tint: tint
            )
        }
    }
}

private struct AnalyticsDistributionBarFill: View {
    let amount: Double
    let total: Double
    let tint: Color

    var body: some View {
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
}

private func distributionPercentageText(_ amount: Double, total: Double) -> String {
    guard total > 0 else { return "0%" }
    return (amount / total).formatted(
        .percent.precision(.fractionLength(0))
    )
}
