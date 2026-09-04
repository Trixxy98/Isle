import SwiftUI

struct NowPlayingExpandedView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let track = model.nowPlaying.track {
            HStack(alignment: .center, spacing: 12) {
                ArtworkView(image: track.artwork, corner: 12)
                    .frame(width: 74, height: 74)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                    }

                    ProgressSlider(
                        progress: track.progress,
                        elapsed: track.position,
                        duration: track.duration
                    ) { newProgress in
                        model.nowPlaying.seek(to: newProgress * track.duration)
                    }

                    HStack(spacing: 18) {
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
                        Text(track.source.rawValue)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            EmptyIslandState(
                symbol: "music.note",
                title: "Nothing playing",
                subtitle: "Start Music or Spotify"
            )
        }
    }
}

struct TransportButton: View {
    var systemName: String
    var large = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: large ? 16 : 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: large ? 28 : 22, height: large ? 28 : 22)
        }
        .buttonStyle(.plain)
    }
}

struct ProgressSlider: View {
    var progress: Double
    var elapsed: TimeInterval
    var duration: TimeInterval
    var onSeek: (Double) -> Void

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.18))
                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(4, proxy.size.width * progress))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let ratio = min(max(value.location.x / proxy.size.width, 0), 1)
                            onSeek(ratio)
                        }
                )
            }
            .frame(height: 4)

            HStack {
                Text(TimeFormat.clock(elapsed))
                Spacer()
                Text(TimeFormat.clock(duration))
            }
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.45))
            .monospacedDigit()
        }
    }
}

enum TimeFormat {
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct EmptyIslandState: View {
    var symbol: String
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
