import SwiftUI

struct SavingsPotentialMonthDetail: Identifiable {
    let month: Date
    let recurringIncome: Double
    let recurringExpenses: Double

    var id: Date { month }
    var income: Double { recurringIncome }
    var expenses: Double { recurringExpenses }
    var remaining: Double { income - expenses }
}

struct SavingsPotentialCard: View {
    let hasRecurringData: Bool
    let averageRemaining: Double
    let annualPotential: Double
    let onShowDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SavingsPotentialHeader(
                showsDetailsButton: hasRecurringData,
                onShowDetails: onShowDetails
            )

            if hasRecurringData {
                SavingsPotentialContent(
                    averageRemaining: averageRemaining,
                    annualPotential: annualPotential
                )
            } else {
                Label(
                    AppStrings.text(.savingsPotentialNoRecurringData),
                    systemImage: "tray"
                )
                .font(.subheadline)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppPalette.savings.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
    }
}

private struct SavingsPotentialHeader: View {
    let showsDetailsButton: Bool
    let onShowDetails: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.title2)
                .foregroundStyle(AppPalette.savings)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(AppStrings.text(.savingsPotentialTitle))
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Text(AppStrings.text(.savingsPotentialSubtitle))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
            }

            Spacer(minLength: 8)

            if showsDetailsButton {
                Button(action: onShowDetails) {
                    Image(systemName: "info.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.mediumBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.text(.savingsPotentialDetailsAccessibility))
            }
        }
    }
}

private struct SavingsPotentialContent: View {
    let averageRemaining: Double
    let annualPotential: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.text(.savingsPotentialAverageRemaining))
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)

                Text(averageRemaining.currencyText)
                    .font(.title2.bold())
                    .foregroundStyle(
                        averageRemaining >= 0 ? AppPalette.positive : AppPalette.primary
                    )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    SavingsPotentialProjection(percentage: 25, amount: annualPotential * 0.25)
                    SavingsPotentialProjection(percentage: 50, amount: annualPotential * 0.50)
                }

                VStack(spacing: 12) {
                    SavingsPotentialProjection(percentage: 25, amount: annualPotential * 0.25)
                    SavingsPotentialProjection(percentage: 50, amount: annualPotential * 0.50)
                }
            }

            Text(AppStrings.text(.savingsPotentialSimulationSummary))
                .font(.caption2)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SavingsPotentialProjection: View {
    let percentage: Int
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(String(
                format: AppStrings.text(.savingsPotentialSavePercentage),
                locale: Locale(identifier: AppStrings.currentLocaleIdentifier),
                "\(percentage)"
            ))
                .font(.caption.bold())
                .foregroundStyle(AppPalette.mutedText)

            Text(amount.currencyText)
                .font(.headline)
                .foregroundStyle(AppPalette.savings)

            Text(AppStrings.text(.savingsPotentialYearEnd))
                .font(.caption2)
                .foregroundStyle(AppPalette.mutedText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SavingsPotentialDetailsView: View {
    let details: [SavingsPotentialMonthDetail]
    let totalIncome: Double
    let totalExpenses: Double
    let totalRemaining: Double
    let averageRemaining: Double
    let annualPotential: Double
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text(AppStrings.text(.savingsPotentialSimulationDetails))
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 4)

                    ForEach(details) { detail in
                        SavingsPotentialMonthRow(detail: detail)
                    }

                    SavingsPotentialFinalCalculation(
                        monthCount: details.count,
                        totalIncome: totalIncome,
                        totalExpenses: totalExpenses,
                        totalRemaining: totalRemaining,
                        averageRemaining: averageRemaining,
                        annualPotential: annualPotential
                    )
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(AppStrings.text(.savingsPotentialCalculationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.text(.savingsPotentialDone), action: onDone)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct SavingsPotentialMonthRow: View {
    let detail: SavingsPotentialMonthDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                detail.month.formatted(
                    .dateTime
                        .locale(Locale(identifier: AppStrings.currentLocaleIdentifier))
                        .month(.wide)
                )
                .capitalized
            )
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialRecurringIncome),
                value: detail.recurringIncome.currencyText
            )
            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialRecurringExpenses),
                value: detail.recurringExpenses.currencyText
            )

            Divider()

            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialRemaining),
                value: detail.remaining.currencyText,
                emphasized: true
            )
        }
        .padding(14)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct SavingsPotentialFinalCalculation: View {
    let monthCount: Int
    let totalIncome: Double
    let totalExpenses: Double
    let totalRemaining: Double
    let averageRemaining: Double
    let annualPotential: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.text(.savingsPotentialFinalCalculation))
                .font(.headline)
                .foregroundStyle(AppPalette.background)

            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialTotalIncome),
                value: totalIncome.currencyText
            )
            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialTotalExpenses),
                value: totalExpenses.currencyText
            )

            Divider()

            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialAnnualRemaining),
                value: totalRemaining.currencyText,
                emphasized: true
            )

            Text("\(totalRemaining.currencyText) ÷ \(monthCount) = \(averageRemaining.currencyText)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(AppPalette.background)

            Text(AppStrings.text(.savingsPotentialAverageMonthlyRemaining))
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)

            Divider()

            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialTwentyFivePercent),
                value: (annualPotential * 0.25).currencyText,
                emphasized: true
            )
            FinancialFormulaLine(
                label: AppStrings.text(.savingsPotentialFiftyPercent),
                value: (annualPotential * 0.50).currencyText,
                emphasized: true
            )
        }
        .padding(16)
        .background(AppPalette.mintSurface.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppPalette.savings.opacity(0.3), lineWidth: 1)
        }
    }
}
