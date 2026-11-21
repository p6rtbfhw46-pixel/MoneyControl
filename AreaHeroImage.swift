import SwiftUI

struct AreaHeroImage: View {
    let name: String
    let aspectRatio: CGFloat
    let horizontalPadding: CGFloat
    let usesSidebarNavigation: Bool

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(effectiveAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: AppPalette.background.opacity(0.10), radius: 18, y: 8)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 8)
            .padding(.bottom, 8)
    }

    private var effectiveAspectRatio: CGFloat {
        usesSidebarNavigation ? aspectRatio / 0.8 : aspectRatio
    }
}
