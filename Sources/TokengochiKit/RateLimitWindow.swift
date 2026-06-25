import Foundation

/// Pulls a rate-limit window's percentage and reset time out of a vendor JSON dict.
///
/// The two producers read different shapes: the OAuth usage endpoint reports
/// `utilization` (already 0–100), while the Claude Code statusline reports
/// `used_percentage`. Each source gets its own extractor so the key and clamping
/// stay with the shape they belong to.
public enum RateLimitWindow {
    public static func usageEndpoint(_ value: Any?) -> (pct: Double?, resetsAt: Double?) {
        let dict = value as? [String: Any]
        return (UsageParsing.percentage(dict?["utilization"]),
                UsageParsing.epochSeconds(dict?["resets_at"]))
    }

    public static func statusline(_ value: Any?) -> (pct: Double?, resetsAt: Double?) {
        let dict = value as? [String: Any]
        return (UsageParsing.number(dict?["used_percentage"]),
                UsageParsing.epochSeconds(dict?["resets_at"]))
    }
}
