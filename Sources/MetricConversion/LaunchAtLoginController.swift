import Combine
import Foundation
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable
}

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var state: LaunchAtLoginState = .disabled

    private let defaults: UserDefaults
    private let registrationKey = "hasRegisteredLaunchAtLogin"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refreshState()
    }

    func registerOnFirstLaunch() {
        guard !defaults.bool(forKey: registrationKey) else {
            refreshState()
            return
        }

        do {
            try SMAppService.mainApp.register()
            defaults.set(true, forKey: registrationKey)
            refreshState()
        } catch {
            state = .unavailable
        }
    }

    func setEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
                defaults.set(true, forKey: registrationKey)
            } else {
                try SMAppService.mainApp.unregister()
                defaults.set(true, forKey: registrationKey)
            }
            refreshState()
        } catch {
            state = .unavailable
        }
    }

    func refreshState() {
        switch SMAppService.mainApp.status {
        case .enabled:
            state = .enabled
        case .requiresApproval:
            state = .requiresApproval
        case .notRegistered, .notFound:
            state = .disabled
        @unknown default:
            state = .unavailable
        }
    }
}