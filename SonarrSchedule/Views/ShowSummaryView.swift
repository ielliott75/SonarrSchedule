import SwiftUI

struct ShowSummaryView: View {
    let show: LibrarySeries
    let qualityProfiles: [QualityProfile]
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedQualityProfileIndex = 0
    @State private var monitored = true
    @State private var showQualityPicker = false
    @State private var isUpdating = false
    @State private var updateError: String?
    @State private var updateSuccess = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var seasonMonitoring: [Int: Bool] = [:]
    @State private var showSeasonPicker = false

    private let service = SonarrAPIService()

    private var progressFraction: Double {
        guard let total = show.statistics?.episodeCount, total > 0,
              let have = show.statistics?.episodeFileCount else { return 0 }
        return Double(have) / Double(total)
    }

    private var selectedQualityProfileId: Int {
        qualityProfiles.indices.contains(selectedQualityProfileIndex)
            ? qualityProfiles[selectedQualityProfileIndex].id : show.qualityProfileId ?? 1
    }

    private var sortedSeasons: [Season] {
        (show.seasons ?? []).sorted { $0.seasonNumber < $1.seasonNumber }
    }

    private var monitoredSeasonsSummary: String {
        let total = sortedSeasons.count
        guard total > 0 else { return "" }
        let monitoredCount = sortedSeasons.filter { seasonMonitoring[$0.seasonNumber] ?? $0.monitored }.count
        if monitoredCount == total { return "All" }
        if monitoredCount == 0 { return "None" }
        return "\(monitoredCount) of \(total)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 30) {
                AsyncImage(url: show.remotePoster.flatMap(URL.init)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .overlay(Image(systemName: "tv").font(.title).foregroundColor(.gray))
                }
                .frame(width: 140, height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 10) {
                    Text(show.title)
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)

                    HStack(spacing: 12) {
                        if let year = show.year { Text(String(year)).foregroundColor(.gray) }
                        if let network = show.network { Text(network).foregroundColor(.gray) }
                        HStack(spacing: 6) {
                            Circle().fill(show.statusColor).frame(width: 7, height: 7)
                            Text(show.statusDisplay).foregroundColor(show.statusColor)
                        }
                    }
                    .font(.callout)

                    if let genres = show.genres, !genres.isEmpty {
                        Text(genres.prefix(4).joined(separator: " · "))
                            .font(.callout).foregroundColor(.white.opacity(0.5))
                    }

                    if let stats = show.statistics, let total = stats.episodeCount, total > 0,
                       let have = stats.episodeFileCount {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(have) of \(total) episodes")
                                .font(.callout).foregroundColor(.white.opacity(0.6))
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.15))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(progressFraction >= 1.0 ? Color.green : Color.blue)
                                        .frame(width: geo.size.width * progressFraction)
                                }
                            }
                            .frame(width: 260, height: 5)
                            if let size = stats.sizeOnDisk, size > 0 {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                    .font(.caption).foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 80)
            .padding(.top, 50)
            .padding(.bottom, 20)

            if let overview = show.overview, !overview.isEmpty {
                Text(overview)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 80)
                    .padding(.bottom, 16)
            }

            Divider().background(Color.white.opacity(0.15))

            // Edit settings
            List {
                Section("Configuration") {
                    if !qualityProfiles.isEmpty {
                        Button {
                            showQualityPicker = true
                        } label: {
                            HStack {
                                Text("Quality Profile").foregroundStyle(.primary)
                                Spacer()
                                Text(qualityProfiles.indices.contains(selectedQualityProfileIndex)
                                     ? qualityProfiles[selectedQualityProfileIndex].name : "")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(isUpdating)
                    }

                    Toggle("Monitored", isOn: $monitored)
                        .tint(.blue)
                        .foregroundStyle(.primary)
                        .disabled(isUpdating)

                    if !sortedSeasons.isEmpty {
                        Button {
                            showSeasonPicker = true
                        } label: {
                            HStack {
                                Text("Monitored Seasons").foregroundStyle(.primary)
                                Spacer()
                                Text(monitoredSeasonsSummary)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(isUpdating || isDeleting)
                    }
                }

                Section {
                    if let error = updateError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    Button {
                        Task { await performUpdate() }
                    } label: {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Label("Update Configuration", systemImage: "arrow.triangle.2.circlepath")
                                .foregroundStyle(.primary)
                        }
                    }
                    .disabled(isUpdating || isDeleting)

                    Button("Close", action: { dismiss() })
                        .foregroundStyle(.primary)
                        .disabled(isUpdating || isDeleting)
                }

                Section {
                    if let error = deleteError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Label("Remove from Sonarr", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isUpdating || isDeleting)
                }
            }
            .listStyle(.grouped)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: $showQualityPicker) {
            QualityProfilePickerView(
                profiles: qualityProfiles,
                selectedIndex: $selectedQualityProfileIndex
            )
        }
        .fullScreenCover(isPresented: $showSeasonPicker) {
            SeasonPickerView(seasons: sortedSeasons, monitoring: $seasonMonitoring)
        }
        .onChange(of: updateSuccess) { _, success in
            if success { dismiss() }
        }
        .alert("Remove \(show.title)?", isPresented: $showDeleteConfirm) {
            Button("Remove from Sonarr", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the show from Sonarr. Your video files will not be deleted.")
        }
        .onAppear {
            monitored = show.monitored
            if let currentId = show.qualityProfileId,
               let idx = qualityProfiles.firstIndex(where: { $0.id == currentId }) {
                selectedQualityProfileIndex = idx
            }
            for season in show.seasons ?? [] {
                seasonMonitoring[season.seasonNumber] = season.monitored
            }
        }
    }

    private func performDelete() async {
        isDeleting = true
        deleteError = nil
        do {
            try await service.deleteSeries(
                ip: calendarViewModel.ipAddress,
                port: calendarViewModel.port,
                apiKey: calendarViewModel.apiKey,
                seriesId: show.id
            )
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
        isDeleting = false
    }

    private func performUpdate() async {
        isUpdating = true
        updateError = nil
        do {
            try await service.updateSeriesById(
                ip: calendarViewModel.ipAddress,
                port: calendarViewModel.port,
                apiKey: calendarViewModel.apiKey,
                seriesId: show.id,
                qualityProfileId: selectedQualityProfileId,
                monitored: monitored,
                seasonMonitoring: seasonMonitoring.isEmpty ? nil : seasonMonitoring
            )
            updateSuccess = true
        } catch {
            updateError = error.localizedDescription
        }
        isUpdating = false
    }
}

struct SeasonPickerView: View {
    let seasons: [Season]
    @Binding var monitoring: [Int: Bool]
    @Environment(\.dismiss) private var dismiss

    private var allSelected: Bool {
        seasons.allSatisfy { monitoring[$0.seasonNumber] ?? $0.monitored }
    }

    private func seasonLabel(_ season: Season) -> String {
        season.seasonNumber == 0 ? "Specials" : "Season \(season.seasonNumber)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Monitored Seasons")
                .font(.title2).fontWeight(.semibold)
                .padding(.top, 60).padding(.bottom, 20)

            List {
                Button {
                    let newValue = !allSelected
                    for season in seasons {
                        monitoring[season.seasonNumber] = newValue
                    }
                } label: {
                    Text(allSelected ? "Deselect All" : "Select All")
                        .foregroundStyle(.primary)
                }

                ForEach(seasons, id: \.seasonNumber) { season in
                    Button {
                        let current = monitoring[season.seasonNumber] ?? season.monitored
                        monitoring[season.seasonNumber] = !current
                    } label: {
                        HStack {
                            Text(seasonLabel(season))
                                .foregroundStyle(.primary)
                            Spacer()
                            if monitoring[season.seasonNumber] ?? season.monitored {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }

            Button("OK") { dismiss() }
                .frame(width: 200)
                .padding(.vertical, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
