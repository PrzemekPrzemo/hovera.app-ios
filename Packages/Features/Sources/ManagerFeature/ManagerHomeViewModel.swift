import SwiftUI
import CorePersistence

@MainActor
@Observable
public final class ManagerHomeViewModel {
    public private(set) var upcomingLessons: [CalendarEntry] = []
    public private(set) var totalHorses: Int = 0
    public private(set) var totalClients: Int = 0
    public private(set) var boxes: [StableBox] = []
    public private(set) var activeAssignments: [BoxAssignment] = []
    public private(set) var recentInvoices: [Invoice] = []
    public private(set) var unpaidCount: Int = 0

    private let calendarRepo: CalendarEntryRepository
    private let horseRepo: HorseRepository
    private let clientRepo: ClientRepository
    private let boxRepo: BoxRepository
    private let assignRepo: BoxAssignmentRepository
    private let invoiceRepo: InvoiceRepository

    public init() {
        let db = HoveraDatabase.shared
        self.calendarRepo = CalendarEntryRepository(database: db)
        self.horseRepo = HorseRepository(database: db)
        self.clientRepo = ClientRepository(database: db)
        self.boxRepo = BoxRepository(database: db)
        self.assignRepo = BoxAssignmentRepository(database: db)
        self.invoiceRepo = InvoiceRepository(database: db)
    }

    public func load() async {
        let nowIso = ISO8601DateFormatter().string(from: Date())

        async let upcoming = (try? calendarRepo.loadUpcoming(nowIso: nowIso)) ?? []
        async let horses = (try? horseRepo.loadAll()) ?? []
        async let clients = (try? clientRepo.loadAll()) ?? []
        async let boxes = (try? boxRepo.loadAll()) ?? []
        async let assignments = (try? assignRepo.loadActive(nowIso: nowIso)) ?? []
        async let invoices = (try? invoiceRepo.loadAll()) ?? []

        let up = await upcoming
        let hs = await horses
        let cs = await clients
        let bs = await boxes
        let asn = await assignments
        let inv = await invoices

        self.upcomingLessons = Array(up.prefix(5))
        self.totalHorses = hs.count
        self.totalClients = cs.count
        self.boxes = bs
        self.activeAssignments = asn
        self.recentInvoices = Array(inv.prefix(5))
        self.unpaidCount = inv.filter { $0.paid_at == nil }.count
    }
}
