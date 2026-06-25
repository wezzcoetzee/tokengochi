import Testing
@testable import TokengochiKit

@Suite struct RateLimitWindowTests {
    @Test func usageEndpointReadsUtilizationAndResets() {
        let window: [String: Any] = ["utilization": 42.5, "resets_at": 1000.0]
        let parsed = RateLimitWindow.usageEndpoint(window)

        #expect(parsed.pct == 42.5)
        #expect(parsed.resetsAt == 1000.0)
    }

    @Test func usageEndpointClampsUtilization() {
        #expect(RateLimitWindow.usageEndpoint(["utilization": 140]).pct == 100)
        #expect(RateLimitWindow.usageEndpoint(["utilization": -5]).pct == 0)
    }

    @Test func statuslineReadsUsedPercentage() {
        let window: [String: Any] = ["used_percentage": 88, "resets_at": "2026-06-24T10:00:00Z"]
        let parsed = RateLimitWindow.statusline(window)

        #expect(parsed.pct == 88)
        #expect(parsed.resetsAt != nil)
    }

    @Test func missingDictYieldsNils() {
        let parsed = RateLimitWindow.usageEndpoint(nil)
        #expect(parsed.pct == nil)
        #expect(parsed.resetsAt == nil)
    }
}
