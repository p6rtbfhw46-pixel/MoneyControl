import SwiftUI

struct AnalyticsOverviewSection<SummaryContent: View>: View {
    let netWorthTotal: Double
    let netWorthVariationRatio: Double?
    let trendHelpMessage: String
    let currentAccountBalance: Double
    let savingsTotal: Double
    let creditDebtTotal: Double
    let usesWideLayout: Bool
    let onCurrentAccount: () -> Void
    let onSavings: () -> Void
    let onCredits: () -> Void
    let onSavingsCredits: () -> Void
    let onHistory: () -> Void
    let summaryContent: SummaryContent

    init(
        netWorthTotal: Double,
        netWorthVariationRatio: Double?,
        trendHelpMessage: String,
        currentAccountBalance: Double,
        savingsTotal: Double,
        creditDebtTotal: Double,
        usesWideLayout: Bool,
        onCurrentAccount: @escaping () -> Void,
        onSavings: @escaping () -> Void,
        onCredits: @escaping () -> Void,
        onSavingsCredits: @escaping () -> Void,
        onHistory: @escaping () -> Void,
        @ViewBuilder summaryContent: () -> SummaryContent
    ) {
        self.netWorthTotal = netWorthTotal
        self.netWorthVariationRatio = netWorthVariationRatio
        self.trendHelpMessage = trendHelpMessage
        self.currentAccountBalance = currentAccountBalance
        self.savingsTotal = savingsTotal
        self.creditDebtTotal = creditDebtTotal
        self.usesWideLayout = usesWideLayout
        self.onCurrentAccount = onCurrentAccount
        self.onSavings = onSavings
        self.onCredits = onCredits
        self.onSavingsCredits = onSavingsCredits
        self.onHistory = onHistory
        self.summaryContent = summaryContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AnalyticsNetWorthCard(
                total: netWorthTotal,
                variationRatio: netWorthVariationRatio,
                trendHelpMessage: trendHelpMessage,
                usesWideLayout: usesWideLayout
            )

            AnalyticsOverviewMetrics(
                currentAccountBalance: currentAccountBalance,
                savingsTotal: savingsTotal,
                creditDebtTotal: creditDebtTotal,
                usesWideLayout: usesWideLayout,
                onCurrentAccount: onCurrentAccount,
                onSavings: onSavings,
                onCredits: onCredits
            )

            AnalyticsQuickSummarySection(
                onSeeAll: onSavingsCredits,
                content: { summaryContent }
            )

            AnalyticsHistoryAccessCard(action: onHistory)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnalyticsOverviewMetrics: View {
    let currentAccountBalance: Double
    let savingsTotal: Double
    let creditDebtTotal: Double
    let usesWideLayout: Bool
    let onCurrentAccount: () -> Void
    let onSavings: () -> Void
    let onCredits: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            AnalyticsOverviewMetricRow(
                icon: "list.bullet.rectangle",
                title: AppStrings.text(.currentAccount),
                subtitle: AppStrings.text(.availableBalanceSummary),
                value: currentAccountBalance.currencyText,
                tint: AppPalette.background,
                usesWideLayout: usesWideLayout,
                action: onCurrentAccount
            )

            AnalyticsOverviewMetricRow(
                icon: "leaf.fill",
                title: SavingsStrings.text(.settingsTitle),
                subtitle: AppStrings.text(.totalSavedSummary),
                value: savingsTotal.currencyText,
                tint: AppPalette.savings,
                usesWideLayout: usesWideLayout,
                action: onSavings
            )

            AnalyticsOverviewMetricRow(
                icon: "creditcard",
                title: CreditStrings.text(.settingsTitle),
                subtitle: AppStrings.text(.totalDebtSummary),
                value: (-creditDebtTotal).currencyText,
                tint: AppPalette.primary,
                usesWideLayout: usesWideLayout,
                action: onCredits
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct AnalyticsNetWorthCard: View {
    let total: Double
    let variationRatio: Double?
    let trendHelpMessage: String
    let usesWideLayout: Bool

    var body: some View {
        GeometryReader { proxy in
            let safeWidth = max(proxy.size.width, 0)

            ZStack(alignment: .leading) {
                Image("NetWorthOverviewHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: safeWidth, height: cardHeight)
                    .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppStrings.text(.netWorthTitle))
                        .font((usesWideLayout ? Font.title2 : Font.title3).bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)

                    Text(AppStrings.text(.netWorthAccountsFormula))
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(total.currencyText)
                        .font(.system(
                            size: usesWideLayout ? 46 : 36,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(total < 0 ? AppPalette.primary : AppPalette.savings)
                        .lineLimit(1)
                        .minimumScaleFactor(0.48)
                        .frame(
                            maxWidth: usesWideLayout ? 360 : 230,
                            alignment: .leading
                        )
                        .padding(.top, 2)

                    if let variationRatio {
                        trendBadge(variationRatio)
                    }
                }
                .padding(usesWideLayout ? 28 : 22)
                .frame(
                    maxWidth: usesWideLayout ? 420 : 245,
                    alignment: .leading
                )
            }
            .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppPalette.background.opacity(0.08), radius: 16, y: 8)
        }
        .frame(height: cardHeight)
    }

    private var cardHeight: CGFloat {
        usesWideLayout ? 230 : 205
    }

    private func trendBadge(_ trend: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: trend >= 0 ? "arrow.up" : "arrow.down")
            Text(overviewPercentageText(abs(trend), total: 1))
            Text(AppStrings.text(.previousMonthComparison))
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            HelpIconButton(
                title: AppStrings.text(.netWorthVariationTitle),
                message: trendHelpMessage,
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

struct AnalyticsOverviewMetricRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let tint: Color
    let usesWideLayout: Bool
    let action: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let safeWidth = max(proxy.size.width, 0)

            Button(action: action) {
                Group {
                    if usesWideLayout {
                        wideContent
                    } else {
                        compactContent
                    }
                }
                .padding(usesWideLayout ? 14 : 12)
                .frame(width: safeWidth, height: rowHeight)
                .contentShape(RoundedRectangle(cornerRadius: 16))
                .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
            }
            .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
            .buttonStyle(.plain)
        }
        .frame(height: rowHeight)
    }

    private var rowHeight: CGFloat {
        usesWideLayout ? 74 : 72
    }

    private var wideContent: some View {
        HStack(spacing: 14) {
            metricIcon(size: 46, font: .title3.weight(.semibold))

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
    }

    private var compactContent: some View {
        HStack(spacing: 10) {
            metricIcon(size: 42, font: .body.weight(.semibold))

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

    private func metricIcon(size: CGFloat, font: Font) -> some View {
        Image(systemName: icon)
            .font(font)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: Circle())
    }
}

private func overviewPercentageText(_ amount: Double, total: Double) -> String {
    guard total > 0 else { return "0%" }
    return (amount / total).formatted(.percent.precision(.fractionLength(0)))
}

struct AnalyticsQuickSummarySection<Content: View>: View {
    let onSeeAll: () -> Void
    @ViewBuilder let content: Content

    init(
        onSeeAll: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onSeeAll = onSeeAll
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppStrings.text(.quickSummary))
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                Button(action: onSeeAll) {
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

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AnalyticsHistoryAccessCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
}
