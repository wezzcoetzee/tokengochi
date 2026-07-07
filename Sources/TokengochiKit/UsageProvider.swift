import Foundation

public enum UsageProvider: String, Codable, CaseIterable, Identifiable {
    case claude
    case codex

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        }
    }

    public var defaultSkin: PetSkin {
        switch self {
        case .claude: return .classic
        case .codex: return .classic
        }
    }

    public var providerSkin: PetSkin {
        switch self {
        case .claude: return .claude
        case .codex: return .codex
        }
    }

    public var noDataText: String {
        switch self {
        case .claude: return "no Claude data yet. start Claude Code"
        case .codex: return "no Codex data yet. run Codex with JSON output"
        }
    }
}

public enum UsageSource: String, Codable, Equatable {
    case claudeStatusline
    case claudePoller
    case codexJsonl
    case codexHook
}

public enum MeasurementKind: String, Codable, Equatable {
    case exactQuota
    case estimatedBudget
    case estimatedResets
}
