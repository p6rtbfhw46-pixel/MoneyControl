import SwiftUI

struct AnalyticsEvolutionUnavailableCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.text(.temporalEvolution))
                .font(.headline.bold())
                .foregroundStyle(AppPalette.background)

            Text(AppStrings.text(.temporalEvolutionUnavailable))
                .font(.caption)
                .foregroundStyle(AppPalette.mutedText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.06), radius: 12, y: 6)
    }
}

struct AnalyticsEvolutionLoadingView: View {
    let isLoading: Bool
    let tint: Color
    let onLoad: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .tint(tint)

                Text(AppStrings.text(.temporalEvolutionLoading))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
            } else {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12), in: Circle())

                Button(action: onLoad) {
                    Text(AppStrings.text(.loadChart))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppPalette.surface)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(tint, in: Capsule())
                }
                .buttonStyle(.plain)

                Text(AppStrings.text(.temporalEvolutionLoadingNote))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.mutedText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AnalyticsEvolutionSegment: View {
    let kind: LightweightEvolutionKind
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: kind.systemImage)
                    .font(.caption.weight(.bold))

                Text(kind.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .foregroundStyle(isSelected ? AppPalette.surface : AppPalette.background)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                isSelected ? kind.tint : AppPalette.appBackground.opacity(0.72),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct AnalyticsEvolutionChart: View {
    let points: [LightweightEvolutionPoint]
    let kind: LightweightEvolutionKind
    let today: Date
    @Binding var expandedMarkerID: Date?

    var body: some View {
        GeometryReader { geometry in
            let axisWidth: CGFloat = 52
            let plotWidth = max(geometry.size.width - axisWidth - 6, 1)
            let plotHeight = max(geometry.size.height - 34, 1)
            let chartFrame = CGRect(
                x: axisWidth,
                y: 12,
                width: plotWidth,
                height: plotHeight
            )
            let values = axisValues

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppPalette.appBackground.opacity(0.58))

                ForEach(values.enumerated(), id: \.offset) { _, value in
                    let y = axisY(value, values: values, in: chartFrame)

                    Text(axisLabel(value))
                        .font(.caption2)
                        .foregroundStyle(AppPalette.mutedText)
                        .opacity(0.82)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 46, alignment: .trailing)
                        .position(x: 23, y: y)
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        scrollablePlot(
                            axisValues: values,
                            viewportWidth: plotWidth,
                            plotHeight: plotHeight
                        )
                    }
                    .onAppear {
                        scrollToToday(proxy: proxy)
                    }
                    .onChange(of: kind) {
                        scrollToToday(proxy: proxy)
                    }
                    .onChange(of: points.count) {
                        scrollToToday(proxy: proxy)
                    }
                }
                .frame(width: plotWidth, height: geometry.size.height)
                .position(
                    x: axisWidth + plotWidth / 2,
                    y: geometry.size.height / 2
                )
            }
        }
    }

    private func scrollablePlot(
        axisValues: [Double],
        viewportWidth: CGFloat,
        plotHeight: CGFloat
    ) -> some View {
        let visibleDayCount = 26.0
        let contentWidth = max(
            viewportWidth,
            viewportWidth * CGFloat(max(Double(points.count) / visibleDayCount, 1))
        )
        let plotRect = CGRect(x: 0, y: 12, width: contentWidth, height: plotHeight)
        let chartPoints = normalizedPoints(in: plotRect)
        let currentIndex = points.firstIndex {
            Calendar.current.isDate($0.month, inSameDayAs: today)
        } ?? min(60, max(points.count - 1, 0))
        let historyPoints = Array(chartPoints.prefix(currentIndex + 1))
        let futurePoints = chartPoints.indices.contains(currentIndex)
            ? Array(chartPoints.suffix(from: currentIndex))
            : []

        return ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                ForEach(points) { point in
                    Color.clear
                        .frame(
                            width: contentWidth / CGFloat(max(points.count, 1)),
                            height: 1
                        )
                        .id(point.id)
                }
            }
            .frame(width: contentWidth, height: 1)

            ForEach(axisValues.enumerated(), id: \.offset) { _, value in
                let y = axisY(value, values: axisValues, in: plotRect)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: contentWidth, y: y))
                }
                .stroke(AppPalette.mutedText.opacity(0.22), lineWidth: 0.5)
            }

            Path { path in
                guard let first = historyPoints.first,
                      let last = historyPoints.last else { return }
                path.move(to: CGPoint(x: first.x, y: plotRect.maxY))
                path.addLine(to: first)
                addSmoothLine(
                    to: &path,
                    points: historyPoints,
                    movesToFirstPoint: false
                )
                path.addLine(to: CGPoint(x: last.x, y: plotRect.maxY))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [kind.tint.opacity(0.12), kind.tint.opacity(0.01)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Path { path in
                addSmoothLine(to: &path, points: historyPoints)
            }
            .stroke(
                LinearGradient(
                    colors: [
                        kind.tint.opacity(0.62),
                        kind.tint.opacity(0.9),
                        kind.tint.opacity(0.62)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(
                    lineWidth: 2.2,
                    lineCap: .round,
                    lineJoin: .round
                )
            )

            Path { path in
                addSmoothLine(to: &path, points: futurePoints)
            }
            .stroke(
                kind.tint.opacity(0.34),
                style: StrokeStyle(
                    lineWidth: 2.1,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: [6, 8]
                )
            )

            if chartPoints.indices.contains(currentIndex) {
                Path { path in
                    let x = chartPoints[currentIndex].x
                    path.move(to: CGPoint(x: x, y: plotRect.minY - 12))
                    path.addLine(to: CGPoint(x: x, y: plotRect.maxY))
                }
                .stroke(AppPalette.mutedText.opacity(0.24), lineWidth: 1)

                Text("Hoje")
                    .font(.caption2.bold())
                    .foregroundStyle(AppPalette.background)
                    .position(
                        x: chartPoints[currentIndex].x,
                        y: plotRect.minY - 16
                    )
            }

            ForEach(points.enumerated(), id: \.element.id) { index, point in
                if chartPoints.indices.contains(index) {
                    chartPoint(
                        point,
                        index: index,
                        currentIndex: currentIndex,
                        position: chartPoints[index],
                        contentWidth: contentWidth,
                        plotRect: plotRect
                    )
                }
            }

            ForEach(points.enumerated(), id: \.element.id) { index, point in
                if chartPoints.indices.contains(index),
                   shouldShowDateLabel(at: index, point: point) {
                    Text(monthTitle(point.month))
                        .font(.caption2)
                        .foregroundStyle(
                            Calendar.current.isDate(point.month, inSameDayAs: today)
                                ? AppPalette.background
                                : AppPalette.mutedText
                        )
                        .position(
                            x: chartPoints[index].x,
                            y: plotRect.maxY + 18
                        )
                }
            }
        }
        .frame(width: contentWidth, height: plotRect.maxY + 34)
    }

    @ViewBuilder
    private func chartPoint(
        _ point: LightweightEvolutionPoint,
        index: Int,
        currentIndex: Int,
        position: CGPoint,
        contentWidth: CGFloat,
        plotRect: CGRect
    ) -> some View {
        let isCurrent = Calendar.current.isDate(point.month, inSameDayAs: today)
        let pointColor = isCurrent
            ? AppPalette.background
            : (index > currentIndex ? kind.tint.opacity(0.62) : kind.tint)

        if isCurrent || point.markerTitle != nil {
            Circle()
                .fill(pointColor)
                .frame(
                    width: isCurrent ? 7 : 4.5,
                    height: isCurrent ? 7 : 4.5
                )
                .overlay(Circle().stroke(AppPalette.surface, lineWidth: 1.5))
                .position(position)
        }

        if let markerTitle = point.markerTitle,
           let markerIcon = point.markerIcon,
           let markerTint = point.markerTint {
            AnalyticsEvolutionMarker(
                title: markerTitle,
                icon: markerIcon,
                tint: markerTint,
                isExpanded: expandedMarkerID == point.id
            ) {
                withAnimation(.snappy) {
                    expandedMarkerID = expandedMarkerID == point.id ? nil : point.id
                }
            }
            .position(
                x: min(max(position.x, 32), contentWidth - 32),
                y: max(position.y - 28, plotRect.minY + 14)
            )
        }
    }

    private var axisValues: [Double] {
        let values = points.map(\.value)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 0
        let rawRange = max(maximum - minimum, 1)
        let step = roundedAxisStep(for: rawRange / 4)
        guard minimum.isFinite,
              maximum.isFinite,
              rawRange.isFinite,
              step.isFinite,
              step > 0 else { return [0] }

        let roundedMaximum = ceil(maximum / step) * step
        let roundedMinimum = minimum < -(step * 0.25)
            ? floor(minimum / step) * step
            : 0
        var result: [Double] = []
        var value = roundedMaximum

        while value >= roundedMinimum, result.count < 6 {
            result.append(value)
            value -= step
        }
        if result.last != roundedMinimum {
            result.append(roundedMinimum)
        }
        return result
    }

    private func normalizedPoints(in rect: CGRect) -> [CGPoint] {
        guard points.count > 1 else { return [] }

        let values = points.map(\.value)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let range = max(maximum - minimum, 1)
        guard minimum.isFinite, maximum.isFinite, range.isFinite else {
            return []
        }

        return points.enumerated().map { index, point in
            let x = rect.minX
                + rect.width * CGFloat(index) / CGFloat(points.count - 1)
            let normalizedY = (point.value - minimum) / range
            let y = rect.minY + rect.height * CGFloat(1 - normalizedY)
            return CGPoint(x: x, y: y)
        }
    }

    private func roundedAxisStep(for rawStep: Double) -> Double {
        guard rawStep.isFinite, rawStep > 0 else { return 100 }

        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude
        let rounded: Double
        switch normalized {
        case ...1: rounded = 1
        case ...2: rounded = 2
        case ...5: rounded = 5
        default: rounded = 10
        }
        return rounded * magnitude
    }

    private func axisY(
        _ value: Double,
        values: [Double],
        in rect: CGRect
    ) -> CGFloat {
        guard let maximum = values.first,
              let minimum = values.last else { return rect.midY }
        let range = max(maximum - minimum, 1)
        guard value.isFinite,
              maximum.isFinite,
              minimum.isFinite,
              range.isFinite else { return rect.midY }

        let normalizedY = (value - minimum) / range
        return rect.minY + rect.height * CGFloat(1 - normalizedY)
    }

    private func axisLabel(_ value: Double) -> String {
        let displayedValue = kind == .credits ? -value : value
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale(identifier: AppStrings.currentLocaleIdentifier)
        return formatter.string(from: NSNumber(value: displayedValue))
            ?? displayedValue.currencyText
    }

    private func scrollToToday(proxy: ScrollViewProxy) {
        guard let todayID = points.first(where: {
            Calendar.current.isDate($0.month, inSameDayAs: today)
        })?.id else { return }

        Task { @MainActor in
            await Task.yield()
            proxy.scrollTo(todayID, anchor: UnitPoint(x: 0.28, y: 0.5))
        }
    }

    private func shouldShowDateLabel(
        at index: Int,
        point: LightweightEvolutionPoint
    ) -> Bool {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: point.month)
        let lastDay = calendar.range(
            of: .day,
            in: .month,
            for: point.month
        )?.count ?? 30
        let middleDay = max(1, Int(ceil(Double(lastDay) / 2)))

        return day == 1
            || day == middleDay
            || day == lastDay
            || index == 0
            || index == points.count - 1
    }

    private func monthTitle(_ month: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: month)
        let lastDay = calendar.range(
            of: .day,
            in: .month,
            for: month
        )?.count ?? 30
        let middleDay = max(1, Int(ceil(Double(lastDay) / 2)))

        if day == middleDay {
            let formatter = DateFormatter()
            formatter.locale = Locale(
                identifier: AppStrings.currentLocaleIdentifier
            )
            formatter.setLocalizedDateFormatFromTemplate("MMM")
            return formatter.string(from: month).capitalized
        }
        return "\(day)"
    }

    private func addSmoothLine(
        to path: inout Path,
        points: [CGPoint],
        movesToFirstPoint: Bool = true
    ) {
        guard let first = points.first else { return }
        if movesToFirstPoint {
            path.move(to: first)
        }
        guard points.count > 1 else { return }

        for index in 1..<points.count {
            let previousPrevious = points[max(index - 2, 0)]
            let previous = points[index - 1]
            let current = points[index]
            let next = points[min(index + 1, points.count - 1)]
            let tension: CGFloat = 0.42
            let control1 = CGPoint(
                x: previous.x + (current.x - previousPrevious.x) * tension / 3,
                y: previous.y + (current.y - previousPrevious.y) * tension / 3
            )
            let control2 = CGPoint(
                x: current.x - (next.x - previous.x) * tension / 3,
                y: current.y - (next.y - previous.y) * tension / 3
            )
            path.addCurve(to: current, control1: control1, control2: control2)
        }
    }
}

struct AnalyticsEvolutionMarker: View {
    let title: String
    let icon: String
    let tint: Color
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 3) {
                if isExpanded {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(AppPalette.surface.opacity(0.94), in: Capsule())
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                Image(systemName: icon)
                    .font(.caption2.bold())
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                    .background(AppPalette.surface.opacity(0.95), in: Circle())
                    .overlay(Circle().stroke(tint.opacity(0.26), lineWidth: 1))
                    .shadow(color: tint.opacity(0.18), radius: 5, y: 3)

                Rectangle()
                    .fill(tint.opacity(0.55))
                    .frame(width: 1, height: 18)
            }
            .frame(width: 92)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AnalyticsEvolutionLegend: View {
    let kind: LightweightEvolutionKind

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Capsule()
                    .fill(kind.tint)
                    .frame(width: 26, height: 3)

                Text(AppStrings.text(.history))
            }

            HStack(spacing: 4) {
                Capsule()
                    .fill(kind.tint.opacity(0.55))
                    .frame(width: 8, height: 3)

                Capsule()
                    .fill(kind.tint.opacity(0.55))
                    .frame(width: 8, height: 3)

                Text(AppStrings.text(.forecast))
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppPalette.mutedText)
    }
}

struct AnalyticsEvolutionMiniSummaries: View {
    let savingsPoints: [LightweightEvolutionPoint]
    let savingsValue: String
    let creditPoints: [LightweightEvolutionPoint]
    let creditValue: String

    var body: some View {
        HStack(spacing: 12) {
            AnalyticsEvolutionMiniSummaryCard(
                kind: .savings,
                points: savingsPoints,
                value: savingsValue
            )

            AnalyticsEvolutionMiniSummaryCard(
                kind: .credits,
                points: creditPoints,
                value: creditValue
            )
        }
    }
}

private struct AnalyticsEvolutionMiniSummaryCard: View {
    let kind: LightweightEvolutionKind
    let points: [LightweightEvolutionPoint]
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: kind.systemImage)
                    .font(.caption.bold())
                    .foregroundStyle(kind.tint)
                    .frame(width: 28, height: 28)
                    .background(kind.tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(kind.title)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)

                    Text(value)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(kind.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            GeometryReader { geometry in
                let chartPoints = normalizedPoints(in: geometry.size)

                Path { path in
                    addSmoothLine(to: &path, points: chartPoints)
                }
                .stroke(
                    kind.tint,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 34)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        let safePoints = points.filter { $0.value.isFinite }
        guard safePoints.count > 1 else { return [] }

        let values = safePoints.map(\.value)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? 1
        let range = max(maximum - minimum, 1)
        guard minimum.isFinite, maximum.isFinite, range.isFinite else { return [] }

        let horizontalPadding: CGFloat = 10
        let verticalPadding: CGFloat = 12
        let width = max(size.width - horizontalPadding * 2, 1)
        let height = max(size.height - verticalPadding * 2, 1)

        return safePoints.enumerated().map { index, point in
            let x = horizontalPadding
                + width * CGFloat(index) / CGFloat(safePoints.count - 1)
            let normalizedY = (point.value - minimum) / range
            let y = verticalPadding + height * CGFloat(1 - normalizedY)
            return CGPoint(x: x, y: y)
        }
    }

    private func addSmoothLine(to path: inout Path, points: [CGPoint]) {
        guard let first = points.first else { return }
        path.move(to: first)
        guard points.count > 1 else { return }

        for index in 1..<points.count {
            let previousPrevious = points[max(index - 2, 0)]
            let previous = points[index - 1]
            let current = points[index]
            let next = points[min(index + 1, points.count - 1)]
            let tension: CGFloat = 0.42
            let control1 = CGPoint(
                x: previous.x + (current.x - previousPrevious.x) * tension / 3,
                y: previous.y + (current.y - previousPrevious.y) * tension / 3
            )
            let control2 = CGPoint(
                x: current.x - (next.x - previous.x) * tension / 3,
                y: current.y - (next.y - previous.y) * tension / 3
            )
            path.addCurve(to: current, control1: control1, control2: control2)
        }
    }
}

struct AnalyticsEvolutionMetric: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)

                Text(value)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 34, alignment: .topLeading)
    }
}
