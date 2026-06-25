import Foundation

public struct CodexUsageObservation: Equatable {
    public var inputTokens: Int
    public var cachedInputTokens: Int
    public var outputTokens: Int
    public var reasoningTokens: Int
    public var model: String?

    public var totalTokens: Int {
        inputTokens + outputTokens + reasoningTokens
    }
}

public enum CodexUsageParsing {
    public static func observations(from data: Data) -> [CodexUsageObservation] {
        let lines = String(decoding: data, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        if lines.count > 1 {
            return lines.flatMap { observations(fromJSONObjectData: Data($0.utf8)) }
        }

        return observations(fromJSONObjectData: data)
    }

    public static func snapshot(from data: Data, previous: UsageSnapshot?, now: Double,
                                sessionBudget: Int, weeklyBudget: Int,
                                nextResetAt: Double?) -> UsageSnapshot? {
        let observations = observations(from: data)
        guard !observations.isEmpty else { return nil }

        let deltaInput = observations.reduce(0) { $0 + $1.inputTokens }
        let deltaCached = observations.reduce(0) { $0 + $1.cachedInputTokens }
        let deltaOutput = observations.reduce(0) { $0 + $1.outputTokens }
        let deltaReasoning = observations.reduce(0) { $0 + $1.reasoningTokens }

        let inputTokens = (previous?.inputTokens ?? 0) + deltaInput
        let cachedInputTokens = (previous?.cachedInputTokens ?? 0) + deltaCached
        let outputTokens = (previous?.outputTokens ?? 0) + deltaOutput
        let reasoningTokens = (previous?.reasoningTokens ?? 0) + deltaReasoning
        let totalTokens = inputTokens + outputTokens + reasoningTokens
        let model = observations.last(where: { $0.model != nil })?.model ?? previous?.model

        return UsageSnapshot(
            provider: .codex,
            source: .codexJsonl,
            measurementKind: .estimatedBudget,
            sessionPct: percent(totalTokens, budget: sessionBudget),
            weeklyPct: percent(totalTokens, budget: weeklyBudget),
            contextPct: nil,
            sessionResetsAt: nextResetAt,
            weeklyResetsAt: previous?.weeklyResetsAt,
            model: model,
            inputTokens: inputTokens,
            cachedInputTokens: cachedInputTokens,
            outputTokens: outputTokens,
            reasoningTokens: reasoningTokens,
            codexResetsAvailable: previous?.codexResetsAvailable,
            codexResetsUsed: previous?.codexResetsUsed,
            codexNextResetAt: nextResetAt,
            updatedAt: now
        )
    }

    private static func observations(fromJSONObjectData data: Data) -> [CodexUsageObservation] {
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return [] }
        return observations(from: root)
    }

    private static func observations(from value: Any) -> [CodexUsageObservation] {
        if let dictionary = value as? [String: Any] {
            var found: [CodexUsageObservation] = []
            if let usage = dictionary["usage"] as? [String: Any],
               let observation = observation(from: usage, model: model(in: dictionary)) {
                found.append(observation)
            }
            for child in dictionary.values {
                if child is [String: Any] || child is [Any] {
                    found.append(contentsOf: observations(from: child))
                }
            }
            return found
        }

        if let array = value as? [Any] {
            return array.flatMap { observations(from: $0) }
        }

        return []
    }

    private static func observation(from usage: [String: Any], model: String?) -> CodexUsageObservation? {
        let input = int(usage["input_tokens"] ?? usage["inputTokens"])
        let cached = int(usage["cached_input_tokens"] ?? usage["cachedInputTokens"])
        let output = int(usage["output_tokens"] ?? usage["outputTokens"])
        let reasoning = int(usage["reasoning_output_tokens"] ?? usage["reasoningOutputTokens"])

        guard input != nil || cached != nil || output != nil || reasoning != nil else { return nil }
        return CodexUsageObservation(
            inputTokens: input ?? 0,
            cachedInputTokens: cached ?? 0,
            outputTokens: output ?? 0,
            reasoningTokens: reasoning ?? 0,
            model: model
        )
    }

    private static func int(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let string = value as? String { return Int(string) }
        return nil
    }

    private static func model(in dictionary: [String: Any]) -> String? {
        if let model = dictionary["model"] as? String { return model }
        if let model = dictionary["model"] as? [String: Any] {
            return (model["display_name"] as? String) ?? (model["id"] as? String)
        }
        return nil
    }

    private static func percent(_ tokens: Int, budget: Int) -> Double? {
        guard budget > 0 else { return nil }
        return min(100, max(0, Double(tokens) / Double(budget) * 100))
    }
}
