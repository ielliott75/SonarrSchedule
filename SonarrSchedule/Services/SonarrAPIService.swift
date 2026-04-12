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

    func fetchAllSeries(ip: String, port: String, apiKey: String) async throws -> [LibrarySeries] {
        let request = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series")
        return try await performRequest(request)
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

    func fetchLanguageProfiles(ip: String, port: String, apiKey: String) async throws -> [LanguageProfile] {
        let request = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "languageprofile")
        return try await performRequest(request)
    }

    func addSeries(
        ip: String,
        port: String,
        apiKey: String,
        series: SeriesSearchResult,
        rootFolderPath: String,
        qualityProfileId: Int,
        languageProfileId: Int,
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
            languageProfileId: languageProfileId,
            rootFolderPath: rootFolderPath,
            monitored: true,
            titleSlug: series.titleSlug,
            seasons: series.seasons ?? [],
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
            let responseBody = String(data: data, encoding: .utf8)
            if http.statusCode == 400, let responseBody, responseBody.lowercased().contains("already") {
                throw APIError.alreadyExists
            }
            // Extract the most useful part of Sonarr's validation error
            if let responseBody, let errorMessage = extractSonarrError(from: responseBody) {
                throw APIError.serverError(http.statusCode, errorMessage)
            }
            throw APIError.serverError(http.statusCode, responseBody)
        }
    }

    func updateSeriesById(
        ip: String,
        port: String,
        apiKey: String,
        seriesId: Int,
        qualityProfileId: Int,
        monitored: Bool
    ) async throws {
        // GET the full current series object
        let getRequest = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series/\(seriesId)")
        let (getData, getResponse) = try await URLSession.shared.data(for: getRequest)

        guard let http = getResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              var series = try? JSONSerialization.jsonObject(with: getData) as? [String: Any] else {
            throw APIError.serverError(404, "Could not fetch series to update.")
        }

        series["qualityProfileId"] = qualityProfileId
        series["monitored"] = monitored

        let putData = try JSONSerialization.data(withJSONObject: series)
        var putRequest = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series/\(seriesId)")
        putRequest.httpMethod = "PUT"
        putRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        putRequest.httpBody = putData

        let (responseData, putResponse) = try await URLSession.shared.data(for: putRequest)
        if let http = putResponse as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: responseData, encoding: .utf8)
            if let body, let msg = extractSonarrError(from: body) { throw APIError.serverError(http.statusCode, msg) }
            throw APIError.serverError(http.statusCode, String(data: responseData, encoding: .utf8))
        }
    }

    func updateSeries(
        ip: String,
        port: String,
        apiKey: String,
        tvdbId: Int,
        qualityProfileId: Int,
        languageProfileId: Int,
        monitor: MonitorOption
    ) async throws {
        // Fetch all series and find the matching one by tvdbId
        let allRequest = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series")
        let (allData, allResponse) = try await URLSession.shared.data(for: allRequest)

        guard let http = allResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let seriesList = try? JSONSerialization.jsonObject(with: allData) as? [[String: Any]],
              let existing = seriesList.first(where: { ($0["tvdbId"] as? Int) == tvdbId }),
              let seriesId = existing["id"] as? Int else {
            throw APIError.serverError(404, "Could not find existing series to update.")
        }

        // Patch the fields we care about
        var updated = existing
        updated["qualityProfileId"] = qualityProfileId
        updated["languageProfileId"] = languageProfileId
        updated["monitored"] = true

        // Update monitor type on each season based on the monitor option
        if var seasons = updated["seasons"] as? [[String: Any]] {
            for i in seasons.indices {
                seasons[i]["monitored"] = (monitor != .none)
            }
            updated["seasons"] = seasons
        }

        let putData = try JSONSerialization.data(withJSONObject: updated)

        var putRequest = try makeRequest(ip: ip, port: port, apiKey: apiKey, path: "series/\(seriesId)")
        putRequest.httpMethod = "PUT"
        putRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        putRequest.httpBody = putData

        let (responseData, putResponse) = try await URLSession.shared.data(for: putRequest)

        if let http = putResponse as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: responseData, encoding: .utf8)
            if let body, let errorMessage = extractSonarrError(from: body) {
                throw APIError.serverError(http.statusCode, errorMessage)
            }
            throw APIError.serverError(http.statusCode, String(data: responseData, encoding: .utf8))
        }
    }

    private func extractSonarrError(from body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        // Sonarr v4 wraps errors in { "message": "...", "description": "..." }
        if let message = json["message"] as? String {
            if let description = json["description"] as? String {
                return "\(message): \(description)"
            }
            return message
        }
        return nil
    }
}
