import SwiftUI

struct SidebarSummaryTiles: View {
    let balance: Double
    let balanceHelpText: String
    let reservationFootnote: String
    let hasFutureReservation: Bool
    let shouldShowMonthUnpaid: Bool
    let monthUnpaid: Double
    let monthRemaining: Double?
    let onMonthUnpaidTap: () -> Void
    let onMonthRemainingTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resumo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.mutedText)

            VStack(spacing: 8) {
                SidebarSummaryRow(
                    title: AppStrings.text(.balanceThisMonth),
                    value: balance,
                    indicatorColor: balance < 0 ? AppPalette.primary : AppPalette.secondary,
                    helpText: balanceHelpText,
                    footnote: reservationFootnote,
                    helpTitle: hasFutureReservation ? AppStrings.text(.reservedBalanceHelpTitle) : nil
                )

                if shouldShowMonthUnpaid {
                    SidebarSummaryRow(
                        title: AppStrings.text(.monthUnpaid),
                        value: monthUnpaid,
                        indicatorColor: AppPalette.primary,
                        helpText: AppStrings.text(.monthUnpaidHelp),
                        onTap: onMonthUnpaidTap
                    )
                }

                if let monthRemaining {
                    SidebarSummaryRow(
                        title: monthRemaining < 0
                            ? AppStrings.text(.monthBudgetExceeded)
                            : AppStrings.text(.monthRemaining),
                        value: monthRemaining,
                        indicatorColor: monthRemaining < 0 ? AppPalette.primary : AppPalette.positive,
                        helpText: AppStrings.text(.monthRemainingHelp),
                        boldHelpNote: AppStrings.text(.monthRemainingHelpNote),
                        onTap: onMonthRemainingTap
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(AppPalette.surface.opacity(0.38), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct SidebarSummaryRow: View {
    let title: String
    let value: Double
    let indicatorColor: Color
    let helpText: String
    var boldHelpNote = ""
    var footnote = ""
    var helpTitle: String?
    var onTap: (() -> Void)?

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
