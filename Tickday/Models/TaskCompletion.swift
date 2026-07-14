import Foundation
import SwiftData

@Model
final class TaskCompletion {
    @Attribute(.unique) var occurrenceKey: String
    @Attribute(.unique) var id: UUID
    var taskDefinitionID: UUID
    var occurrenceDate: Date
    var isCompleted: Bool
    var completedAt: Date?
    var updatedAt: Date

    init(id: UUID = UUID(), taskDefinitionID: UUID, occurrenceDate: Date,
         isCompleted: Bool, completedAt: Date? = nil, updatedAt: Date = .now,
         calendar: Calendar = .current) {
        self.id = id
        self.taskDefinitionID = taskDefinitionID
        let day = calendar.startOfDay(for: occurrenceDate)
        self.occurrenceDate = day
        self.occurrenceKey = Self.key(taskID: taskDefinitionID, date: day, calendar: calendar)
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }

    static func key(taskID: UUID, date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.era, .year, .month, .day], from: date)
        return "\(taskID.uuidString)|\(parts.era ?? 1)-\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
