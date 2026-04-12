import Foundation
import SwiftUI

struct Season: Codable {
    let seasonNumber: Int
    let monitored: Bool
}

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
    let seasons: [Season]?

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

struct LanguageProfile: Identifiable, Codable {
    let id: Int
    let name: String
}

enum MonitorOption: String, CaseIterable {
    case all = "all"
    case future = "future"
    case missing = "missing"
    case existing = "existing"
    case firstSeason = "firstSeason"
    case lastSeason = "lastSeason"
    case latestSeason = "latestSeason"
    case none = "none"

    var displayName: String {
        switch self {
        case .all: return "All Episodes"
        case .future: return "Future Episodes"
        case .missing: return "Missing Episodes"
        case .existing: return "Existing Episodes"
        case .firstSeason: return "First Season"
        case .lastSeason: return "Last Season"
        case .latestSeason: return "Latest Season"
        case .none: return "None"
        }
    }
}

struct SeriesImage: Codable {
    let coverType: String
    let remoteUrl: String?
}

struct LibrarySeries: Identifiable, Codable {
    let id: Int
    let tvdbId: Int?
    let title: String
    let year: Int?
    let overview: String?
    let network: String?
    let status: String?
    let monitored: Bool
    let qualityProfileId: Int?
    let images: [SeriesImage]?
    let genres: [String]?
    let statistics: SeriesStatistics?

    var remotePoster: String? {
        images?.first(where: { $0.coverType == "poster" })?.remoteUrl
    }

    var statusDisplay: String {
        switch status?.lowercased() {
        case "continuing": return "Continuing"
        case "ended": return "Ended"
        case "upcoming": return "Upcoming"
        default: return status?.capitalized ?? "Unknown"
        }
    }

    var statusColor: Color {
        switch status?.lowercased() {
        case "continuing": return .green
        case "ended": return .gray
        case "upcoming": return .blue
        default: return .gray
        }
    }
}

struct SeriesStatistics: Codable {
    let episodeCount: Int?
    let episodeFileCount: Int?
    let percentOfEpisodes: Double?
    let sizeOnDisk: Int?
}

struct AddSeriesRequest: Codable {
    let title: String
    let tvdbId: Int
    let qualityProfileId: Int
    let languageProfileId: Int
    let rootFolderPath: String
    let monitored: Bool
    let titleSlug: String?
    let seasons: [Season]
    let addOptions: AddOptions

    struct AddOptions: Codable {
        let monitor: String
        let searchForMissingEpisodes: Bool
    }
}
