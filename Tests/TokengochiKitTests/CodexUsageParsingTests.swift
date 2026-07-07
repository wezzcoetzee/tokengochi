import Foundation
import Testing
@testable import TokengochiKit

@Suite struct CodexUsageParsingTests {
    @Test func parsesTurnCompletedJsonlUsage() {
        let jsonl = """
        {"type":"thread.started","thread_id":"abc"}
        {"type":"turn.completed","usage":{"input_tokens":24763,"cached_input_tokens":24448,"output_tokens":122,"reasoning_output_tokens":3}}
        """

        let observations = CodexUsageParsing.observations(from: Data(jsonl.utf8))

        #expect(observations.count == 1)
        #expect(observations[0].inputTokens == 24763)
        #expect(observations[0].cachedInputTokens == 24448)
        #expect(observations[0].outputTokens == 122)
        #expect(observations[0].reasoningTokens == 3)
    }

    @Test func snapshotAccumulatesPreviousTokenTotalsAndEstimatesBudget() {
        let jsonl = """
        {"type":"turn.completed","usage":{"input_tokens":100,"output_tokens":40,"reasoning_output_tokens":10}}
        """
        let previous = UsageSnapshot(
            provider: .codex,
            source: .codexJsonl,
            measurementKind: .estimatedBudget,
            sessionPct: 1,
            weeklyPct: 1,
            contextPct: nil,
            sessionResetsAt: nil,
            weeklyResetsAt: nil,
            inputTokens: 50,
            cachedInputTokens: 5,
            outputTokens: 10,
            reasoningTokens: 0,
            updatedAt: 0
        )

        let snapshot = CodexUsageParsing.snapshot(
            from: Data(jsonl.utf8),
            previous: previous,
            now: 99,
            sessionBudget: 1_000,
            weeklyBudget: 10_000,
            nextResetAt: 500
        )

        #expect(snapshot?.provider == .codex)
        #expect(snapshot?.measurementKind == .estimatedBudget)
        #expect(snapshot?.inputTokens == 150)
        #expect(snapshot?.outputTokens == 50)
        #expect(snapshot?.reasoningTokens == 10)
        #expect(snapshot?.sessionPct == 21)
        #expect(snapshot?.weeklyPct == 2.1)
        #expect(snapshot?.codexNextResetAt == 500)
        #expect(snapshot?.updatedAt == 99)
    }
}
