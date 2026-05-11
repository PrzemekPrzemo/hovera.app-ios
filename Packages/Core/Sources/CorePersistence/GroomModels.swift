import Foundation

public struct StableActivity: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let kind: String?
    public let title: String?
    public let description: String?
    public let status: String?
    public let due_at: String?
    public let completed_at: String?
    public let horse_id: String?
    public let assigned_to_user_id: String?
    public let notes: String?

    public init(
        id: String, kind: String? = nil, title: String? = nil,
        description: String? = nil, status: String? = nil,
        due_at: String? = nil, completed_at: String? = nil,
        horse_id: String? = nil, assigned_to_user_id: String? = nil,
        notes: String? = nil
    ) {
        self.id = id; self.kind = kind; self.title = title
        self.description = description; self.status = status
        self.due_at = due_at; self.completed_at = completed_at
        self.horse_id = horse_id; self.assigned_to_user_id = assigned_to_user_id
        self.notes = notes
    }
}

public struct HorseWeightMeasurement: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let horse_id: String
    public let weight_kg: Double?
    public let bcs_score: Double?
    public let measurement_date: String?
    public let notes: String?

    public init(
        id: String, horse_id: String,
        weight_kg: Double? = nil, bcs_score: Double? = nil,
        measurement_date: String? = nil, notes: String? = nil
    ) {
        self.id = id; self.horse_id = horse_id
        self.weight_kg = weight_kg; self.bcs_score = bcs_score
        self.measurement_date = measurement_date; self.notes = notes
    }
}
