import SwiftUI

struct AddShowView: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddShowViewModel()

    @State private var selectedShow: SeriesSearchResult?

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .focusSection()
            searchBar
                .padding(.horizontal, 60)
                .padding(.bottom, 20)
                .focusSection()
            if viewModel.isSearching {
                Spacer()
                ProgressView("Searching...")
                    .font(.title3)
                Spacer()
            } else if let error = viewModel.searchError {
                Spacer()
                errorView(error)
                Spacer()
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                Spacer()
                Text("No results found")
                    .font(.title3)
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { result in
                            ShowSearchResultRow(result: result) {
                                selectedShow = result
                                viewModel.resetAddState()
                            }
                        }
                    }
                    .padding(.horizontal, 60)
                }
                .focusSection()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(item: $selectedShow) { show in
            AddShowConfirmView(
                show: show,
                rootFolders: viewModel.rootFolders,
                qualityProfiles: viewModel.qualityProfiles,
                isAdding: viewModel.isAdding,
                addError: viewModel.addError,
                addSuccess: viewModel.addSuccess,
                showUpdatePrompt: viewModel.showUpdatePrompt
            ) { rootFolderPath, qualityProfileId, monitor, searchForMissing in
                await viewModel.addShow(
                    show,
                    rootFolderPath: rootFolderPath,
                    qualityProfileId: qualityProfileId,
                    monitor: monitor,
                    searchForMissingEpisodes: searchForMissing,
                    ip: calendarViewModel.ipAddress,
                    port: calendarViewModel.port,
                    apiKey: calendarViewModel.apiKey
                )
            } onUpdate: { qualityProfileId, monitor in
                await viewModel.updateShow(
                    show,
                    qualityProfileId: qualityProfileId,
                    monitor: monitor,
                    ip: calendarViewModel.ipAddress,
                    port: calendarViewModel.port,
                    apiKey: calendarViewModel.apiKey
                )
            } onDismiss: {
                selectedShow = nil
                if viewModel.addSuccess {
                    Task { await calendarViewModel.fetchEvents() }
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadOptions(
                ip: calendarViewModel.ipAddress,
                port: calendarViewModel.port,
                apiKey: calendarViewModel.apiKey
            )
        }
    }

    private var headerBar: some View {
        HStack {
            Text("Add Show")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 30)
        .padding(.bottom, 20)
    }

    private var searchBar: some View {
        HStack(spacing: 16) {
            TextField("Search by show name...", text: $viewModel.searchQuery)
                .font(.callout)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .onSubmit {
                    Task {
                        await viewModel.search(
                            ip: calendarViewModel.ipAddress,
                            port: calendarViewModel.port,
                            apiKey: calendarViewModel.apiKey
                        )
                    }
                }

            Button(action: {
                Task {
                    await viewModel.search(
                        ip: calendarViewModel.ipAddress,
                        port: calendarViewModel.port,
                        apiKey: calendarViewModel.apiKey
                    )
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .frame(width: 60, height: 50)
            }
            .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            Text(message)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Search Result Row

struct ShowSearchResultRow: View {
    let result: SeriesSearchResult
    let onSelect: () -> Void
    @Environment(\.isFocused) private var isFocused

    private var statusColor: Color {
        switch result.status?.lowercased() {
        case "continuing": return .green
        case "ended": return .gray
        case "upcoming": return .blue
        default: return .gray
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 20) {
                // Poster
                AsyncImage(url: result.remotePoster.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "tv")
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(result.title)
                            .font(.system(size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let year = result.year {
                            Text(String(year))
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    HStack(spacing: 16) {
                        if let network = result.network {
                            Label(network, systemImage: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        HStack(spacing: 4) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(result.statusDisplay)
                                .font(.system(size: 16))
                                .foregroundColor(statusColor)
                        }
                    }

                    if let genres = result.genres, !genres.isEmpty {
                        Text(genres.prefix(3).joined(separator: " · "))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    if let overview = result.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(3)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue.opacity(isFocused ? 1.0 : 0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.blue.opacity(isFocused ? 0.6 : 0.0), lineWidth: 2)
            )
        }
        .buttonStyle(.card)
        .padding(.vertical, 6)
    }
}

// MARK: - Confirm Add (full screen)

struct AddShowConfirmView: View {
    let show: SeriesSearchResult
    let rootFolders: [RootFolder]
    let qualityProfiles: [QualityProfile]
    let isAdding: Bool
    let addError: String?
    let addSuccess: Bool
    let showUpdatePrompt: Bool
    let onAdd: (String, Int, MonitorOption, Bool) async -> Void
    let onUpdate: (Int, MonitorOption) async -> Void
    let onDismiss: () -> Void

    @State private var selectedQualityProfileIndex = 0
    @State private var selectedMonitor: MonitorOption = .latestSeason
    @State private var searchForMissing = false
    @State private var showQualityPicker = false
    @State private var showMonitorPicker = false

    private var selectedRootFolderPath: String { rootFolders.first?.path ?? "/tv/" }
    private var selectedQualityProfileId: Int {
        qualityProfiles.indices.contains(selectedQualityProfileIndex)
            ? qualityProfiles[selectedQualityProfileIndex].id : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Show info — non-interactive header
            HStack(spacing: 24) {
                AsyncImage(url: show.remotePoster.flatMap(URL.init)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .overlay(Image(systemName: "tv").foregroundColor(.gray))
                }
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 8) {
                    Text(show.title)
                        .font(.title).fontWeight(.bold).foregroundColor(.white)
                    HStack(spacing: 12) {
                        if let year = show.year { Text(String(year)).foregroundColor(.gray) }
                        if let network = show.network { Text(network).foregroundColor(.gray) }
                        Text(show.statusDisplay)
                            .foregroundColor(show.status?.lowercased() == "continuing" ? .green : .gray)
                    }
                    .font(.callout)
                    if let overview = show.overview, !overview.isEmpty {
                        Text(overview).font(.footnote).foregroundColor(.white.opacity(0.6)).lineLimit(3)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 60)
            .padding(.top, 40)
            .padding(.bottom, 20)

            // All interactive content in a List so tvOS focus navigation works reliably
            List {
                Section("Options") {
                    if !qualityProfiles.isEmpty {
                        Button {
                            showQualityPicker = true
                        } label: {
                            listOptionRow(
                                label: "Quality Profile",
                                value: qualityProfiles.indices.contains(selectedQualityProfileIndex)
                                    ? qualityProfiles[selectedQualityProfileIndex].name : ""
                            )
                        }
                        .disabled(isAdding)
                    }

                    Button {
                        showMonitorPicker = true
                    } label: {
                        listOptionRow(label: "Monitor", value: selectedMonitor.displayName)
                    }
                    .disabled(isAdding)

                    Toggle("Search for Missing Episodes", isOn: $searchForMissing)
                        .tint(.blue)
                        .foregroundStyle(.primary)
                        .disabled(isAdding)
                }

                Section {
                    if let error = addError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    if showUpdatePrompt {
                        Text("\(show.title) is already in your library. Update its configuration with the selected options?")
                            .foregroundStyle(.primary)
                            .font(.callout)

                        Button {
                            Task { await onUpdate(selectedQualityProfileId, selectedMonitor) }
                        } label: {
                            if isAdding {
                                ProgressView()
                            } else {
                                Label("Update Configuration", systemImage: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .disabled(isAdding)

                        Button("Cancel", action: onDismiss)
                            .foregroundStyle(.primary)
                            .disabled(isAdding)
                    } else {
                        Button {
                            Task { await onAdd(selectedRootFolderPath, selectedQualityProfileId, selectedMonitor, searchForMissing) }
                        } label: {
                            if isAdding {
                                ProgressView()
                            } else {
                                Label("Add to Sonarr", systemImage: "plus.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .disabled(isAdding)

                        Button("Cancel", action: onDismiss)
                            .foregroundStyle(.primary)
                            .disabled(isAdding)
                    }
                }
            }
            .listStyle(.grouped)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onChange(of: addSuccess) { _, success in
            if success { onDismiss() }
        }
        .fullScreenCover(isPresented: $showQualityPicker) {
            QualityProfilePickerView(
                profiles: qualityProfiles,
                selectedIndex: $selectedQualityProfileIndex
            )
        }
        .fullScreenCover(isPresented: $showMonitorPicker) {
            MonitorPickerView(selection: $selectedMonitor)
        }
    }

    private func listOptionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Option picker screens

struct QualityProfilePickerView: View {
    let profiles: [QualityProfile]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Quality Profile")
                .font(.title2).fontWeight(.semibold)
                .padding(.top, 60).padding(.bottom, 20)

            List(profiles.indices, id: \.self) { i in
                Button {
                    selectedIndex = i
                } label: {
                    HStack {
                        Text(profiles[i].name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedIndex == i {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.primary)
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

struct MonitorPickerView: View {
    @Binding var selection: MonitorOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Monitor")
                .font(.title2).fontWeight(.semibold)
                .padding(.top, 60).padding(.bottom, 20)

            List(MonitorOption.allCases, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    HStack {
                        Text(option.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.primary)
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
