import Foundation

struct RecurrenceService {
    var calendar: Calendar
    init(calendar: Calendar = .autoupdatingCurrent) { self.calendar = calendar }

    func occurs(_ task: TaskDefinition, on date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        let start = calendar.startOfDay(for: task.startDate)
        guard day >= start, !task.isArchived else { return false }
        switch task.recurrenceType {
        case .none:
            return calendar.isDate(day, inSameDayAs: start)
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(calendar.component(.weekday, from: day))
        case .weekends:
            return [1, 7].contains(calendar.component(.weekday, from: day))
        case .weekly:
            return task.selectedWeekdays.contains(Weekday(rawValue: calendar.component(.weekday, from: day)) ?? .sunday)
        case .monthly:
            let startDay = calendar.component(.day, from: start)
            let range = calendar.range(of: .day, in: .month, for: day)
            return calendar.component(.day, from: day) == min(startDay, range?.count ?? startDay)
        case .customInterval:
            let days = calendar.dateComponents([.day], from: start, to: day).day ?? -1
            return days >= 0 && days % max(1, task.recurrenceInterval ?? 1) == 0
        }
    }
}
