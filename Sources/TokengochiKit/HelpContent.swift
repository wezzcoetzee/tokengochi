import Foundation

public struct HelpTopic: Identifiable {
    public let id = UUID()
    public let symbol: String
    public let title: String
    public let detail: String

    public init(symbol: String, title: String, detail: String) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }
}

public enum HelpContent {
    public static let vitals: [HelpTopic] = [
        HelpTopic(symbol: "fork.knife",
                  title: "Hunger = unused session",
                  detail: "Spending tokens feeds your pet (100 − session%). Using more is always good."),
        HelpTopic(symbol: "face.smiling",
                  title: "Happiness = weekly usage",
                  detail: "Climbs with weekly%. Capped while Overfed so burning a window early still costs you."),
        HelpTopic(symbol: "heart.fill",
                  title: "Health = 100 − messes × \(PetEngine.healthPerPoop)",
                  detail: "Uncleaned messes drain health. Below 40% the pet turns Sick."),
        HelpTopic(symbol: "scalemass",
                  title: "Weight = proud fatness",
                  detail: "Body size grows with weekly value. Burning a window early bloats it past the healthy band.")
    ]

    public static let mechanics: [HelpTopic] = [
        HelpTopic(symbol: "exclamationmark.triangle",
                  title: "Wasted window → 💩",
                  detail: "End a 5-hour window under \(Int(PetEngine.wastedWindowThreshold))% used and the pet leaves one mess."),
        HelpTopic(symbol: "sparkles",
                  title: "Clean by using Claude",
                  detail: "Reach \(Int(PetEngine.cleanThreshold))% session in a later window to auto-clean one mess. There is no clean button."),
        HelpTopic(symbol: "thermometer.medium",
                  title: "Messes make it Sick",
                  detail: "Each mess costs \(PetEngine.healthPerPoop) health; stack a few and the pet falls ill."),
        HelpTopic(symbol: "tortoise.fill",
                  title: "Pace the whole window",
                  detail: "Hit \(Int(PetEngine.overfedSessionThreshold))% session with over an hour left and the pet gets Overfed — bloated and rate-limited. Spread usage across the 5-hour window instead.")
    ]
}
