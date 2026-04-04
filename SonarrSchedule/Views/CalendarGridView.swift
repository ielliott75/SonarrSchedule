import SwiftUI

struct CalendarGridView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var selectedEvent: CalendarEvent?

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 40) {
                weekSection(title: "This Week", days: Array(viewModel.daysInRange.prefix(7)))
                weekSection(title: "Next Week", days: Array(viewModel.daysInRange.suffix(7)))
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 60)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }

    private func weekSection(title: String, days: [Date]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            HStack(alignment: .top, spacing: 30) {
                ForEach(days, id: \.self) { date in
                    DayColumnView(
                        date: date,
                        events: viewModel.events(for: date),
                        selectedEvent: $selectedEvent
                    )
                    .focusSection()
                }
            }
        }
    }
}

struct DayColumnView: View {
    let date: Date
    let events: [CalendarEvent]
    @Binding var selectedEvent: CalendarEvent?

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Day header
            VStack(spacing: 1) {
                Text(date, format: .dateTime.weekday(.abbreviated))
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .blue : .gray)
                    .textCase(.uppercase)

                Text(date, format: .dateTime.day())
                    .font(.system(size: 20))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .blue : .white)
            }
            .padding(.bottom, 4)

            if events.isEmpty {
                Text("No shows")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
            } else {
                ForEach(events) { event in
                    EventCardView(event: event) {
                        selectedEvent = event
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
