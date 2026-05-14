import Foundation

actor ICalService {
    enum ServiceError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidData

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid calendar URL. Check your settings."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidData:
                return "Could not parse calendar data."
            }
        }
    }

    func fetchEvents(ip: String, port: String, apiKey: String) async throws -> [CalendarEvent] {
        let urlString = "http://\(ip):\(port)/feed/v3/calendar/Sonarr.ics?unmonitored=true&apikey=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw ServiceError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await URLSession.shared.data(from: url)
            data = responseData
        } catch {
            throw ServiceError.networkError(error)
        }

        guard let icalString = String(data: data, encoding: .utf8) else {
            throw ServiceError.invalidData
        }

        return ICalParser.parse(icalString)
    }
}
