import Foundation
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefresh: Date?

    // Settings with defaults from the Sonarr URL
    @Published var ipAddress: String {
        didSet { UserDefaults.standard.set(ipAddress, forKey: "ipAddress") }
    }
    @Published var port: String {
        didSet { UserDefaults.standard.set(port, forKey: "port") }
    }
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "apiKey") }
    }

    private let service = ICalService()
    private var refreshTimer: Timer?

    // 12 hours in seconds
    private let refreshInterval: TimeInterval = 12 * 60 * 60

    init() {
        self.ipAddress = UserDefaults.standard.string(forKey: "ipAddress") ?? "192.168.86.200"
        self.port = UserDefaults.standard.string(forKey: "port") ?? "8989"
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? "94939d6242474e4b88a9e483e1f4659b"

        startAutoRefresh()
    }

    var daysInRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }

    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await service.fetchEvents(ip: ipAddress, port: port, apiKey: apiKey)
            events = fetched
            lastRefresh = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchEvents()
            }
        }
    }

    func saveSettings(ip: String, port: String, apiKey: String) {
        self.ipAddress = ip
        self.port = port
        self.apiKey = apiKey
        Task {
            await fetchEvents()
        }
    }
}
