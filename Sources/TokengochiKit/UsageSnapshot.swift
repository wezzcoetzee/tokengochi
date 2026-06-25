import Foundation

public struct UsageSnapshot: Codable, Equatable {
    public var sessionPct: Double?
    public var weeklyPct: Double?
    public var contextPct: Double?
    public var sessionResetsAt: Double?
    public var weeklyResetsAt: Double?
    public var model: String?
    public var effortLevel: String?
    public var fastMode: Bool?
    public var updatedAt: Double

    public init(sessionPct: Double?, weeklyPct: Double?, contextPct: Double?,
                sessionResetsAt: Double?, weeklyResetsAt: Double?,
                model: String? = nil, effortLevel: String? = nil, fastMode: Bool? = nil,
                updatedAt: Double) {
        self.sessionPct = sessionPct
        self.weeklyPct = weeklyPct
        self.contextPct = contextPct
        self.sessionResetsAt = sessionResetsAt
        self.weeklyResetsAt = weeklyResetsAt
        self.model = model
        self.effortLevel = effortLevel
        self.fastMode = fastMode
        self.updatedAt = updatedAt
    }

    public static func load() -> UsageSnapshot? {
        guard let data = try? Data(contentsOf: AppPaths.snapshotFile) else { return nil }
        return try? JSONDecoder().decode(UsageSnapshot.self, from: data)
    }

    public func save() throws {
        try AppPaths.ensureSupportDirectory()
        let data = try JSONEncoder().encode(self)
        try data.write(to: AppPaths.snapshotFile, options: .atomic)
    }
}
