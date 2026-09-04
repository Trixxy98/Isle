import AppKit
import SwiftUI

struct CompactNowPlayingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            ArtworkView(image: model.nowPlaying.track?.artwork, corner: 5)
                .frame(width: 20, height: 20)
            Spacer(minLength: 0)
            EqualizerBars(
                isPlaying: model.nowPlaying.track?.isPlaying ?? false,
                colors: model.nowPlaying.palette,
                style: .compact
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum EqualizerStyle {
    case compact
    case expanded
}

struct EqualizerBars: View {
    var isPlaying: Bool
    var colors: [Color] = ArtworkPalette.fallback
    var style: EqualizerStyle = .compact

    private var bars: [(low: CGFloat, high: CGFloat, rest: CGFloat, period: Double, phase: Double)] {
        switch style {
        case .compact:
            [
                (4, 11, 5, 0.96, 0.00),
                (6, 16, 10, 0.68, 0.18),
                (5, 14, 7, 0.84, 0.41),
                (4, 12, 6, 1.12, 0.27)
            ]
        case .expanded:
            [
                (4, 10, 5, 0.92, 0.00),
                (6, 16, 8, 0.64, 0.14),
                (5, 13, 7, 0.78, 0.31),
                (7, 18, 10, 0.56, 0.47),
                (4, 12, 6, 0.88, 0.22)
            ]
        }
    }

    private var barWidth: CGFloat { style == .compact ? 3 : 2.5 }
    private var spacing: CGFloat { style == .compact ? 1.5 : 1.8 }
    private var clusterSize: CGSize {
        switch style {
        case .compact: CGSize(width: 18, height: 16)
        case .expanded: CGSize(width: 22, height: 18)
        }
    }

    var body: some View {
        let specs = bars
        TimelineView(.animation(minimumInterval: isPlaying ? 1.0 / 30.0 : 10, paused: !isPlaying)) { timeline in
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(0..<specs.count, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(color(at: index))
                        .frame(width: barWidth, height: height(specs[index], date: timeline.date))
                }
            }
            .frame(width: clusterSize.width, height: clusterSize.height, alignment: .bottom)
        }
    }

    private func color(at index: Int) -> Color {
        switch style {
        case .compact:
            let palette = colors.isEmpty ? ArtworkPalette.fallback : colors
            return palette[index % palette.count]
        case .expanded:
            return .white
        }
    }

    private func height(
        _ spec: (low: CGFloat, high: CGFloat, rest: CGFloat, period: Double, phase: Double),
        date: Date
    ) -> CGFloat {
        guard isPlaying else { return spec.rest }
        let t = date.timeIntervalSinceReferenceDate + spec.phase
        return spec.low + (spec.high - spec.low) * CGFloat(easeInOutPingPong(t, period: spec.period))
    }

    private func easeInOutPingPong(_ time: Double, period: Double) -> Double {
        let unit = time.truncatingRemainder(dividingBy: period) / period
        let triangle = unit < 0.5 ? unit * 2 : (1 - unit) * 2
        return triangle * triangle * (3 - 2 * triangle)
    }
}

struct ArtworkView: View {
    var image: NSImage?
    var corner: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: corner > 10 ? 18 : 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.12))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}
