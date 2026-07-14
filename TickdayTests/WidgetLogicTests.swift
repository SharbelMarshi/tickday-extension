import XCTest
@testable import Tickday

final class WidgetLogicTests: XCTestCase {
    func testPageStateRawValueRoundTrip() {
        XCTAssertEqual(WidgetPage(rawValue: WidgetPage.tasks.rawValue), .tasks)
        XCTAssertEqual(WidgetPage(rawValue: WidgetPage.countdowns.rawValue), .countdowns)
    }

    func testOccurrenceKeyIsStableWithinCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jerusalem")!
        let id = UUID()
        let morning = calendar.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 1))!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 23))!
        XCTAssertEqual(TaskCompletion.key(taskID: id, date: morning, calendar: calendar),
                       TaskCompletion.key(taskID: id, date: evening, calendar: calendar))
    }
}
