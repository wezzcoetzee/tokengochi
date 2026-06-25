import Testing
@testable import TokengochiKit

private final class InMemoryStore: SnapshotStore {
    var snapshot: UsageSnapshot?
    var petState: PetState
    private(set) var saveCount = 0

    init(snapshot: UsageSnapshot?, petState: PetState = PetState()) {
        self.snapshot = snapshot
        self.petState = petState
    }

    func loadSnapshot() -> UsageSnapshot? { snapshot }
    func loadPetState() -> PetState { petState }
    func savePetState(_ state: PetState) {
        petState = state
        saveCount += 1
    }
}

private func snapshot(session: Double?, weekly: Double? = 0) -> UsageSnapshot {
    UsageSnapshot(sessionPct: session, weeklyPct: weekly, contextPct: nil,
                  sessionResetsAt: nil, weeklyResetsAt: nil, updatedAt: 0)
}

@Suite struct PetSessionTests {
    @Test func refreshRunsEngineAndReturnsVitals() {
        let store = InMemoryStore(snapshot: snapshot(session: 50, weekly: 70))
        let session = PetSession(store: store)

        let result = session.refresh()

        #expect(result.vitals.hasData)
        #expect(result.vitals.mood == .thriving)
        #expect(result.snapshot != nil)
    }

    @Test func refreshPersistsStateOnlyWhenChanged() {
        let store = InMemoryStore(snapshot: snapshot(session: PetEngine.cleanThreshold),
                                  petState: PetState(poops: 1))
        let session = PetSession(store: store)

        session.refresh()
        #expect(store.petState.poops == 0)
        #expect(store.saveCount == 1)

        session.refresh()
        #expect(store.saveCount == 1)
    }

    @Test func refreshDoesNotPersistWhenNoData() {
        let store = InMemoryStore(snapshot: nil)
        let session = PetSession(store: store)

        session.refresh()
        #expect(store.saveCount == 0)
    }
}
