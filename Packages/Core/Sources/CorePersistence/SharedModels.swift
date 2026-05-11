import Foundation

public struct Client: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String?
    public let email: String?
    public let phone: String?
    public init(id: String, name: String? = nil, email: String? = nil, phone: String? = nil) {
        self.id = id; self.name = name; self.email = email; self.phone = phone
    }
}

public struct StableBox: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String?
    public let number: String?
    public let building_id: String?
    public let status: String?
    public init(id: String, name: String? = nil, number: String? = nil, building_id: String? = nil, status: String? = nil) {
        self.id = id; self.name = name; self.number = number; self.building_id = building_id; self.status = status
    }
}

public struct BoxAssignment: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let horse_id: String
    public let box_id: String
    public let from_date: String?
    public let to_date: String?
    public init(id: String, horse_id: String, box_id: String, from_date: String? = nil, to_date: String? = nil) {
        self.id = id; self.horse_id = horse_id; self.box_id = box_id
        self.from_date = from_date; self.to_date = to_date
    }
}
