import Foundation

struct CalendarService {
    var calendar: Calendar
    var locale: Locale
    var timeZone: TimeZone

    init(calendar: Calendar = .autoupdatingCurrent,
         locale: Locale = .autoupdatingCurrent,
         timeZone: TimeZone = .autoupdatingCurrent) {
        var configured = calendar
        configured.locale = locale
        configured.timeZone = timeZone
        self.calendar = configured
        self.locale = locale
        self.timeZone = timeZone
    }

    func startOfDay(for date: Date) -> Date { calendar.startOfDay(for: date) }
    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool { calendar.isDate(lhs, inSameDayAs: rhs) }

    func nextDayBoundary(after date: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date.addingTimeInterval(3_600)
    }

    func merging(day: Date, time: Date?) -> Date {
        guard let time else { return startOfDay(for: day) }
        let components = calendar.dateComponents([.hour, .minute, .second], from: time)
        return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0,
                             second: components.second ?? 0, of: day) ?? day
    }
}
