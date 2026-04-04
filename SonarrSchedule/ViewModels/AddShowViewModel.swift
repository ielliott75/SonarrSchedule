import Foundation

@MainActor
class AddShowViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SeriesSearchResult] = []
    @Published var isSearching = false
    @Published var searchError: String?

    @Published var rootFolders: [RootFolder] = []
    @Published var qualityProfiles: [QualityProfile] = []
    @Published var isLoadingOptions = false

    @Published var isAdding = false
    @Published var addError: String?
    @Published var addSuccess = false

    private let service = SonarrAPIService()

    func search(ip: String, port: String, apiKey: String) async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        searchError = nil
        searchResults = []

        do {
            searchResults = try await service.searchSeries(ip: ip, port: port, apiKey: apiKey, term: searchQuery)
        } catch {
            searchError = error.localizedDescription
        }

        isSearching = false
    }

    func loadOptions(ip: String, port: String, apiKey: String) async {
        isLoadingOptions = true
        async let folders = service.fetchRootFolders(ip: ip, port: port, apiKey: apiKey)
        async let profiles = service.fetchQualityProfiles(ip: ip, port: port, apiKey: apiKey)

        do {
            let (f, p) = try await (folders, profiles)
            rootFolders = f
            qualityProfiles = p
        } catch {
            // Non-fatal — user can still try to add, error will surface then
        }

        isLoadingOptions = false
    }

    func addShow(
        _ series: SeriesSearchResult,
        rootFolderPath: String,
        qualityProfileId: Int,
        monitor: MonitorOption,
        searchForMissingEpisodes: Bool,
        ip: String,
        port: String,
        apiKey: String
    ) async {
        isAdding = true
        addError = nil
        addSuccess = false

        do {
            try await service.addSeries(
                ip: ip,
                port: port,
                apiKey: apiKey,
                series: series,
                rootFolderPath: rootFolderPath,
                qualityProfileId: qualityProfileId,
                monitor: monitor,
                searchForMissingEpisodes: searchForMissingEpisodes
            )
            addSuccess = true
        } catch {
            addError = error.localizedDescription
        }

        isAdding = false
    }

    func resetAddState() {
        addError = nil
        addSuccess = false
    }
}
