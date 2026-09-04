import Foundation
import ServiceManagement

@Observable
@MainActor
final class AppSettings {
    var launchAtLogin: Bool {
        didSet {
            guard ready, launchAtLogin != oldValue else { return }
            setLaunchAtLogin(launchAtLogin)
        }
    }

    private var ready = false

    init() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        ready = true
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
