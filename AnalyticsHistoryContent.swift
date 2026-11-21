import SwiftUI

struct AnalyticsHistoryContent: View {
    @Binding var filterMode: AnalyticsHistoryFilterMode
    @Binding var selectedMonthOffset: Int
    @Binding var startDate: Date
    @Binding var endDate: Date

    let monthOffsets: [Int]
    let selectedMonth: Date
    let lines: [AnalyticsHistoryLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $filterMode) {
                ForEach(AnalyticsHistoryFilterMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(AppPalette.background)

            if filterMode == .month {
                HStack(spacing: 12) {
                    navigationButton(systemImage: "chevron.left") {
                        moveMonth(by: -1)
                    }

                    Text(selectedMonth.monthTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity)

                    navigationButton(systemImage: "chevron.right") {
                        moveMonth(by: 1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker(
                        "Início",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Fim",
                        selection: $endDate,
                        displayedComponents: .date
                    )
                }
                .font(.subheadline)
                .foregroundStyle(AppPalette.background)
            }

            if lines.isEmpty {
                ContentUnavailableView(
                    AppStrings.text(.noListData),
                    systemImage: "list.bullet.rectangle"
                )
                .foregroundStyle(AppPalette.background)
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(lines) { line in
                        AnalyticsHistoryRow(line: line)
                    }
                }
            }
        }
    }

    private func navigationButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.background)
                .frame(width: 34, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func moveMonth(by value: Int) {
        let nextOffset = selectedMonthOffset + value
        let clampedOffset = min(
            max(nextOffset, monthOffsets.first ?? 0),
            monthOffsets.last ?? 0
        )

        withAnimation(.snappy) {
            selectedMonthOffset = clampedOffset
        }
    }
}
