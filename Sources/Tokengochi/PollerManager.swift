import ServiceManagement
import SwiftUI

@MainActor
final class PollerManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var lastError: String?

    private let service = SMAppService.agent(plistName: "com.tokengochi.poller.plist")

    init() {
        isEnabled = service.status == .enabled
    }

    func refresh() {
        isEnabled = service.status == .enabled
    }

    func enableIfNeeded() {
        if service.status == .enabled {
            try? service.unregister()
        }
        setEnabled(true)
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
