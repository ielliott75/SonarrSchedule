import Foundation

@MainActor
class AddShowViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [SeriesSearchResult] = []
    @Published var isSearching = false
    @Published var searchError: String?

    @Published var rootFolders: [RootFolder] = []
    @Published var qualityProfiles: [QualityProfile] = []
    @Published var languageProfiles: [LanguageProfile] = []
    @Published var isLoadingOptions = false

    @Published var isAdding = false
    @Published var addError: String?
    @Published var addSuccess = false
    @Published var showUpdatePrompt = false

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
        async let langProfiles = service.fetchLanguageProfiles(ip: ip, port: port, apiKey: apiKey)

        do {
            let (f, p) = try await (folders, profiles)
            rootFolders = f
            qualityProfiles = p
        } catch {}

        // Language profiles only exist in Sonarr v3 — ignore failure on v4
        if let lp = try? await langProfiles {
            languageProfiles = lp
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

        let languageProfileId = languageProfiles.first?.id ?? 1

        do {
            try await service.addSeries(
                ip: ip,
                port: port,
                apiKey: apiKey,
                series: series,
                rootFolderPath: rootFolderPath,
                qualityProfileId: qualityProfileId,
                languageProfileId: languageProfileId,
                monitor: monitor,
                searchForMissingEpisodes: searchForMissingEpisodes
            )
            addSuccess = true
        } catch SonarrAPIService.APIError.alreadyExists {
            showUpdatePrompt = true
        } catch {
            addError = error.localizedDescription
        }

        isAdding = false
    }

    func updateShow(
        _ series: SeriesSearchResult,
        qualityProfileId: Int,
        monitor: MonitorOption,
        ip: String,
        port: String,
        apiKey: String
    ) async {
        isAdding = true
        addError = nil
        showUpdatePrompt = false

        let languageProfileId = languageProfiles.first?.id ?? 1

        do {
            try await service.updateSeries(
                ip: ip,
                port: port,
                apiKey: apiKey,
                tvdbId: series.tvdbId,
                qualityProfileId: qualityProfileId,
                languageProfileId: languageProfileId,
                monitor: monitor
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
        showUpdatePrompt = false
    }
}
