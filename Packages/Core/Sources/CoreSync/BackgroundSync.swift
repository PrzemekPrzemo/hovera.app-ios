import Foundation
import BackgroundTasks

/// Registers the periodic BGTaskScheduler refresh. Apple expects one
/// `BGTaskSchedulerPermittedIdentifiers` entry in Info.plist matching
/// the identifier used here.
public enum BackgroundSync {
    public static func registerTask(
        identifier: String,
        run: @escaping @Sendable () async -> Void
    ) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            schedule(identifier: identifier)
            let task = task as! BGAppRefreshTask
            let work = Task { await run() }
            task.expirationHandler = { work.cancel() }
            Task {
                _ = await work.value
                task.setTaskCompleted(success: true)
            }
        }
        schedule(identifier: identifier)
    }

    public static func schedule(identifier: String, after seconds: TimeInterval = 15 * 60) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        try? BGTaskScheduler.shared.submit(request)
    }
}
