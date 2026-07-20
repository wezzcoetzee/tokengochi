import Foundation
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

    @Test func subSecondResetJitterDoesNotRollWindow() {
        var state = PetState(lastSessionResetsAt: 1000, windowStartSession: 5, windowPeakSession: 30)
        _ = PetEngine.update(snapshot: snapshot(session: 32, sessionResetsAt: 1000.9), state: &state)

        #expect(state.poops == 0)
        #expect(state.lastSessionResetsAt == 1000)
        #expect(state.windowPeakSession == 32)
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

    @Test func healthReachingZeroKillsThePet() {
        var state = PetState(poops: 10)
        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 50), state: &state)

        #expect(vitals.health == 0)
        #expect(vitals.isDead)
        #expect(state.isDead)
    }

    @Test func deathWipesUnlocksAndBaselinesUsage() {
        var state = PetState(poops: 5, peakWeekly: 80)
        let vitals = PetEngine.update(snapshot: snapshot(session: 10, weekly: 60), state: &state)

        #expect(vitals.isDead)
        #expect(state.peakWeekly == 0)
        #expect(state.unlockFloor == 60)
        #expect(vitals.animationTier == .dormant)
    }

    @Test func deathUnlocksReekAndSurvivesRevival() {
        var state = PetState(poops: 5)
        let dead = PetEngine.update(snapshot: snapshot(session: 10, weekly: 60), state: &state)

        #expect(dead.isDead)
        #expect(dead.reekUnlocked)
        #expect(state.hasDiedOnce)

        PetEngine.revive(state: &state)
        let revived = PetEngine.update(snapshot: snapshot(session: 50, weekly: 60), state: &state)
        #expect(!revived.isDead)
        #expect(revived.reekUnlocked)
        #expect(state.hasDiedOnce)
    }

    @Test func reekLockedUntilFirstDeath() {
        var state = PetState()
        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 60), state: &state)
        #expect(!vitals.reekUnlocked)
    }

    @Test func deadPetIsFrozenUntilRevived() {
        var state = PetState(poops: 5, isDead: true)
        let vitals = PetEngine.update(snapshot: snapshot(session: 96, weekly: 96, sessionResetsAt: 5000), state: &state)

        #expect(vitals.isDead)
        #expect(state.poops == 5)
        #expect(state.peakWeekly == 0)
    }

    @Test func reviveRestoresHealthButKeepsUnlockPenalty() {
        var state = PetState(poops: 5, peakWeekly: 0, isDead: true, unlockFloor: 60)
        PetEngine.revive(state: &state)

        #expect(!state.isDead)
        #expect(state.poops == 0)
        #expect(state.unlockFloor == 60)

        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 60), state: &state)
        #expect(!vitals.isDead)
        #expect(vitals.health == 100)
        #expect(vitals.peakWeekly == 0)
        #expect(vitals.animationTier == .dormant)
    }

    @Test func unlocksReEarnFromUsageAboveFloor() {
        var state = PetState(peakWeekly: 0, unlockFloor: 60)
        _ = PetEngine.update(snapshot: snapshot(session: 50, weekly: 85), state: &state)

        #expect(state.peakWeekly == 25)
    }

    @Test func newWeekClearsUnlockPenalty() {
        var state = PetState(peakWeekly: 0, unlockFloor: 60)
        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 10), state: &state)

        #expect(state.unlockFloor == 0)
        #expect(vitals.peakWeekly == 10)
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

    @Test func sessionMoodTracksSessionNotWeekly() {
        var heavySession = PetState()
        let vitals = PetEngine.update(snapshot: snapshot(session: 74, weekly: 10), state: &heavySession)

        #expect(vitals.mood == .lonely)
        #expect(vitals.sessionMood == .thriving)
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

    @Test func pikaUnlocksOnHighSessionEarlyInWindow() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 90, sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.1)),
            state: &state)

        #expect(vitals.pikaUnlocked)
        #expect(state.pikaUnlocked)
    }

    @Test func pikaDoesNotUnlockOnHighSessionLateInWindow() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 90, sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.4)),
            state: &state)

        #expect(!vitals.pikaUnlocked)
        #expect(!state.pikaUnlocked)
    }

    @Test func pikaDoesNotUnlockAtExactlyEightyPercentEarly() {
        var state = PetState(lastSessionResetsAt: windowEnd)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 80, sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.1)),
            state: &state)

        #expect(!vitals.pikaUnlocked)
        #expect(!state.pikaUnlocked)
    }

    @Test func pikaStaysUnlockedOnLaterLowSessionTicks() {
        var state = PetState(lastSessionResetsAt: windowEnd, pikaUnlocked: true)
        let vitals = PetEngine.update(
            snapshot: snapshot(session: 10, sessionResetsAt: windowEnd, updatedAt: now(atFraction: 0.9)),
            state: &state)

        #expect(vitals.pikaUnlocked)
        #expect(state.pikaUnlocked)
    }

    @Test func deathResetsPikaUnlocked() {
        var state = PetState(poops: 10, pikaUnlocked: true)
        let vitals = PetEngine.update(snapshot: snapshot(session: 50, weekly: 50), state: &state)

        #expect(vitals.isDead)
        #expect(!state.pikaUnlocked)
    }

    @Test func petStateWithoutPikaUnlockedKeyDecodesFalse() throws {
        let json = """
        {"poops":0,"windowPeakSession":0,"windowCleaned":false,"peakWeekly":0,"isDead":false,"unlockFloor":0}
        """.data(using: .utf8)!
        let state = try JSONDecoder().decode(PetState.self, from: json)

        #expect(!state.pikaUnlocked)
    }
}
