import AppKit
import SwiftUI

/// Pulls a few vivid colors out of album artwork so the equalizer can match
/// whatever is playing.
enum ArtworkPalette {
    static let fallback: [Color] = [
        Color(red: 0.98, green: 0.29, blue: 0.53),
        Color(red: 1.00, green: 0.60, blue: 0.22),
        Color(red: 0.36, green: 0.85, blue: 0.98),
        Color(red: 0.62, green: 0.51, blue: 0.99)
    ]

    static func colors(from image: NSImage?, count: Int = 4) -> [Color] {
        guard count > 0,
              let image,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let space = CGColorSpace(name: CGColorSpace.sRGB)
        else {
            return fallback
        }

        // Squash the artwork into a single row, then keep the most saturated
        // sample from each horizontal slice.
        let samplesPerSlice = 4
        let width = count * samplesPerSlice
        var pixels = [UInt8](repeating: 0, count: width * 4)

        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: 1))
            return true
        }

        guard drawn else { return fallback }

        return (0..<count).map { slice in
            let range = (slice * samplesPerSlice)..<((slice + 1) * samplesPerSlice)
            let best = range
                .map { sample(pixels, at: $0) }
                .max { saturation(of: $0) < saturation(of: $1) }
            guard let best else { return fallback[slice % fallback.count] }
            return vivid(best)
        }
    }

    private static func sample(_ pixels: [UInt8], at index: Int) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let offset = index * 4
        return (
            CGFloat(pixels[offset]) / 255,
            CGFloat(pixels[offset + 1]) / 255,
            CGFloat(pixels[offset + 2]) / 255
        )
    }

    private static func saturation(of rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGFloat {
        let high = max(rgb.r, rgb.g, rgb.b)
        let low = min(rgb.r, rgb.g, rgb.b)
        guard high > 0 else { return 0 }
        return (high - low) / high
    }

    /// Keeps the artwork's hue but forces enough saturation and brightness to
    /// read against the black island.
    private static func vivid(_ rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> Color {
        let base = NSColor(srgbRed: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        guard let converted = base.usingColorSpace(.sRGB) else { return Color(nsColor: base) }
        return Color(
            hue: Double(converted.hueComponent),
            saturation: Double(max(converted.saturationComponent, 0.7)),
            brightness: Double(min(max(converted.brightnessComponent, 0.85), 1.0))
        )
    }
}
