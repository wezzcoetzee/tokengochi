import Foundation
import TokengochiKit

signal(SIGPIPE, SIG_IGN)

let inputData = FileHandle.standardInput.readDataToEndOfFile()

let root = (try? JSONSerialization.jsonObject(with: inputData)) as? [String: Any]
let rateLimits = root?["rate_limits"] as? [String: Any]
let fiveHour = RateLimitWindow.statusline(rateLimits?["five_hour"])
let sevenDay = RateLimitWindow.statusline(rateLimits?["seven_day"])
let contextWindow = root?["context_window"] as? [String: Any]
let model = root?["model"] as? [String: Any]
let effort = root?["effort"] as? [String: Any]

let snapshot = SnapshotMerge.statuslineObservation(
    contextPct: UsageParsing.number(contextWindow?["used_percentage"]),
    model: (model?["display_name"] as? String) ?? (model?["id"] as? String),
    effortLevel: effort?["level"] as? String,
    fastMode: root?["fast_mode"] as? Bool,
    fallbackSessionPct: fiveHour.pct,
    fallbackWeeklyPct: sevenDay.pct,
    fallbackSessionResetsAt: fiveHour.resetsAt,
    fallbackWeeklyResetsAt: sevenDay.resetsAt,
    into: UsageSnapshot.load(),
    at: Date().timeIntervalSince1970
)
try? snapshot.save()

let passthrough = ProcessInfo.processInfo.environment["TOKENGOCHI_PASSTHROUGH_CMD"]
if let passthrough, !passthrough.isEmpty {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = ["-c", passthrough]
    let stdinPipe = Pipe()
    process.standardInput = stdinPipe
    do {
        try process.run()
        try stdinPipe.fileHandleForWriting.write(contentsOf: inputData)
        try stdinPipe.fileHandleForWriting.close()
        process.waitUntilExit()
    } catch {
        try? stdinPipe.fileHandleForWriting.close()
    }
} else {
    let session = snapshot.sessionPct.map { "\(Int($0))%" } ?? "—"
    let weekly = snapshot.weeklyPct.map { "\(Int($0))%" } ?? "—"
    FileHandle.standardOutput.write(Data("🐣 S:\(session) W:\(weekly)".utf8))
}
