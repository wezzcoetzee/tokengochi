import SwiftUI
import TokengochiKit

struct CombinedMenuBarLabel: View {
    let stores: [UsageStore]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(stores, id: \.provider) { store in
                HStack(spacing: 2) {
                    Image(systemName: store.vitals.mood.symbolName)
                    Text(store.provider == .claude ? "C" : "X")
                    if store.vitals.hasData {
                        Text("\(Int(store.vitals.session))%")
                    }
                }
            }
        }
    }
}

struct MultiProviderMenuContentView: View {
    let stores: [UsageStore]

    var body: some View {
        Group {
            if stores.count > 1 {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(stores.enumerated()), id: \.element.provider) { index, store in
                        MenuContentView(store: store)
                        if index < stores.count - 1 {
                            Divider()
                                .padding(.vertical, Metric.content)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            } else if let store = stores.first {
                MenuContentView(store: store)
            }
        }
    }
}

struct MenuContentView: View {
    @ObservedObject var store: UsageStore
    @StateObject private var loginItem = LoginItemManager()
    @State private var showingHelp = false
    @AppStorage("petSkin") private var claudeSkinRaw = PetSkin.classic.rawValue
    @AppStorage("petSkinCodex") private var codexSkinRaw = PetSkin.classic.rawValue
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

    private var selectedSkin: PetSkin {
        let choices = PetSkin.providerChoices(for: store.provider)
        switch store.provider {
        case .claude:
            let skin = PetSkin(rawValue: claudeSkinRaw) ?? store.provider.defaultSkin
            return choices.contains(skin) ? skin : store.provider.defaultSkin
        case .codex:
            let skin = PetSkin(rawValue: codexSkinRaw) ?? store.provider.defaultSkin
            return choices.contains(skin) ? skin : store.provider.defaultSkin
        }
    }

    private var providerSkinUnlocked: Bool {
        store.provider.providerSkin.isUnlocked(forPeakWeekly: store.vitals.peakWeekly)
    }

    private var effectiveSkin: PetSkin {
        let providerSkin = store.provider.providerSkin
        return selectedSkin == providerSkin && providerSkinUnlocked ? providerSkin : .classic
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
            Text(store.provider.displayName).font(.headline)
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

    private var statsBody: some View {
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

            codexInfoRows

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
                ForEach(PetSkin.providerChoices(for: store.provider), id: \.self) { skin in
                    skinButton(skin)
                }
            }
            .font(.system(.caption, design: .monospaced))

            if !providerSkinUnlocked {
                Text("\(store.provider.providerSkin.displayName) unlocks at \(Int(store.provider.providerSkin.unlockThreshold))% weekly peak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func skinButton(_ skin: PetSkin) -> some View {
        let providerSkin = store.provider.providerSkin
        let locked = skin == providerSkin && !providerSkinUnlocked
        let isSelected = effectiveSkin == skin
        Button {
            switch store.provider {
            case .claude:
                claudeSkinRaw = skin.rawValue
            case .codex:
                codexSkinRaw = skin.rawValue
            }
        } label: {
            HStack(spacing: Metric.xs) {
                if locked { Image(systemName: "lock.fill") }
                if skin == .codex { Image(systemName: "terminal") }
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
        .accessibilityHint(locked ? "Reach \(Int(providerSkin.unlockThreshold)) percent weekly usage to unlock" : "")
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

    @ViewBuilder
    private var codexInfoRows: some View {
        if store.provider == .codex {
            VStack(spacing: Metric.xs) {
                if let totalTokens = totalCodexTokens {
                    infoRow("Tokens", Self.tokenLabel(totalTokens), systemImage: "number")
                }
                if let reasoning = store.reasoningTokens, reasoning > 0 {
                    infoRow("Reasoning", Self.tokenLabel(reasoning), systemImage: "brain")
                }
                if let resets = store.codexResetsAvailable {
                    infoRow("Resets", "\(resets) left", systemImage: "arrow.clockwise")
                } else if store.vitals.hasData {
                    infoRow("Resets", "Unknown", systemImage: "arrow.clockwise")
                }
                if let resetText = store.codexNextResetText {
                    infoRow("Next reset", resetText, systemImage: "calendar")
                }
                if store.measurementKind == .estimatedBudget || store.measurementKind == .estimatedResets {
                    infoRow("Source", "Estimated", systemImage: "waveform.path.ecg")
                }
            }
        }
    }

    private var totalCodexTokens: Int? {
        let total = (store.inputTokens ?? 0) + (store.outputTokens ?? 0) + (store.reasoningTokens ?? 0)
        return total > 0 ? total : nil
    }

    private static func tokenLabel(_ value: Int) -> String {
        if value >= 1_000_000 { return "\(value / 1_000_000)m" }
        if value >= 1_000 { return "\(value / 1_000)k" }
        return "\(value)"
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
