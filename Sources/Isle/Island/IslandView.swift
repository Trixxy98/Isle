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
        VStack(spacing: 0) {
            islandBody
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var island: IslandController { model.island }

    private var islandBody: some View {
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
        .shadow(color: island.mode == .idle ? .clear : .black.opacity(0.28), radius: 12, y: 6)
        .animation(island.spring, value: island.mode)
        .animation(island.spring, value: size)
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
