import Testing
@testable import TokengochiKit

private func previous(session: Double? = 40, weekly: Double? = 60, context: Double? = 30,
                      sessionResets: Double? = 1000, weeklyResets: Double? = 2000,
                      model: String? = "Opus", effort: String? = "high",
                      fast: Bool? = true) -> UsageSnapshot {
    UsageSnapshot(sessionPct: session, weeklyPct: weekly, contextPct: context,
                  sessionResetsAt: sessionResets, weeklyResetsAt: weeklyResets,
                  model: model, effortLevel: effort, fastMode: fast, updatedAt: 0)
}

@Suite struct SnapshotMergeTests {
    @Test func pollerOwnsSessionWeeklyResetsAndPreservesWriterFields() {
        let merged = SnapshotMerge.pollerObservation(
            sessionPct: 11, weeklyPct: 22, sessionResetsAt: 3000, weeklyResetsAt: 4000,
            into: previous(), at: 99)

        #expect(merged.sessionPct == 11)
        #expect(merged.weeklyPct == 22)
        #expect(merged.sessionResetsAt == 3000)
        #expect(merged.weeklyResetsAt == 4000)
        #expect(merged.contextPct == 30)
        #expect(merged.model == "Opus")
        #expect(merged.effortLevel == "high")
        #expect(merged.fastMode == true)
        #expect(merged.updatedAt == 99)
    }

    @Test func statuslineOwnsContextModelEffortAndPreservesPollerFields() {
        let merged = SnapshotMerge.statuslineObservation(
            contextPct: 77, model: "Sonnet", effortLevel: "low", fastMode: false,
            fallbackSessionPct: 5, fallbackWeeklyPct: 5,
            fallbackSessionResetsAt: 8, fallbackWeeklyResetsAt: 9,
            into: previous(), at: 99)

        #expect(merged.contextPct == 77)
        #expect(merged.model == "Sonnet")
        #expect(merged.effortLevel == "low")
        #expect(merged.fastMode == false)
        #expect(merged.sessionPct == 40)
        #expect(merged.weeklyPct == 60)
        #expect(merged.sessionResetsAt == 1000)
        #expect(merged.weeklyResetsAt == 2000)
    }

    @Test func statuslineFallsBackOnlyWhenNoPoll() {
        let merged = SnapshotMerge.statuslineObservation(
            contextPct: 77, model: nil, effortLevel: nil, fastMode: nil,
            fallbackSessionPct: 5, fallbackWeeklyPct: 6,
            fallbackSessionResetsAt: 8, fallbackWeeklyResetsAt: 9,
            into: nil, at: 99)

        #expect(merged.sessionPct == 5)
        #expect(merged.weeklyPct == 6)
        #expect(merged.sessionResetsAt == 8)
        #expect(merged.weeklyResetsAt == 9)
    }

    @Test func pollerPreservesNothingWhenNoPrevious() {
        let merged = SnapshotMerge.pollerObservation(
            sessionPct: 11, weeklyPct: 22, sessionResetsAt: 3000, weeklyResetsAt: 4000,
            into: nil, at: 99)

        #expect(merged.contextPct == nil)
        #expect(merged.model == nil)
        #expect(merged.fastMode == nil)
    }
}
