import SwiftUI
import TokengochiKit

@main
struct TokengochiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var claudeStore = UsageStore(provider: .claude)
    @StateObject private var codexStore = UsageStore(provider: .codex)

    var body: some Scene {
        MenuBarExtra {
            MultiProviderMenuContentView(stores: visibleStores)
        } label: {
            CombinedMenuBarLabel(stores: visibleStores)
        }
        .menuBarExtraStyle(.window)
    }

    private var visibleStores: [UsageStore] {
        let stores = [claudeStore, codexStore]
        let visible = stores.filter { $0.vitals.hasData || ProviderAvailability.isAvailable($0.provider) }
        return visible.isEmpty ? [claudeStore] : visible
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
