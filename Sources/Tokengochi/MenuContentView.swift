import SwiftUI
import TokengochiKit

struct MenuContentView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var poller: PollerManager
    var startShowingHelp = false
    var startShowingSettings = false
    @StateObject private var loginItem = LoginItemManager()
    @StateObject private var statusline = StatuslineManager()
    @State private var showingHelp = false
    @State private var showingSettings = false
    @State private var titleTapCount = 0
    @State private var lastTitleTapAt = Date.distantPast
    @State private var petHintsRevealed = false
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

    private var pikaUnlocked: Bool { store.vitals.pikaUnlocked }

    private var reekUnlocked: Bool { store.vitals.reekUnlocked }

    private func isUnlocked(_ skin: PetSkin) -> Bool {
        switch skin {
        case .classic: return true
        case .claude: return claudeUnlocked
        case .pika: return pikaUnlocked
        case .reek: return reekUnlocked
        }
    }

    private var effectiveSkin: PetSkin {
        isUnlocked(selectedSkin) ? selectedSkin : .classic
    }

    private var unlockedSkins: [PetSkin] {
        PetSkin.helpOrder.filter(isUnlocked)
    }

    private var skinSelection: Binding<String> {
        Binding(
            get: { effectiveSkin.rawValue },
            set: { skinRaw = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.lg) {
            header

            if showingHelp {
                HelpView(vitals: store.vitals, activeAnimationTier: effectiveAnimationTier,
                         showPetUnlocks: petHintsRevealed, activeSkin: effectiveSkin)
            } else if showingSettings {
                settingsBody
            } else {
                statsBody
            }

            HStack {
                Button("Refresh") { store.refresh() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(Metric.content)
        .frame(minWidth: 264, idealWidth: 264, maxWidth: 320)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: showingHelp) { _, showing in
            if !showing { petHintsRevealed = false }
        }
        .onAppear {
            showingHelp = startShowingHelp
            showingSettings = startShowingSettings
            petHintsRevealed = false
            store.setActive(true)
            poller.refresh()
            loginItem.refresh()
            statusline.enableIfNeeded()
        }
        .onDisappear { store.setActive(false) }
    }

    private var header: some View {
        HStack {
            Text("Tokengochi").font(.headline)
                .onTapGesture(perform: registerTitleTap)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Something might happen if you're quick about it")
            Spacer()
            Button {
                showingHelp.toggle()
                if showingHelp { showingSettings = false }
            } label: {
                Image(systemName: showingHelp ? "questionmark.circle.fill" : "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(showingHelp ? Color.accentColor : .secondary)
            .accessibilityLabel(showingHelp ? "Close help" : "Help")
            .accessibilityHint("Explains moods, vitals, and mechanics")

            Button {
                showingSettings.toggle()
                if showingSettings { showingHelp = false }
            } label: {
                Image(systemName: showingSettings ? "gearshape.fill" : "gearshape")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(showingSettings ? Color.accentColor : .secondary)
            .accessibilityLabel(showingSettings ? "Close settings" : "Settings")
            .accessibilityHint("Configure background updates, statusline, and launch at login")
        }
    }

    private func registerTitleTap() {
        let now = Date()
        titleTapCount = now.timeIntervalSince(lastTitleTapAt) <= 1.0 ? titleTapCount + 1 : 1
        lastTitleTapAt = now
        guard titleTapCount >= 5 else { return }
        titleTapCount = 0
        petHintsRevealed = true
        showingSettings = false
        showingHelp = true
    }

    private var settingsBody: some View {
        VStack(alignment: .leading, spacing: Metric.lg) {
            petPickerRow

            animationUnlockRow

            Divider()

            backgroundUpdatesRow

            statuslineRow

            launchAtLoginRow
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

    private var statuslineRow: some View {
        VStack(alignment: .leading, spacing: Metric.xs) {
            Toggle(isOn: Binding(
                get: { statusline.isEnabled },
                set: { statusline.setEnabled($0) }
            )) {
                Label("Statusline writer", systemImage: "text.insert")
                    .font(.system(.caption, design: .monospaced))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)

            if let error = statusline.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                Text("Captures model, reasoning & context from Claude Code's statusline. Chains to your existing statusline.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { statusline.enableIfNeeded() }
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

            Text(store.freshnessText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var petPickerRow: some View {
        HStack {
            Label("Pet", systemImage: "pawprint.fill")
            Spacer()
            Picker("Pet", selection: skinSelection) {
                ForEach(unlockedSkins, id: \.self) { skin in
                    Text(skin.displayName).tag(skin.rawValue)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()
        }
        .font(.system(.caption, design: .monospaced))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pet")
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
