import Foundation

struct SeriesSearchResult: Identifiable, Codable {
    let tvdbId: Int
    let title: String
    let year: Int?
    let overview: String?
    let network: String?
    let status: String?
    let remotePoster: String?
    let titleSlug: String?
    let genres: [String]?

    var id: Int { tvdbId }

    var statusDisplay: String {
        switch status?.lowercased() {
        case "continuing": return "Continuing"
        case "ended": return "Ended"
        case "upcoming": return "Upcoming"
        default: return status?.capitalized ?? "Unknown"
        }
    }

    var statusColor: String {
        switch status?.lowercased() {
        case "continuing": return "green"
        case "ended": return "gray"
        case "upcoming": return "blue"
        default: return "gray"
        }
    }
}

struct RootFolder: Identifiable, Codable {
    let id: Int
    let path: String
}

struct QualityProfile: Identifiable, Codable {
    let id: Int
    let name: String
}

enum MonitorOption: String, CaseIterable {
    case all = "all"
    case future = "future"
    case missing = "missing"
    case existing = "existing"
    case first = "first"
    case latest = "latest"
    case none = "none"

    var displayName: String {
        switch self {
        case .all: return "All Episodes"
        case .future: return "Future Episodes Only"
        case .missing: return "Missing Episodes"
        case .existing: return "Existing Episodes"
        case .first: return "First Season"
        case .latest: return "Latest Season"
        case .none: return "None"
        }
    }
}

struct AddSeriesRequest: Codable {
    let title: String
    let tvdbId: Int
    let qualityProfileId: Int
    let rootFolderPath: String
    let monitored: Bool
    let titleSlug: String?
    let seasons: [CodableSeason]
    let addOptions: AddOptions

    struct AddOptions: Codable {
        let monitor: String
        let searchForMissingEpisodes: Bool
    }

    struct CodableSeason: Codable {}
}
