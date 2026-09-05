import AppKit
import SwiftUI

enum IsleHaptics {
    static func alignment() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}

struct IslePressButtonStyle: ButtonStyle {
    var playsHaptic = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed, playsHaptic {
                    IsleHaptics.alignment()
                }
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
        .buttonStyle(IslePressButtonStyle())
    }
}

struct ProgressSlider: View {
    var track: NowPlayingTrack
    var onSeek: (Double) -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !track.isPlaying)) { timeline in
            let elapsed = track.displayPosition(at: timeline.date)
            let progress = track.displayProgress(at: timeline.date)
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
                    Text(TimeFormat.remaining(track.duration - elapsed))
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .monospacedDigit()
            }
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
