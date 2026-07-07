import Foundation

/// The seam the refresh loop reads and writes through. Disk is the production adapter;
/// tests substitute an in-memory adapter.
public protocol SnapshotStore {
    func loadSnapshot() -> UsageSnapshot?
    func loadPetState() -> PetState
    func savePetState(_ state: PetState)
}

public struct DiskSnapshotStore: SnapshotStore {
    private let provider: UsageProvider

    public init(provider: UsageProvider = .claude) {
        self.provider = provider
    }

    public func loadSnapshot() -> UsageSnapshot? { UsageSnapshot.load(provider: provider) }
    public func loadPetState() -> PetState { PetState.load(provider: provider) }
    public func savePetState(_ state: PetState) { state.save(provider: provider) }
}

/// One refresh tick: load the latest snapshot, advance pet state through `PetEngine`,
/// persist the state only when it changed, and hand back the vitals and the snapshot
/// the display layer projects from.
public final class PetSession {
    private let store: SnapshotStore
    private var state: PetState

    public init(store: SnapshotStore = DiskSnapshotStore()) {
        self.store = store
        self.state = store.loadPetState()
    }

    @discardableResult
    public func refresh() -> (vitals: Vitals, snapshot: UsageSnapshot?) {
        let snapshot = store.loadSnapshot()
        let previous = state
        let vitals = PetEngine.update(snapshot: snapshot, state: &state)
        if state != previous { store.savePetState(state) }
        return (vitals, snapshot)
    }
}
