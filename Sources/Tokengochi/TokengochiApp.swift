import SwiftUI
import TokengochiKit

@main
struct TokengochiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = UsageStore()
    @StateObject private var poller = PollerManager()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(store: store, poller: poller)
                .task { poller.enableIfNeeded() }
        } label: {
            let vitals = store.vitals
            if vitals.hasData {
                Label("\(Int(vitals.session))%", systemImage: vitals.sessionMood.symbolName)
            } else {
                Label("—", systemImage: Mood.noData.symbolName)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
