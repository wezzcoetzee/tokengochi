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

    public static func bodyRows(skin: PetSkin) -> [String] {
        switch skin {
        case .classic: return classicBody
        case .claude: return claudeBody
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
        if blink || mood == .overfed {
            return [FaceCell(4, 6), FaceCell(5, 6), FaceCell(10, 6), FaceCell(11, 6)]
        }
        return [FaceCell(4, 5), FaceCell(5, 5), FaceCell(4, 6), FaceCell(5, 6),
                FaceCell(10, 5), FaceCell(11, 5), FaceCell(10, 6), FaceCell(11, 6)]
    }

    public static func mouthCells(skin: PetSkin, mood: Mood) -> [FaceCell] {
        guard skin == .classic else { return [] }
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
}
