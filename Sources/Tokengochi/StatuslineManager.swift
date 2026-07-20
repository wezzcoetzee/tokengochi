import SwiftUI
import TokengochiKit

/// Wires `TokengochiWriter` into Claude Code's statusline config, chaining any existing
/// statusline command through `TOKENGOCHI_PASSTHROUGH_CMD` so it keeps rendering.
@MainActor
final class StatuslineManager: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var lastError: String?

    @AppStorage("statuslineOptOut") private var optedOut = false

    private let fileManager = FileManager.default

    private var configDirectory: URL {
        if let custom = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"], !custom.isEmpty {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        return fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude", isDirectory: true)
    }

    private var settingsFile: URL { configDirectory.appendingPathComponent("settings.json") }
    private var backupFile: URL { configDirectory.appendingPathComponent("settings.json.tokengochi-backup") }
    private var wrapperFile: URL { configDirectory.appendingPathComponent(StatuslineWiring.wrapperFileName) }
    private var passthroughFile: URL { configDirectory.appendingPathComponent(StatuslineWiring.passthroughFileName) }

    private var writerFile: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/TokengochiWriter")
    }

    func refresh() {
        isEnabled = StatuslineWiring.isWired(command: currentCommand()) { path in
            try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        }
    }

    func enableIfNeeded() {
        refresh()
        guard !isEnabled, !optedOut,
              fileManager.fileExists(atPath: configDirectory.path) else { return }
        setEnabled(true)
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try wire()
                optedOut = false
            } else {
                try unwire()
                optedOut = true
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    private struct WiringError: LocalizedError {
        let errorDescription: String?
    }

    private func wire() throws {
        guard fileManager.fileExists(atPath: writerFile.path) else {
            throw WiringError(errorDescription: "TokengochiWriter missing from the app bundle")
        }
        guard fileManager.fileExists(atPath: configDirectory.path) else {
            throw WiringError(errorDescription: "no Claude Code config at \(configDirectory.path)")
        }

        let settings = try loadSettings()
        var passthroughPath: String?
        if let existing = StatuslineWiring.command(inSettings: settings),
           !existing.contains(StatuslineWiring.writerMarker),
           existing != wrapperFile.path {
            try write(StatuslineWiring.passthroughScript(preserving: existing), to: passthroughFile)
            passthroughPath = passthroughFile.path
        } else if fileManager.fileExists(atPath: passthroughFile.path) {
            passthroughPath = passthroughFile.path
        }

        try write(StatuslineWiring.wrapperScript(writerPath: writerFile.path,
                                                 passthroughPath: passthroughPath),
                  to: wrapperFile)

        if fileManager.fileExists(atPath: settingsFile.path),
           !fileManager.fileExists(atPath: backupFile.path) {
            try fileManager.copyItem(at: settingsFile, to: backupFile)
        }
        try save(StatuslineWiring.settings(settings, pointingAt: wrapperFile.path))
    }

    private func unwire() throws {
        let settings = try loadSettings()
        guard StatuslineWiring.isWired(command: StatuslineWiring.command(inSettings: settings), scriptContents: { path in
            try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
        }) else { return }

        if let script = try? String(contentsOf: passthroughFile, encoding: .utf8),
           let preserved = StatuslineWiring.preservedCommand(inPassthroughScript: script) {
            try save(StatuslineWiring.settings(settings, pointingAt: preserved))
        } else {
            try save(StatuslineWiring.settingsRemovingStatusline(settings))
        }
    }

    private func currentCommand() -> String? {
        guard let settings = try? loadSettings() else { return nil }
        return StatuslineWiring.command(inSettings: settings)
    }

    private func loadSettings() throws -> [String: Any] {
        guard fileManager.fileExists(atPath: settingsFile.path) else { return [:] }
        let data = try Data(contentsOf: settingsFile)
        guard let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WiringError(errorDescription: "could not parse \(settingsFile.path)")
        }
        return settings
    }

    private func save(_ settings: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: settings,
                                              options: [.prettyPrinted, .sortedKeys])
        try data.write(to: settingsFile, options: .atomic)
    }

    private func write(_ script: String, to url: URL) throws {
        try script.write(to: url, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}
