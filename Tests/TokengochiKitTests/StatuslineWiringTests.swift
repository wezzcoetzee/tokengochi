import Testing
@testable import TokengochiKit

@Suite struct StatuslineWiringTests {
    @Test func commandExtractedOnlyFromCommandTypeStatusline() {
        #expect(StatuslineWiring.command(inSettings: ["statusLine": ["type": "command", "command": "hud"]]) == "hud")
        #expect(StatuslineWiring.command(inSettings: ["statusLine": ["type": "static", "command": "hud"]]) == nil)
        #expect(StatuslineWiring.command(inSettings: [:]) == nil)
    }

    @Test func directWriterCommandIsWired() {
        let wired = StatuslineWiring.isWired(command: "/Applications/Tokengochi.app/Contents/Helpers/TokengochiWriter") { _ in nil }
        #expect(wired)
    }

    @Test func wrapperScriptReferencingWriterIsWired() {
        let wired = StatuslineWiring.isWired(command: "/Users/me/.claude/tokengochi-statusline.sh") { path in
            path == "/Users/me/.claude/tokengochi-statusline.sh" ? "#!/bin/bash\nexec 'TokengochiWriter'\n" : nil
        }
        #expect(wired)
    }

    @Test func unrelatedCommandIsNotWired() {
        #expect(!StatuslineWiring.isWired(command: "bash -c 'run-my-hud'") { _ in "TokengochiWriter" })
        #expect(!StatuslineWiring.isWired(command: "/Users/me/.claude/hud.sh") { _ in "exec bun hud.ts" })
        #expect(!StatuslineWiring.isWired(command: nil) { _ in nil })
        #expect(!StatuslineWiring.isWired(command: "") { _ in nil })
    }

    @Test func wrapperScriptChainsPassthroughAndQuotesPaths() {
        let script = StatuslineWiring.wrapperScript(writerPath: "/Applications/My App/Writer",
                                                    passthroughPath: "/Users/me/.claude/tokengochi-passthrough.sh")
        #expect(script == """
        #!/bin/bash
        export TOKENGOCHI_PASSTHROUGH_CMD='/Users/me/.claude/tokengochi-passthrough.sh'
        exec '/Applications/My App/Writer'

        """)
    }

    @Test func wrapperScriptWithoutPassthroughOmitsExport() {
        let script = StatuslineWiring.wrapperScript(writerPath: "/w", passthroughPath: nil)
        #expect(!script.contains("TOKENGOCHI_PASSTHROUGH_CMD"))
        #expect(script.contains("exec '/w'"))
    }

    @Test func passthroughScriptRoundTripsOriginalCommand() {
        let original = "bash -c 'my hud | thing'"
        let script = StatuslineWiring.passthroughScript(preserving: original)
        #expect(StatuslineWiring.preservedCommand(inPassthroughScript: script) == original)
    }

    @Test func preservedCommandIsNilForEmptyScript() {
        #expect(StatuslineWiring.preservedCommand(inPassthroughScript: "#!/bin/bash\n\n") == nil)
    }

    @Test func settingsUpdatePreservesOtherKeys() {
        let updated = StatuslineWiring.settings(["model": "opus", "statusLine": ["type": "command", "command": "old"]],
                                                pointingAt: "/wrapper.sh")
        #expect(updated["model"] as? String == "opus")
        #expect(StatuslineWiring.command(inSettings: updated) == "/wrapper.sh")
    }

    @Test func settingsRemovalDropsOnlyStatusline() {
        let updated = StatuslineWiring.settingsRemovingStatusline(["model": "opus", "statusLine": ["type": "command", "command": "x"]])
        #expect(updated["statusLine"] == nil)
        #expect(updated["model"] as? String == "opus")
    }

    @Test func shellQuotingEscapesSingleQuotes() {
        #expect(StatuslineWiring.shellQuoted("it's") == "'it'\\''s'")
    }
}
