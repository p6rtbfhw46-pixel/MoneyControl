import SwiftUI

struct SidebarAnalyticsScreen<Content: View>: View {
    let heroName: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                AreaHeroImage(
                    name: heroName,
                    aspectRatio: 1334.0 / 298.0,
                    horizontalPadding: 0,
                    usesSidebarNavigation: true
                )
                .padding(.top, -8)
                .padding(.bottom, -8)

                content
            }
            .padding()
        }
        .background(AppPalette.appBackground)
    }
}

struct PhoneAnalyticsScreen<Content: View>: View {
    let heroName: String
    @Binding var selection: AnalyticsSidebarTab
    let tabs: [AnalyticsSidebarTab]
    let onAppear: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 22
            let contentWidth = max(proxy.size.width - (horizontalPadding * 2), 0)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AreaHeroImage(
                        name: heroName,
                        aspectRatio: 1334.0 / 298.0,
                        horizontalPadding: 0,
                        usesSidebarNavigation: false
                    )
                    .padding(.top, -8)
                    .padding(.bottom, -8)
                    .frame(width: contentWidth)

                    AnalyticsPhoneTabPicker(selection: $selection, tabs: tabs)
                        .frame(width: contentWidth, alignment: .leading)

                    content
                        .frame(width: contentWidth, alignment: .leading)
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 16)
            }
            .background(AppPalette.appBackground)
        }
        .onAppear(perform: onAppear)
    }
}
