import AppKit
import SwiftUI

struct NowPlayingExpandedView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let track = model.nowPlaying.track {
            VStack(spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    ArtworkView(image: track.artwork, corner: 10)
                        .frame(width: 44, height: 44)

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

                    Spacer(minLength: 8)

                    EqualizerBars(
                        isPlaying: track.isPlaying,
                        colors: model.nowPlaying.palette,
                        style: .expanded
                    )
                }

                ProgressSlider(
                    progress: track.progress,
                    elapsed: track.position,
                    duration: track.duration
                ) { newProgress in
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
                    .buttonStyle(.plain)
                    .help("Sound Output")
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

    private func openSoundOutput() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(url)
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
                .font(.system(size: large ? 18 : 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: large ? 34 : 28, height: large ? 34 : 28)
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
        VStack(spacing: 5) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.22))
                    Capsule()
                        .fill(Color.white.opacity(0.9))
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
            .frame(height: 3)

            HStack {
                Text(TimeFormat.clock(elapsed))
                Spacer()
                Text(TimeFormat.remaining(duration - elapsed))
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
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

    static func remaining(_ interval: TimeInterval) -> String {
        "-\(clock(interval))"
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
