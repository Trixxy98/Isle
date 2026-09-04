import AppKit
import SwiftUI

struct SettingsMenu: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = model.settings

        Text("Isle")
            .font(.headline)

        Toggle("Launch at Login", isOn: $settings.launchAtLogin)

        Divider()

        Button("Quit Isle") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
