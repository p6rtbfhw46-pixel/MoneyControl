import SwiftUI

struct AnalyticsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let freeText: String
    let value: String
    let tint: Color

    init(
        icon: String,
        title: String,
        subtitle: String,
        freeText: String = "",
        value: String,
        tint: Color
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.freeText = freeText
        self.value = value
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !freeText.isEmpty {
                    Text(freeText)
                        .font(.caption.bold())
                        .foregroundStyle(AppPalette.background)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AnalyticsHistoryRow: View {
    let line: AnalyticsHistoryLine

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: line.icon)
                .font(.caption.bold())
                .foregroundStyle(line.tint)
                .frame(width: 30, height: 30)
                .background(line.tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppPalette.background)
                    .lineLimit(2)

                Text(line.type)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)
                    .lineLimit(2)

                Text(line.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.mutedText)

                if !line.note.isEmpty {
                    Text(line.note)
                        .font(.caption)
                        .foregroundStyle(AppPalette.mutedText)
                        .lineLimit(4)
                }
            }

            Spacer(minLength: 8)

            Text(line.amountText)
                .font(.subheadline.bold())
                .foregroundStyle(line.amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .background(AppPalette.appBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
