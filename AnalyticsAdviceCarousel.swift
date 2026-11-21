import SwiftUI

struct AnalyticsAdviceCarousel: View {
    @Binding var selectedIndex: Int

    private var adviceCards: [(title: String, message: String)] {
        AppStrings.analyticsAdviceCards
    }

    private var currentAdvice: (title: String, message: String) {
        guard !adviceCards.isEmpty else { return ("", "") }
        let index = abs(selectedIndex) % adviceCards.count
        return adviceCards[index]
    }

    var body: some View {
        if !adviceCards.isEmpty {
            HStack(spacing: 12) {
                navigationButton(systemImage: "chevron.left") {
                    move(by: -1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentAdvice.title)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.primary)
                        .lineLimit(1)

                    Text(currentAdvice.message)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .id(selectedIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer(minLength: 0)

                navigationButton(systemImage: "chevron.right") {
                    move(by: 1)
                }
            }
            .padding(14)
            .background(AppPalette.mintSurface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppPalette.secondary.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: AppPalette.background.opacity(0.06), radius: 14, y: 7)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard adviceCards.count > 1, abs(value.translation.width) > 36 else {
                            return
                        }
                        move(by: value.translation.width < 0 ? 1 : -1)
                    }
            )
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(25))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        move(by: 1)
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

    private func move(by offset: Int) {
        guard !adviceCards.isEmpty else { return }

        withAnimation(.snappy) {
            selectedIndex = (selectedIndex + offset + adviceCards.count) % adviceCards.count
        }
    }
}
