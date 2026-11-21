import SwiftUI

struct AppIconView: View {
    var body: some View {
        Image("SpendWiseIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 34, height: 34)
    }
}

struct TopToolbarIconButton: View {
    let systemImage: String
    var badge: String? = nil
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 40, height: 40)
                    .background(AppPalette.surface.opacity(0.78), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppPalette.background.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: AppPalette.background.opacity(0.08), radius: 7, y: 3)

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 18, height: 18)
                        .background(AppPalette.primary, in: Circle())
                        .offset(x: 2, y: -2)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct PhoneBottomActionButton: View {
    let systemImage: String
    var badge: String? = nil
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppPalette.background)
                    .frame(width: 50, height: 50)
                    .background(AppPalette.surface.opacity(0.78), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppPalette.background.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: AppPalette.background.opacity(0.10), radius: 10, y: 5)

                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(AppPalette.surface)
                        .frame(width: 18, height: 18)
                        .background(AppPalette.primary, in: Circle())
                        .offset(x: 1, y: -1)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct PhoneVerticalQuickActionButton: View {
    let title: String
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 124, height: 34)
                    .background(AppPalette.surface.opacity(0.98), in: Capsule())
                    .shadow(color: AppPalette.background.opacity(0.12), radius: 8, y: 4)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .shadow(color: AppPalette.background.opacity(0.18), radius: 12, y: 7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct PhoneQuickActionsBar: View {
    let hasSavings: Bool
    let hasCredits: Bool
    let onSaving: () -> Void
    let onCredit: () -> Void
    let onIncome: () -> Void
    let onExpense: () -> Void
    let onReceipt: () -> Void

    var body: some View {
        Group {
            if hasSavings && hasCredits {
                HStack(spacing: 10) {
                    VStack(spacing: 10) {
                        savingButton
                        creditButton
                    }

                    VStack(spacing: 10) {
                        incomeButton
                        expenseButton
                        receiptButton
                    }
                }
            } else if hasSavings || hasCredits {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        incomeButton
                        expenseButton
                    }

                    receiptButton

                    if hasSavings {
                        savingButton
                    }

                    if hasCredits {
                        creditButton
                    }
                }
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        incomeButton
                        expenseButton
                    }
                    receiptButton
                }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var savingButton: some View {
        PhoneVerticalQuickActionButton(
            title: SavingsStrings.text(.saving),
            imageName: "QuickActionPoupanca",
            action: onSaving
        )
    }

    private var creditButton: some View {
        PhoneVerticalQuickActionButton(
            title: CreditStrings.text(.credit),
            imageName: "QuickActionCredito",
            action: onCredit
        )
    }

    private var incomeButton: some View {
        PhoneVerticalQuickActionButton(
            title: AppStrings.text(.income),
            imageName: "QuickActionReceita",
            action: onIncome
        )
    }

    private var expenseButton: some View {
        PhoneVerticalQuickActionButton(
            title: AppStrings.text(.expense),
            imageName: "QuickActionDespesa",
            action: onExpense
        )
    }

    private var receiptButton: some View {
        PhoneVerticalQuickActionButton(
            title: AppStrings.text(.readReceipt),
            imageName: "QuickActionLerFatura",
            action: onReceipt
        )
    }
}

struct RecurringQuickActionsBar: View {
    let onExpense: () -> Void
    let onIncome: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            PhoneVerticalQuickActionButton(
                title: AppStrings.text(.recurringExpenses),
                imageName: "QuickActionDespesa",
                action: onExpense
            )
            PhoneVerticalQuickActionButton(
                title: AppStrings.text(.recurringIncome),
                imageName: "QuickActionReceita",
                action: onIncome
            )
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
