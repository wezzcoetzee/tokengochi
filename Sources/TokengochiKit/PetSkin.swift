import Foundation

public enum PetSkin: String, Codable, CaseIterable {
    case classic
    case claude
    case codex

    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .claude: return "Claude"
        case .codex: return "Codex"
        }
    }

    public var unlockThreshold: Double {
        switch self {
        case .classic: return 0
        case .claude: return 95
        case .codex: return 95
        }
    }

    public static func providerChoices(for provider: UsageProvider) -> [PetSkin] {
        switch provider {
        case .claude: return [.classic, .claude]
        case .codex: return [.classic, .codex]
        }
    }

    public func isUnlocked(forPeakWeekly peak: Double) -> Bool {
        peak >= unlockThreshold
    }
}
