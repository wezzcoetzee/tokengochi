import Foundation
import TokengochiKit

let keychainService = "Claude Code-credentials"
let usageEndpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

struct PollerError: Error, CustomStringConvertible {
    let description: String
}

func readAccessToken() throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    process.arguments = ["find-generic-password", "-s", keychainService, "-w"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw PollerError(description: "no Claude credentials in Keychain (is Claude Code / T3 Code signed in?)")
    }
    let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let oauth = root?["claudeAiOauth"] as? [String: Any] ?? root
    guard let token = oauth?["accessToken"] as? String else {
        throw PollerError(description: "credential blob had no accessToken")
    }
    return token
}

func fetchUsage(token: String) throws -> [String: Any] {
    var request = URLRequest(url: usageEndpoint)
    request.timeoutInterval = 30
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

    var result: Result<[String: Any], Error>!
    let semaphore = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        if let error { result = .failure(error); return }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let hint = status == 401 ? " (token expired; open Claude Code or T3 Code to refresh it)" : ""
            result = .failure(PollerError(description: "usage endpoint returned HTTP \(status)\(hint)"))
            return
        }
        guard let data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            result = .failure(PollerError(description: "could not parse usage response"))
            return
        }
        result = .success(json)
    }.resume()
    semaphore.wait()
    return try result.get()
}

func snapshot(from usage: [String: Any]) -> UsageSnapshot {
    let fiveHour = RateLimitWindow.usageEndpoint(usage["five_hour"])
    let sevenDay = RateLimitWindow.usageEndpoint(usage["seven_day"])
    return SnapshotMerge.pollerObservation(
        sessionPct: fiveHour.pct,
        weeklyPct: sevenDay.pct,
        sessionResetsAt: fiveHour.resetsAt,
        weeklyResetsAt: sevenDay.resetsAt,
        into: UsageSnapshot.load(provider: .claude),
        at: Date().timeIntervalSince1970
    )
}

func pollOnce() throws {
    let token = try readAccessToken()
    let usage = try fetchUsage(token: token)
    try snapshot(from: usage).save(provider: .claude)
}

let arguments = CommandLine.arguments
let watchIndex = arguments.firstIndex(of: "--watch")
let interval = watchIndex.flatMap { arguments.indices.contains($0 + 1) ? Double(arguments[$0 + 1]) : nil } ?? 60

func runOnceLogging() -> Bool {
    do {
        try pollOnce()
        FileHandle.standardError.write(Data("tokengochi-poller: snapshot updated\n".utf8))
        return true
    } catch {
        FileHandle.standardError.write(Data("tokengochi-poller: \(error)\n".utf8))
        return false
    }
}

let maxBackoff = 900.0

if watchIndex != nil {
    var consecutiveFailures = 0
    while true {
        if runOnceLogging() {
            consecutiveFailures = 0
            Thread.sleep(forTimeInterval: interval)
        } else {
            consecutiveFailures += 1
            let delay = min(maxBackoff, interval * pow(2, Double(consecutiveFailures - 1)))
            Thread.sleep(forTimeInterval: delay)
        }
    }
} else {
    exit(runOnceLogging() ? 0 : 1)
}
