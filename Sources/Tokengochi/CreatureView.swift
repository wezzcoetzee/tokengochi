import SwiftUI
import TokengochiKit

struct CreatureView: View {
    let vitals: Vitals
    var skin: PetSkin = .classic
    var animationTier: AnimationTier? = nil

    private var activeTier: AnimationTier { animationTier ?? vitals.animationTier }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lcdBackground: Color { Phosphor.screenBackground(for: skin) }

    private var blobColor: Color { Phosphor.body(for: vitals.mood, skin: skin) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metric.screenRadius).fill(lcdBackground)
            scanlines

            VStack(spacing: Metric.xs) {
                HStack(alignment: .top) {
                    Text(meter("FED", 100 - vitals.hunger))
                    Spacer()
                    Text(meter("HAP", vitals.happiness))
                }
                .lcdReadout(skin)

                Spacer(minLength: 0)
                sprite
                Spacer(minLength: 0)

                Text(vitals.hasData ? vitals.mood.rawValue : "NO DATA")
                    .lcdReadout(skin)
            }
            .padding(Metric.md)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metric.screenHeight)
        .clipShape(RoundedRectangle(cornerRadius: Metric.screenRadius))
        .overlay(alignment: .bottomLeading) {
            if vitals.poops > 0 {
                Text(String(repeating: "💩", count: min(vitals.poops, 4)))
                    .font(.system(size: 14))
                    .padding(.leading, Metric.lg)
                    .padding(.bottom, Metric.messInset)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: Metric.screenRadius).strokeBorder(lcdBackground, lineWidth: Metric.screenBezel))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(vitals.screenAccessibilityLabel)
    }

    @ViewBuilder
    private var sprite: some View {
        if reduceMotion {
            creatureCanvas(blink: false)
                .frame(height: Metric.screenSpriteBand)
        } else {
            TimelineView(.animation) { timeline in
                let motion = SpriteMotion(tier: activeTier,
                                          time: timeline.date.timeIntervalSinceReferenceDate)
                ZStack {
                    if let sparklePhase = motion.sparklePhase {
                        sparkles(phase: sparklePhase)
                    }
                    creatureCanvas(blink: motion.blink)
                        .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                        .rotationEffect(.degrees(motion.rotation), anchor: .bottom)
                        .offset(y: motion.offsetY)
                }
                .frame(height: Metric.screenSpriteBand)
            }
        }
    }

    private func creatureCanvas(blink: Bool) -> some View {
        Canvas { context, size in
            let rows = CreatureFace.bodyRows(skin: skin)
            let cols = 16
            let cell = 4.3 + vitals.weight * 1.5
            let spriteW = Double(cols) * cell
            let spriteH = Double(rows.count) * cell
            let ox = (size.width - spriteW) / 2
            let oy = (size.height - spriteH) / 2

            func fill(_ c: Int, _ r: Int, _ color: Color) {
                let rect = CGRect(x: ox + Double(c) * cell, y: oy + Double(r) * cell,
                                  width: cell + 0.6, height: cell + 0.6)
                context.fill(Path(rect), with: .color(color))
            }

            for (r, line) in rows.enumerated() {
                for (c, ch) in line.enumerated() where ch == "#" {
                    fill(c, r, blobColor)
                }
            }
            for eye in CreatureFace.eyeCells(skin: skin, mood: vitals.mood, blink: blink) {
                fill(eye.col, eye.row, lcdBackground)
            }
            for mouth in CreatureFace.mouthCells(skin: skin, mood: vitals.mood) {
                fill(mouth.col, mouth.row, lcdBackground)
            }
        }
    }

    private func sparkles(phase: Double) -> some View {
        Canvas { context, size in
            let spots: [(x: Double, y: Double, offset: Double)] = [
                (0.12, 0.20, 0.0), (0.88, 0.26, 1.3), (0.22, 0.78, 2.2), (0.82, 0.72, 0.8)
            ]
            for spot in spots {
                let twinkle = (sin(phase * 3 + spot.offset) + 1) / 2
                guard twinkle > 0.45 else { continue }
                let radius = 1.4 + twinkle * 1.8
                let center = CGPoint(x: spot.x * size.width, y: spot.y * size.height)
                let rect = CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Phosphor.accent(for: skin).opacity(twinkle)))
            }
        }
    }

    private var scanlines: some View {
        GeometryReader { geometry in
            Path { path in
                var y: CGFloat = 0
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += 4
                }
            }
            .stroke(Phosphor.scanline, lineWidth: 2)
        }
    }

    private func meter(_ label: String, _ value: Double) -> String {
        let filled = max(0, min(10, Int((value / 10).rounded())))
        return label + " " + String(repeating: "█", count: filled) + String(repeating: "░", count: 10 - filled)
    }
}

private struct SpriteMotion {
    var offsetY: Double = 0
    var scaleX: Double = 1
    var scaleY: Double = 1
    var rotation: Double = 0
    var blink = false
    var sparklePhase: Double?

    init(tier: AnimationTier, time: Double) {
        if tier.includes(.breathing) {
            let breath = sin(time * 1.7)
            offsetY += breath * 1.8
            scaleY += breath * 0.03
            scaleX -= breath * 0.03
        }
        if tier.includes(.blinking) {
            blink = time.truncatingRemainder(dividingBy: 4.2) > 4.05
        }
        if tier.includes(.swaying) {
            rotation += sin(time * 1.2) * 4
        }
        if tier.includes(.bouncing) {
            let bounce = pow(max(0, sin(time * 2.6)), 1.5)
            offsetY -= bounce * 7
            scaleY += bounce * 0.08
            scaleX -= bounce * 0.05
        }
        if tier.includes(.sparkling) {
            sparklePhase = time
        }
    }
}
