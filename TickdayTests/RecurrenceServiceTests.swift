import XCTest
@testable import Tickday

final class RecurrenceServiceTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = .gmt
        return value
    }
    private func date(_ day: Int) -> Date { date(2026, 7, day) }
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testDailyRecurrence() {
        let task = TaskDefinition(title: "Daily", startDate: date(10), recurrenceType: .daily)
        XCTAssertTrue(RecurrenceService(calendar: calendar).occurs(task, on: date(14)))
        XCTAssertFalse(RecurrenceService(calendar: calendar).occurs(task, on: date(9)))
    }

    func testWeekdayAndWeekendRecurrence() {
        let weekday = TaskDefinition(title: "Work", startDate: date(1), recurrenceType: .weekdays)
        let weekend = TaskDefinition(title: "Rest", startDate: date(1), recurrenceType: .weekends)
        XCTAssertTrue(RecurrenceService(calendar: calendar).occurs(weekday, on: date(14)))
        XCTAssertTrue(RecurrenceService(calendar: calendar).occurs(weekend, on: date(12)))
    }

    func testSelectedWeeklyRecurrence() {
        let task = TaskDefinition(title: "Tuesday", startDate: date(1), recurrenceType: .weekly, selectedWeekdays: [.tuesday])
        XCTAssertTrue(RecurrenceService(calendar: calendar).occurs(task, on: date(14)))
        XCTAssertFalse(RecurrenceService(calendar: calendar).occurs(task, on: date(15)))
    }

    func testMonthlyClampsToLastDay() {
        let task = TaskDefinition(title: "Month end", startDate: date(2026, 1, 31), recurrenceType: .monthly)
        XCTAssertTrue(RecurrenceService(calendar: calendar).occurs(task, on: date(2026, 2, 28)))
    }

    func testCustomInterval() {
        let task = TaskDefinition(title: "Alternate", startDate: date(10), recurrenceType: .customInterval, recurrenceInterval: 2)
        XCTAssertTrue(RecurrenceService(calendar: calendar).occurs(task, on: date(14)))
        XCTAssertFalse(RecurrenceService(calendar: calendar).occurs(task, on: date(13)))
    }
}
