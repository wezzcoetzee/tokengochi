import ServiceManagement
import SwiftUI

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var lastError: String?

    private let service = SMAppService.mainApp

    init() {
        isEnabled = service.status == .enabled
    }

    func refresh() {
        isEnabled = service.status == .enabled
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
