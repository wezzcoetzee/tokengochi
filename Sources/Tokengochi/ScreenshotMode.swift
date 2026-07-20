#if DEBUG
import SwiftUI
import TokengochiKit

/// App Store capture harness. `-uiScreenshots -uiScreen <id>` swaps the disk-backed
/// store for seeded demo data and presents the panel in a regular window, because the
/// production `MenuBarExtra` popover sits at a window layer `screencapture` can't reach.
enum ScreenshotMode {
    static var isEnabled: Bool { CommandLine.arguments.contains("-uiScreenshots") }

    private static var screen: String {
        guard let flag = CommandLine.arguments.firstIndex(of: "-uiScreen"),
              CommandLine.arguments.indices.contains(flag + 1) else { return "healthy" }
        return CommandLine.arguments[flag + 1]
    }

    @MainActor
    static func makeWindow() -> NSWindow {
        let store = UsageStore(store: demoStore(for: screen))
        let content = MenuContentView(store: store, poller: PollerManager(),
                                      startShowingHelp: screen == "help",
                                      startShowingSettings: screen == "settings")
        let hosting = NSHostingController(rootView: content.frame(width: 300))
        hosting.sizingOptions = [.preferredContentSize]
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        for button: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        window.setContentSize(NSSize(width: 300, height: hosting.view.fittingSize.height))
        if let visible = NSScreen.main?.visibleFrame {
            window.setFrameOrigin(NSPoint(x: visible.midX - window.frame.width / 2,
                                          y: visible.midY - window.frame.height / 2))
        }
        window.makeKeyAndOrderFront(nil)
        return window
    }

    private static func demoStore(for screen: String) -> SnapshotStore {
        let now = Date().timeIntervalSince1970
        func snapshot(session: Double, weekly: Double, context: Double,
                      model: String, effort: String, fastMode: Bool) -> UsageSnapshot {
            UsageSnapshot(sessionPct: session, weeklyPct: weekly, contextPct: context,
                          sessionResetsAt: now + 2 * 3600, weeklyResetsAt: now + 3 * 86400,
                          model: model, effortLevel: effort, fastMode: fastMode,
                          updatedAt: now - 45)
        }

        switch screen {
        case "claude":
            return DemoSnapshotStore(
                snapshot: snapshot(session: 78, weekly: 97, context: 55,
                                   model: "Opus 4.8", effort: "xhigh", fastMode: true),
                state: PetState(windowCleaned: true, peakWeekly: 97))
        case "pika":
            return DemoSnapshotStore(
                snapshot: snapshot(session: 88, weekly: 72, context: 48,
                                   model: "Opus 4.8", effort: "high", fastMode: true),
                state: PetState(windowCleaned: true, peakWeekly: 72, pikaUnlocked: true))
        case "neglected":
            return DemoSnapshotStore(
                snapshot: snapshot(session: 12, weekly: 34, context: 18,
                                   model: "Sonnet 5", effort: "medium", fastMode: false),
                state: PetState(poops: 4, windowCleaned: true, peakWeekly: 34))
        default:
            return DemoSnapshotStore(
                snapshot: snapshot(session: 64, weekly: 68, context: 41,
                                   model: "Opus 4.8", effort: "high", fastMode: false),
                state: PetState(windowCleaned: true, peakWeekly: 68))
        }
    }
}

private struct DemoSnapshotStore: SnapshotStore {
    let snapshot: UsageSnapshot
    let state: PetState

    func loadSnapshot() -> UsageSnapshot? { snapshot }
    func loadPetState() -> PetState { state }
    func savePetState(_ state: PetState) {}
}
#endif
