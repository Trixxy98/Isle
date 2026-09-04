import CoreGraphics
import Foundation
import SwiftUI

enum IslandMode: Equatable {
    case idle
    case compact
    case expanded
}

@Observable
@MainActor
final class IslandController {
    var geometry: NotchGeometry = .detect()
    var mode: IslandMode = .idle
    var isHovering = false

    private weak var model: AppModel?
    private var collapseTask: Task<Void, Never>?

    var currentSize: CGSize {
        let notch = geometry
        switch mode {
        case .idle:
            return CGSize(width: notch.width, height: notch.height)
        case .compact:
            return CGSize(width: notch.width + 76, height: notch.height)
        case .expanded:
            return CGSize(width: 368, height: notch.height + 150)
        }
    }

    var bottomRadius: CGFloat {
        switch mode {
        case .idle: 12
        case .compact: 14
        case .expanded: 24
        }
    }

    var spring: Animation {
        .spring(response: 0.35, dampingFraction: 0.78)
    }

    func attach(_ model: AppModel) {
        self.model = model
        refreshGeometry()
        recompute()
    }

    func refreshGeometry() {
        geometry = .detect()
        AppDelegate.shared?.repositionPanel()
    }

    func setHovering(_ hovering: Bool) {
        guard isHovering != hovering else { return }
        isHovering = hovering
        if hovering {
            collapseTask?.cancel()
            collapseTask = nil
            recompute()
        } else {
            collapseTask?.cancel()
            collapseTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(220))
                guard let self, !self.isHovering else { return }
                self.recompute()
            }
        }
    }

    func recompute() {
        let hasTrack = model?.nowPlaying.hasTrack == true
        if isHovering, hasTrack {
            mode = .expanded
            return
        }
        if hasTrack {
            mode = .compact
            return
        }
        mode = .idle
    }
}
