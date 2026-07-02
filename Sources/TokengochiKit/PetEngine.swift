import Foundation

public enum Mood: String {
    case sick = "SICK"
    case overfed = "OVERFED"
    case starving = "STARVING"
    case thriving = "THRIVING"
    case okay = "OKAY"
    case lonely = "LONELY"
    case noData = "NO DATA"

    public var emoji: String {
        switch self {
        case .sick: return "🤒"
        case .overfed: return "🐷"
        case .starving: return "🍴"
        case .thriving: return "😄"
        case .okay: return "🙂"
        case .lonely: return "😔"
        case .noData: return "🥚"
        }
    }

    public var symbolName: String {
        switch self {
        case .sick: return "thermometer.medium"
        case .overfed: return "tortoise.fill"
        case .starving: return "fork.knife"
        case .thriving: return "face.smiling.inverse"
        case .okay: return "face.smiling"
        case .lonely: return "cloud.rain"
        case .noData: return "oval.portrait"
        }
    }

    public var spokenName: String {
        switch self {
        case .sick: return "sick"
        case .overfed: return "overfed"
        case .starving: return "starving"
        case .thriving: return "thriving"
        case .okay: return "okay"
        case .lonely: return "lonely"
        case .noData: return "no data yet"
        }
    }

    public var helpCondition: String {
        switch self {
        case .sick: return "health < \(Int(PetEngine.sickHealthThreshold))%"
        case .overfed: return "session ≥ \(Int(PetEngine.overfedSessionThreshold))% with > 1h left"
        case .starving: return "behind pace this window"
        case .thriving: return "happiness ≥ \(Int(PetEngine.thrivingHappinessThreshold))%"
        case .okay: return "happiness ≥ \(Int(PetEngine.okayHappinessThreshold))%"
        case .lonely: return "happiness < \(Int(PetEngine.okayHappinessThreshold))%"
        case .noData: return "no snapshot yet"
        }
    }

    public var helpDescription: String {
        switch self {
        case .sick: return "Too many uncleaned messes. Cured only by using Claude."
        case .overfed: return "Burned through the window early and is now bloated & rate-limited. Pace yourself across the whole window."
        case .starving: return "Behind pace this window. Run a session to feed it."
        case .thriving: return "Strong weekly usage. The happy default for heavy users."
        case .okay: return "Moderate weekly usage. Content but not glowing."
        case .lonely: return "Light week so far. More usage cheers it up."
        case .noData: return "Start a Claude Code session to wake it up."
        }
    }

    public static var helpOrder: [Mood] {
        [.sick, .overfed, .thriving, .okay, .lonely, .starving, .noData]
    }
}

public struct Vitals {
    public let session: Double
    public let weekly: Double
    public let context: Double
    public let hunger: Double
    public let happiness: Double
    public let health: Int
    public let poops: Int
    public let mood: Mood
    public let weight: Double
    public let hasData: Bool
    public let animationTier: AnimationTier
    public let peakWeekly: Double

    public static func noData(poops: Int, health: Int, peakWeekly: Double) -> Vitals {
        Vitals(session: 0, weekly: 0, context: 0, hunger: 100, happiness: 0,
               health: health, poops: poops,
               mood: .noData, weight: 0, hasData: false,
               animationTier: AnimationTier.unlocked(forPeakWeekly: peakWeekly),
               peakWeekly: peakWeekly)
    }

    public var nextAnimationUnlock: (tier: AnimationTier, threshold: Double)? {
        guard let next = animationTier.next else { return nil }
        return (next, next.unlockThreshold)
    }

    public var screenAccessibilityLabel: String {
        guard hasData else {
            return "Tokengochi: no data yet. Start a Claude Code session to wake it up."
        }
        let fedTenths = Int(((100 - hunger) / 10).rounded())
        let happinessTenths = Int((happiness / 10).rounded())
        var parts = [
            "Tokengochi: \(mood.spokenName)",
            "fed \(fedTenths) of 10",
            "happiness \(happinessTenths) of 10"
        ]
        if poops > 0 {
            parts.append(poops == 1 ? "1 mess to clean up" : "\(poops) messes to clean up")
        }
        return parts.joined(separator: ", ") + "."
    }
}

public enum PetEngine {
    public static let wastedWindowThreshold = 20.0
    public static let minEngagedSessionDelta = 3.0
    public static let cleanThreshold = 25.0
    public static let healthPerPoop = 20
    public static let sessionWindowSeconds = 5.0 * 3600
    /// The OAuth usage endpoint returns the same window's `resets_at` with sub-second
    /// jitter on every poll, so only an advance larger than this counts as a real new
    /// window. Distinct 5-hour windows are always at least 5 hours apart.
    public static let windowRollTolerance = 60.0
    public static let overfedSessionThreshold = 90.0
    public static let overfedWindowFraction = 0.8
    public static let overfedHappinessFloor = 50.0
    public static let overfedHappinessCeiling = 90.0
    public static let happinessWeeklyMultiplier = 1.1
    public static let sickHealthThreshold = 40.0
    public static let thrivingHappinessThreshold = 70.0
    public static let okayHappinessThreshold = 35.0

    public static func update(snapshot: UsageSnapshot?, state: inout PetState) -> Vitals {
        guard let snapshot, let rawSession = snapshot.sessionPct else {
            return Vitals.noData(poops: state.poops,
                                 health: health(forPoops: state.poops),
                                 peakWeekly: state.peakWeekly)
        }

        let clamp = { (value: Double) in min(100, max(0, value)) }
        let session = clamp(rawSession)
        let weekly = clamp(snapshot.weeklyPct ?? 0)
        let context = clamp(snapshot.contextPct ?? 0)

        rollWindowIfNeeded(snapshot.sessionResetsAt, state: &state)
        if state.windowStartSession == nil { state.windowStartSession = session }
        state.windowPeakSession = max(state.windowPeakSession, session)
        state.peakWeekly = max(state.peakWeekly, weekly)

        if session >= cleanThreshold && !state.windowCleaned && state.poops > 0 {
            state.poops -= 1
            state.windowCleaned = true
        }

        let hunger = 100 - session
        let currentHealth = health(forPoops: state.poops)

        let elapsed = windowElapsedFraction(now: snapshot.updatedAt, end: snapshot.sessionResetsAt)
        let overfed = isOverfed(session: session, elapsed: elapsed)
        let overfedSeverity = overfedSeverity(elapsed: elapsed)
        let behindPace = isBehindPace(session: session, elapsed: elapsed)

        var happiness = min(100, weekly * happinessWeeklyMultiplier)
        if overfed {
            let cap = overfedHappinessFloor + (1 - overfedSeverity) * (overfedHappinessCeiling - overfedHappinessFloor)
            happiness = min(happiness, cap)
        }

        let mood: Mood
        if currentHealth < Int(sickHealthThreshold) { mood = .sick }
        else if overfed { mood = .overfed }
        else if happiness >= thrivingHappinessThreshold { mood = .thriving }
        else if happiness >= okayHappinessThreshold { mood = .okay }
        else if behindPace { mood = .starving }
        else { mood = .lonely }

        let baseWeight = min(0.7, weekly / 100 * 0.7)
        let weight = min(1.0, baseWeight + (overfed ? overfedSeverity * 0.3 : 0))

        return Vitals(session: session, weekly: weekly, context: context,
                      hunger: hunger, happiness: happiness, health: currentHealth,
                      poops: state.poops, mood: mood, weight: weight, hasData: true,
                      animationTier: AnimationTier.unlocked(forPeakWeekly: state.peakWeekly),
                      peakWeekly: state.peakWeekly)
    }

    private static func rollWindowIfNeeded(_ resetsAt: Double?, state: inout PetState) {
        guard let resetsAt else { return }
        guard let last = state.lastSessionResetsAt else {
            state.lastSessionResetsAt = resetsAt
            return
        }
        guard resetsAt > last + windowRollTolerance else { return }
        let engagement = state.windowPeakSession - (state.windowStartSession ?? 0)
        let windowWasUsed = engagement >= minEngagedSessionDelta
        if windowWasUsed && state.windowPeakSession < wastedWindowThreshold { state.poops += 1 }
        state.windowStartSession = nil
        state.windowPeakSession = 0
        state.windowCleaned = false
        state.lastSessionResetsAt = resetsAt
    }

    private static func health(forPoops poops: Int) -> Int {
        max(0, 100 - poops * healthPerPoop)
    }

    private static func windowElapsedFraction(now: Double, end: Double?) -> Double? {
        guard let end else { return nil }
        let start = end - sessionWindowSeconds
        guard now > start else { return nil }
        return min(1, (now - start) / sessionWindowSeconds)
    }

    private static func isOverfed(session: Double, elapsed: Double?) -> Bool {
        guard let elapsed else { return false }
        return session >= overfedSessionThreshold && elapsed < overfedWindowFraction
    }

    private static func overfedSeverity(elapsed: Double?) -> Double {
        guard let elapsed else { return 0 }
        return min(1, max(0, (overfedWindowFraction - elapsed) / overfedWindowFraction))
    }

    private static func isBehindPace(session: Double, elapsed: Double?) -> Bool {
        guard let elapsed else { return session < wastedWindowThreshold }
        return session < elapsed * 100 - wastedWindowThreshold
    }
}
