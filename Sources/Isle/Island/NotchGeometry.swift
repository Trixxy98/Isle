import AppKit
import CoreGraphics

struct NotchGeometry: Equatable {
    var screenFrame: CGRect
    var notchFrame: CGRect
    var width: CGFloat
    var height: CGFloat
    var hasNotch: Bool

    var centerX: CGFloat { notchFrame.midX }
    var size: CGSize { CGSize(width: width, height: height) }

    static func detect() -> NotchGeometry {
        let notched = NSScreen.screens.first { screen in
            guard let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea else {
                return false
            }
            return screen.safeAreaInsets.top > 0 && left.width > 0 && right.width > 0
        }

        if let screen = notched {
            return fromNotchedScreen(screen)
        }

        if let screen = NSScreen.main ?? NSScreen.screens.first {
            return fallback(on: screen)
        }
        let frame = CGRect(x: 0, y: 0, width: 1470, height: 956)
        return NotchGeometry(
            screenFrame: frame,
            notchFrame: CGRect(x: frame.midX - 90, y: frame.maxY - 32, width: 180, height: 32),
            width: 180,
            height: 32,
            hasNotch: false
        )
    }

    private static func fromNotchedScreen(_ screen: NSScreen) -> NotchGeometry {
        let frame = screen.frame
        guard let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea else {
            return fallback(on: screen)
        }
        // The menu bar is a touch taller than the safe area inset (38 vs 37.5 on
        // an M4 Air), so use it to keep the collapsed island flush with it.
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let height = max(menuBarHeight, screen.safeAreaInsets.top)
        let minX = left.maxX
        let maxX = right.minX
        let width = max(maxX - minX, 40)
        let notchFrame = CGRect(
            x: minX,
            y: frame.maxY - height,
            width: width,
            height: height
        )
        return NotchGeometry(
            screenFrame: frame,
            notchFrame: notchFrame,
            width: width,
            height: height,
            hasNotch: true
        )
    }

    private static func fallback(on screen: NSScreen) -> NotchGeometry {
        let frame = screen.frame
        let width: CGFloat = 180
        let height: CGFloat = 32
        let notchFrame = CGRect(
            x: frame.midX - width / 2,
            y: frame.maxY - height,
            width: width,
            height: height
        )
        return NotchGeometry(
            screenFrame: frame,
            notchFrame: notchFrame,
            width: width,
            height: height,
            hasNotch: false
        )
    }
}
