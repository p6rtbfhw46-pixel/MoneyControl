import SwiftUI

struct CurrentAccountMonthHeader: View {
    let month: Date
    let showsCurrentDay: Bool
    let currentDayNumber: Int
    let usesSidebarNavigation: Bool
    let canMoveToPreviousMonth: Bool
    let canMoveToNextMonth: Bool
    let moveToPreviousMonth: () -> Void
    let moveToNextMonth: () -> Void

    var body: some View {
        HStack(spacing: usesSidebarNavigation ? 16 : 10) {
            monthArrowButton(
                systemImage: "chevron.left",
                isEnabled: canMoveToPreviousMonth,
                action: moveToPreviousMonth
            )

            VStack(alignment: .center, spacing: 2) {
                Text(month.monthTitle)
                    .font((usesSidebarNavigation ? Font.title : Font.title2).bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if showsCurrentDay {
                    Text("\(AppStrings.text(.day)) \(currentDayNumber)")
                        .font(usesSidebarNavigation ? .title3 : .subheadline)
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            monthArrowButton(
                systemImage: "chevron.right",
                isEnabled: canMoveToNextMonth,
                action: moveToNextMonth
            )
        }
        .padding(.horizontal, usesSidebarNavigation ? 28 : 22)
        .padding(.top, usesSidebarNavigation ? 8 : 2)
        .padding(.bottom, usesSidebarNavigation ? 6 : 2)
        .background(AppPalette.appBackground)
    }

    private func monthArrowButton(
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font((usesSidebarNavigation ? Font.title3 : Font.body).weight(.semibold))
                .foregroundStyle(AppPalette.primary)
                .frame(
                    width: usesSidebarNavigation ? 44 : 38,
                    height: usesSidebarNavigation ? 44 : 38
                )
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, AppPalette.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 1)
                        }
                        .shadow(
                            color: AppPalette.background.opacity(0.12),
                            radius: 10,
                            y: 5
                        )
                        .shadow(
                            color: .white.opacity(0.85),
                            radius: 2,
                            x: -1,
                            y: -1
                        )
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
    }
}
