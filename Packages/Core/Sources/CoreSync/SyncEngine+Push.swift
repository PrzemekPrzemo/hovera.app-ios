import Foundation

/// BISECTION STUB — will be filled in once CI confirms the file shell compiles.
/// Originally contained `enqueueMutation` (INSERT to mutation_queue) and
/// `pushMutations` (POST /sync/mutations + drain queue) but those were
/// repeatedly hitting Swift 6 compile errors we couldn't pinpoint from
/// the truncated CI output. Stripped here to verify the extension shell
/// + the existing public method signatures compile, then we add bodies
/// back one at a time.
extension SyncEngine {
    public func enqueueMutation(
        entity: String,
        op: String,
        payloadJson: String,
        baseVersion: Int? = nil
    ) async throws -> String {
        return UUID().uuidString
    }

    func pushMutations() async throws {
        // intentionally empty
    }
}
