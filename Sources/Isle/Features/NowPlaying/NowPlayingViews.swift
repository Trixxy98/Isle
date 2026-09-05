import AppKit
import SwiftUI

struct NowPlayingIslandContent: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let track = model.nowPlaying.track {
            playingBody(track)
        } else {
            EmptyIslandState(
                symbol: "music.note",
                title: "Nothing playing",
                subtitle: "Start Music or Spotify"
            )
        }
    }

    private var isExpanded: Bool {
        model.island.mode == .expanded
    }

    private func playingBody(_ track: NowPlayingTrack) -> some View {
        VStack(spacing: isExpanded ? 12 : 0) {
            HStack(alignment: .center, spacing: isExpanded ? 10 : 0) {
                ArtworkView(image: track.artwork, corner: isExpanded ? 10 : 5)
                    .frame(width: isExpanded ? 44 : 20, height: isExpanded ? 44 : 20)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    .transition(.opacity.combined(with: .offset(x: -6)))
                }

                Spacer(minLength: isExpanded ? 8 : 0)

                EqualizerBars(
                    isPlaying: track.isPlaying,
                    pauseStartedAt: model.nowPlaying.pausedAt,
                    colors: model.nowPlaying.palette,
                    style: isExpanded ? .expanded : .compact
                )
            }

            if isExpanded {
                ProgressSlider(track: track) { newProgress in
                    model.nowPlaying.seek(to: newProgress * track.duration)
                }

                HStack {
                    Spacer(minLength: 0)
                    TransportButton(systemName: "backward.fill") {
                        model.nowPlaying.previousTrack()
                    }
                    TransportButton(systemName: track.isPlaying ? "pause.fill" : "play.fill", large: true) {
                        model.nowPlaying.playPause()
                    }
                    TransportButton(systemName: "forward.fill") {
                        model.nowPlaying.nextTrack()
                    }
                    Spacer(minLength: 0)
                    Button(action: openSoundOutput) {
                        Image(systemName: "airplayaudio")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(IslePressButtonStyle())
                    .help("Sound Output")
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func openSoundOutput() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

enum EqualizerStyle {
    case compact
    case expanded
}

struct EqualizerBars: View {
    var isPlaying: Bool
    var pauseStartedAt: Date?
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

    private var isSettling: Bool {
        guard !isPlaying, let pauseStartedAt else { return false }
        return Date().timeIntervalSince(pauseStartedAt) < 0.22
    }

    var body: some View {
        let specs = bars
        let live = isPlaying || isSettling
        TimelineView(.animation(minimumInterval: live ? 1.0 / 30.0 : 10, paused: !live)) { timeline in
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
        let live = spec.low + (spec.high - spec.low) * CGFloat(easeInOutPingPong(
            date.timeIntervalSinceReferenceDate + spec.phase,
            period: spec.period
        ))
        guard !isPlaying else { return live }
        guard let pauseStartedAt else { return spec.rest }
        let t = min(1, date.timeIntervalSince(pauseStartedAt) / 0.22)
        let eased = t * t * (3 - 2 * t)
        return live + (spec.rest - live) * CGFloat(eased)
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
