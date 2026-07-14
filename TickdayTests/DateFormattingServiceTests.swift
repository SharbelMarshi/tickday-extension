import XCTest
@testable import Tickday

final class DateFormattingServiceTests: XCTestCase {
    private func calendar(timeZone: String = "UTC") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZone) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    func testDateOnlyUsesCalendarDaysNotSeconds() throws {
        let cal = calendar(timeZone: "America/Los_Angeles")
        let service = DateFormattingService(calendarService: CalendarService(calendar: cal, locale: cal.locale!, timeZone: cal.timeZone))
        let now = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 23, minute: 30)))
        let target = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 0, minute: 1)))
        XCTAssertEqual(service.countdownText(targetDate: target, includesTime: false, now: now), "1 day")
    }

    func testTodayAndPastDate() throws {
        let cal = calendar()
        let service = DateFormattingService(calendarService: CalendarService(calendar: cal, locale: .init(identifier: "en_US"), timeZone: cal.timeZone))
        let now = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 12)))
        XCTAssertEqual(service.countdownText(targetDate: now, includesTime: false, now: now), "Today")
        let past = try XCTUnwrap(cal.date(byAdding: .day, value: -2, to: now))
        XCTAssertEqual(service.countdownText(targetDate: past, includesTime: false, now: now), "Passed 2 days ago")
    }

    func testDSTBoundaryCountsOneCalendarDay() throws {
        let cal = calendar(timeZone: "America/New_York")
        let service = DateFormattingService(calendarService: CalendarService(calendar: cal, locale: .init(identifier: "en_US"), timeZone: cal.timeZone))
        let before = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 12)))
        let after = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12)))
        XCTAssertEqual(service.countdownText(targetDate: after, includesTime: false, now: before), "1 day")
    }

    func testWidgetCountdownUsesNumericCalendarDaysWithoutUnits() throws {
        let cal = calendar()
        let service = DateFormattingService(calendarService: CalendarService(
            calendar: cal, locale: .init(identifier: "en_US_POSIX"), timeZone: cal.timeZone
        ))
        let now = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 23)))
        let future = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 7, day: 16, hour: 1)))
        let past = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 7, day: 12, hour: 23)))

        XCTAssertEqual(service.widgetCountdownNumber(targetDate: future, now: now), "2")
        XCTAssertEqual(service.widgetCountdownNumber(targetDate: now, now: now), "0")
        XCTAssertEqual(service.widgetCountdownNumber(targetDate: past, now: now), "-2")
    }

    func testWidgetAccessibilityRetainsCountdownMeaning() throws {
        let cal = calendar()
        let service = DateFormattingService(calendarService: CalendarService(
            calendar: cal, locale: .init(identifier: "en_US_POSIX"), timeZone: cal.timeZone
        ))
        let now = try XCTUnwrap(cal.date(from: DateComponents(year: 2026, month: 7, day: 14)))
        let target = try XCTUnwrap(cal.date(byAdding: .day, value: 2, to: now))

        XCTAssertEqual(
            service.widgetCountdownAccessibilityLabel(title: "Holiday", targetDate: target, now: now),
            "2 days remaining until Holiday"
        )
    }

    func testTimeZoneChangesCalendarMeaning() throws {
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-01-01T01:00:00Z"))
        let losAngeles = calendar(timeZone: "America/Los_Angeles")
        let target = try XCTUnwrap(losAngeles.date(byAdding: .day, value: 1, to: instant))
        XCTAssertEqual(losAngeles.dateComponents([.day], from: losAngeles.startOfDay(for: instant), to: losAngeles.startOfDay(for: target)).day, 1)
    }
}
