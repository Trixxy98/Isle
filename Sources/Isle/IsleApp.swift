import AppKit
import SwiftUI

@main
struct IsleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Isle", systemImage: "capsule.portrait.fill") {
            SettingsMenu()
                .environment(AppModel.shared)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private(set) var panel: IslandPanel?
    private var hostingView: IslandHostingView<IslandRootView>?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        NSApp.setActivationPolicy(.accessory)

        let model = AppModel.shared
        model.start()

        let panel = IslandPanel()
        let hosting = IslandHostingView(rootView: IslandRootView())
        hosting.frame = NSRect(origin: .zero, size: IslandPanel.windowSize)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        panel.orderFrontRegardless()

        self.panel = panel
        self.hostingView = hosting

        repositionPanel()
        startMouseMonitoring()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                AppModel.shared.island.refreshGeometry()
                self?.repositionPanel()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func repositionPanel() {
        guard let panel else { return }
        let geometry = AppModel.shared.island.geometry
        let size = IslandPanel.windowSize
        let x = geometry.centerX - size.width / 2
        let y = geometry.screenFrame.maxY - size.height
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    private var lastOverIsland: Bool?

    private func startMouseMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        ) { event in
            let isClick = event.type == .leftMouseDown
            DispatchQueue.main.async {
                AppDelegate.shared?.syncMouseState(isClick: isClick)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        ) { event in
            AppDelegate.shared?.syncMouseState(isClick: event.type == .leftMouseDown)
            return event
        }

        syncMouseState()
    }

    func syncMouseState(isClick: Bool = false) {
        guard let panel else { return }
        let islandRect = currentIslandScreenRect()
        let overIsland = islandRect.insetBy(dx: -8, dy: -8).contains(NSEvent.mouseLocation)

        if isClick {
            if overIsland {
                AppModel.shared.island.pin()
            } else {
                AppModel.shared.island.unpin()
            }
        }

        guard lastOverIsland != overIsland else { return }
        lastOverIsland = overIsland
        panel.ignoresMouseEvents = !overIsland
        AppModel.shared.island.setHovering(overIsland)
    }

    func currentIslandScreenRect() -> CGRect {
        guard let panel else { return .zero }
        let size = AppModel.shared.island.hitSize
        let frame = panel.frame
        return CGRect(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }
}

struct IslandRootView: View {
    var body: some View {
        IslandView()
            .environment(AppModel.shared)
    }
}
