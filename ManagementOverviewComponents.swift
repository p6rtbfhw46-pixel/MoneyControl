import SwiftUI

enum ManagementSidebarTab: CaseIterable, Identifiable, Hashable {
    case accounts
    case recurringExpenses
    case recurringIncome
    case savings
    case credits
    case planning

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
        case .planning:
            AppStrings.text(.planning)
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
        case .planning:
            "map.fill"
        }
    }
}

struct ManagementSidebarScreen<Content: View>: View {
    let heroName: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            AreaHeroImage(
                name: heroName,
                aspectRatio: 1334.0 / 295.0,
                horizontalPadding: 12,
                usesSidebarNavigation: true
            )
            content
        }
    }
}

struct ManagementOverviewScreen: View {
    let heroName: String
    let recurringMonthlyBalance: Double
    let accountCount: Int
    let accountsBalance: Double
    let totalSaved: Double
    let totalDebt: Double
    let activePlanningSummary: String
    let activePlanningCount: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AreaHeroImage(
                    name: heroName,
                    aspectRatio: 1334.0 / 295.0,
                    horizontalPadding: 0,
                    usesSidebarNavigation: false
                )
                .padding(.top, -10)
                .padding(.bottom, -8)

                ManagementOverviewCards(
                    recurringMonthlyBalance: recurringMonthlyBalance,
                    accountCount: accountCount,
                    accountsBalance: accountsBalance,
                    totalSaved: totalSaved,
                    totalDebt: totalDebt,
                    activePlanningSummary: activePlanningSummary,
                    activePlanningCount: activePlanningCount
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
        }
        .background(AppPalette.appBackground)
    }
}

struct ManagementOverviewCards: View {
    let recurringMonthlyBalance: Double
    let accountCount: Int
    let accountsBalance: Double
    let totalSaved: Double
    let totalDebt: Double
    let activePlanningSummary: String
    let activePlanningCount: Int

    var body: some View {
        VStack(spacing: 14) {
            ForEach(cards) { card in
                NavigationLink(value: card.route) {
                    ManagementOverviewCardView(card: card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cards: [ManagementOverviewCard] {
        [
            ManagementOverviewCard(
                route: .recurringExpenses,
                title: AppStrings.text(.budgetSettings),
                subtitle: AppStrings.text(.managementBudgetDescription),
                imageName: "ManagementRecorrentesIcon",
                summaryTitle: "Saldo recorrente",
                summaryValue: recurringMonthlyBalance,
                summaryValueText: nil,
                summaryTint: recurringMonthlyBalance < 0 ? AppPalette.primary : AppPalette.positive
            ),
            ManagementOverviewCard(
                route: .accounts,
                title: AppStrings.text(.accounts),
                subtitle: AppStrings.text(.accountsSubtitle),
                imageName: "ManagementContasIcon",
                summaryTitle: "\(accountCount) \(accountCount == 1 ? AppStrings.text(.accountSingular) : AppStrings.text(.accountPlural)) · \(AppStrings.text(.totalSummaryLabel))",
                summaryValue: accountsBalance,
                summaryValueText: nil,
                summaryTint: AppPalette.mediumBlue
            ),
            ManagementOverviewCard(
                route: .savings,
                title: SavingsStrings.text(.settingsTitle),
                subtitle: AppStrings.text(.managementSavingsDescription),
                imageName: "QuickActionPoupanca",
                summaryTitle: "Total poupado",
                summaryValue: totalSaved,
                summaryValueText: nil,
                summaryTint: AppPalette.savings
            ),
            ManagementOverviewCard(
                route: .credits,
                title: CreditStrings.text(.settingsTitle),
                subtitle: AppStrings.text(.managementCreditsDescription),
                imageName: "QuickActionCredito",
                summaryTitle: "Total em dívida",
                summaryValue: -totalDebt,
                summaryValueText: nil,
                summaryTint: AppPalette.primary
            ),
            ManagementOverviewCard(
                route: .planning,
                title: AppStrings.text(.planning),
                subtitle: AppStrings.text(.planningDescription),
                imageName: "ManagementPlaneamentosIcon",
                summaryTitle: activePlanningSummary,
                summaryValue: nil,
                summaryValueText: "\(activePlanningCount)",
                summaryTint: AppPalette.mediumBlue
            )
        ]
    }
}

private struct ManagementOverviewCard: Identifiable {
    let route: ManagementSidebarTab
    let title: String
    let subtitle: String
    let imageName: String
    let summaryTitle: String
    let summaryValue: Double?
    let summaryValueText: String?
    let summaryTint: Color

    var id: ManagementSidebarTab { route }
}

private struct ManagementOverviewCardView: View {
    let card: ManagementOverviewCard

    var body: some View {
        HStack(spacing: 16) {
            Image(card.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .shadow(color: AppPalette.background.opacity(0.08), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 7) {
                Text(card.title)
                    .font(.title3.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(card.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let summaryValueText = card.summaryValueText {
                    ManagementOverviewSummary(
                        title: card.summaryTitle,
                        value: summaryValueText,
                        tint: card.summaryTint
                    )
                } else if let summaryValue = card.summaryValue {
                    ManagementOverviewSummary(
                        title: card.summaryTitle,
                        value: summaryValue.currencyText,
                        tint: card.summaryTint
                    )
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
}

private struct ManagementOverviewSummary: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.mutedText)
                .lineLimit(1)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}
