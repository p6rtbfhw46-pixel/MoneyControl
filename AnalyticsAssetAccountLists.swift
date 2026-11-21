import SwiftUI

struct AnalyticsSavingsAccountList: View {
    let accounts: [SavingAccount]
    let movements: [SavingMovement]
    let currentMonth: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if accounts.isEmpty {
                AnalyticsAccountEmptyState()
            } else {
                ForEach(accounts) { saving in
                    NavigationLink {
                        SavingDetailView(saving: saving)
                    } label: {
                        AnalyticsRow(
                            icon: saving.purposeIconName,
                            title: saving.displayName,
                            subtitle: subtitle(for: saving),
                            value: saving.balance(with: movements).currencyText,
                            tint: AppPalette.savings
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func subtitle(for saving: SavingAccount) -> String {
        let variation = saving.monthVariation(in: currentMonth, movements: movements)
        var parts = ["\(SavingsStrings.text(.monthVariation)): \(variation.currencyText)"]

        if let target = saving.targetAmount, target > 0 {
            let balance = saving.balance(with: movements)
            parts.append(
                "\(SavingsStrings.text(.targetProgress)): \(assetPercentageText(balance, total: target))"
            )
        }

        return parts.joined(separator: " · ")
    }
}

struct AnalyticsCreditAccountList: View {
    let accounts: [CreditAccount]
    let movements: [CreditMovement]
    let currentMonth: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if accounts.isEmpty {
                AnalyticsAccountEmptyState()
            } else {
                ForEach(accounts) { credit in
                    NavigationLink {
                        CreditDetailView(credit: credit)
                    } label: {
                        AnalyticsRow(
                            icon: credit.creditType.iconName,
                            title: credit.displayName,
                            subtitle: subtitle(for: credit),
                            value: credit.balance(with: movements).currencyText,
                            tint: AppPalette.primary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func subtitle(for credit: CreditAccount) -> String {
        let balance = credit.balance(with: movements)
        let variation = credit.monthVariation(in: currentMonth, movements: movements)
        var parts = [
            credit.creditType.title,
            "\(CreditStrings.text(.monthVariation)): \(variation.currencyText)"
        ]

        if let limit = credit.creditLimit, limit > 0 {
            parts.append(
                "\(CreditStrings.text(.usedPercentage)): \(assetPercentageText(balance, total: limit))"
            )
        }

        return parts.joined(separator: " · ")
    }
}

private struct AnalyticsAccountEmptyState: View {
    var body: some View {
        ContentUnavailableView(
            AppStrings.text(.noListData),
            systemImage: "list.bullet.rectangle"
        )
        .foregroundStyle(AppPalette.background)
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}

private func assetPercentageText(_ amount: Double, total: Double) -> String {
    guard total > 0 else { return "0%" }
    return (amount / total).formatted(.percent.precision(.fractionLength(0)))
}
