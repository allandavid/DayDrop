import SwiftUI
import ServiceManagement

// MARK: - Root

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(0)

            StorageTab()
                .tabItem { Label("Storage", systemImage: "folder") }
                .tag(1)

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(2)
        }
        .frame(width: 460, height: 260)
        .padding()
    }
}

// MARK: - General tab

struct GeneralTab: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Picker("Bing region:", selection: $settings.region) {
                ForEach(BingRegion.allCases) { region in
                    Text(region.displayName).tag(region)
                }
            }
            .onChange(of: settings.region) { _ in
                // Re-fetch when region changes
                Task {
                    await BingService.shared.fetchImages(force: true)
                    await BingService.shared.applyCurrentWallpaper()
                }
            }

            Divider().padding(.vertical, 4)

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    setLaunchAtLogin(newValue)
                }

            Toggle("Hide Dock icon", isOn: $settings.hideDockIcon)
                .onChange(of: settings.hideDockIcon) { _ in
                    let appDelegate = NSApp.delegate as? AppDelegate
                    appDelegate?.applyDockIconPolicy()
                }
        }
        .padding()
        .onAppear { launchAtLogin = isRegisteredForLaunchAtLogin() }
    }

    // MARK: SMAppService helpers

    private func isRegisteredForLaunchAtLogin() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[Settings] Launch at login error: \(error)")
        }
    }
}

// MARK: - Storage tab

struct StorageTab: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var cachedImageCount: Int = 0

    var body: some View {
        Form {
            HStack(alignment: .center) {
                Text("Image folder:")
                Spacer()
                Text(settings.storageLocation.abbreviatingWithTilde)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: 200)

                Button("Change…") { chooseFolder() }
            }

            HStack {
                Text("Cached images:")
                Spacer()
                Text("\(cachedImageCount)")
                    .foregroundColor(.secondary)

                Button("Open Folder") {
                    NSWorkspace.shared.open(settings.storageLocation)
                }
            }
        }
        .padding()
        .onAppear { cachedImageCount = countCachedImages() }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.message = "Choose where DayDrop saves downloaded wallpapers."

        if panel.runModal() == .OK, let url = panel.url {
            settings.setStorageLocation(url)
            cachedImageCount = countCachedImages()
        }
    }

    private func countCachedImages() -> Int {
        let url = settings.storageLocation
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil
        ) else { return 0 }
        return contents.filter { $0.pathExtension.lowercased() == "jpg" }.count
    }
}

// MARK: - About tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("DayDrop")
                .font(.title2.bold())

            Text("A fresh photo on your Mac desktop, every day.")
                .foregroundColor(.secondary)

            Text("Built for Apple Silicon · macOS 13+")
                .font(.caption)
                .foregroundColor(.secondary)

            Link("Source on GitHub", destination: URL(string: "https://github.com/pengsrc/BingPaper")!)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Helpers

private extension URL {
    var abbreviatingWithTilde: String {
        path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
    }
}
