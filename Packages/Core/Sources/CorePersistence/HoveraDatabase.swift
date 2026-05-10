import Foundation
import GRDB

/// SQLite database. One file per app install; all syncable entities live
/// in the same DB so the change feed can be applied in a single tx.
public final class HoveraDatabase: @unchecked Sendable {
    public static let shared: HoveraDatabase = {
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("hovera.sqlite")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        return try! HoveraDatabase(path: url.path)
    }()

    public let queue: DatabaseQueue

    public init(path: String) throws {
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        self.queue = try DatabaseQueue(path: path, configuration: config)
        try Migrations.register(in: self.queue)
    }
}
