import Foundation
import TokengochiKit

signal(SIGPIPE, SIG_IGN)

let inputData = FileHandle.standardInput.readDataToEndOfFile()

let environment = ProcessInfo.processInfo.environment
let sessionBudget = Int(environment["TOKENGOCHI_CODEX_SESSION_TOKEN_BUDGET"] ?? "") ?? 200_000
let weeklyBudget = Int(environment["TOKENGOCHI_CODEX_WEEKLY_TOKEN_BUDGET"] ?? "") ?? 2_000_000

func nextLocalMidnight(after date: Date) -> Date? {
    Calendar.current.nextDate(
        after: date,
        matching: DateComponents(hour: 0, minute: 0, second: 0),
        matchingPolicy: .nextTime
    )
}

let now = Date()
let previous = UsageSnapshot.load(provider: .codex)
let snapshot = CodexUsageParsing.snapshot(
    from: inputData,
    previous: previous,
    now: now.timeIntervalSince1970,
    sessionBudget: sessionBudget,
    weeklyBudget: weeklyBudget,
    nextResetAt: nextLocalMidnight(after: now)?.timeIntervalSince1970
)

if let snapshot {
    do {
        try snapshot.save(provider: .codex)
        let session = snapshot.sessionPct.map { "\(Int($0))%" } ?? "est"
        let tokens = (snapshot.inputTokens ?? 0) + (snapshot.outputTokens ?? 0) + (snapshot.reasoningTokens ?? 0)
        FileHandle.standardOutput.write(Data("Codex \(session) \(tokens)t\n".utf8))
    } catch {
        FileHandle.standardError.write(Data("tokengochi-codex-writer: \(error)\n".utf8))
        exit(1)
    }
} else {
    FileHandle.standardError.write(Data("tokengochi-codex-writer: no Codex usage events found\n".utf8))
    exit(2)
}
