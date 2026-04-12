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
                    .disabled(isUpdating)

                    Button("Close", action: { dismiss() })
                        .foregroundStyle(.primary)
                        .disabled(isUpdating)
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
        .onChange(of: updateSuccess) { _, success in
            if success { dismiss() }
        }
        .onAppear {
            monitored = show.monitored
            if let currentId = show.qualityProfileId,
               let idx = qualityProfiles.firstIndex(where: { $0.id == currentId }) {
                selectedQualityProfileIndex = idx
            }
        }
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
                monitored: monitored
            )
            updateSuccess = true
        } catch {
            updateError = error.localizedDescription
        }
        isUpdating = false
    }
}
