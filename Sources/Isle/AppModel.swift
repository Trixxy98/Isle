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
        island.refreshReduceMotion()
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) {_ in
        Task { @MainActor in 
            AppModel.shared.island.refreshReduceMotion()
            }}
    }
}
