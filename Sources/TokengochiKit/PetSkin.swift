import Foundation

public enum PetSkin: String, Codable, CaseIterable {
    case classic
    case claude

    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .claude: return "Claude"
        }
    }

    public var unlockThreshold: Double {
        switch self {
        case .classic: return 0
        case .claude: return 95
        }
    }

    public func isUnlocked(forPeakWeekly peak: Double) -> Bool {
        peak >= unlockThreshold
    }
}
