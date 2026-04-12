import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @State private var showSettings = false
    @State private var showAddShow = false
    @State private var showLibrary = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                    .focusSection()

                if viewModel.isLoading && viewModel.events.isEmpty {
                    Spacer()
                    ProgressView("Loading Schedule...")
                        .font(.title3)
                    Spacer()
                } else if let error = viewModel.errorMessage, viewModel.events.isEmpty {
                    Spacer()
                    errorView(error)
                        .focusSection()
                    Spacer()
                } else {
                    CalendarGridView()
                        .focusSection()
                }
            }
            .background(Color.black.ignoresSafeArea())
            .task {
                await viewModel.fetchEvents()
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showAddShow) {
                AddShowView()
            }
            .fullScreenCover(isPresented: $showLibrary) {
                LibraryView()
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TV Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if let lastRefresh = viewModel.lastRefresh {
                    Text("Updated \(lastRefresh, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .padding(.trailing, 20)
            }

            Button(action: {
                Task { await viewModel.fetchEvents() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
            }

            Button(action: { showLibrary = true }) {
                Image(systemName: "list.bullet")
                    .font(.title3)
            }

            Button(action: { showAddShow = true }) {
                Image(systemName: "plus.circle")
                    .font(.title3)
            }

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
        }
        .padding(.horizontal, 60)
        .padding(.top, 30)
        .padding(.bottom, 20)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            Text(message)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                showSettings = true
            }
            Button("Retry") {
                Task { await viewModel.fetchEvents() }
            }
        }
        .padding()
    }
}
