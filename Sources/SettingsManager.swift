import Foundation
import AppKit
import Combine

// MARK: - Region

enum BingRegion: String, CaseIterable, Identifiable {
    case enUS = "en-US"
    case enGB = "en-GB"
    case enAU = "en-AU"
    case enCA = "en-CA"
    case enIN = "en-IN"
    case zhCN = "zh-CN"
    case jaJP = "ja-JP"
    case deDE = "de-DE"
    case frFR = "fr-FR"
    case ptBR = "pt-BR"
    case esES = "es-ES"
    case itIT = "it-IT"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .enUS: return "English (United States)"
        case .enGB: return "English (United Kingdom)"
        case .enAU: return "English (Australia)"
        case .enCA: return "English (Canada)"
        case .enIN: return "English (India)"
        case .zhCN: return "Chinese (Simplified)"
        case .jaJP: return "Japanese"
        case .deDE: return "German"
        case .frFR: return "French"
        case .ptBR: return "Portuguese (Brazil)"
        case .esES: return "Spanish (Spain)"
        case .itIT: return "Italian"
        }
    }
}

// MARK: - SettingsManager

final class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: Keys

    private enum Keys {
        static let region             = "region"
        static let storageLocationBookmark = "storageLocationBookmark"
        static let hideDockIcon       = "hideDockIcon"
        static let lastSeenDate       = "lastSeenDate"
    }

    // MARK: Published properties

    @Published var region: BingRegion {
        didSet {
            defaults.set(region.rawValue, forKey: Keys.region)
        }
    }

    @Published var hideDockIcon: Bool {
        didSet {
            defaults.set(hideDockIcon, forKey: Keys.hideDockIcon)
        }
    }

    /// Last Bing image date string we fetched (e.g. "20240315"),
    /// used to avoid redundant downloads.
    var lastSeenDate: String {
        get { defaults.string(forKey: Keys.lastSeenDate) ?? "" }
        set { defaults.set(newValue, forKey: Keys.lastSeenDate) }
    }

    // MARK: Storage location (security-scoped bookmark)

    private(set) var storageLocation: URL

    func setStorageLocation(_ url: URL) {
        // Persist as a security-scoped bookmark so the path survives app restarts
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(bookmark, forKey: Keys.storageLocationBookmark)
            storageLocation = url
            objectWillChange.send()
        } catch {
            // Fall back to plain path storage
            defaults.set(url.path, forKey: "storageLocationFallback")
            storageLocation = url
            objectWillChange.send()
        }
    }

    // MARK: Init

    private init() {
        // Region
        region = BingRegion(rawValue: defaults.string(forKey: Keys.region) ?? "") ?? .enUS

        // Dock icon
        hideDockIcon = defaults.bool(forKey: Keys.hideDockIcon)

        // Storage location — resolve bookmark first, fall back to ~/Pictures/DayDrop
        let defaultStorage = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("DayDrop", isDirectory: true)

        if let bookmarkData = defaults.data(forKey: Keys.storageLocationBookmark) {
            var isStale = false
            if let resolved = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                storageLocation = resolved
                _ = resolved.startAccessingSecurityScopedResource()
                return
            }
        }

        storageLocation = defaultStorage
    }
}
