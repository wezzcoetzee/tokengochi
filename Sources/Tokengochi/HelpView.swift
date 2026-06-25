import SwiftUI
import TokengochiKit

struct HelpView: View {
    let vitals: Vitals
    var activeAnimationTier: AnimationTier? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.lg) {
                intro

                legendSection("Moods") {
                    ForEach(Mood.helpOrder, id: \.self) { mood in
                        moodRow(mood)
                    }
                }

                legendSection("Vitals") {
                    ForEach(HelpContent.vitals) { topicRow($0, active: false) }
                }

                legendSection("Messes") {
                    ForEach(HelpContent.mechanics) { topicRow($0, active: false) }
                }

                legendSection("Animations") {
                    ForEach(AnimationTier.allCases, id: \.self) { tierRow($0) }
                }
            }
            .padding(.vertical, Metric.xs)
        }
        .frame(maxHeight: 360)
    }

    private var intro: some View {
        Text("Tokengochi turns your Claude usage into a pet. Using more is good. The only failure is wasting a window.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func legendSection<Content: View>(_ title: String,
                                               @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Metric.sm) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(1)
            content()
        }
    }

    private func moodRow(_ mood: Mood) -> some View {
        let active = vitals.hasData && vitals.mood == mood
        return row(emoji: mood.emoji,
                   title: mood.rawValue,
                   condition: mood.helpCondition,
                   detail: mood.helpDescription,
                   active: active)
    }

    private func tierRow(_ tier: AnimationTier) -> some View {
        let active = (activeAnimationTier ?? vitals.animationTier) == tier
        return row(symbol: "sparkle",
                   title: tier.displayName,
                   condition: tier.helpCondition,
                   detail: nil,
                   active: active)
    }

    private func topicRow(_ topic: HelpTopic, active: Bool) -> some View {
        row(symbol: topic.symbol, title: topic.title, condition: nil,
            detail: topic.detail, active: active)
    }

    private func row(emoji: String? = nil, symbol: String? = nil, title: String,
                     condition: String?, detail: String?, active: Bool) -> some View {
        HStack(alignment: .top, spacing: Metric.sm) {
            Group {
                if let emoji { Text(emoji) }
                else if let symbol { Image(systemName: symbol) }
            }
            .frame(width: 22, alignment: .center)
            .font(.system(size: 14))
            .foregroundStyle(active ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: Metric.xs) {
                    Text(title).font(.system(.caption, design: .monospaced)).bold()
                    if let condition {
                        Text(condition).font(.caption2).foregroundStyle(.secondary)
                    }
                    if active {
                        Text("● now").font(.caption2).foregroundStyle(Color.accentColor)
                    }
                }
                if let detail {
                    Text(detail).font(.caption2).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Metric.sm)
        .background(active ? Color.accentColor.opacity(0.12) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: Metric.xs))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(title: title, condition: condition, detail: detail, active: active))
    }

    private func accessibilityLabel(title: String, condition: String?, detail: String?, active: Bool) -> String {
        var parts = [title]
        if active { parts.append("current state") }
        if let condition { parts.append(condition) }
        if let detail { parts.append(detail) }
        return parts.joined(separator: ". ")
    }
}
