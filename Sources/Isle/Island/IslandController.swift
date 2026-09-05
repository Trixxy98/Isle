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
    var isPinned = false

    private weak var model: AppModel?
    private var collapseTask: Task<Void, Never>?
    private var stickyHitTask: Task<Void, Never>?
    private var stickyHitSize: CGSize?

    var currentSize: CGSize {
        size(for: mode)
    }

    /// Hit testing uses the larger of the visual target and a short-lived sticky
    /// expanded rect so collapse doesn't drop the pointer mid-spring.
    var hitSize: CGSize {
        let current = currentSize
        guard let sticky = stickyHitSize else { return current }
        return CGSize(
            width: max(current.width, sticky.width),
            height: max(current.height, sticky.height)
        )
    }

    var bottomRadius: CGFloat {
        switch mode {
        case .idle: 12
        case .compact: 14
        case .expanded: 36
        }
    }

    var spring: Animation {
        .spring(response: 0.42, dampingFraction: 0.82)
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
                try? await Task.sleep(for: .milliseconds(400))
                guard let self, !self.isHovering else { return }
                self.recompute()
            }
        }
    }

    func pin() {
        isPinned = true
        recompute()
    }

    func unpin() {
        guard isPinned else { return }
        isPinned = false
        recompute()
    }

    func recompute() {
        let previous = mode
        let visible = model?.nowPlaying.shouldShowIsland == true

        let next: IslandMode
        if !visible {
            isPinned = false
            next = .idle
        } else if isPinned || isHovering {
            next = .expanded
        } else {
            next = .compact
        }

        if previous == .expanded && next != .expanded {
            stickyHitSize = size(for: .expanded)
            stickyHitTask?.cancel()
            stickyHitTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(400))
                guard let self else { return }
                self.stickyHitSize = nil
            }
        }

        mode = next
    }

    private func size(for mode: IslandMode) -> CGSize {
        let notch = geometry
        switch mode {
        case .idle:
            return CGSize(width: notch.width, height: notch.height)
        case .compact:
            return CGSize(width: notch.width + 76, height: notch.height)
        case .expanded:
            return CGSize(width: 386, height: notch.height + 158)
        }
    }
}
