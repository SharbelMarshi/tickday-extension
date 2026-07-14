import Foundation
import SwiftData

@Model
final class TaskDefinition {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var startDate: Date
    var scheduledTime: Date?
    private var recurrenceRawValue: String
    var selectedWeekdayRawValues: [Int]
    var recurrenceInterval: Int?
    private var priorityRawValue: Int
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    var isArchived: Bool

    var recurrenceType: TaskRecurrenceType {
        get { TaskRecurrenceType(rawValue: recurrenceRawValue) ?? .none }
        set { recurrenceRawValue = newValue.rawValue }
    }
    var selectedWeekdays: Set<Weekday> {
        get { Set(selectedWeekdayRawValues.compactMap(Weekday.init(rawValue:))) }
        set { selectedWeekdayRawValues = newValue.map(\.rawValue).sorted() }
    }
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .none }
        set { priorityRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(), title: String, notes: String? = nil, startDate: Date,
         scheduledTime: Date? = nil, recurrenceType: TaskRecurrenceType = .none,
         selectedWeekdays: Set<Weekday> = [], recurrenceInterval: Int? = nil,
         priority: TaskPriority = .none, createdAt: Date = .now, updatedAt: Date = .now,
         sortOrder: Int = 0, isArchived: Bool = false) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes
        self.startDate = startDate
        self.scheduledTime = scheduledTime
        self.recurrenceRawValue = recurrenceType.rawValue
        self.selectedWeekdayRawValues = selectedWeekdays.map(\.rawValue).sorted()
        self.recurrenceInterval = recurrenceInterval
        self.priorityRawValue = priority.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
        self.isArchived = isArchived
    }
}
