import Foundation

public enum PetSkin: String, Codable, CaseIterable {
    case classic
    case claude
    case pika
    case reek

    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .claude: return "Claude"
        case .pika: return "Pika"
        case .reek: return "Reek"
        }
    }

    /// Peak-weekly usage that unlocks the skin. `.pika` and `.reek` are gated by conditions
    /// tracked in `PetState` (session shape and a past death), not by peak weekly, so their
    /// thresholds are unreachable and `isUnlocked(forPeakWeekly:)` never grants them.
    public var unlockThreshold: Double {
        switch self {
        case .classic: return 0
        case .claude: return 95
        case .pika: return .greatestFiniteMagnitude
        case .reek: return .greatestFiniteMagnitude
        }
    }

    public func isUnlocked(forPeakWeekly peak: Double) -> Bool {
        peak >= unlockThreshold
    }

    public var helpCondition: String {
        switch self {
        case .classic: return "always available"
        case .pika: return "> 80% session in the first hour"
        case .claude: return "\(Int(unlockThreshold))% weekly peak"
        case .reek: return "let a pet die once"
        }
    }

    public var helpDescription: String {
        switch self {
        case .classic: return "The original green blob. Yours from day one."
        case .pika: return "Burn hot out of the gate: pass 80% of a session window within its first 60 minutes."
        case .claude: return "Push your weekly peak to \(Int(unlockThreshold))%. Dying resets the progress."
        case .reek: return "The one that crawls out of the mess. Neglect a Tokengochi to death and Reek is yours to keep — even after reviving."
        }
    }

    public static var helpOrder: [PetSkin] { [.classic, .pika, .claude, .reek] }
}
