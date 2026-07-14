import Foundation

struct CountdownSnapshot: Identifiable, Sendable {
    let id: UUID
    let title: String
    let targetDate: Date
    let includesTime: Bool
    let symbolName: String?
}

struct TaskSnapshot: Identifiable, Sendable {
    let id: UUID
    let title: String
    let scheduledTime: Date?
    let isCompleted: Bool
    let priority: TaskPriority
}
