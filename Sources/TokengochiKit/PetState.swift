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

    public static func load() -> PetState {
        guard let data = try? Data(contentsOf: AppPaths.petStateFile),
              let state = try? JSONDecoder().decode(PetState.self, from: data) else {
            return PetState()
        }
        return state
    }

    public func save() {
        try? AppPaths.ensureSupportDirectory()
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: AppPaths.petStateFile, options: .atomic)
        }
    }
}
