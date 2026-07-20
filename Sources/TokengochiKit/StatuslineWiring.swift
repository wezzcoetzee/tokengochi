import Foundation

/// Pure logic for wiring `TokengochiWriter` into Claude Code's statusline config.
/// The app-side manager owns file IO; this module owns detection and content so the
/// "is it installed / what should the files say" rules are testable without a filesystem.
public enum StatuslineWiring {
    public static let wrapperFileName = "tokengochi-statusline.sh"
    public static let passthroughFileName = "tokengochi-passthrough.sh"
    public static let writerMarker = "TokengochiWriter"

    public static func command(inSettings settings: [String: Any]) -> String? {
        guard let statusLine = settings["statusLine"] as? [String: Any],
              statusLine["type"] as? String == "command" else { return nil }
        return statusLine["command"] as? String
    }

    /// A statusline counts as wired if its command mentions the writer directly, or is a
    /// bare path to a script whose contents do (the wrapper-script install this produces).
    public static func isWired(command: String?, scriptContents: (String) -> String?) -> Bool {
        guard let command, !command.isEmpty else { return false }
        if command.contains(writerMarker) { return true }
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(" "), let contents = scriptContents(trimmed) else { return false }
        return contents.contains(writerMarker)
    }

    public static func wrapperScript(writerPath: String, passthroughPath: String?) -> String {
        var lines = ["#!/bin/bash"]
        if let passthroughPath {
            lines.append("export TOKENGOCHI_PASSTHROUGH_CMD=\(shellQuoted(passthroughPath))")
        }
        lines.append("exec \(shellQuoted(writerPath))")
        return lines.joined(separator: "\n") + "\n"
    }

    public static func passthroughScript(preserving command: String) -> String {
        "#!/bin/bash\n\(command)\n"
    }

    public static func preservedCommand(inPassthroughScript script: String) -> String? {
        let body = script
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("#!") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? nil : body
    }

    public static func settings(_ settings: [String: Any], pointingAt commandPath: String) -> [String: Any] {
        var updated = settings
        updated["statusLine"] = ["type": "command", "command": commandPath]
        return updated
    }

    public static func settingsRemovingStatusline(_ settings: [String: Any]) -> [String: Any] {
        var updated = settings
        updated.removeValue(forKey: "statusLine")
        return updated
    }

    static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
