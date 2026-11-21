import SwiftUI

struct SidebarNavigationLayout<Sidebar: View, Detail: View, BottomActions: View>: View {
    @ViewBuilder let sidebar: Sidebar
    @ViewBuilder let detail: Detail
    @ViewBuilder let bottomActions: BottomActions

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            NavigationStack {
                detail
                    .safeAreaInset(edge: .bottom) {
                        bottomActions
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct SidebarMainContent<Content: View, Trailing: View>: View {
    let title: String
    @Binding var selectedSaving: SavingAccount?
    @Binding var selectedCredit: CreditAccount?
    @ViewBuilder let content: Content
    @ViewBuilder let trailing: Trailing

    var body: some View {
        content
            .background {
                AppPalette.appBackground
                    .ignoresSafeArea()
                    .backgroundExtensionEffectIfAvailable()
            }
            .toolbarBackground(AppPalette.appBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedSaving) { saving in
                SavingDetailView(saving: saving)
            }
            .navigationDestination(item: $selectedCredit) { credit in
                CreditDetailView(credit: credit)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    AppIconView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    trailing
                }
            }
    }
}
