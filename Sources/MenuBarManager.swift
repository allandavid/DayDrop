import AppKit
import SwiftUI
import Combine

final class MenuBarManager {

    private var statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setupButton()
        buildMenu()

        // Rebuild menu whenever BingService publishes new images
        BingService.shared.$currentImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildMenu() }
            .store(in: &cancellables)

        BingService.shared.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildMenu() }
            .store(in: &cancellables)
    }

    // MARK: - Setup

    private func setupButton() {
        guard let button = statusItem.button else { return }
        if let icon = NSImage(named: "StatusBarIcon") {
            icon.isTemplate = true  // lets macOS recolour for light/dark menu bar
            button.image = icon
        } else {
            // Fallback to a system symbol if the asset isn't in the bundle yet
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            button.image = NSImage(systemSymbolName: "photo.on.rectangle.angled",
                                   accessibilityDescription: "DayDrop")?
                .withSymbolConfiguration(config)
        }
        button.toolTip = "DayDrop"
    }

    // MARK: - Menu building

    private func buildMenu() {
        let menu = NSMenu()

        // ── Image info ──────────────────────────────────────────────────
        if let img = BingService.shared.currentImage {
            addDisabled(img.title.isEmpty ? "Bing Daily Photo" : img.title, to: menu)
            addDisabled(img.displayDate, to: menu)
            if !img.copyright.isEmpty {
                addDisabled(img.copyright, to: menu, truncate: true)
            }
            menu.addItem(.separator())
        } else if BingService.shared.isLoading {
            addDisabled("Loading…", to: menu)
            menu.addItem(.separator())
        } else if let err = BingService.shared.lastError {
            addDisabled("⚠️ \(err)", to: menu)
            menu.addItem(.separator())
        }

        // ── History submenu ──────────────────────────────────────────────
        if BingService.shared.images.count > 1 {
            let historyItem = NSMenuItem(title: "History", action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: "History")
            for image in BingService.shared.images {
                let item = NSMenuItem(
                    title: "\(image.displayDate)  \(image.title)",
                    action: #selector(selectHistoryImage(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = image
                submenu.addItem(item)
            }
            historyItem.submenu = submenu
            menu.addItem(historyItem)
            menu.addItem(.separator())
        }

        // ── Actions ──────────────────────────────────────────────────────
        let refresh = NSMenuItem(title: "Refresh Now", action: #selector(refresh), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)

        let openFolder = NSMenuItem(title: "Open Image Folder", action: #selector(openFolder), keyEquivalent: "f")
        openFolder.target = self
        menu.addItem(openFolder)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit DayDrop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Helpers

    private func addDisabled(_ title: String, to menu: NSMenu, truncate: Bool = false) {
        var displayTitle = title
        if truncate && title.count > 60 {
            displayTitle = String(title.prefix(60)) + "…"
        }
        let item = NSMenuItem(title: displayTitle, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    // MARK: - Actions

    @objc private func refresh() {
        Task {
            await BingService.shared.fetchImages(force: true)
            await BingService.shared.applyCurrentWallpaper()
        }
    }

    @objc private func openFolder() {
        let location = SettingsManager.shared.storageLocation
        // Create if it doesn't exist yet
        try? FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
        NSWorkspace.shared.open(location)
    }

    @objc private func openSettings() {
        // Standard SwiftUI Settings scene selector
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func selectHistoryImage(_ sender: NSMenuItem) {
        guard let image = sender.representedObject as? BingImage else { return }
        Task {
            await BingService.shared.applyCurrentWallpaper(image: image)
        }
    }
}
