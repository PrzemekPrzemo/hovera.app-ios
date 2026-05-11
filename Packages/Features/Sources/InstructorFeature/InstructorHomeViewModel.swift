import SwiftUI
import CorePersistence

@MainActor
@Observable
public final class InstructorHomeViewModel {
    public private(set) var todayLessons: [CalendarEntry] = []
    public private(set) var horsesById: [String: Horse] = [:]

    private let calendarRepo: CalendarEntryRepository
    private let horseRepo: HorseRepository

    public init() {
        let db = HoveraDatabase.shared
        self.calendarRepo = CalendarEntryRepository(database: db)
        self.horseRepo = HorseRepository(database: db)
    }

    public func load() async {
        let cal = Calendar(identifier: .iso8601)
        let now = Date()
        let start = cal.startOfDay(for: now)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? now
        let formatter = ISO8601DateFormatter()
        let startIso = formatter.string(from: start)
        let endIso = formatter.string(from: end)

        async let upcoming = (try? calendarRepo.loadUpcoming(nowIso: startIso)) ?? []
        async let hs = (try? horseRepo.loadAll()) ?? []

        let lessons = await upcoming
        let horses = await hs

        self.todayLessons = lessons.filter { ($0.starts_at ?? "") < endIso }
        self.horsesById = Dictionary(uniqueKeysWithValues: horses.map { ($0.id, $0) })
    }
}
