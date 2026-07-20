import Testing
@testable import TokengochiKit

@Suite struct CreatureFaceTests {
    @Test func classicBodyHasFeetClaudeDoesNot() {
        #expect(CreatureFace.bodyRows(skin: .classic).count == 14)
        #expect(CreatureFace.bodyRows(skin: .claude).count == 12)
    }

    @Test func sickMouthDiffersFromHappyMouth() {
        let sick = CreatureFace.mouthCells(skin: .classic, mood: .sick)
        let thriving = CreatureFace.mouthCells(skin: .classic, mood: .thriving)
        #expect(sick != thriving)
        #expect(sick.contains(FaceCell(6, 7)))
    }

    @Test func thrivingMouthSmilesLonelyFrowns() {
        let smile = CreatureFace.mouthCells(skin: .classic, mood: .thriving)
        let frown = CreatureFace.mouthCells(skin: .classic, mood: .lonely)
        #expect(smile == [FaceCell(5, 7), FaceCell(6, 8), FaceCell(7, 8), FaceCell(8, 8), FaceCell(9, 8), FaceCell(10, 7)])
        #expect(frown == [FaceCell(5, 8), FaceCell(6, 7), FaceCell(7, 7), FaceCell(8, 7), FaceCell(9, 7), FaceCell(10, 8)])
    }

    @Test func claudeSkinHasNoMouth() {
        #expect(CreatureFace.mouthCells(skin: .claude, mood: .sick).isEmpty)
    }

    @Test func overfedClosesEyesLikeBlink() {
        let overfed = CreatureFace.eyeCells(skin: .classic, mood: .overfed, blink: false)
        let blinking = CreatureFace.eyeCells(skin: .classic, mood: .okay, blink: true)
        #expect(overfed == blinking)
        #expect(overfed.count == 4)
    }

    @Test func openClassicEyesAreTallerThanBlink() {
        let open = CreatureFace.eyeCells(skin: .classic, mood: .okay, blink: false)
        let blink = CreatureFace.eyeCells(skin: .classic, mood: .okay, blink: true)
        #expect(open.count == 8)
        #expect(blink.count == 4)
    }

    @Test func pikaBodyIsFifteenRowsAndSixteenColumnsWide() {
        let rows = CreatureFace.bodyRows(skin: .pika)
        #expect(rows.count == 15)
        #expect(rows.allSatisfy { $0.count == 16 })
    }

    private func expectCellsAreBody(_ cells: [FaceCell], rows: [String]) {
        for cell in cells {
            let row = Array(rows[cell.row])
            #expect(row[cell.col] == "#")
        }
    }

    @Test func pikaEyeAndMouthCellsLandInsideBody() {
        let rows = CreatureFace.bodyRows(skin: .pika)
        expectCellsAreBody(CreatureFace.eyeCells(skin: .pika, mood: .okay, blink: false), rows: rows)
        expectCellsAreBody(CreatureFace.eyeCells(skin: .pika, mood: .okay, blink: true), rows: rows)
        for mood in [Mood.thriving, .okay, .lonely, .starving, .sick, .overfed, .noData] {
            expectCellsAreBody(CreatureFace.mouthCells(skin: .pika, mood: mood), rows: rows)
        }
    }

    @Test func pikaBlinkingEyesDifferFromOpenEyes() {
        let open = CreatureFace.eyeCells(skin: .pika, mood: .okay, blink: false)
        let blink = CreatureFace.eyeCells(skin: .pika, mood: .okay, blink: true)
        #expect(open != blink)
        #expect(open.count == 8)
        #expect(blink.count == 4)
    }

    @Test func pikaOverfedClosesEyesLikeBlink() {
        let overfed = CreatureFace.eyeCells(skin: .pika, mood: .overfed, blink: false)
        let blinking = CreatureFace.eyeCells(skin: .pika, mood: .okay, blink: true)
        #expect(overfed == blinking)
    }

    @Test func pikaSickMouthDiffersFromThrivingMouth() {
        let sick = CreatureFace.mouthCells(skin: .pika, mood: .sick)
        let thriving = CreatureFace.mouthCells(skin: .pika, mood: .thriving)
        #expect(sick != thriving)
    }

    @Test func reekBodyIsThirteenRowsAndSixteenColumnsWide() {
        let rows = CreatureFace.bodyRows(skin: .reek)
        #expect(rows.count == 13)
        #expect(rows.allSatisfy { $0.count == 16 })
    }

    @Test func reekEyeAndMouthCellsLandInsideBody() {
        let rows = CreatureFace.bodyRows(skin: .reek)
        expectCellsAreBody(CreatureFace.eyeCells(skin: .reek, mood: .okay, blink: false), rows: rows)
        expectCellsAreBody(CreatureFace.eyeCells(skin: .reek, mood: .okay, blink: true), rows: rows)
        for mood in [Mood.thriving, .okay, .lonely, .starving, .sick, .overfed, .noData] {
            expectCellsAreBody(CreatureFace.mouthCells(skin: .reek, mood: mood), rows: rows)
        }
    }

    @Test func reekOverfedClosesEyesLikeBlink() {
        let overfed = CreatureFace.eyeCells(skin: .reek, mood: .overfed, blink: false)
        let blinking = CreatureFace.eyeCells(skin: .reek, mood: .okay, blink: true)
        #expect(overfed == blinking)
    }
}
