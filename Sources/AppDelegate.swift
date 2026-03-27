import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarManager: MenuBarManager?
    private var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyDockIconPolicy()

        menuBarManager = MenuBarManager()

        // Kick off an immediate fetch on launch
        Task {
            await BingService.shared.fetchImages()
            await BingService.shared.applyCurrentWallpaper()
        }

        scheduleHourlyCheck()
    }

    // MARK: - Dock icon

    func applyDockIconPolicy() {
        let hide = SettingsManager.shared.hideDockIcon
        NSApp.setActivationPolicy(hide ? .accessory : .regular)
    }

    // MARK: - Scheduled updates

    /// Checks every hour. Bing only publishes one new image per day,
    /// so we compare the stored date before actually downloading anything.
    private func scheduleHourlyCheck() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            guard self != nil else { return }
            Task {
                await BingService.shared.fetchImages()
                await BingService.shared.applyCurrentWallpaper()
            }
        }
        RunLoop.main.add(updateTimer!, forMode: .common)
    }
}
