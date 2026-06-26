import Testing
@testable import TokengochiKit

private func snapshot(session: Double?, weekly: Double? = 0, context: Double? = nil,
                      sessionResetsAt: Double? = nil, updatedAt: Double = 0) -> UsageSnapshot {
    UsageSnapshot(sessionPct: session, weeklyPct: weekly, contextPct: context,
                  sessionResetsAt: sessionResetsAt, weeklyResetsAt: nil, updatedAt: updatedAt)
}

private let windowEnd = 100_000.0
private let windowStart = 100_000.0 - PetEngine.sessionWindowSeconds

private func now(atFraction f: Double) -> Double {
    windowStart + f * PetEngine.sessionWindowSeconds
}

@Suite struct PetEngineTests {
    @Test func nilSnapshotReportsNoData() {
        var state = PetState(poops: 2)
        let vitals = PetEngine.update(snapshot: nil, state: &state)

        #expect(!vitals.hasData)
        #expect(vitals.mood == .noData)
        #expect(vitals.health == 100 - 2 * PetEngine.healthPerPoop)
        #expect(vitals.poops == 2)
    }

    @Test func nilSessionPctReportsNoData() {
        var state = PetState()
        let vitals = PetEngine.update(snapshot: snapshot(session: nil), state: &state)

        #expect(!vitals.hasData)
        #expect(vitals.mood == .noData)
    }

    @Test func firstObservationSetsBaselineWithoutPoop() {
        var state = PetState(lastSessionResetsAt: nil, windowPeakSession: 0)
        _ = PetEngine.update(snapshot: snapshot(session: 5, sessionResetsAt: 2000), state: &state)

        #expect(state.poops == 0)
        #expect(state.lastSessionResetsAt == 2000)
    }

    @Test func wastedWindowAddsPoopOnRollover() {
        var state = PetState(lastSessionResetsAt: 1000, windowPeakSession: 10)
        _ = PetEngine.update(snapshot: snapshot(session: 5, sessionResetsAt: 2000), state: &state)

        #expect(state.poops == 1)
        #expect(state.windowPeakSession == 5)
        #expect(!state.windowCleaned)
    }

    @Test func sleptThroughWindowWithResidualOnlyDoesNotAddPoop() {
        var state = PetState(lastSessionResetsAt: 1000,
                             windowStartSession: 12, windowPeakSession: 12)
        _ = PetEngine.update(snapshot: snapshot(session: 5, sessionResetsAt: 2000), state: &state)

        #expect(state.poops == 0)
    }

    @Test func lightlyUsedWindowBelowEngagementFloorDoesNotAddPoop() {
        var state = PetState(lastSessionResetsAt: 1000,
                             windowStartSession: 0, windowPeakSession: 2)
        _ = PetEngine.update(snapshot: snapshot(session: 5, sessionResetsAt: 2000), state: &state)

        #expect(state.poops == 0)
    }

    @Test func productiveWindowDoesNotAddPoopOnRollover() {
        var state = PetState(lastSessionResetsAt: 1000, windowPeakSession: 50)
        _ = PetEngine.update(snapshot: snapshot(session: 5, sessionResetsAt: 2000), state: &state)

        #expect(state.poops == 0)
    }

    @Test func peakExactlyAtThresholdIsNotWasted() {
        var state = PetState(lastSessionResetsAt: 1000,
                             windowPeakSession: PetEngine.wastedWindowThreshold)
        _ = PetEngine.update(snapshot: snapshot(session: 5, sessionResetsAt: 2000), state: &state)

        #expect(state.poops == 0)
    }

    @Test func cleanFiresOncePerWindow() {
        var state = PetState(poops: 2)
        _ = PetEngine.update(snapshot: snapshot(session: PetEngine.cleanThreshold), state: &state)
        #expect(state.poops == 1)
        #expect(state.windowCleaned)

        _ = PetEngine.update(snapshot: snapshot(session: PetEngine.cleanThreshold), state: &state)
        #expect(state.poops == 1)
    }

    @Test func cleanRequiresMessToClean() {
        var state = PetState(poops: 0)
        _ = PetEngine.update(snapshot: snapshot(session: PetEngine.cleanThreshold), state: &state)

        #expect(state.poops == 0)
        #expect(!state.windowCleaned)
    }

    @Test func healthFloorsAtZero() {
        var state = PetState(poops: 10)
        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 50), state: &state)

        #expect(vitals.health == 0)
        #expect(vitals.mood == .sick)
    }

    @Test func moodSickWinsOverMaxedAfterWindowClean() {
        var state = PetState(poops: 5)
        let vitals = PetEngine.update(snapshot: snapshot(session: 96, weekly: 96), state: &state)

        #expect(state.poops == 4)
        #expect(vitals.health == 20)
        #expect(vitals.mood == .sick)
    }

    @Test func moodOverfedWhenMaxedEarly() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 10,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.2)),
            state: &state)

        #expect(vitals.mood == .overfed)
    }

    @Test func notOverfedWhenMaxedNearWindowEnd() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 70,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.9)),
            state: &state)

        #expect(vitals.mood != .overfed)
        #expect(vitals.mood == .thriving)
    }

    @Test func overfedCapsHappinessEvenWhenWeeklyMaxed() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 100,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.2)),
            state: &state)

        #expect(vitals.mood == .overfed)
        #expect(vitals.happiness < 100)
        #expect(vitals.happiness <= PetEngine.overfedHappinessCeiling)
    }

    @Test func overfedBloatsWeightPastHealthyBand() {
        var paced = PetState()
        let pacedVitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 100), state: &paced)

        var overfed = PetState(lastSessionResetsAt: windowEnd)
        let overfedVitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 100,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.2)),
            state: &overfed)

        #expect(pacedVitals.weight <= 0.7)
        #expect(overfedVitals.weight > pacedVitals.weight)
    }

    @Test func heavyWeekIsThrivingNotStarvingEarlyInWindow() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 5, weekly: 90,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.05)),
            state: &state)

        #expect(vitals.mood == .thriving)
    }

    @Test func behindPaceLateInWindowStarves() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 10, weekly: 10,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.8)),
            state: &state)

        #expect(vitals.mood == .starving)
    }

    @Test func healthUnaffectedByOverfeeding() {
        var state = PetState(poops: 1, lastSessionResetsAt: windowEnd, windowCleaned: true)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 100,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.2)),
            state: &state)

        #expect(vitals.health == 100 - PetEngine.healthPerPoop)
    }

    @Test func moodByHappiness() {
        var thriving = PetState()
        #expect(PetEngine.update(snapshot: snapshot(session: 50, weekly: 70), state: &thriving).mood == .thriving)

        var okay = PetState()
        #expect(PetEngine.update(snapshot: snapshot(session: 50, weekly: 40), state: &okay).mood == .okay)

        var lonely = PetState()
        #expect(PetEngine.update(snapshot: snapshot(session: 50, weekly: 10), state: &lonely).mood == .lonely)
    }

    @Test func peakWeeklyMonotonicAndDrivesAnimationTier() {
        var state = PetState(peakWeekly: 50)
        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 10), state: &state)

        #expect(state.peakWeekly == 50)
        #expect(vitals.animationTier == AnimationTier.unlocked(forPeakWeekly: 50))
    }

    @Test func behindPaceWithoutResetTimeStarvesWhenSessionLow() {
        var state = PetState()
        let vitals = PetEngine.update(snapshot: snapshot(session: 10, weekly: 5), state: &state)
        #expect(vitals.mood == .starving)
    }

    @Test func notBehindPaceWithoutResetTimeIsLonelyWhenSessionPastThreshold() {
        var state = PetState()
        let vitals = PetEngine.update(snapshot: snapshot(session: 30, weekly: 5), state: &state)
        #expect(vitals.mood == .lonely)
    }

    @Test func overfedHappinessCapTightensEarlierInWindow() {
        var early = PetState(lastSessionResetsAt: windowEnd)
        let earlyVitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 100,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.2)),
            state: &early)
        var late = PetState(lastSessionResetsAt: windowEnd)
        let lateVitals = PetEngine.update(
            snapshot: snapshot(session: 96, weekly: 100,
                               sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.6)),
            state: &late)
        #expect(earlyVitals.mood == .overfed)
        #expect(lateVitals.mood == .overfed)
        #expect(earlyVitals.happiness < lateVitals.happiness)
    }
}
