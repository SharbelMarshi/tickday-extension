import Foundation
import AppIntents

enum CountdownPastBehavior: String, Codable, CaseIterable, Identifiable, Sendable {
    case keep, hideFromWidget, archive
    var id: String { rawValue }
    var title: String {
        switch self {
        case .keep: "Keep and show elapsed time"
        case .hideFromWidget: "Hide from widget"
        case .archive: "Archive automatically"
        }
    }
}

enum TaskRecurrenceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case none, daily, weekdays, weekends, weekly, monthly, customInterval
    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "Does not repeat"
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekends: "Weekends"
        case .weekly: "Weekly on selected days"
        case .monthly: "Monthly"
        case .customInterval: "Custom day interval"
        }
    }
}

enum TaskPriority: Int, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case none = 0, low = 1, medium = 2, high = 3
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    var id: Int { rawValue }
    var shortTitle: String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return symbols.indices.contains(rawValue - 1) ? symbols[rawValue - 1] : String(rawValue)
    }
}

enum CountdownSort: String, CaseIterable, Identifiable, Sendable {
    case nearest, farthest, created, custom
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum TaskCompletionFilter: String, CaseIterable, Identifiable, Sendable {
    case all, incomplete, completed
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum WidgetPage: String, Codable, CaseIterable, AppEnum, Sendable {
    case countdowns, tasks
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Page")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .countdowns: "Countdowns", .tasks: "Tasks"
    ]
}
