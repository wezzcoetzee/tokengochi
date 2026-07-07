import Foundation

/// Owns the field-ownership rule that lets two Claude producers write one provider snapshot
/// without clobbering each other.
///
/// `TokengochiPoller` owns session/weekly utilization and both reset times (rolling
/// `utilization` from the OAuth usage endpoint, which `PetEngine` is tuned for).
/// `TokengochiWriter` owns context/model/effort/fastMode (from the Claude Code
/// statusline payload) and falls back to its own `used_percentage` for session/weekly
/// only when no poll has landed yet. Each producer hands this module only the fields it
/// owns; the module preserves the other producer's fields from the previous snapshot.
/// Keeping `resets_at` single-sourced this way stops `PetEngine` from seeing phantom
/// window rolls.
public enum SnapshotMerge {
    public static func pollerObservation(
        sessionPct: Double?, weeklyPct: Double?,
        sessionResetsAt: Double?, weeklyResetsAt: Double?,
        into previous: UsageSnapshot?, at now: Double
    ) -> UsageSnapshot {
        UsageSnapshot(
            provider: .claude,
            source: .claudePoller,
            measurementKind: .exactQuota,
            sessionPct: sessionPct,
            weeklyPct: weeklyPct,
            contextPct: previous?.contextPct,
            sessionResetsAt: sessionResetsAt,
            weeklyResetsAt: weeklyResetsAt,
            model: previous?.model,
            effortLevel: previous?.effortLevel,
            fastMode: previous?.fastMode,
            updatedAt: now)
    }

    public static func statuslineObservation(
        contextPct: Double?, model: String?, effortLevel: String?, fastMode: Bool?,
        fallbackSessionPct: Double?, fallbackWeeklyPct: Double?,
        fallbackSessionResetsAt: Double?, fallbackWeeklyResetsAt: Double?,
        into previous: UsageSnapshot?, at now: Double
    ) -> UsageSnapshot {
        UsageSnapshot(
            provider: .claude,
            source: .claudeStatusline,
            measurementKind: previous?.measurementKind ?? .exactQuota,
            sessionPct: previous?.sessionPct ?? fallbackSessionPct,
            weeklyPct: previous?.weeklyPct ?? fallbackWeeklyPct,
            contextPct: contextPct,
            sessionResetsAt: previous?.sessionResetsAt ?? fallbackSessionResetsAt,
            weeklyResetsAt: previous?.weeklyResetsAt ?? fallbackWeeklyResetsAt,
            model: model,
            effortLevel: effortLevel,
            fastMode: fastMode,
            updatedAt: now)
    }
}
