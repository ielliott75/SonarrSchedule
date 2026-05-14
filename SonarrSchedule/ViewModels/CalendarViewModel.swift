import Foundation
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var monitoredSeriesTitles: Set<String> = []
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
    private let sonarrService = SonarrAPIService()
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
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Calculate days since Monday (weekday: 2=Mon ... 1=Sun)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        return (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchEvents() async {
        isLoading = true
        errorMessage = nil

        async let calendarFetch = service.fetchEvents(ip: ipAddress, port: port, apiKey: apiKey)
        async let seriesFetch = sonarrService.fetchAllSeries(ip: ipAddress, port: port, apiKey: apiKey)

        do {
            events = try await calendarFetch
            lastRefresh = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        if let series = try? await seriesFetch {
            monitoredSeriesTitles = Set(series.filter { $0.monitored }.map { $0.title })
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
