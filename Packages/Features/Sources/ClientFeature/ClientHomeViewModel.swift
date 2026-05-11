import SwiftUI
import CorePersistence

@MainActor
@Observable
public final class ClientHomeViewModel {
    public private(set) var horses: [Horse] = []
    public private(set) var nextLesson: CalendarEntry?
    public private(set) var invoices: [Invoice] = []
    public private(set) var isLoading = false

    private let horseRepo: HorseRepository
    private let calendarRepo: CalendarEntryRepository
    private let invoiceRepo: InvoiceRepository

    public init() {
        let db = HoveraDatabase.shared
        self.horseRepo = HorseRepository(database: db)
        self.calendarRepo = CalendarEntryRepository(database: db)
        self.invoiceRepo = InvoiceRepository(database: db)
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        let nowIso = ISO8601DateFormatter().string(from: Date())
        async let h: [Horse] = (try? horseRepo.loadAll()) ?? []
        async let n: [CalendarEntry] = (try? calendarRepo.loadUpcoming(nowIso: nowIso)) ?? []
        async let i: [Invoice] = (try? invoiceRepo.loadAll()) ?? []

        let horsesResult = await h
        let upcomingResult = await n
        let invoicesResult = await i

        self.horses = horsesResult
        self.nextLesson = upcomingResult.first
        self.invoices = invoicesResult
    }
}
