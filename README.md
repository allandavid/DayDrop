# DayDrop

A fresh photo on your Mac desktop, every day.

DayDrop is a clean rewrite of [pengsrc/BingPaper](https://github.com/pengsrc/BingPaper),
targeting **Apple Silicon (arm64) only**, with zero external dependencies.

## What changed vs the original

| Original (BingPaper) | DayDrop |
|---|---|
| CocoaPods + MASPreferences | Pure SwiftUI — no dependencies |
| LoginItem helper app bundle (deprecated) | `SMAppService` (macOS 13+) |
| Old AppKit preferences window | SwiftUI `Settings {}` scene |
| x86_64 build target | arm64-only |
| macOS 10.15 deployment target | macOS 13.0+ |
| Unsigned, Gatekeeper bypass needed | Sandboxed, ready to sign |

## Features

- Auto downloads today's photo on launch
- Hourly check for new images
- History: last 8 images selectable from the menu bar
- Choose region (12 regions supported)
- Launch at login via `SMAppService`
- Hide/show Dock icon
- Custom image storage location (security-scoped bookmarks, survives restarts)
- Sets wallpaper on all connected screens
- Caches images — won't re-download if already on disk
- Zero third-party dependencies

---

## Building in Xcode

### 1. Create a new Xcode project

1. Open Xcode → File → New → Project
2. Choose **macOS → App**
3. Set:
   - **Product Name:** `DayDrop`
   - **Bundle Identifier:** `com.yourname.DayDrop` *(match Info.plist)*
   - **Language:** Swift
   - **Interface:** SwiftUI
   - **Uncheck** "Include Tests" (optional)

### 2. Replace generated files

Delete all generated Swift files Xcode created (`ContentView.swift`, `DayDropApp.swift`).
Then drag all files from `Sources/` into the Xcode project (make sure "Copy items if needed" is checked).

### 3. Configure Info.plist

Replace the generated `Info.plist` with the one in `Resources/Info.plist`.
Update `CFBundleIdentifier` to match your team/name.

### 4. Add entitlements

Drag `Resources/DayDrop.entitlements` into the project.
In **Project → Target → Signing & Capabilities**, set the entitlements file path to `DayDrop.entitlements`.

### 5. Set arm64-only build settings

In **Project → Target → Build Settings**:

| Setting | Value |
|---|---|
| `ARCHS` | `arm64` |
| `EXCLUDED_ARCHS` | `x86_64` |
| `ONLY_ACTIVE_ARCH` | `No` (for release) |
| `MACOSX_DEPLOYMENT_TARGET` | `13.0` |
| `SWIFT_VERSION` | `5.9` or later |

### 6. Signing

- Set a development team under **Signing & Capabilities**
- Enable **Automatically manage signing**

### 7. Build & Run

Hit `⌘ + R`. DayDrop will appear in the menu bar with a photo icon.

---

## Project structure

```
Sources/
├── DayDropApp.swift        # @main entry point, SwiftUI App lifecycle
├── AppDelegate.swift       # NSApplicationDelegate, dock icon, hourly timer
├── BingService.swift       # Daily photo API client, download, caching
├── WallpaperManager.swift  # NSWorkspace wallpaper setter (all screens)
├── MenuBarManager.swift    # NSStatusItem, dynamic menu, history submenu
├── SettingsManager.swift   # UserDefaults wrapper, all user preferences
└── SettingsView.swift      # SwiftUI Settings UI (General, Storage, About)

Resources/
├── Info.plist              # App bundle config
└── DayDrop.entitlements    # Sandbox + network + SMAppService
```

---

## API

Daily photos are sourced from a public image feed, fetched over HTTPS.
Up to 8 recent images are available per region, served at UHD resolution.

---

## Permissions required

- **Network** — to fetch daily photos
- **Pictures folder** — default image storage location
- **User-selected folders** — if user chooses a custom storage path
- **SMAppService** — launch at login registration

---

## License

GPLv3 — same as the original project.
Original BingPaper by [pengsrc](https://github.com/pengsrc/BingPaper).
DayDrop is an Apple Silicon rewrite with modernised APIs and zero dependencies.
