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
                colors: model.nowPlaying.palette
            )
            .frame(width: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EqualizerBars: View {
    var isPlaying: Bool
    var colors: [Color] = ArtworkPalette.fallback

    var body: some View {
        TimelineView(.animation(minimumInterval: isPlaying ? 0.12 : 10, paused: !isPlaying)) { timeline in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(gradient(for: index))
                        .frame(width: 2.5, height: barHeight(index: index, date: timeline.date))
                }
            }
            .frame(height: 14, alignment: .bottom)
        }
    }

    private func gradient(for index: Int) -> LinearGradient {
        let color = colors.isEmpty
            ? ArtworkPalette.fallback[index % ArtworkPalette.fallback.count]
            : colors[index % colors.count]
        return LinearGradient(
            colors: [color.opacity(0.55), color],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func barHeight(index: Int, date: Date) -> CGFloat {
        guard isPlaying else { return [6, 10, 7, 5][index] }
        let t = date.timeIntervalSinceReferenceDate
        let wave = sin(t * 7 + Double(index) * 1.1)
        return 5 + CGFloat((wave + 1) / 2) * 9
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
