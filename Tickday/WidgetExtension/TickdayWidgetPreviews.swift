import SwiftUI
import WidgetKit

private let previewConfiguration = TickdayWidgetConfigurationIntent()
private let previewNow = Date.now

private func previewDate(daysFromNow: Int) -> Date {
    let calendar = Calendar.autoupdatingCurrent
    return calendar.date(byAdding: .day, value: daysFromNow, to: calendar.startOfDay(for: previewNow))
        ?? previewNow
}

private let previewCountdowns = [
    CountdownSnapshot(id: UUID(), title: "החופשה המשפחתית", targetDate: previewDate(daysFromNow: 2),
                      includesTime: false, symbolName: "airplane"),
    CountdownSnapshot(id: UUID(), title: "Design conference", targetDate: previewDate(daysFromNow: 8),
                      includesTime: false, symbolName: "briefcase"),
    CountdownSnapshot(id: UUID(), title: "Project release", targetDate: previewDate(daysFromNow: 21),
                      includesTime: false, symbolName: "shippingbox")
]

private let previewTasks = [
    TaskSnapshot(id: UUID(), title: "Plan the week", scheduledTime: nil, isCompleted: false, priority: .high),
    TaskSnapshot(id: UUID(), title: "Water plants", scheduledTime: nil, isCompleted: true, priority: .none),
    TaskSnapshot(id: UUID(), title: "Review notes", scheduledTime: nil, isCompleted: false, priority: .medium)
]

private func previewEntry(page: WidgetPage, countdowns: [CountdownSnapshot] = [],
                          tasks: [TaskSnapshot] = [],
                          forcesRightToLeft: Bool = false,
                          firstPage: WidgetPage = .countdowns) -> TickdayWidgetEntry {
    TickdayWidgetEntry(date: previewNow, configuration: previewConfiguration, page: page,
                       countdowns: countdowns, tasks: tasks,
                       totalTaskCount: tasks.count, errorDescription: nil,
                       forcesRightToLeft: forcesRightToLeft, firstPage: firstPage)
}

#Preview("Empty Countdowns • Small", as: .systemSmall) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .countdowns)
}

#Preview("One Countdown • Small", as: .systemSmall) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .countdowns, countdowns: Array(previewCountdowns.prefix(1)))
}

#Preview("Nearest Countdown Emphasized • Medium", as: .systemMedium) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .countdowns, countdowns: previewCountdowns)
}

#Preview("No Tasks • Medium", as: .systemMedium) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .tasks)
}

#Preview("Interactive Tasks • Large", as: .systemLarge) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .tasks, tasks: previewTasks)
}

#Preview("Tasks First Page • Medium", as: .systemMedium) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .tasks, tasks: previewTasks, firstPage: .tasks)
}

#Preview("Forced RTL Setting • Medium", as: .systemMedium) {
    TickdayWidget()
} timeline: {
    previewEntry(page: .countdowns, countdowns: previewCountdowns, forcesRightToLeft: true)
}

#Preview("RTL Countdown • Dark") {
    TickdayWidgetEntryView(
        entry: previewEntry(page: .countdowns, countdowns: previewCountdowns),
        previewFamily: .systemMedium
    )
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .frame(width: 360, height: 170)
}

#Preview("Tasks • Light") {
    TickdayWidgetEntryView(
        entry: previewEntry(page: .tasks, tasks: previewTasks),
        previewFamily: .systemLarge
    )
        .preferredColorScheme(.light)
        .frame(width: 360, height: 360)
}
