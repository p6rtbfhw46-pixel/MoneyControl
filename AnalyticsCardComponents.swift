import SwiftUI

struct AnalyticsChartCard<HeaderAccessory: View, Content: View>: View {
    let title: String
    let total: Double
    @ViewBuilder let headerAccessory: HeaderAccessory
    @ViewBuilder let content: Content

    init(
        title: String,
        total: Double,
        @ViewBuilder headerAccessory: () -> HeaderAccessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.total = total
        self.headerAccessory = headerAccessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.background)

                Spacer()

                headerAccessory

                Text(total.currencyText)
                    .font(.subheadline.bold())
                    .foregroundStyle(total < 0 ? AppPalette.primary : AppPalette.background)
            }

            content
        }
        .padding()
        .background(AppPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: AppPalette.background.opacity(0.07), radius: 16, y: 8)
    }
}

extension AnalyticsChartCard where HeaderAccessory == EmptyView {
    init(
        title: String,
        total: Double,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            total: total,
            headerAccessory: { EmptyView() },
            content: content
        )
    }
}
