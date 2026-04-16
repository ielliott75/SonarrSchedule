import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedShow: LibrarySeries?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Library")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    if !viewModel.series.isEmpty {
                        Text("\(viewModel.series.count) shows")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 30)
            .padding(.bottom, 20)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading Library...").font(.title3)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50)).foregroundColor(.yellow)
                    Text(error).font(.title3).foregroundColor(.gray).multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.fetch(ip: calendarViewModel.ipAddress, port: calendarViewModel.port, apiKey: calendarViewModel.apiKey) }
                    }
                }
                Spacer()
            } else if viewModel.series.isEmpty {
                Spacer()
                Text("No shows in library").font(.title3).foregroundColor(.gray)
                Spacer()
            } else {
                HStack(alignment: .top, spacing: 20) {
                    // Left column: monitored shows
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Monitored")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.sortedSeries.filter { $0.monitored }) { show in
                                    Button(action: { selectedShow = show }) {
                                        LibraryRowView(show: show)
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                            .padding(.top, 10)
                        }
                        .focusSection()
                    }
                    .frame(maxWidth: .infinity)

                    // Right column: unmonitored shows
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Unmonitored")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.sortedSeries.filter { !$0.monitored }) { show in
                                    Button(action: { selectedShow = show }) {
                                        LibraryRowView(show: show)
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            .padding(.top, 10)
                        }
                        .focusSection()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 52)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(item: $selectedShow) { show in
            ShowSummaryView(show: show, qualityProfiles: viewModel.qualityProfiles)
        }
        .task {
            await viewModel.fetch(ip: calendarViewModel.ipAddress, port: calendarViewModel.port, apiKey: calendarViewModel.apiKey)
        }
    }
}

struct LibraryRowView: View {
    let show: LibrarySeries
    @Environment(\.isFocused) private var isFocused

    private var progressFraction: Double {
        guard let total = show.statistics?.episodeCount, total > 0,
              let have = show.statistics?.episodeFileCount else { return 0 }
        return Double(have) / Double(total)
    }

    private var cardTintColor: Color {
        if !show.monitored { return .blue }
        switch show.status?.lowercased() {
        case "continuing": return .green
        case "ended": return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            AsyncImage(url: show.remotePoster.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .overlay(Image(systemName: "tv").foregroundColor(.gray))
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(show.title)
                        .font(.system(size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let year = show.year {
                        Text(String(year))
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(show.statusColor)
                            .frame(width: 6, height: 6)
                        Text(show.statusDisplay)
                            .font(.system(size: 15))
                            .foregroundColor(show.statusColor)
                    }

                    if let network = show.network {
                        Text(network)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    if !show.monitored {
                        Label("Unmonitored", systemImage: "eye.slash")
                            .font(.system(size: 14))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }

                if let stats = show.statistics, let total = stats.episodeCount, total > 0,
                   let have = stats.episodeFileCount {
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(progressFraction >= 1.0 ? Color.green : Color.blue)
                                    .frame(width: geo.size.width * progressFraction)
                            }
                        }
                        .frame(width: 120, height: 4)

                        Text("\(have) / \(total)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardTintColor.opacity(isFocused ? 0.55 : 0.3))
        )
        .scaleEffect(isFocused ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}
