import SwiftUI

struct AnnualAllocationSimulationRowView: View {
    let row: AnnualAllocationSimulationRow
    let kind: AnnualAllocationSimulationKind
    let tint: Color
    let payoffEstimate: String?
    var emphasized = false

    private var currentLabel: String {
        kind == .savings
            ? AppStrings.text(.annualSimulationCurrentSaved)
            : AppStrings.text(.annualSimulationCurrentDebt)
    }

    private var projectedLabel: String {
        kind == .savings
            ? AppStrings.text(.annualSimulationProjectedSaved)
            : AppStrings.text(.annualSimulationProjectedDebt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(row.name)
                    .font(emphasized ? .headline : .subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Text(row.projectedValue.currencyText)
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(tint)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    Text("\(currentLabel): \(row.startingValue.currencyText)")
                    Text("→")
                    Text("\(projectedLabel): \(row.projectedValue.currencyText)")
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(currentLabel): \(row.startingValue.currencyText)")
                    Text("\(projectedLabel): \(row.projectedValue.currencyText)")
                }
            }
            .font(.caption)
            .foregroundStyle(AppPalette.mutedText)

            if kind == .credits {
                Text(
                    "\(AppStrings.text(.annualSimulationPlannedCreditPayments)): "
                        + row.plannedRecurringPaymentValue.currencyText
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.background)

                Text(
                    "\(AppStrings.text(.annualSimulationAdditionalCreditPayment)): "
                        + row.allocatedValue.currencyText
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.background)

                if let payoffEstimate {
                    Label(payoffEstimate, systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(
                    "\(AppStrings.text(.annualSimulationAnnualAllocation)): "
                        + row.allocatedValue.currencyText
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.background)
            }
        }
        .padding(12)
        .background(
            emphasized ? tint.opacity(0.12) : AppPalette.appBackground,
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

struct AnnualAllocationRowPresentation: Identifiable {
    let row: AnnualAllocationSimulationRow
    let payoffEstimate: String?

    var id: String { row.id }
}

struct AnnualAllocationSimulationCard: View {
    @Binding var allocationPercentage: Int
    @Binding var showsMonths: Bool
    @Binding var excludedMonths: Set<Int>

    let kind: AnnualAllocationSimulationKind
    let tint: Color
    let title: String
    let subtitle: String
    let months: [Date]
    let recurringAllocation: Double
    let rows: [AnnualAllocationRowPresentation]
    let total: AnnualAllocationRowPresentation
    let onShowDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: kind == .savings ? "banknote.fill" : "creditcard.fill")
                    .font(.title2)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppPalette.background)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button(action: onShowDetails) {
                    Image(systemName: "info.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppPalette.mediumBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.text(.annualSimulationDetailsAccessibility))
            }

            Picker("", selection: $allocationPercentage) {
                Text("25%").tag(25)
                Text("50%").tag(50)
                Text("75%").tag(75)
            }
            .pickerStyle(.segmented)
            .tint(tint)

            AnnualAllocationMonthSelector(
                isExpanded: $showsMonths,
                excludedMonths: $excludedMonths,
                months: months,
                tint: tint
            )

            if recurringAllocation <= 0 {
                Label(
                    AppStrings.text(.annualSimulationNoPositiveRemaining),
                    systemImage: "exclamationmark.circle"
                )
                .font(.subheadline)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(rows) { item in
                AnnualAllocationSimulationRowView(
                    row: item.row,
                    kind: kind,
                    tint: tint,
                    payoffEstimate: item.payoffEstimate
                )
            }

            if !rows.isEmpty {
                Divider()
            }

            AnnualAllocationSimulationRowView(
                row: total.row,
                kind: kind,
                tint: tint,
                payoffEstimate: total.payoffEstimate,
                emphasized: true
            )

            Text(AppStrings.text(.annualSimulationInterestNote))
                .font(.caption2)
                .foregroundStyle(AppPalette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
    }
}

struct AnnualAllocationMonthSelector: View {
    @Binding var isExpanded: Bool
    @Binding var excludedMonths: Set<Int>

    let months: [Date]
    let tint: Color

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            HStack {
                Spacer()

                if !excludedMonths.isEmpty {
                    Button(AppStrings.text(.annualSimulationRestoreMonths)) {
                        excludedMonths.removeAll()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .buttonStyle(.plain)
                }
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 70), spacing: 8)],
                spacing: 8
            ) {
                ForEach(months, id: \.self) { month in
                    monthButton(month)
                }
            }
            .padding(.top, 8)
        } label: {
            Text(AppStrings.text(.annualSimulationMonthsTitle))
                .font(.caption.bold())
                .foregroundStyle(AppPalette.background)
        }
        .tint(tint)
    }

    private func monthButton(_ month: Date) -> some View {
        let monthNumber = month.monthNumber
        let isExcluded = excludedMonths.contains(monthNumber)
        let monthName = month.formatted(
            .dateTime
                .locale(Locale(identifier: AppStrings.currentLocaleIdentifier))
                .month(.abbreviated)
        ).capitalized
        let accessibilityFormat = isExcluded
            ? AppStrings.text(.annualSimulationMonthExcluded)
            : AppStrings.text(.annualSimulationMonthIncluded)

        return Button {
            if isExcluded {
                excludedMonths.remove(monthNumber)
            } else {
                excludedMonths.insert(monthNumber)
            }
        } label: {
            HStack(spacing: 4) {
                Image(
                    systemName: isExcluded
                        ? "xmark.circle.fill"
                        : "checkmark.circle.fill"
                )
                .font(.caption2)

                Text(monthName)
                    .font(.caption.weight(.semibold))
                    .strikethrough(isExcluded)
                    .lineLimit(1)
            }
            .foregroundStyle(isExcluded ? AppPalette.mutedText : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isExcluded ? AppPalette.appBackground : tint.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 9)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(
                        isExcluded
                            ? AppPalette.mutedText.opacity(0.35)
                            : tint.opacity(0.35),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: accessibilityFormat, monthName))
    }
}

struct AnnualAllocationMonthDetailCard: View {
    let month: Date
    let isExcluded: Bool
    let income: Double
    let expenses: Double
    let remaining: Double
    let allocationPercentage: Int
    let appliedValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(.headline)
                .foregroundStyle(isExcluded ? AppPalette.mutedText : AppPalette.background)
                .strikethrough(isExcluded)

            if isExcluded {
                Label(
                    AppStrings.text(.annualSimulationExcludedCalculation),
                    systemImage: "xmark.circle.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(AppPalette.primary)
            }

            FinancialFormulaLine(
                label: AppStrings.text(.annualSimulationMonthlyIncome),
                value: income.currencyText
            )
            FinancialFormulaLine(
                label: AppStrings.text(.annualSimulationMonthlyExpenses),
                value: expenses.currencyText
            )
            FinancialFormulaLine(
                label: AppStrings.text(.annualSimulationMonthlyRemaining),
                value: remaining.currencyText
            )

            Divider()

            FinancialFormulaLine(
                label: "\(AppStrings.text(.annualSimulationMonthlyAvailable)) (\(allocationPercentage)%)",
                value: appliedValue.currencyText,
                emphasized: true
            )
        }
        .padding(14)
        .background(
            isExcluded ? AppPalette.appBackground.opacity(0.7) : AppPalette.surface,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            if isExcluded {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppPalette.mutedText.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [5])
                    )
            }
        }
        .opacity(isExcluded ? 0.72 : 1)
    }

    private var monthName: String {
        month.formatted(
            .dateTime
                .locale(Locale(identifier: AppStrings.currentLocaleIdentifier))
                .month(.wide)
        ).capitalized
    }

}

struct FinancialFormulaLine: View {
    let label: String
    let value: String
    var emphasized = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(emphasized ? .subheadline.bold() : .subheadline)
                .foregroundStyle(emphasized ? AppPalette.background : AppPalette.mutedText)

            Spacer(minLength: 8)

            Text(value)
                .font(
                    emphasized
                        ? .subheadline.bold().monospacedDigit()
                        : .subheadline.monospacedDigit()
                )
                .foregroundStyle(emphasized ? AppPalette.savings : AppPalette.background)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AnnualAllocationMonthPresentation: Identifiable {
    let month: Date
    let isExcluded: Bool
    let income: Double
    let expenses: Double
    let remaining: Double
    let allocationPercentage: Int
    let appliedValue: Double

    var id: Date { month }
}

struct AnnualAllocationDetailsView: View {
    let kind: AnnualAllocationSimulationKind
    let title: String
    let tint: Color
    let months: [AnnualAllocationMonthPresentation]
    let annualAllocation: Double
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    Text(AppStrings.text(.annualSimulationExplanation))
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    if kind == .credits {
                        Text(AppStrings.text(.annualSimulationCreditPaymentsExplanation))
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(months) { month in
                        AnnualAllocationMonthDetailCard(
                            month: month.month,
                            isExcluded: month.isExcluded,
                            income: month.income,
                            expenses: month.expenses,
                            remaining: month.remaining,
                            allocationPercentage: month.allocationPercentage,
                            appliedValue: month.appliedValue
                        )
                    }

                    FinancialFormulaLine(
                        label: AppStrings.text(.annualSimulationAnnualAllocation),
                        value: annualAllocation.currencyText,
                        emphasized: true
                    )
                    .padding(16)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                    Label(
                        AppStrings.text(.annualSimulationInterestNote),
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(AppPalette.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(AppPalette.appBackground)
            .navigationTitle(title)
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
