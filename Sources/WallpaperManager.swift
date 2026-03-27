import AppKit

final class WallpaperManager {

    static let shared = WallpaperManager()
    private init() {}

    /// Sets the wallpaper on every connected screen.
    /// NSWorkspace handles the heavy lifting; we just loop screens.
    func set(imageURL: URL) {
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true
        ]

        for screen in NSScreen.screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: options)
            } catch {
                print("[WallpaperManager] Failed on screen \(screen.localizedName): \(error)")
            }
        }
    }
}
