import Foundation

/// Wall-clock abstraction. Named `SyncClock` (not `Clock`) to avoid
/// collision with `Swift.Clock` from the standard library, which has a
/// `var now: Instant` property — the compiler resolves `any Clock` to
/// the stdlib one in modules that also `import Foundation`, breaking
/// our `clock.now()` calls.
public protocol SyncClock: Sendable {
    func now() -> Date
}

public struct SystemSyncClock: SyncClock {
    public init() {}
    public func now() -> Date { Date() }
}
