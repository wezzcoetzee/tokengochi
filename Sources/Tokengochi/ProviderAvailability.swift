import Foundation
import TokengochiKit

enum ProviderAvailability {
    static func isAvailable(_ provider: UsageProvider) -> Bool {
        switch provider {
        case .claude:
            return UsageSnapshot.load(provider: .claude) != nil
        case .codex:
            return UsageSnapshot.load(provider: .codex) != nil || hasCodexLocalState() || hasCodexExecutable()
        }
    }

    private static func hasCodexLocalState() -> Bool {
        let fileManager = FileManager.default
        let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"].map(URL.init(fileURLWithPath:))
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
        let candidates = [
            "auth.json",
            "config.toml",
            ".codex-global-state.json",
            "sessions"
        ]
        return candidates.contains { fileManager.fileExists(atPath: codexHome.appendingPathComponent($0).path) }
    }

    private static func hasCodexExecutable() -> Bool {
        let fileManager = FileManager.default
        let candidates = [
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex",
            "/usr/bin/codex"
        ]
        return candidates.contains { fileManager.isExecutableFile(atPath: $0) }
    }
}
