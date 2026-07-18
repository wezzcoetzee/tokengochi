import SwiftUI
import TokengochiKit

struct MenuContentView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var poller: PollerManager
    @StateObject private var loginItem = LoginItemManager()
    @State private var showingHelp = false
    @AppStorage("petSkin") private var skinRaw = PetSkin.classic.rawValue
    @AppStorage("animationTier") private var animationTierRaw = AnimationTier.sparkling.rawValue

    private var unlockedTier: AnimationTier { store.vitals.animationTier }

    private var effectiveAnimationTier: AnimationTier {
        AnimationTier(rawValue: min(animationTierRaw, unlockedTier.rawValue)) ?? unlockedTier
    }

    private var animationSelection: Binding<Int> {
        Binding(
            get: { effectiveAnimationTier.rawValue },
            set: { animationTierRaw = $0 }
        )
    }

    private var unlockedTiers: [AnimationTier] {
        AnimationTier.allCases.filter { $0.rawValue <= unlockedTier.rawValue }
    }

    private var selectedSkin: PetSkin { PetSkin(rawValue: skinRaw) ?? .classic }

    private var claudeUnlocked: Bool {
        PetSkin.claude.isUnlocked(forPeakWeekly: store.vitals.peakWeekly)
    }

    private var effectiveSkin: PetSkin {
        selectedSkin == .claude && claudeUnlocked ? .claude : .classic
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.lg) {
            header

            if showingHelp {
                HelpView(vitals: store.vitals, activeAnimationTier: effectiveAnimationTier)
            } else {
                statsBody
            }

            Divider()

            backgroundUpdatesRow

            launchAtLoginRow

            HStack {
                Button("Refresh") { store.refresh() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(Metric.content)
        .frame(minWidth: 264, idealWidth: 264, maxWidth: 320)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { store.setActive(true) }
        .onDisappear { store.setActive(false) }
    }

    private var header: some View {
        HStack {
            Text("Tokengochi").font(.headline)
            Spacer()
            Button {
                showingHelp.toggle()
            } label: {
                Image(systemName: showingHelp ? "questionmark.circle.fill" : "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(showingHelp ? Color.accentColor : .secondary)
            .accessibilityLabel(showingHelp ? "Close help" : "Help")
            .accessibilityHint("Explains moods, vitals, and mechanics")
        }
    }

    private var backgroundUpdatesRow: some View {
        VStack(alignment: .leading, spacing: Metric.xs) {
            Toggle(isOn: Binding(
                get: { poller.isEnabled },
                set: { poller.setEnabled($0) }
            )) {
                Label("Background updates", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(.caption, design: .monospaced))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            if let error = poller.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                Text("Polls your Claude usage every 2 min. Needs Claude Code or T3 Code signed in.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { poller.refresh() }
    }

    private var launchAtLoginRow: some View {
        VStack(alignment: .leading, spacing: Metric.xs) {
            Toggle(isOn: Binding(
                get: { loginItem.isEnabled },
                set: { loginItem.setEnabled($0) }
            )) {
                Label("Launch at login", systemImage: "power")
                    .font(.system(.caption, design: .monospaced))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            if let error = loginItem.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { loginItem.refresh() }
    }

    @ViewBuilder
    private var statsBody: some View {
        if store.vitals.isDead {
            deadBody
        } else {
            aliveBody
        }
    }

    private var deadBody: some View {
        VStack(alignment: .leading, spacing: Metric.lg) {
            CreatureView(vitals: store.vitals, skin: .classic, animationTier: .dormant)

            VStack(alignment: .leading, spacing: Metric.sm) {
                Text("Your Tokengochi died.")
                    .font(.system(.callout, design: .monospaced)).bold()
                Text("Too many uncleaned messes drained its health to zero. Reviving starts it over and resets every unlocked animation and skin — you'll re-earn them through new Claude usage.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                store.revive()
            } label: {
                Label("Revive", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityHint("Resets the pet and all unlocked animations and skins")
        }
    }

    private var aliveBody: some View {
        VStack(alignment: .leading, spacing: Metric.lg) {
            CreatureView(vitals: store.vitals, skin: effectiveSkin, animationTier: effectiveAnimationTier)

            petPickerRow

            VStack(spacing: Metric.sm) {
                statRow("Session", store.vitals.session, detail: store.sessionResetText)
                statRow("Weekly", store.vitals.weekly, detail: store.weeklyResetText)
                statRow("Context", store.vitals.context)
            }

            HStack {
                Label("\(store.vitals.health)%", systemImage: "heart.fill")
                    .foregroundStyle(store.vitals.health < 40 ? .red : .primary)
                    .accessibilityLabel("Health \(store.vitals.health) percent")
                Spacer()
                Text("💩 \(store.vitals.poops)")
                    .accessibilityLabel("\(store.vitals.poops) messes")
            }
            .font(.system(.caption, design: .monospaced))

            sessionInfoRows

            animationUnlockRow

            Text(store.freshnessText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var petPickerRow: some View {
        VStack(alignment: .leading, spacing: Metric.xs) {
            HStack(spacing: Metric.sm) {
                Label("Pet", systemImage: "pawprint.fill")
                Spacer()
                skinButton(.classic)
                skinButton(.claude)
            }
            .font(.system(.caption, design: .monospaced))

            if !claudeUnlocked {
                Text("Claude unlocks at \(Int(PetSkin.claude.unlockThreshold))% weekly peak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func skinButton(_ skin: PetSkin) -> some View {
        let locked = skin == .claude && !claudeUnlocked
        let isSelected = effectiveSkin == skin
        Button {
            skinRaw = skin.rawValue
        } label: {
            HStack(spacing: Metric.xs) {
                if locked { Image(systemName: "lock.fill") }
                Text(skin.displayName)
            }
            .font(.system(.caption, design: .monospaced))
            .padding(.horizontal, Metric.sm)
            .padding(.vertical, Metric.xs)
            .background(isSelected ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.12),
                        in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .foregroundStyle(locked ? Color.secondary : .primary)
        .accessibilityLabel("\(skin.displayName) pet")
        .accessibilityValue(locked ? "locked" : (isSelected ? "selected" : "not selected"))
        .accessibilityHint(locked ? "Reach \(Int(PetSkin.claude.unlockThreshold)) percent weekly usage to unlock" : "")
    }

    @ViewBuilder
    private var sessionInfoRows: some View {
        if store.model != nil || store.effortLevel != nil || store.fastMode != nil {
            VStack(spacing: Metric.xs) {
                if let model = store.model {
                    infoRow("Model", model, systemImage: "cpu")
                }
                if let effort = store.effortLevel {
                    infoRow("Reasoning", Self.effortLabel(effort), systemImage: "brain")
                }
                if let fastMode = store.fastMode {
                    infoRow("Fast mode", fastMode ? "On" : "Off", systemImage: "bolt.fill")
                }
            }
        }
    }

    private func infoRow(_ name: String, _ value: String, systemImage: String) -> some View {
        HStack {
            Label(name, systemImage: systemImage)
            Spacer()
            Text(value).bold()
        }
        .font(.system(.caption, design: .monospaced))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(value)
    }

    private static func effortLabel(_ level: String) -> String {
        switch level.lowercased() {
        case "xhigh": return "X-High"
        case "max": return "Max"
        default: return level.prefix(1).uppercased() + level.dropFirst()
        }
    }

    private var animationUnlockRow: some View {
        let vitals = store.vitals
        return VStack(alignment: .leading, spacing: Metric.xs) {
            HStack {
                Label("Animations", systemImage: "sparkles")
                Spacer()
                Picker("Animations", selection: animationSelection) {
                    ForEach(unlockedTiers, id: \.self) { tier in
                        Text(tier.displayName).tag(tier.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }
            .font(.system(.caption, design: .monospaced))

            if let next = vitals.nextAnimationUnlock {
                Text("next: \(next.tier.displayName) at \(Int(next.threshold))% weekly")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("all animations unlocked ✨")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Animations")
    }

    private func statRow(_ name: String, _ pct: Double, detail: String? = nil) -> some View {
        let value = store.vitals.hasData ? "\(Int(pct))%" : "—"
        return VStack(alignment: .leading, spacing: Metric.xs) {
            HStack {
                Text(name)
                if let detail, store.vitals.hasData {
                    Text(detail).foregroundStyle(.secondary)
                }
                Spacer()
                Text(value).bold()
            }
            .font(.system(.caption, design: .monospaced))
            ProgressView(value: min(max(pct, 0), 100), total: 100)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(accessibilityValue(pct, detail: detail))
    }

    private func accessibilityValue(_ pct: Double, detail: String?) -> String {
        guard store.vitals.hasData else { return "no data" }
        if let detail { return "\(Int(pct)) percent, \(detail)" }
        return "\(Int(pct)) percent"
    }
}
