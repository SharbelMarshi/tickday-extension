import Foundation

struct TaskOccurrence: Identifiable {
    let task: TaskDefinition
    let date: Date
    let completion: TaskCompletion?
    var id: String { TaskCompletion.key(taskID: task.id, date: date) }
    var isCompleted: Bool { completion?.isCompleted == true }
}
