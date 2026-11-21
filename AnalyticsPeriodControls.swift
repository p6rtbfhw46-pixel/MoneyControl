import SwiftUI

struct AnalyticsPeriodControls: View {
    @Binding var period: AnalyticsPeriod
    @Binding var selectedMonthOffset: Int

    let monthOffsets: [Int]
    let selectedMonth: Date

    var body: some View {
        VStack(spacing: 10) {
            AnalyticsPeriodPicker(selection: $period)

            if period == .month {
                HStack(spacing: 12) {
                    monthArrowButton(systemImage: "chevron.left") {
                        moveMonth(by: -1)
                    }
                    .disabled(selectedMonthOffset <= firstOffset)
                    .opacity(selectedMonthOffset <= firstOffset ? 0.35 : 1)

                    Text(selectedMonth.monthTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity)

                    monthArrowButton(systemImage: "chevron.right") {
                        moveMonth(by: 1)
                    }
                    .disabled(selectedMonthOffset >= lastOffset)
                    .opacity(selectedMonthOffset >= lastOffset ? 0.35 : 1)
                }
            }
        }
    }

    private var firstOffset: Int {
        monthOffsets.first ?? 0
    }

    private var lastOffset: Int {
        monthOffsets.last ?? 0
    }

    private func monthArrowButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(width: 38, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func moveMonth(by value: Int) {
        let nextOffset = selectedMonthOffset + value
        let clampedOffset = min(max(nextOffset, firstOffset), lastOffset)

        withAnimation(.snappy) {
            selectedMonthOffset = clampedOffset
        }
    }
}

struct AnalyticsExpenseTabPicker: View {
    @Binding var selection: AnalyticsExpenseTab

    var body: some View {
        Picker("", selection: $selection) {
            Text(AppStrings.text(.whereSpent)).tag(AnalyticsExpenseTab.whereSpent)
            Text(AppStrings.text(.budgetRule)).tag(AnalyticsExpenseTab.budgetRule)
        }
        .pickerStyle(.segmented)
        .tint(AppPalette.background)
    }
}

struct AnalyticsPhoneTabPicker: View {
    @Binding var selection: AnalyticsSidebarTab

    let tabs: [AnalyticsSidebarTab]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabs) { tab in
                    let isSelected = selection == tab

                    Button {
                        selection = tab
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.systemImage)
                                .font(.caption.weight(.bold))

                            Text(title(for: tab))
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
                        .overlay {
                            Capsule()
                                .stroke(
                                    AppPalette.separator.opacity(isSelected ? 0 : 0.7),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func title(for tab: AnalyticsSidebarTab) -> String {
        switch tab {
        case .summaries:
            "Insights"
        default:
            tab.title
        }
    }
}

struct AnalyticsMonthYearExpenseCard<Content: View>: View {
    @Binding var period: AnalyticsPeriod
    @Binding var selectedMonthOffset: Int
    @Binding var selectedExpenseTab: AnalyticsExpenseTab

    let title: String
    let total: Double
    let monthOffsets: [Int]
    let selectedMonth: Date
    let content: Content

    init(
        title: String,
        total: Double,
        period: Binding<AnalyticsPeriod>,
        selectedMonthOffset: Binding<Int>,
        selectedExpenseTab: Binding<AnalyticsExpenseTab>,
        monthOffsets: [Int],
        selectedMonth: Date,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.total = total
        self._period = period
        self._selectedMonthOffset = selectedMonthOffset
        self._selectedExpenseTab = selectedExpenseTab
        self.monthOffsets = monthOffsets
        self.selectedMonth = selectedMonth
        self.content = content()
    }

    var body: some View {
        AnalyticsChartCard(title: title, total: total) {
            VStack(alignment: .leading, spacing: 14) {
                AnalyticsPeriodControls(
                    period: $period,
                    selectedMonthOffset: $selectedMonthOffset,
                    monthOffsets: monthOffsets,
                    selectedMonth: selectedMonth
                )
                AnalyticsExpenseTabPicker(selection: $selectedExpenseTab)
                content
            }
        }
    }
}
