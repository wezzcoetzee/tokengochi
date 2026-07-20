import SwiftUI
import TokengochiKit

enum Phosphor {
    static let dotMatrixGreen = Color(red: 0.61, green: 0.74, blue: 0.06)
    static let fadedPhosphor = Color(red: 0.81, green: 0.88, blue: 0.31)
    static let overfedAmber = Color(red: 1.0, green: 0.80, blue: 0.24)
    static let queasyOrange = Color(red: 1.0, green: 0.54, blue: 0.36)
    static let lowBatteryGreen = Color(red: 0.40, green: 0.54, blue: 0.07)
    static let screenOffGreen = Color(red: 0.06, green: 0.22, blue: 0.06)
    static let scanline = Color.black.opacity(0.18)

    static let terracotta = Color(red: 0.71, green: 0.40, blue: 0.29)
    static let fadedTerracotta = Color(red: 0.82, green: 0.52, blue: 0.40)
    static let overfedRust = Color(red: 0.85, green: 0.55, blue: 0.30)
    static let queasyEmber = Color(red: 0.80, green: 0.30, blue: 0.22)
    static let lowBatteryBrown = Color(red: 0.45, green: 0.28, blue: 0.22)
    static let screenOffBrown = Color(red: 0.16, green: 0.09, blue: 0.06)

    static let mud = Color(red: 0.60, green: 0.40, blue: 0.22)
    static let fadedMud = Color(red: 0.73, green: 0.55, blue: 0.37)
    static let overfedMud = Color(red: 0.72, green: 0.50, blue: 0.26)
    static let queasyMud = Color(red: 0.74, green: 0.43, blue: 0.20)
    static let lowBatteryMud = Color(red: 0.38, green: 0.26, blue: 0.15)
    static let screenOffMud = Color(red: 0.11, green: 0.07, blue: 0.04)

    static let sparkYellow = Color(red: 0.98, green: 0.82, blue: 0.2)
    static let fadedSpark = Color(red: 0.95, green: 0.88, blue: 0.55)
    static let overfedGold = Color(red: 1.0, green: 0.7, blue: 0.15)
    static let queasyMustard = Color(red: 0.75, green: 0.72, blue: 0.25)
    static let lowBatterySpark = Color(red: 0.55, green: 0.48, blue: 0.15)
    static let screenOffSpark = Color(red: 0.14, green: 0.11, blue: 0.04)

    static func body(for mood: Mood, skin: PetSkin) -> Color {
        switch skin {
        case .classic:
            switch mood {
            case .sick: return queasyOrange
            case .overfed: return overfedAmber
            case .okay: return fadedPhosphor
            case .noData: return lowBatteryGreen
            case .starving, .thriving, .lonely: return dotMatrixGreen
            }
        case .claude:
            switch mood {
            case .sick: return queasyEmber
            case .overfed: return overfedRust
            case .okay: return fadedTerracotta
            case .noData: return lowBatteryBrown
            case .starving, .thriving, .lonely: return terracotta
            }
        case .pika:
            switch mood {
            case .sick: return queasyMustard
            case .overfed: return overfedGold
            case .okay: return fadedSpark
            case .noData: return lowBatterySpark
            case .starving, .thriving, .lonely: return sparkYellow
            }
        case .reek:
            switch mood {
            case .sick: return queasyMud
            case .overfed: return overfedMud
            case .okay: return fadedMud
            case .noData: return lowBatteryMud
            case .starving, .thriving, .lonely: return mud
            }
        }
    }

    static func screenBackground(for skin: PetSkin) -> Color {
        switch skin {
        case .classic: return screenOffGreen
        case .claude: return screenOffBrown
        case .pika: return screenOffSpark
        case .reek: return screenOffMud
        }
    }

    static func readout(for skin: PetSkin) -> Color {
        switch skin {
        case .classic: return dotMatrixGreen
        case .claude: return terracotta
        case .pika: return sparkYellow
        case .reek: return mud
        }
    }

    static func accent(for skin: PetSkin) -> Color {
        switch skin {
        case .classic: return fadedPhosphor
        case .claude: return fadedTerracotta
        case .pika: return fadedSpark
        case .reek: return fadedMud
        }
    }
}

enum Metric {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let content: CGFloat = 14

    static let screenRadius: CGFloat = 10
    static let screenBezel: CGFloat = 4
    static let screenHeight: CGFloat = 152
    static let screenSpriteBand: CGFloat = 84
    static let messInset: CGFloat = 22
}

private struct LCDReadout: ViewModifier {
    let skin: PetSkin

    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(0.2)
            .foregroundStyle(Phosphor.readout(for: skin))
    }
}

extension View {
    func lcdReadout(_ skin: PetSkin = .classic) -> some View { modifier(LCDReadout(skin: skin)) }
}
