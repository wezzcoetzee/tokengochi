import Foundation

public struct FaceCell: Equatable {
    public let col: Int
    public let row: Int

    public init(_ col: Int, _ row: Int) {
        self.col = col
        self.row = row
    }
}

/// The creature's pixel geometry as a function of skin, mood, and blink. Pure data, so
/// the renderer only fills cells and "what does SICK look like" is asserted in a test
/// rather than trapped in a `Canvas`. Colours stay with the renderer by design.
public enum CreatureFace {
    private static let classicBody = [
        "....########....",
        "..############..",
        ".##############.",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        ".##############.",
        ".##############.",
        "..############..",
        "...###....###...",
        "..####....####.."
    ]

    private static let claudeBody = [
        "................",
        "..############..",
        ".##############.",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        "################",
        ".##..##..##..##.",
        ".##..##..##..##."
    ]

    private static let pikaBody = [
        "..##........##..",
        ".####......####.",
        ".####......####.",
        ".#####....#####.",
        "..############..",
        ".##############.",
        "################",
        "################",
        "################",
        "################",
        "################",
        ".##############.",
        "..############..",
        "...###....###...",
        "..####....####.."
    ]

    private static let reekBody = [
        ".......##.......",
        "......####......",
        ".....######.....",
        "......####......",
        "....########....",
        "...##########...",
        "....########....",
        "..############..",
        ".##############.",
        "################",
        "################",
        ".##############.",
        "..############.."
    ]

    public static func bodyRows(skin: PetSkin) -> [String] {
        switch skin {
        case .classic: return classicBody
        case .claude: return claudeBody
        case .pika: return pikaBody
        case .reek: return reekBody
        }
    }

    public static func eyeCells(skin: PetSkin, mood: Mood, blink: Bool) -> [FaceCell] {
        if skin == .claude {
            if blink {
                return [FaceCell(4, 6), FaceCell(5, 6), FaceCell(10, 6), FaceCell(11, 6)]
            }
            return [FaceCell(4, 4), FaceCell(5, 4), FaceCell(4, 5), FaceCell(5, 5), FaceCell(4, 6), FaceCell(5, 6),
                    FaceCell(10, 4), FaceCell(11, 4), FaceCell(10, 5), FaceCell(11, 5), FaceCell(10, 6), FaceCell(11, 6)]
        }
        if skin == .reek {
            if blink || mood == .overfed {
                return [FaceCell(4, 9), FaceCell(5, 9), FaceCell(10, 9), FaceCell(11, 9)]
            }
            return [FaceCell(4, 8), FaceCell(5, 8), FaceCell(4, 9), FaceCell(5, 9),
                    FaceCell(10, 8), FaceCell(11, 8), FaceCell(10, 9), FaceCell(11, 9)]
        }
        if skin == .pika {
            if blink || mood == .overfed {
                return [FaceCell(4, 8), FaceCell(5, 8), FaceCell(10, 8), FaceCell(11, 8)]
            }
            return [FaceCell(4, 7), FaceCell(5, 7), FaceCell(4, 8), FaceCell(5, 8),
                    FaceCell(10, 7), FaceCell(11, 7), FaceCell(10, 8), FaceCell(11, 8)]
        }
        if blink || mood == .overfed {
            return [FaceCell(4, 6), FaceCell(5, 6), FaceCell(10, 6), FaceCell(11, 6)]
        }
        return [FaceCell(4, 5), FaceCell(5, 5), FaceCell(4, 6), FaceCell(5, 6),
                FaceCell(10, 5), FaceCell(11, 5), FaceCell(10, 6), FaceCell(11, 6)]
    }

    public static func mouthCells(skin: PetSkin, mood: Mood) -> [FaceCell] {
        switch skin {
        case .classic:
            return classicMouth(mood: mood)
        case .pika:
            return lowMouth(mood: mood)
        case .reek:
            return reekMouth(mood: mood)
        case .claude:
            return []
        }
    }

    private static func reekMouth(mood: Mood) -> [FaceCell] {
        switch mood {
        case .thriving, .okay:
            return [FaceCell(5, 10), FaceCell(6, 11), FaceCell(7, 11), FaceCell(8, 11), FaceCell(9, 11), FaceCell(10, 10)]
        case .lonely, .starving:
            return [FaceCell(5, 11), FaceCell(6, 10), FaceCell(7, 10), FaceCell(8, 10), FaceCell(9, 10), FaceCell(10, 11)]
        case .sick:
            return [FaceCell(6, 10), FaceCell(7, 10), FaceCell(8, 10), FaceCell(9, 10), FaceCell(6, 11), FaceCell(7, 11), FaceCell(8, 11), FaceCell(9, 11)]
        case .overfed:
            return [FaceCell(5, 11), FaceCell(6, 11), FaceCell(7, 11), FaceCell(8, 11), FaceCell(9, 11), FaceCell(10, 11)]
        case .noData:
            return [FaceCell(6, 11), FaceCell(7, 11), FaceCell(8, 11), FaceCell(9, 11)]
        }
    }

    private static func classicMouth(mood: Mood) -> [FaceCell] {
        switch mood {
        case .thriving, .okay:
            return [FaceCell(5, 7), FaceCell(6, 8), FaceCell(7, 8), FaceCell(8, 8), FaceCell(9, 8), FaceCell(10, 7)]
        case .lonely, .starving:
            return [FaceCell(5, 8), FaceCell(6, 7), FaceCell(7, 7), FaceCell(8, 7), FaceCell(9, 7), FaceCell(10, 8)]
        case .sick:
            return [FaceCell(6, 7), FaceCell(7, 7), FaceCell(8, 7), FaceCell(9, 7), FaceCell(6, 8), FaceCell(7, 8), FaceCell(8, 8), FaceCell(9, 8)]
        case .overfed:
            return [FaceCell(5, 8), FaceCell(6, 8), FaceCell(7, 8), FaceCell(8, 8), FaceCell(9, 8), FaceCell(10, 8)]
        case .noData:
            return [FaceCell(6, 8), FaceCell(7, 8), FaceCell(8, 8), FaceCell(9, 8)]
        }
    }

    private static func lowMouth(mood: Mood) -> [FaceCell] {
        switch mood {
        case .thriving, .okay:
            return [FaceCell(5, 9), FaceCell(6, 10), FaceCell(7, 10), FaceCell(8, 10), FaceCell(9, 10), FaceCell(10, 9)]
        case .lonely, .starving:
            return [FaceCell(5, 10), FaceCell(6, 9), FaceCell(7, 9), FaceCell(8, 9), FaceCell(9, 9), FaceCell(10, 10)]
        case .sick:
            return [FaceCell(6, 9), FaceCell(7, 9), FaceCell(8, 9), FaceCell(9, 9), FaceCell(6, 10), FaceCell(7, 10), FaceCell(8, 10), FaceCell(9, 10)]
        case .overfed:
            return [FaceCell(5, 10), FaceCell(6, 10), FaceCell(7, 10), FaceCell(8, 10), FaceCell(9, 10), FaceCell(10, 10)]
        case .noData:
            return [FaceCell(6, 10), FaceCell(7, 10), FaceCell(8, 10), FaceCell(9, 10)]
        }
    }
}
