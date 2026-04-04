import SwiftUI

@main
struct SonarrScheduleApp: App {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
