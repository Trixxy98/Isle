import SwiftUI

struct IslandShape: Shape {
    var bottomRadius: CGFloat

    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: 0,
            style: .continuous
        ).path(in: rect)
    }
}

struct IslandView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPulsing)) { timeline in
            islandBody(at: timeline.date)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var island: IslandController { model.island }

    private func islandBody(at date: Date) -> some View {
        let size = island.currentSize
        return ZStack(alignment: .top) {
            IslandShape(bottomRadius: island.bottomRadius)
                .fill(Color.black)

            islandContent
                .padding(.top, contentTopPadding)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, bottomPadding)
                .animation(island.spring, value: island.mode)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(IslandShape(bottomRadius: island.bottomRadius))
        .scaleEffect(pulseScale(at: date), anchor: .top)
        .shadow(color: island.mode == .idle ? .clear : .black.opacity(0.28), radius: 12, y: 6)
        .animation(island.spring, value: island.mode)
        .animation(island.spring, value: size)
    }

    private var isPulsing: Bool {
        guard let changedAt = model.nowPlaying.trackChangedAt else { return false }
        return Date().timeIntervalSince(changedAt) < 0.4
    }

    private func pulseScale(at date: Date) -> CGFloat {
        guard let changedAt = model.nowPlaying.trackChangedAt else { return 1 }
        let t = date.timeIntervalSince(changedAt)
        let duration = 0.35
        guard t >= 0, t < duration else { return 1 }
        let unit = t / duration
        let triangle = unit < 0.5 ? unit * 2 : (1 - unit) * 2
        let eased = triangle * triangle * (3 - 2 * triangle)
        let peak: CGFloat = island.mode == .expanded ? 0.018 : 0.04
        return 1 + peak * eased
    }

    private var contentTopPadding: CGFloat {
        switch island.mode {
        case .idle:
            0
        case .compact:
            0
        case .expanded:
            island.geometry.height
        }
    }

    private var horizontalPadding: CGFloat {
        switch island.mode {
        case .idle: 0
        case .compact: 9
        case .expanded: 16
        }
    }

    private var bottomPadding: CGFloat {
        switch island.mode {
        case .idle: 0
        case .compact: 0
        case .expanded: 14
        }
    }

    @ViewBuilder
    private var islandContent: some View {
        switch island.mode {
        case .idle:
            Color.clear
        case .compact, .expanded:
            NowPlayingIslandContent()
        }
    }
}
