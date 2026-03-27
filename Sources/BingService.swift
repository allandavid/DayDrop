import Foundation
import AppKit

// MARK: - Model

struct BingImage: Codable, Identifiable, Hashable {
    let startdate: String   // "20240315"
    let url: String         // relative path, e.g. "/th?id=OHR.SomeName_EN-US..."
    let urlbase: String
    let copyright: String
    let title: String
    let hsh: String         // unique hash — good stable ID

    var id: String { hsh }

    /// Full 1920×1080 image URL
    var fullResURL: URL? {
        // Bing serves UHD images at _UHD.jpg; fall back to 1920x1080
        URL(string: "https://www.bing.com\(urlbase)_UHD.jpg")
    }

    /// Human-readable date, e.g. "March 15, 2024"
    var displayDate: String {
        guard startdate.count == 8,
              let year = Int(startdate.prefix(4)),
              let month = Int(startdate.dropFirst(4).prefix(2)),
              let day = Int(startdate.dropFirst(6))
        else { return startdate }

        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        guard let date = Calendar.current.date(from: comps) else { return startdate }

        let fmt = DateFormatter()
        fmt.dateStyle = .long
        return fmt.string(from: date)
    }
}

private struct BingAPIResponse: Codable {
    let images: [BingImage]
}

// MARK: - Service

@MainActor
final class BingService: ObservableObject {

    static let shared = BingService()

    @Published private(set) var images: [BingImage] = []
    @Published private(set) var currentImage: BingImage?
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private init() {}

    // MARK: - Public API

    /// Fetches up to 8 recent Bing images for the configured region.
    /// Only hits the network if we haven't seen today's image already.
    func fetchImages(force: Bool = false) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let region = SettingsManager.shared.region.rawValue
        let urlString = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=\(region)"

        guard let url = URL(string: urlString) else {
            lastError = "Invalid API URL."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BingAPIResponse.self, from: data)
            images = response.images
            if let first = images.first {
                currentImage = first
                SettingsManager.shared.lastSeenDate = first.startdate
            }
        } catch {
            lastError = "Could not fetch images: \(error.localizedDescription)"
        }
    }

    /// Downloads and sets `currentImage` (or a specific image) as the wallpaper.
    func applyCurrentWallpaper(image: BingImage? = nil) async {
        guard let target = image ?? currentImage else { return }
        await download(and: target)
    }

    // MARK: - Private

    private func download(and image: BingImage) async {
        guard let remoteURL = image.fullResURL else {
            lastError = "Could not build image URL."
            return
        }

        let storage = SettingsManager.shared.storageLocation

        // Ensure directory exists
        do {
            try FileManager.default.createDirectory(at: storage, withIntermediateDirectories: true)
        } catch {
            lastError = "Cannot create storage folder: \(error.localizedDescription)"
            return
        }

        let filename = "\(image.startdate)_\(image.hsh).jpg"
        let fileURL = storage.appendingPathComponent(filename)

        // Re-use cached file if it's already on disk
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let (data, _) = try await URLSession.shared.data(from: remoteURL)
                try data.write(to: fileURL, options: .atomic)
            } catch {
                lastError = "Download failed: \(error.localizedDescription)"
                return
            }
        }

        WallpaperManager.shared.set(imageURL: fileURL)
        currentImage = image
    }
}
