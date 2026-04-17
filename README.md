# SonarrSchedule

A native tvOS app for Apple TV that brings your [Sonarr](https://sonarr.tv) media server to the big screen. Browse your TV schedule, manage your library, and add new shows — all without leaving your couch.

---

## Features

### TV Schedule
- Displays a two-week calendar starting from Monday of the current week
- Each episode card shows show name, season, episode number, network, and air time
- Colour-coded cards: **green** for confirmed airings, **red** for tentative
- Auto-refreshes every 12 hours in the background

### Library
- View your complete Sonarr collection in a two-column layout
- **Left column** — monitored shows; **right column** — unmonitored shows
- Cards are colour-coded by status: **green** for continuing, **red** for ended, **blue** for unmonitored
- Tap any show to view its full summary: poster, episode progress, disk usage, overview, genres, and status

### Add Shows
- Search for any show by name directly from your Sonarr server
- Browse results with poster art, overview, network, and status
- Configure before adding:
  - Quality profile
  - Monitor option (All, Latest Season, Future, Missing, and more)
  - Automatic search for missing episodes
- If a show already exists in Sonarr, you'll be prompted to update its configuration instead

### Edit Show Settings
- From the Library, tap any show to open its summary
- Update quality profile and monitored status
- Changes are pushed directly back to Sonarr

### Settings
- Configure your Sonarr server connection: IP address, port, and API key
- Settings are persisted across app launches

---

## Requirements

| Requirement | Version |
|---|---|
| Platform | tvOS 17.0+ |
| Sonarr | v3 or v4 |
| Xcode | 15.0+ |

---

## Setup

### Sonarr Configuration
1. Open Sonarr in your browser
2. Go to **Settings → General**
3. Copy your **API Key**
4. Note your server's **IP address** and **port** (default: `8989`)

### App Configuration
1. Launch SonarrSchedule on your Apple TV
2. Press the **gear icon** (⚙) in the top-right corner
3. Enter your Sonarr **IP address**, **port**, and **API key**
4. Press **Save** — the schedule will load automatically

---

## Project Structure

```
SonarrSchedule/
├── Models/
│   ├── CalendarEvent.swift          # iCal event model
│   └── SeriesSearchResult.swift     # Sonarr series models (search results, library, profiles)
├── Services/
│   ├── ICalParser.swift             # iCal feed parser
│   ├── ICalService.swift            # Fetches calendar feed from Sonarr
│   └── SonarrAPIService.swift       # Sonarr REST API v3/v4 client
├── ViewModels/
│   ├── CalendarViewModel.swift      # Schedule state and auto-refresh
│   ├── AddShowViewModel.swift       # Add/update show logic
│   └── LibraryViewModel.swift       # Library fetch and sort
└── Views/
    ├── ContentView.swift            # Root view with header and navigation
    ├── CalendarGridView.swift       # Weekly calendar grid
    ├── EventCardView.swift          # Individual episode card
    ├── EventDetailView.swift        # Episode detail sheet
    ├── AddShowView.swift            # Search and add show flow
    ├── LibraryView.swift            # Library two-column layout
    ├── ShowSummaryView.swift        # Show detail and edit
    └── SettingsView.swift           # Connection settings
```

---

## Building

```bash
# Open the project
open SonarrSchedule.xcodeproj

# Build for Apple TV simulator
xcodebuild \
  -project SonarrSchedule.xcodeproj \
  -scheme SonarrSchedule \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  build
```

---

## How It Works

SonarrSchedule connects to your Sonarr instance in two ways:

1. **iCal feed** — fetches `http://<host>:<port>/feed/v3/calendar/Sonarr.ics?apikey=<key>` to populate the schedule calendar
2. **REST API v3** — communicates with `/api/v3/series`, `/api/v3/series/lookup`, `/api/v3/qualityprofile`, `/api/v3/languageprofile`, and `/api/v3/rootfolder` endpoints to power the library and add-show features

All network calls are made over HTTP on your local network. No data is sent to any third party.

---

## License

MIT
