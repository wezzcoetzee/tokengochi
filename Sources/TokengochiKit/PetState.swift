import Foundation

public struct PetState: Codable, Equatable {
    public var poops: Int
    public var lastSessionResetsAt: Double?
    public var windowStartSession: Double?
    public var windowPeakSession: Double
    public var windowCleaned: Bool
    public var peakWeekly: Double

    public init(poops: Int = 0, lastSessionResetsAt: Double? = nil,
                windowStartSession: Double? = nil,
                windowPeakSession: Double = 0, windowCleaned: Bool = false,
                peakWeekly: Double = 0) {
        self.poops = poops
        self.lastSessionResetsAt = lastSessionResetsAt
        self.windowStartSession = windowStartSession
        self.windowPeakSession = windowPeakSession
        self.windowCleaned = windowCleaned
        self.peakWeekly = peakWeekly
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        poops = try container.decodeIfPresent(Int.self, forKey: .poops) ?? 0
        lastSessionResetsAt = try container.decodeIfPresent(Double.self, forKey: .lastSessionResetsAt)
        windowStartSession = try container.decodeIfPresent(Double.self, forKey: .windowStartSession)
        windowPeakSession = try container.decodeIfPresent(Double.self, forKey: .windowPeakSession) ?? 0
        windowCleaned = try container.decodeIfPresent(Bool.self, forKey: .windowCleaned) ?? false
        peakWeekly = try container.decodeIfPresent(Double.self, forKey: .peakWeekly) ?? 0
    }

    public static func load(provider: UsageProvider = .claude) -> PetState {
        let file = AppPaths.petStateFile(for: provider)
        if let data = try? Data(contentsOf: file),
           let state = try? JSONDecoder().decode(PetState.self, from: data) {
            return state
        }
        guard provider == .claude,
              let data = try? Data(contentsOf: AppPaths.petStateFile),
              let state = try? JSONDecoder().decode(PetState.self, from: data) else {
            return PetState()
        }
        return state
    }

    public func save(provider: UsageProvider = .claude) {
        try? AppPaths.ensureSupportDirectory()
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: AppPaths.petStateFile(for: provider), options: .atomic)
        }
    }
}
