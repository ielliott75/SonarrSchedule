import Foundation

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var series: [LibrarySeries] = []
    @Published var qualityProfiles: [QualityProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SonarrAPIService()

    var sortedSeries: [LibrarySeries] {
        series.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func fetch(ip: String, port: String, apiKey: String) async {
        isLoading = true
        errorMessage = nil
        async let seriesFetch = service.fetchAllSeries(ip: ip, port: port, apiKey: apiKey)
        async let profilesFetch = service.fetchQualityProfiles(ip: ip, port: port, apiKey: apiKey)
        do {
            series = try await seriesFetch
        } catch {
            errorMessage = error.localizedDescription
        }
        if let profiles = try? await profilesFetch {
            qualityProfiles = profiles
        }
        isLoading = false
    }
}
