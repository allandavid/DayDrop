import SwiftUI

@main
struct DayDropApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window — this is a menu bar app.
        // Settings window is opened via the menu bar item.
        Settings {
            SettingsView()
        }
    }
}
