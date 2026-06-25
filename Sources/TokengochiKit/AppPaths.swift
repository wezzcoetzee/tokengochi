import Foundation

public enum AppPaths {
    private static let directoryName = "Tokengochi"
    private static let legacyDirectoryName = "Tokengotchi"

    private static var baseDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    public static var supportDirectory: URL {
        _ = migratedLegacyDirectory
        return baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
    }

    public static var snapshotFile: URL {
        supportDirectory.appendingPathComponent("snapshot.json")
    }

    public static func snapshotFile(for provider: UsageProvider) -> URL {
        switch provider {
        case .claude:
            return supportDirectory.appendingPathComponent("snapshot-claude.json")
        case .codex:
            return supportDirectory.appendingPathComponent("snapshot-codex.json")
        }
    }

    public static var petStateFile: URL {
        supportDirectory.appendingPathComponent("pet-state.json")
    }

    public static func petStateFile(for provider: UsageProvider) -> URL {
        switch provider {
        case .claude:
            return supportDirectory.appendingPathComponent("pet-state-claude.json")
        case .codex:
            return supportDirectory.appendingPathComponent("pet-state-codex.json")
        }
    }

    public static func ensureSupportDirectory() throws {
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
    }

    private static let migratedLegacyDirectory: Void = {
        let fileManager = FileManager.default
        let current = baseDirectory.appendingPathComponent(directoryName, isDirectory: true)
        let legacy = baseDirectory.appendingPathComponent(legacyDirectoryName, isDirectory: true)
        guard fileManager.fileExists(atPath: legacy.path),
              !fileManager.fileExists(atPath: current.path) else { return }
        try? fileManager.moveItem(at: legacy, to: current)
    }()
}
