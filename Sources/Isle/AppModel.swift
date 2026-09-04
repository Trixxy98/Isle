import AppKit
import SwiftUI

@Observable
@MainActor
final class AppModel {
    static let shared = AppModel()

    let settings = AppSettings()
    let island = IslandController()
    let nowPlaying = NowPlayingService()

    private init() {}

    func start() {
        island.attach(self)
        nowPlaying.start()
    }
}
