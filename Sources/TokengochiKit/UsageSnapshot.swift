import Foundation

public struct UsageSnapshot: Codable, Equatable {
    public var provider: UsageProvider?
    public var source: UsageSource?
    public var measurementKind: MeasurementKind?
    public var sessionPct: Double?
    public var weeklyPct: Double?
    public var contextPct: Double?
    public var sessionResetsAt: Double?
    public var weeklyResetsAt: Double?
    public var model: String?
    public var effortLevel: String?
    public var fastMode: Bool?
    public var inputTokens: Int?
    public var cachedInputTokens: Int?
    public var outputTokens: Int?
    public var reasoningTokens: Int?
    public var codexResetsAvailable: Int?
    public var codexResetsUsed: Int?
    public var codexNextResetAt: Double?
    public var updatedAt: Double

    public init(provider: UsageProvider? = nil, source: UsageSource? = nil,
                measurementKind: MeasurementKind? = nil,
                sessionPct: Double?, weeklyPct: Double?, contextPct: Double?,
                sessionResetsAt: Double?, weeklyResetsAt: Double?,
                model: String? = nil, effortLevel: String? = nil, fastMode: Bool? = nil,
                inputTokens: Int? = nil, cachedInputTokens: Int? = nil,
                outputTokens: Int? = nil, reasoningTokens: Int? = nil,
                codexResetsAvailable: Int? = nil, codexResetsUsed: Int? = nil,
                codexNextResetAt: Double? = nil,
                updatedAt: Double) {
        self.provider = provider
        self.source = source
        self.measurementKind = measurementKind
        self.sessionPct = sessionPct
        self.weeklyPct = weeklyPct
        self.contextPct = contextPct
        self.sessionResetsAt = sessionResetsAt
        self.weeklyResetsAt = weeklyResetsAt
        self.model = model
        self.effortLevel = effortLevel
        self.fastMode = fastMode
        self.inputTokens = inputTokens
        self.cachedInputTokens = cachedInputTokens
        self.outputTokens = outputTokens
        self.reasoningTokens = reasoningTokens
        self.codexResetsAvailable = codexResetsAvailable
        self.codexResetsUsed = codexResetsUsed
        self.codexNextResetAt = codexNextResetAt
        self.updatedAt = updatedAt
    }

    public static func load(provider: UsageProvider = .claude) -> UsageSnapshot? {
        let file = AppPaths.snapshotFile(for: provider)
        if let data = try? Data(contentsOf: file) {
            return try? JSONDecoder().decode(UsageSnapshot.self, from: data)
        }
        guard provider == .claude,
              let data = try? Data(contentsOf: AppPaths.snapshotFile),
              var snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            return nil
        }
        snapshot.provider = snapshot.provider ?? .claude
        return snapshot
    }

    public func save(provider: UsageProvider = .claude) throws {
        try AppPaths.ensureSupportDirectory()
        var snapshot = self
        snapshot.provider = snapshot.provider ?? provider
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: AppPaths.snapshotFile(for: provider), options: .atomic)
    }
}
