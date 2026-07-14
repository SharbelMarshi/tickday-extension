import Foundation
import SwiftData

@MainActor
enum WidgetDataLoader {
    static func load(configuration: TickdayWidgetConfigurationIntent, date: Date = .now) throws -> (countdowns: [CountdownSnapshot], tasks: [TaskSnapshot], totalTaskCount: Int) {
        let container = try SharedModelContainer.make()
        let countdownRepository = CountdownRepository(container: container)
        let taskRepository = TaskRepository(container: container)
        let pastBehavior = SharedPreferences.string(forKey: AppConstants.countdownPastBehaviorPreferenceKey)
            .flatMap(CountdownPastBehavior.init(rawValue:)) ?? .keep
        let sort: CountdownSort = configuration.countdownOrder == .custom ? .custom : .nearest
        try countdownRepository.applyPastBehavior(pastBehavior, now: date)
        var events = try countdownRepository.fetch(sort: sort)
        let formatter = DateFormattingService()
        if pastBehavior == .hideFromWidget {
            events.removeAll {
                $0.includesTime
                    ? $0.targetDate < date
                    : formatter.countdownDayCount(targetDate: $0.targetDate, now: date) < 0
            }
        }
        if configuration.countdownOrder == .nearest {
            events.sort {
                let lhsDays = formatter.countdownDayCount(targetDate: $0.targetDate, now: date)
                let rhsDays = formatter.countdownDayCount(targetDate: $1.targetDate, now: date)
                if (lhsDays >= 0) != (rhsDays >= 0) { return lhsDays >= 0 }
                if lhsDays >= 0 { return $0.targetDate < $1.targetDate }
                return $0.targetDate > $1.targetDate
            }
        }
        let primary = events
            .filter { formatter.countdownDayCount(targetDate: $0.targetDate, now: date) >= 0 }
            .min { $0.targetDate < $1.targetDate } ?? events.max { $0.targetDate < $1.targetDate }
        if let primary, let index = events.firstIndex(where: { $0.id == primary.id }), index != events.startIndex {
            events.remove(at: index)
            events.insert(primary, at: events.startIndex)
        }
        let countdowns = events.prefix(configuration.maximumItems).map {
            CountdownSnapshot(id: $0.id, title: $0.title, targetDate: $0.targetDate,
                              includesTime: $0.includesTime, symbolName: $0.symbolName)
        }
        let occurrences = try taskRepository.occurrences(on: date)
            .filter { configuration.includeCompletedTasks || !$0.isCompleted }
        let tasks = occurrences.prefix(configuration.maximumItems).map {
            TaskSnapshot(id: $0.task.id, title: $0.task.title, scheduledTime: $0.task.scheduledTime,
                         isCompleted: $0.isCompleted, priority: $0.task.priority)
        }
        return (Array(countdowns), Array(tasks), occurrences.count)
    }
}
