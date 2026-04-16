import SwiftUI

struct EventCardView: View {
    let event: CalendarEvent
    let onSelect: () -> Void
    @Environment(\.isFocused) private var isFocused

    private var statusColor: Color {
        event.isConfirmed ? .green : .red
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                // Network badge
                Text(event.categories)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                // Show name
                Text(event.showName)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Season & Episode on separate lines
                if !event.seasonNumber.isEmpty {
                    Text("Season: \(event.seasonNumber)")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }
                if !event.episodeOnly.isEmpty {
                    Text("Episode: \(event.episodeOnly)")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }

                // Time
                Text("Time: \(event.startDate, format: .dateTime.hour().minute())")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.75))

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(event.isConfirmed ? "Confirmed" : "Tentative")
                        .font(.system(size: 14))
                        .foregroundColor(statusColor)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.card)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
