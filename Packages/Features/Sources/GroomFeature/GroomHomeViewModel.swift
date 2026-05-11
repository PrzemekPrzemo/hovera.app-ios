import SwiftUI
import CorePersistence
import CoreNetworking
import CoreSync

@MainActor
@Observable
public final class GroomHomeViewModel {
    public private(set) var pendingToday: [StableActivity] = []
    public private(set) var horses: [Horse] = []
    public private(set) var recentWeights: [HorseWeightMeasurement] = []
    public private(set) var lastUploadError: String?

    private let activityRepo: StableActivityRepository
    private let horseRepo: HorseRepository
    private let weightRepo: HorseWeightRepository

    public init() {
        let db = HoveraDatabase.shared
        self.activityRepo = StableActivityRepository(database: db)
        self.horseRepo = HorseRepository(database: db)
        self.weightRepo = HorseWeightRepository(database: db)
    }

    public func load() async {
        let cal = Calendar(identifier: .iso8601)
        let now = Date()
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? now
        let formatter = ISO8601DateFormatter()
        let startIso = formatter.string(from: start)
        let endIso = formatter.string(from: end)

        async let acts = (try? activityRepo.loadPendingToday(startIso: startIso, endIso: endIso)) ?? []
        async let hs = (try? horseRepo.loadAll()) ?? []
        async let ws = (try? weightRepo.loadAll()) ?? []

        let pending = await acts
        let allHorses = await hs
        let recent = await ws

        self.pendingToday = pending
        self.horses = allHorses
        self.recentWeights = Array(recent.prefix(10))
    }

    public func toggleActivity(_ activity: StableActivity) async {
        let newStatus = activity.status == "completed" ? "pending" : "completed"
        let completedAt = newStatus == "completed" ? ISO8601DateFormatter().string(from: Date()) : nil
        try? await activityRepo.setStatus(activity, to: newStatus, completedAt: completedAt)
        let payload: [String: Any] = [
            "id": activity.id,
            "status": newStatus,
            "completed_at": completedAt ?? NSNull(),
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let json = String(data: data, encoding: .utf8) {
            _ = try? await SyncEngineProvider.shared.enqueueMutation(
                entity: "stable_activities",
                op: "update",
                payloadJson: json
            )
        }
        await load()
    }

    /// Upload bytes via presigned PUT (PhotoUploader), then enqueue a
    /// `horse_photos.create` mutation referencing the returned storage_key.
    /// Errors surface through `lastUploadError` so the UI can display them.
    public func addHorsePhoto(data: Data, horseId: String) async {
        lastUploadError = nil
        do {
            let storageKey = try await PhotoUploader.shared.uploadHorsePhoto(
                data: data, mime: "image/jpeg"
            )
            let id = UUID().uuidString
            let payload: [String: Any] = [
                "id": id,
                "horse_id": horseId,
                "storage_key": storageKey,
                "sha256": PhotoUploader.sha256Hex(data),
            ]
            if let payloadData = try? JSONSerialization.data(withJSONObject: payload),
               let json = String(data: payloadData, encoding: .utf8) {
                _ = try? await SyncEngineProvider.shared.enqueueMutation(
                    entity: "horse_photos",
                    op: "create",
                    payloadJson: json
                )
            }
        } catch {
            lastUploadError = String(describing: error)
        }
    }
}
