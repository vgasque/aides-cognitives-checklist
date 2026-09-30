import Foundation

// MINUTERIES DE LA SYNCHRO — le débounce de 900 ms (`Sync.schedule`) et la relance après échec
// (`_scheduleRetry` : 5 s, 10 s, 20 s… plafonnée à 2 min). Injectables : en test, une horloge
// MANUELLE fait avancer le temps d'un coup, sans attendre deux minutes de vraie montre.

public protocol SyncCancellable: AnyObject {
    func cancel()
}

@MainActor
public protocol SyncScheduler: AnyObject {
    /// Exécute `action` après `ms` millisecondes (sur l'acteur principal), sauf annulation.
    func after(ms: Double, _ action: @escaping @MainActor () async -> Void) -> SyncCancellable
}

/// Minuterie réelle (tâches Swift). Une tâche annulée ne lance jamais son action.
@MainActor
public final class TaskSyncScheduler: SyncScheduler {
    public init() {}
    final class Handle: SyncCancellable {
        var task: Task<Void, Never>?
        func cancel() { task?.cancel(); task = nil }
    }
    public func after(ms: Double, _ action: @escaping @MainActor () async -> Void) -> SyncCancellable {
        let h = Handle()
        h.task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(max(0, ms) * 1_000_000))
            if Task.isCancelled { return }
            await action()
        }
        return h
    }
}

/// Minuterie MANUELLE (tests) : `advance(by:)` fait avancer une horloge virtuelle et exécute, dans
/// l'ordre, les actions arrivées à échéance.
@MainActor
public final class ManualSyncScheduler: SyncScheduler {
    public private(set) var now: Double = 0
    final class Item: SyncCancellable {
        let due: Double
        let seq: Int
        var action: (@MainActor () async -> Void)?
        init(due: Double, seq: Int, action: @escaping @MainActor () async -> Void) { self.due = due; self.seq = seq; self.action = action }
        func cancel() { action = nil }
    }
    private var items: [Item] = []
    private var seq = 0
    public init() {}

    public func after(ms: Double, _ action: @escaping @MainActor () async -> Void) -> SyncCancellable {
        seq += 1
        let it = Item(due: now + ms, seq: seq, action: action)
        items.append(it)
        return it
    }
    /// Délais (depuis maintenant) des actions encore armées, dans l'ordre d'échéance.
    public var pendingDelays: [Double] {
        items.filter { $0.action != nil }.sorted { ($0.due, $0.seq) < ($1.due, $1.seq) }.map { $0.due - now }
    }
    /// Avance l'horloge et exécute chaque action échue (y compris celles qu'elles programment).
    public func advance(by ms: Double) async {
        let target = now + ms
        while true {
            let live = items.filter { $0.action != nil && $0.due <= target }.sorted { ($0.due, $0.seq) < ($1.due, $1.seq) }
            guard let next = live.first else { break }
            now = max(now, next.due)
            let a = next.action
            next.action = nil
            items.removeAll { $0 === next }
            await a?()
        }
        now = target
        items.removeAll { $0.action == nil }
    }
}
