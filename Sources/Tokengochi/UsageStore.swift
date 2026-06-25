import Foundation
import TokengochiKit

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var vitals: Vitals
    @Published private(set) var updatedAt: Date?
    @Published private(set) var sessionResetsAt: Date?
    @Published private(set) var weeklyResetsAt: Date?
    @Published private(set) var model: String?
    @Published private(set) var effortLevel: String?
    @Published private(set) var fastMode: Bool?

    private let session: PetSession
    private var timer: Timer?
    private var isActive = false

    private static let activeInterval: TimeInterval = 5
    private static let idleInterval: TimeInterval = 30

    init(store: SnapshotStore = DiskSnapshotStore()) {
        session = PetSession(store: store)
        var placeholder = PetState()
        vitals = PetEngine.update(snapshot: nil, state: &placeholder)
        refresh()
        scheduleTimer(interval: Self.idleInterval)
    }

    deinit {
        timer?.invalidate()
    }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        if active { refresh() }
        scheduleTimer(interval: active ? Self.activeInterval : Self.idleInterval)
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        let (vitals, snapshot) = session.refresh()
        self.vitals = vitals
        if let snapshot {
            updatedAt = Date(timeIntervalSince1970: snapshot.updatedAt)
            sessionResetsAt = snapshot.sessionResetsAt.map { Date(timeIntervalSince1970: $0) }
            weeklyResetsAt = snapshot.weeklyResetsAt.map { Date(timeIntervalSince1970: $0) }
            model = snapshot.model
            effortLevel = snapshot.effortLevel
            fastMode = snapshot.fastMode
        }
    }

    var sessionResetText: String? { Self.resetText(for: sessionResetsAt) }

    var weeklyResetText: String? { Self.resetText(for: weeklyResetsAt) }

    private static func resetText(for date: Date?) -> String? {
        guard let date else { return nil }
        return TimeFormatting.countdown(secondsRemaining: Int(date.timeIntervalSince(Date())))
    }

    var freshnessText: String {
        guard let updatedAt else { return "no data yet. start a Claude Code session" }
        return TimeFormatting.freshness(secondsAgo: Int(Date().timeIntervalSince(updatedAt)))
    }
}
