import Foundation

public struct Horse: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let microchip: String?
    public let passport_number: String?
    public let breed: String?
    public let sex: String?
    public let color: String?
    public let birth_date: String?
    public let owner_client_id: String?
    public let box_id: String?
    public let cover_image_path: String?
    public let notes: String?

    public init(
        id: String, name: String,
        microchip: String? = nil, passport_number: String? = nil,
        breed: String? = nil, sex: String? = nil, color: String? = nil,
        birth_date: String? = nil, owner_client_id: String? = nil,
        box_id: String? = nil, cover_image_path: String? = nil, notes: String? = nil
    ) {
        self.id = id; self.name = name
        self.microchip = microchip; self.passport_number = passport_number
        self.breed = breed; self.sex = sex; self.color = color
        self.birth_date = birth_date; self.owner_client_id = owner_client_id
        self.box_id = box_id; self.cover_image_path = cover_image_path; self.notes = notes
    }
}

public struct CalendarEntry: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let type: String?
    public let status: String?
    public let starts_at: String?
    public let ends_at: String?
    public let horse_id: String?
    public let instructor_id: String?
    public let arena_id: String?
    public let client_id: String?
    public let title: String?
    public let notes: String?
    public let price_cents: Int?

    public init(
        id: String, type: String? = nil, status: String? = nil,
        starts_at: String? = nil, ends_at: String? = nil,
        horse_id: String? = nil, instructor_id: String? = nil,
        arena_id: String? = nil, client_id: String? = nil,
        title: String? = nil, notes: String? = nil, price_cents: Int? = nil
    ) {
        self.id = id; self.type = type; self.status = status
        self.starts_at = starts_at; self.ends_at = ends_at
        self.horse_id = horse_id; self.instructor_id = instructor_id
        self.arena_id = arena_id; self.client_id = client_id
        self.title = title; self.notes = notes; self.price_cents = price_cents
    }
}

public struct Invoice: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let number: String?
    public let amount_cents: Int?
    public let currency: String?
    public let ksef_status: String?
    public let pdf_url: String?
    public let issued_at: String?
    public let due_at: String?
    public let paid_at: String?
    public let client_id: String?

    public init(
        id: String, number: String? = nil, amount_cents: Int? = nil,
        currency: String? = nil, ksef_status: String? = nil, pdf_url: String? = nil,
        issued_at: String? = nil, due_at: String? = nil, paid_at: String? = nil,
        client_id: String? = nil
    ) {
        self.id = id; self.number = number; self.amount_cents = amount_cents
        self.currency = currency; self.ksef_status = ksef_status; self.pdf_url = pdf_url
        self.issued_at = issued_at; self.due_at = due_at; self.paid_at = paid_at
        self.client_id = client_id
    }
}
