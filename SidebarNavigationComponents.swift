import SwiftUI

struct SidebarSectionHeaderLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppPalette.background)
            .labelStyle(.titleAndIcon)
    }
}

struct SidebarHeaderIcon: View {
    let systemImage: String
    let badge: String?

    init(systemImage: String, badge: String? = nil) {
        self.systemImage = systemImage
        self.badge = badge
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppPalette.background)
                .frame(width: 28, height: 28)
                .background(AppPalette.surface.opacity(0.95), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(AppPalette.background.opacity(0.12), lineWidth: 1)
                }

            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppPalette.surface)
                    .frame(width: 14, height: 14)
                    .background(AppPalette.primary, in: Circle())
                    .offset(x: 2, y: -2)
            }
        }
        .contentShape(Circle())
    }
}

struct SidebarSubmenuLabel: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isSelected ? AppPalette.primary : AppPalette.separator)
                .frame(width: 4, height: 28)

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? AppPalette.primary : AppPalette.mutedText)
                .frame(width: 24, height: 24)
                .background(
                    isSelected ? AppPalette.paleOrange : AppPalette.surface.opacity(0.7),
                    in: Circle()
                )

            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppPalette.background : AppPalette.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected ? AppPalette.paleOrange.opacity(0.48) : AppPalette.surface.opacity(0.38),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SidebarSubmenuButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarSubmenuLabel(
                title: title,
                systemImage: systemImage,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 10))
        .listRowBackground(Color.clear)
    }
}

struct SidebarHeaderActionButton: View {
    let systemImage: String
    let badge: String?
    let accessibilityLabel: String
    let action: () -> Void

    init(
        systemImage: String,
        badge: String? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.badge = badge
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            SidebarHeaderIcon(systemImage: systemImage, badge: badge)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct CurrentAccountSidebarHeader: View {
    let systemImage: String
    let activeFilterCount: Int
    let showsQuickActions: Bool
    let onFilters: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SidebarSectionHeaderLabel(
                title: AppStrings.text(.currentAccount),
                systemImage: systemImage
            )

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                SidebarHeaderActionButton(
                    systemImage: "line.3.horizontal.decrease",
                    badge: activeFilterCount > 0 ? "\(activeFilterCount)" : nil,
                    accessibilityLabel: AppStrings.text(.filters),
                    action: onFilters
                )
                SidebarHeaderActionButton(
                    systemImage: showsQuickActions ? "xmark" : "plus",
                    accessibilityLabel: AppStrings.text(.add),
                    action: onAdd
                )
            }
        }
    }
}

struct RecurringSidebarHeader: View {
    let showsQuickActions: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SidebarSectionHeaderLabel(
                title: AppStrings.text(.budgetSettings),
                systemImage: "arrow.triangle.2.circlepath"
            )

            Spacer(minLength: 8)

            SidebarHeaderActionButton(
                systemImage: showsQuickActions ? "xmark" : "plus",
                accessibilityLabel: AppStrings.text(.add),
                action: onAdd
            )
        }
    }
}
