import Foundation
import Network

/// Wraps NWPathMonitor with an AsyncStream of online/offline transitions.
/// SyncEngine subscribes; transitions to online trigger a push attempt.
public actor Reachability {
    public static let shared = Reachability()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "app.hovera.reachability")
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]
    private var current: Bool = true
    private var started = false

    public func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { await self?.publish(online) }
        }
        monitor.start(queue: queue)
    }

    public func isOnline() -> Bool { current }

    public nonisolated func stream() -> AsyncStream<Bool> {
        AsyncStream { cont in
            let id = UUID()
            Task { await self.register(id: id, cont: cont) }
            cont.onTermination = { _ in
                Task { await self.unregister(id: id) }
            }
        }
    }

    private func register(id: UUID, cont: AsyncStream<Bool>.Continuation) {
        continuations[id] = cont
        cont.yield(current)
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func publish(_ online: Bool) {
        guard online != current else { return }
        current = online
        for c in continuations.values { c.yield(online) }
    }
}
