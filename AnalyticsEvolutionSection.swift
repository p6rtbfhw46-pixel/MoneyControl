import SwiftUI

struct AnalyticsEvolutionSection: View {
    @Binding var selectedKind: LightweightEvolutionKind
    @Binding var expandedMarkerID: Date?

    let points: [LightweightEvolutionPoint]
    let isLoading: Bool
    let currentValue: String
    let maximumValue: String
    let monthEndValue: String
    let savingsPoints: [LightweightEvolutionPoint]
    let savingsValue: String
    let creditPoints: [LightweightEvolutionPoint]
    let creditValue: String
    let onLoad: () -> Void

    private var shouldShowLoading: Bool {
        isLoading || points.isEmpty
    }

    private var hasChartData: Bool {
        points.contains { abs($0.value) > 0.009 }
    }

    private var showsMiniSummaries: Bool {
        !savingsPoints.isEmpty && !creditPoints.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            kindSelector

            if shouldShowLoading {
                AnalyticsEvolutionLoadingView(
                    isLoading: isLoading,
                    tint: selectedKind.tint,
                    onLoad: onLoad
                )
            } else {
                metrics
                chartContent
            }
        }
        .padding()
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(AppStrings.text(.temporalEvolution))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

            Text(AppStrings.text(.temporalEvolutionSubtitle))
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
        }
    }

    private var kindSelector: some View {
        HStack(spacing: 8) {
            ForEach(LightweightEvolutionKind.allCases) { kind in
                AnalyticsEvolutionSegment(
                    kind: kind,
                    isSelected: selectedKind == kind
                ) {
                    withAnimation(.snappy) {
                        selectedKind = kind
                    }
                }
            }
        }
    }

    private var metrics: some View {
        HStack(alignment: .top, spacing: 14) {
            AnalyticsEvolutionMetric(
                icon: selectedKind.systemImage,
                title: selectedKind.currentMetricTitle,
                value: currentValue,
                tint: selectedKind.tint
            )
            AnalyticsEvolutionMetric(
                icon: "chart.line.uptrend.xyaxis",
                title: AppStrings.text(.maximum),
                value: maximumValue,
                tint: selectedKind.tint
            )
            AnalyticsEvolutionMetric(
                icon: "calendar.badge.clock",
                title: AppStrings.text(.expectedEndOfMonth),
                value: monthEndValue,
                tint: selectedKind.tint
            )
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if hasChartData {
            AnalyticsEvolutionLegend(kind: selectedKind)

            AnalyticsEvolutionChart(
                points: points,
                kind: selectedKind,
                today: Date(),
                expandedMarkerID: $expandedMarkerID
            )
            .id(selectedKind)
            .frame(height: 220)

            if showsMiniSummaries {
                AnalyticsEvolutionMiniSummaries(
                    savingsPoints: savingsPoints,
                    savingsValue: savingsValue,
                    creditPoints: creditPoints,
                    creditValue: creditValue
                )
            }
        } else {
            Text(AppStrings.text(.temporalEvolutionNoData))
                .font(.subheadline)
                .foregroundStyle(AppPalette.mutedText)
                .frame(maxWidth: .infinity, minHeight: 120)
                .multilineTextAlignment(.center)
        }
    }
}
