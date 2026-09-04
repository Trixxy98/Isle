import AppKit
import Foundation
import SwiftUI

struct NowPlayingTrack: Equatable {
    enum Source: String {
        case music = "Music"
        case spotify = "Spotify"
    }

    var source: Source
    var title: String
    var artist: String
    var album: String
    var isPlaying: Bool
    var position: TimeInterval
    var duration: TimeInterval
    var artwork: NSImage?

    var identity: String { "\(source.rawValue)|\(title)|\(artist)|\(album)" }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1)
    }
}

@Observable
@MainActor
final class NowPlayingService {
    var track: NowPlayingTrack?
    var palette: [Color] = ArtworkPalette.fallback
    var hasTrack: Bool { track != nil }
    var shouldShowIsland: Bool = false

    private var pollTask: Task<Void, Never>?
    private var hideAfterPauseTask: Task<Void, Never>?
    private var pausedAt: Date?
    private var lastIdentity: String?
    private let queue = DispatchQueue(label: "com.isle.mac.media", qos: .utility)

    func start() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refresh()
                let interval: Duration = self.hasRunningPlayer ? .milliseconds(1000) : .milliseconds(2000)
                try? await Task.sleep(for: interval)
            }
        }
    }

    func playPause() {
        runCommand("playpause")
    }

    func nextTrack() {
        runCommand("next track")
    }

    func previousTrack() {
        runCommand("previous track")
    }

    func seek(to position: TimeInterval) {
        guard let track else { return }
        let clamped = max(0, min(position, track.duration))
        let source = track.source.rawValue
        self.track?.position = clamped
        queue.async {
            _ = AppleScript.run(
                """
                if application "\(source)" is running then
                    tell application "\(source)" to set player position to \(clamped)
                end if
                """
            )
        }
    }

    private var hasRunningPlayer: Bool {
        musicIsRunning || spotifyIsRunning
    }

    private var musicIsRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
    }

    private var spotifyIsRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    private func runCommand(_ command: String) {
        guard let source = track?.source.rawValue else { return }
        queue.async {
            _ = AppleScript.run(
                """
                if application "\(source)" is running then
                    tell application "\(source)" to \(command)
                end if
                """
            )
        }
    }

    private func refresh() async {
        let musicRunning = musicIsRunning
        let spotifyRunning = spotifyIsRunning
        let snapshot = await withCheckedContinuation { continuation in
            queue.async {
                let result = Self.fetchTrack(musicRunning: musicRunning, spotifyRunning: spotifyRunning)
                continuation.resume(returning: result)
            }
        }

        var next = snapshot

        if let existing = next, existing.identity == lastIdentity, track?.artwork != nil {
            next?.artwork = track?.artwork
        }

        track = next
        updateVisibility(for: next)
        AppModel.shared.island.recompute()

        if let next {
            if lastIdentity != next.identity {
                lastIdentity = next.identity
                Task { await loadArtwork(for: next) }
            }
        } else {
            lastIdentity = nil
            palette = ArtworkPalette.fallback
        }
    }

    private func updateVisibility(for next: NowPlayingTrack?) {
    guard let next else {
        hideAfterPauseTask?.cancel()
        hideAfterPauseTask = nil
        pausedAt = nil
        shouldShowIsland = false
        return
    }

    if next.isPlaying {
        hideAfterPauseTask?.cancel()
        hideAfterPauseTask = nil
        pausedAt = nil
        shouldShowIsland = true
        return
    }

    if pausedAt == nil {
        pausedAt = Date()
    }

    let elapsed = Date().timeIntervalSince(pausedAt ?? Date())
    shouldShowIsland = elapsed < 60
}

    private func loadArtwork(for track: NowPlayingTrack) async {
        let identity = track.identity
        let loaded: (image: NSImage?, palette: [Color]) = await withCheckedContinuation { continuation in
            queue.async {
                let image: NSImage?
                switch track.source {
                case .music:
                    image = Self.musicArtwork()
                case .spotify:
                    image = Self.spotifyArtwork()
                }
                continuation.resume(returning: (image, ArtworkPalette.colors(from: image)))
            }
        }
        guard AppModel.shared.nowPlaying.track?.identity == identity else { return }
        AppModel.shared.nowPlaying.track?.artwork = loaded.image
        AppModel.shared.nowPlaying.palette = loaded.palette
    }

    nonisolated private static func fetchTrack(musicRunning: Bool, spotifyRunning: Bool) -> NowPlayingTrack? {
        let music = musicRunning ? parse(runInfo(app: "Music"), source: .music, durationIsMilliseconds: false) : nil
        let spotify = spotifyRunning ? parse(runInfo(app: "Spotify"), source: .spotify, durationIsMilliseconds: true) : nil
        if let music, music.isPlaying { return music }
        if let spotify, spotify.isPlaying { return spotify }
        return music ?? spotify
    }

    nonisolated private static func runInfo(app: String) -> String? {
        AppleScript.run(
            """
            if application "\(app)" is running then
                tell application "\(app)"
                    try
                        set ps to player state as string
                        if ps is "stopped" then return "stopped"
                        set n to name of current track
                        set a to artist of current track
                        set al to album of current track
                        set d to duration of current track
                        set p to player position
                        return n & character id 31 & a & character id 31 & al & character id 31 & ps & character id 31 & p & character id 31 & d
                    on error
                        return "stopped"
                    end try
                end tell
            end if
            return "stopped"
            """
        )
    }

    nonisolated private static func parse(_ raw: String?, source: NowPlayingTrack.Source, durationIsMilliseconds: Bool) -> NowPlayingTrack? {
        guard let raw, raw != "stopped", !raw.isEmpty else { return nil }
        let parts = raw.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 6 else { return nil }
        let position = TimeInterval(parts[4]) ?? 0
        var duration = TimeInterval(parts[5]) ?? 0
        if durationIsMilliseconds {
            duration /= 1000
        }
        return NowPlayingTrack(
            source: source,
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3].lowercased() == "playing",
            position: position,
            duration: duration,
            artwork: nil
        )
    }

    nonisolated private static func musicArtwork() -> NSImage? {
        let path = "/tmp/isle-artwork.bin"
        let result = AppleScript.run(
            """
            if application "Music" is running then
                tell application "Music"
                    try
                        if (count of artworks of current track) is 0 then return ""
                        set artData to raw data of artwork 1 of current track
                        set fileRef to open for access POSIX file "\(path)" with write permission
                        set eof of fileRef to 0
                        write artData to fileRef
                        close access fileRef
                        return "\(path)"
                    on error
                        try
                            close access POSIX file "\(path)"
                        end try
                        return ""
                    end try
                end tell
            end if
            return ""
            """
        )
        guard result == path else { return nil }
        return NSImage(contentsOfFile: path)
    }

    nonisolated private static func spotifyArtwork() -> NSImage? {
        guard let urlString = AppleScript.run(
            """
            if application "Spotify" is running then
                tell application "Spotify"
                    try
                        return artwork url of current track
                    on error
                        return ""
                    end try
                end tell
            end if
            return ""
            """
        ), let url = URL(string: urlString), !urlString.isEmpty else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return NSImage(data: data)
    }
}

enum AppleScript {
    nonisolated static func run(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
}
