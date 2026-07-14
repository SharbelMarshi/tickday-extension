import Foundation
import SwiftData

@MainActor
final class TaskRepository {
    private let context: ModelContext
    private let recurrenceService: RecurrenceService
    private let calendar: Calendar
    private let refreshService: WidgetRefreshService

    init(container: ModelContainer, calendar: Calendar = .autoupdatingCurrent,
         refreshService: WidgetRefreshService = WidgetRefreshService()) {
        context = ModelContext(container)
        self.calendar = calendar
        recurrenceService = RecurrenceService(calendar: calendar)
        self.refreshService = refreshService
    }

    func fetchDefinitions(search: String = "") throws -> [TaskDefinition] {
        var tasks = try context.fetch(FetchDescriptor<TaskDefinition>()).filter { !$0.isArchived }
        if !search.isEmpty { tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(search) } }
        return tasks.sorted { $0.sortOrder == $1.sortOrder ? $0.createdAt < $1.createdAt : $0.sortOrder < $1.sortOrder }
    }

    func occurrences(on date: Date, search: String = "", filter: TaskCompletionFilter = .all) throws -> [TaskOccurrence] {
        let day = calendar.startOfDay(for: date)
        let definitions = try fetchDefinitions(search: search).filter { recurrenceService.occurs($0, on: day) }
        let completions = try context.fetch(FetchDescriptor<TaskCompletion>())
        let byKey = Dictionary(uniqueKeysWithValues: completions.map { ($0.occurrenceKey, $0) })
        return definitions.compactMap { task in
            let occurrence = TaskOccurrence(task: task, date: day,
                completion: byKey[TaskCompletion.key(taskID: task.id, date: day, calendar: calendar)])
            switch filter {
            case .all: return occurrence
            case .incomplete: return occurrence.isCompleted ? nil : occurrence
            case .completed: return occurrence.isCompleted ? occurrence : nil
            }
        }.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.task.priority != $1.task.priority { return $0.task.priority > $1.task.priority }
            let lhs = $0.task.scheduledTime ?? .distantFuture
            let rhs = $1.task.scheduledTime ?? .distantFuture
            return lhs == rhs ? $0.task.sortOrder < $1.task.sortOrder : lhs < rhs
        }
    }

    @discardableResult
    func add(title: String, notes: String?, startDate: Date, scheduledTime: Date?,
             recurrenceType: TaskRecurrenceType, selectedWeekdays: Set<Weekday>,
             recurrenceInterval: Int?, priority: TaskPriority) throws -> TaskDefinition {
        let order = (try fetchDefinitions().map(\.sortOrder).max() ?? -1) + 1
        let task = TaskDefinition(title: title, notes: notes, startDate: startDate,
                                  scheduledTime: scheduledTime, recurrenceType: recurrenceType,
                                  selectedWeekdays: selectedWeekdays, recurrenceInterval: recurrenceInterval,
                                  priority: priority, sortOrder: order)
        context.insert(task)
        try save()
        return task
    }

    func update(_ task: TaskDefinition, title: String, notes: String?, startDate: Date,
                scheduledTime: Date?, recurrenceType: TaskRecurrenceType,
                selectedWeekdays: Set<Weekday>, recurrenceInterval: Int?, priority: TaskPriority) throws {
        task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        task.startDate = startDate
        task.scheduledTime = scheduledTime
        task.recurrenceType = recurrenceType
        task.selectedWeekdays = selectedWeekdays
        task.recurrenceInterval = recurrenceInterval
        task.priority = priority
        task.updatedAt = .now
        try save()
    }

    func delete(_ task: TaskDefinition) throws {
        let taskID = task.id
        for completion in try context.fetch(FetchDescriptor<TaskCompletion>()).filter({ $0.taskDefinitionID == taskID }) {
            context.delete(completion)
        }
        context.delete(task)
        try save()
    }

    func toggle(taskID: UUID, on date: Date, explicitState: Bool? = nil) throws {
        guard let task = try context.fetch(FetchDescriptor<TaskDefinition>()).first(where: { $0.id == taskID }),
              recurrenceService.occurs(task, on: date) else { throw TaskRepositoryError.occurrenceNotFound }
        let day = calendar.startOfDay(for: date)
        let key = TaskCompletion.key(taskID: taskID, date: day, calendar: calendar)
        let existing = try context.fetch(FetchDescriptor<TaskCompletion>()).first { $0.occurrenceKey == key }
        let newState = explicitState ?? !(existing?.isCompleted ?? false)
        if let existing {
            existing.isCompleted = newState
            existing.completedAt = newState ? .now : nil
            existing.updatedAt = .now
        } else {
            context.insert(TaskCompletion(taskDefinitionID: taskID, occurrenceDate: day,
                                          isCompleted: newState, completedAt: newState ? .now : nil,
                                          calendar: calendar))
        }
        try save()
    }

    func move(_ tasks: [TaskDefinition], from offsets: IndexSet, to destination: Int) throws {
        var reordered = tasks
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, task) in reordered.enumerated() { task.sortOrder = index; task.updatedAt = .now }
        try save()
    }

    private func save() throws { try context.save(); refreshService.reload() }
}

enum TaskRepositoryError: LocalizedError {
    case occurrenceNotFound
    var errorDescription: String? { "This task occurrence no longer exists." }
}
