import Foundation
import SwiftData

@MainActor
final class CountdownRepository {
    private let context: ModelContext
    private let refreshService: WidgetRefreshService

    init(container: ModelContainer, refreshService: WidgetRefreshService = WidgetRefreshService()) {
        context = ModelContext(container)
        self.refreshService = refreshService
    }

    func fetch(search: String = "", sort: CountdownSort = .custom, includeArchived: Bool = false) throws -> [CountdownEvent] {
        let descriptor = FetchDescriptor<CountdownEvent>()
        var events = try context.fetch(descriptor).filter { includeArchived || !$0.isArchived }
        if !search.isEmpty { events = events.filter { $0.title.localizedCaseInsensitiveContains(search) } }
        switch sort {
        case .nearest: events.sort { $0.targetDate < $1.targetDate }
        case .farthest: events.sort { $0.targetDate > $1.targetDate }
        case .created: events.sort { $0.createdAt < $1.createdAt }
        case .custom: events.sort { $0.sortOrder == $1.sortOrder ? $0.createdAt < $1.createdAt : $0.sortOrder < $1.sortOrder }
        }
        return events
    }

    @discardableResult
    func add(title: String, targetDate: Date, includesTime: Bool, symbolName: String?, colorIdentifier: String?) throws -> CountdownEvent {
        let order = (try fetch(includeArchived: true).map(\.sortOrder).max() ?? -1) + 1
        let event = CountdownEvent(title: title, targetDate: targetDate, includesTime: includesTime,
                                   symbolName: symbolName, colorIdentifier: colorIdentifier, sortOrder: order)
        context.insert(event)
        try save()
        return event
    }

    func update(_ event: CountdownEvent, title: String, targetDate: Date, includesTime: Bool,
                symbolName: String?, colorIdentifier: String?) throws {
        event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.targetDate = targetDate
        event.includesTime = includesTime
        event.symbolName = symbolName
        event.colorIdentifier = colorIdentifier
        event.updatedAt = .now
        try save()
    }

    func duplicate(_ event: CountdownEvent) throws {
        _ = try add(title: "\(event.title) Copy", targetDate: event.targetDate, includesTime: event.includesTime,
                    symbolName: event.symbolName, colorIdentifier: event.colorIdentifier)
    }

    func delete(_ event: CountdownEvent) throws { context.delete(event); try save() }

    func applyPastBehavior(_ behavior: CountdownPastBehavior, now: Date = .now,
                           calendar: Calendar = .autoupdatingCurrent) throws {
        guard behavior == .archive else { return }
        var changed = false
        for event in try fetch(includeArchived: false) {
            let hasPassed = event.includesTime
                ? event.targetDate < now
                : calendar.startOfDay(for: event.targetDate) < calendar.startOfDay(for: now)
            if hasPassed { event.isArchived = true; event.updatedAt = now; changed = true }
        }
        if changed { try save() }
    }

    func move(_ events: [CountdownEvent], from offsets: IndexSet, to destination: Int) throws {
        var reordered = events
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, event) in reordered.enumerated() { event.sortOrder = index; event.updatedAt = .now }
        try save()
    }

    private func save() throws { try context.save(); refreshService.reload() }
}
