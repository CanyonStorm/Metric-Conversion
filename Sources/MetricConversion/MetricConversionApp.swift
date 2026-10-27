import AppKit
import SwiftUI

@main
struct MetricConversionApp: App {
    @StateObject private var launchAtLoginController = LaunchAtLoginController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("Metric Converter", systemImage: "ruler") {
            ConverterView(launchAtLoginController: launchAtLoginController)
                .task {
                    launchAtLoginController.registerOnFirstLaunch()
                }
        }
        .menuBarExtraStyle(.window)
    }
}