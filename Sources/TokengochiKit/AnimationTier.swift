import Foundation

public enum AnimationTier: Int, CaseIterable, Comparable {
    case dormant = 0
    case breathing = 1
    case blinking = 2
    case swaying = 3
    case bouncing = 4
    case sparkling = 5
    case adhd = 6

    public static func < (lhs: AnimationTier, rhs: AnimationTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var unlockThreshold: Double {
        switch self {
        case .dormant: return 0
        case .breathing: return 5
        case .blinking: return 20
        case .swaying: return 40
        case .bouncing: return 60
        case .sparkling: return 80
        case .adhd: return 99
        }
    }

    public var displayName: String {
        switch self {
        case .dormant: return "Dormant"
        case .breathing: return "Breathing"
        case .blinking: return "Blinking"
        case .swaying: return "Sway"
        case .bouncing: return "Bounce"
        case .sparkling: return "Sparkle"
        case .adhd: return "ADHD"
        }
    }

    public var next: AnimationTier? {
        AnimationTier(rawValue: rawValue + 1)
    }

    public func includes(_ tier: AnimationTier) -> Bool {
        rawValue >= tier.rawValue
    }

    public var helpCondition: String {
        self == .dormant ? "always" : "≥ \(Int(unlockThreshold))% weekly peak"
    }

    public static func unlocked(forPeakWeekly peak: Double) -> AnimationTier {
        allCases.last { peak >= $0.unlockThreshold } ?? .dormant
    }
}
