import Foundation

actor SonarrAPIService {
    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case serverError(Int, String?)
        case alreadyExists

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL. Check your server settings."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Could not parse server response: \(error.localizedDescription)"
            case .serverError(let code, let message):
                if code == 400, let msg = message, msg.contains("already") {
                    return "This show already exists in Sonarr."
                }
                return "Server error (\(code))\(message.map { ": \($0)" } ?? "")"
            case .alreadyExists:
                return "This show is already in your Sonarr library."
            }
        }
    }

    private func makeRequest(ip: String, port: String, apiKey: String, path: String) throws -> URLRequest {
        guard let url = URL(string: "http://\(ip):\(port)/api/v3/\(path)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8)
            if http.statusCode == 400 {
                // Check for "already exists" in Sonarr error response
                if let body, body.lowercased().contains("already") {
                    throw APIError.alreadyExists
                }
            }
            throw APIError.serverError(http.statusCode, body)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func searchSeries(ip: String, port: String, apiKey: String, term: String) async throws -> [SeriesSearchResult] {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let request = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series/lookup?term=\(encoded)")
        return try await performRequest(request)
    }

    func fetchRootFolders(ip: String, port: String, apiKey: String) async throws -> [RootFolder] {
        let request = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "rootfolder")
        return try await performRequest(request)
    }

    func fetchQualityProfiles(ip: String, port: String, apiKey: String) async throws -> [QualityProfile] {
        let request = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "qualityprofile")
        return try await performRequest(request)
    }

    func addSeries(
        ip: String,
        port: String,
        apiKey: String,
        series: SeriesSearchResult,
        rootFolderPath: String,
        qualityProfileId: Int,
        monitor: MonitorOption,
        searchForMissingEpisodes: Bool
    ) async throws {
        var request = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AddSeriesRequest(
            title: series.title,
            tvdbId: series.tvdbId,
            qualityProfileId: qualityProfileId,
            rootFolderPath: rootFolderPath,
            monitored: true,
            titleSlug: series.titleSlug,
            seasons: [],
            addOptions: AddSeriesRequest.AddOptions(
                monitor: monitor.rawValue,
                searchForMissingEpisodes: searchForMissingEpisodes
            )
        )

        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8)
            if http.statusCode == 400, let body, body.lowercased().contains("already") {
                throw APIError.alreadyExists
            }
            throw APIError.serverError(http.statusCode, body)
        }
    }
}
