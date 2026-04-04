import Foundation

struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let summary: String
    let description: String
    let startDate: Date
    let endDate: Date
    let categories: String
    let status: String

    // Parsed from summary format: "Show Name - SxxExx - Episode Title"
    var showName: String {
        let parts = summary.components(separatedBy: " - ")
        return parts.first ?? summary
    }

    var episodeNumber: String {
        let parts = summary.components(separatedBy: " - ")
        guard parts.count >= 2 else { return "" }
        return parts[1]
    }

    // Parses "8x13" into season number "8"
    var seasonNumber: String {
        let parts = episodeNumber.lowercased().components(separatedBy: "x")
        guard parts.count == 2 else { return "" }
        return parts[0]
    }

    // Parses "8x13" into episode number "13"
    var episodeOnly: String {
        let parts = episodeNumber.lowercased().components(separatedBy: "x")
        guard parts.count == 2 else { return "" }
        return parts[1]
    }

    var episodeTitle: String {
        let parts = summary.components(separatedBy: " - ")
        guard parts.count >= 3 else { return "" }
        return parts.dropFirst(2).joined(separator: " - ")
    }

    var isConfirmed: Bool {
        status.uppercased() == "CONFIRMED"
    }
}
