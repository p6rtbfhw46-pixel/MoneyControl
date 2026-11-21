import SwiftUI

extension View {
    @ViewBuilder
    func backgroundExtensionEffectIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.backgroundExtensionEffect()
        } else {
            self
        }
    }

    @ViewBuilder
    func minimizeTabBarOnScrollDownIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }

    func phoneTabRootStyle(title: String) -> some View {
        background {
            AppPalette.appBackground
                .ignoresSafeArea()
                .backgroundExtensionEffectIfAvailable()
        }
        .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PhoneTabNavigationRoot<Content: View, Leading: View, Trailing: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        NavigationStack {
            content
                .phoneTabRootStyle(title: title)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        leading
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        trailing
                    }
                }
        }
    }
}

struct PhoneActionPlaceholder: View {
    var body: some View {
        Color.clear
            .background(AppPalette.appBackground.ignoresSafeArea())
    }
}
