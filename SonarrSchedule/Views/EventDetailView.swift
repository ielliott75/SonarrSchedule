import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss

    private var statusColor: Color {
        event.isConfirmed ? .green : .orange
    }

    private var formattedDuration: String {
        let interval = event.endDate.timeIntervalSince(event.startDate)
        let minutes = Int(interval) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // Network
                Text(event.categories)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                // Show name
                Text(event.showName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Episode
                if !event.episodeNumber.isEmpty || !event.episodeTitle.isEmpty {
                    HStack(spacing: 8) {
                        if !event.episodeNumber.isEmpty {
                            Text(event.episodeNumber)
                                .fontWeight(.semibold)
                        }
                        if !event.episodeNumber.isEmpty && !event.episodeTitle.isEmpty {
                            Text("•")
                                .foregroundColor(.gray)
                        }
                        if !event.episodeTitle.isEmpty {
                            Text(event.episodeTitle)
                        }
                    }
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
                }

                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(event.isConfirmed ? "Confirmed" : "Tentative")
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
                .font(.body)
                .padding(.top, 4)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)

            // Details grid
            VStack(spacing: 20) {
                detailRow(icon: "calendar", label: "Date",
                          value: event.startDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))

                detailRow(icon: "clock", label: "Time",
                          value: "\(event.startDate.formatted(.dateTime.hour().minute())) – \(event.endDate.formatted(.dateTime.hour().minute()))")

                detailRow(icon: "timer", label: "Duration",
                          value: formattedDuration)

                detailRow(icon: "tv", label: "Network",
                          value: event.categories)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Description")
                        .foregroundColor(.gray)
                        .frame(width: 200, alignment: .leading)
                    if event.description.isEmpty {
                        Text("No episode description available at this time.")
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                            .lineSpacing(4)
                    } else {
                        Text(event.description)
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                    Spacer()
                }
                .font(.body)
            }
            .padding(.horizontal, 80)

            Spacer()

            Button("Close") {
                dismiss()
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.95))
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(label)
                .foregroundColor(.gray)
                .frame(width: 200, alignment: .leading)
            Text(value)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.body)
    }
}
