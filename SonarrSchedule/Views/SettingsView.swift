import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var ipAddress: String = ""
    @State private var port: String = ""
    @State private var apiKey: String = ""
    @State private var showSaved = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Sonarr Connection Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.top, 50)
                .padding(.bottom, 30)

            // Fields
            VStack(spacing: 18) {
                settingsField(label: "IP Address", placeholder: "192.168.86.200", text: $ipAddress)
                settingsField(label: "Port", placeholder: "8989", text: $port)
                settingsField(label: "API Key", placeholder: "Your Sonarr API key", text: $apiKey)
            }
            .padding(.horizontal, 200)

            // Connection URL preview
            VStack(spacing: 4) {
                Text("Calendar URL")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("http://\(ipAddress):\(port)/feed/v3/calendar/Sonarr.ics?apikey=\(apiKey)")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 200)
            .padding(.top, 20)

            if showSaved {
                Text("Settings saved and calendar refreshed!")
                    .foregroundColor(.green)
                    .font(.caption)
                    .transition(.opacity)
                    .padding(.top, 12)
            }

            Spacer()

            // Buttons
            HStack(spacing: 30) {
                Button(action: {
                    viewModel.saveSettings(ip: ipAddress, port: port, apiKey: apiKey)
                    withAnimation {
                        showSaved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSaved = false
                        }
                        dismiss()
                    }
                }) {
                    Text("Save")
                        .font(.callout)
                        .frame(width: 200)
                }

                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.callout)
                        .frame(width: 200)
                }
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            ipAddress = viewModel.ipAddress
            port = viewModel.port
            apiKey = viewModel.apiKey
        }
    }

    private func settingsField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(placeholder, text: text)
                .font(.callout)
                .textFieldStyle(.plain)
                .padding(12)
        }
    }
}
