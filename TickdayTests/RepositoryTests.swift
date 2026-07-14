import XCTest
import SwiftData
@testable import Tickday

@MainActor
final class RepositoryTests: XCTestCase {
    func testCompletingOneOccurrenceDoesNotCompleteFutureOccurrenceAndNoDuplicates() throws {
        let container = try SharedModelContainer.make(inMemory: true)
        let repository = TaskRepository(container: container, calendar: fixedCalendar)
        let start = date(14)
        let task = try repository.add(title: "Daily", notes: nil, startDate: start, scheduledTime: nil,
                                      recurrenceType: .daily, selectedWeekdays: [], recurrenceInterval: nil, priority: .none)
        try repository.toggle(taskID: task.id, on: start)
        try repository.toggle(taskID: task.id, on: start, explicitState: true)
        XCTAssertTrue(try XCTUnwrap(repository.occurrences(on: start).first).isCompleted)
        XCTAssertFalse(try XCTUnwrap(repository.occurrences(on: date(15)).first).isCompleted)
        let context = ModelContext(container)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskCompletion>()).count, 1)
        try repository.toggle(taskID: task.id, on: start, explicitState: false)
        XCTAssertFalse(try XCTUnwrap(repository.occurrences(on: start).first).isCompleted)
    }

    func testCountdownSorting() throws {
        let container = try SharedModelContainer.make(inMemory: true)
        let repository = CountdownRepository(container: container)
        try repository.add(title: "Later", targetDate: date(20), includesTime: false, symbolName: nil, colorIdentifier: nil)
        try repository.add(title: "Sooner", targetDate: date(15), includesTime: false, symbolName: nil, colorIdentifier: nil)
        XCTAssertEqual(try repository.fetch(sort: .nearest).map(\.title), ["Sooner", "Later"])
        XCTAssertEqual(try repository.fetch(sort: .farthest).map(\.title), ["Later", "Sooner"])
    }

    func testFilteringTasksByDateAndCompletion() throws {
        let container = try SharedModelContainer.make(inMemory: true)
        let repository = TaskRepository(container: container, calendar: fixedCalendar)
        let task = try repository.add(title: "One time", notes: nil, startDate: date(14), scheduledTime: nil,
                                      recurrenceType: .none, selectedWeekdays: [], recurrenceInterval: nil, priority: .high)
        XCTAssertEqual(try repository.occurrences(on: date(14)).count, 1)
        XCTAssertEqual(try repository.occurrences(on: date(15)).count, 0)
        try repository.toggle(taskID: task.id, on: date(14))
        XCTAssertEqual(try repository.occurrences(on: date(14), filter: .completed).count, 1)
        XCTAssertEqual(try repository.occurrences(on: date(14), filter: .incomplete).count, 0)
    }

    func testTaskEmptyStateDistinguishesNoTasksFiltersAndHiddenCompletions() {
        XCTAssertEqual(
            TaskEmptyStateKind.resolve(totalCount: 0, completedCount: 0, hideCompleted: false),
            .noTasks
        )
        XCTAssertEqual(
            TaskEmptyStateKind.resolve(totalCount: 3, completedCount: 1, hideCompleted: false),
            .noMatches
        )
        XCTAssertEqual(
            TaskEmptyStateKind.resolve(totalCount: 3, completedCount: 3, hideCompleted: true),
            .allTasksCompletedHidden
        )
    }

    private var fixedCalendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = .gmt; return c }
    private func date(_ day: Int) -> Date { fixedCalendar.date(from: DateComponents(year: 2026, month: 7, day: day))! }
}
