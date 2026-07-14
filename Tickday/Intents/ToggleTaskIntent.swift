import AppIntents
import Foundation
import OSLog

struct ToggleTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle Tickday Task"
    static let description = IntentDescription("Completes or uncompletes one task occurrence.")
    static let openAppWhenRun = false

    @Parameter(title: "Task ID") var taskID: String
    @Parameter(title: "Occurrence Date") var occurrenceDate: Date
    @Parameter(title: "Completed") var completed: Bool

    init() {}
    init(taskID: UUID, occurrenceDate: Date, completed: Bool) {
        self.taskID = taskID.uuidString
        self.occurrenceDate = occurrenceDate
        self.completed = completed
    }

    func perform() async throws -> some IntentResult {
        let logger = Logger(subsystem: AppConstants.appBundleIdentifier, category: "TaskIntent")
        guard let id = UUID(uuidString: taskID) else {
            logger.error("Task intent received an invalid identifier")
            throw TaskRepositoryError.occurrenceNotFound
        }
        do {
            let container = try SharedModelContainer.make()
            try await MainActor.run {
                let repository = TaskRepository(container: container)
                try repository.toggle(taskID: id, on: occurrenceDate, explicitState: completed)
            }
            return .result()
        } catch {
            logger.error("Task intent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
