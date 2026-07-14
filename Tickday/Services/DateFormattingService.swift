import Foundation

struct DateFormattingService {
    let calendarService: CalendarService

    init(calendarService: CalendarService = CalendarService()) {
        self.calendarService = calendarService
    }

    /// Returns the calendar-day distance used by the widget's numeric countdown.
    func countdownDayCount(targetDate: Date, now: Date = .now) -> Int {
        let calendar = calendarService.calendar
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    /// Returns a localized, unit-free number for visual widget presentation.
    func widgetCountdownNumber(targetDate: Date, now: Date = .now) -> String {
        countdownDayCount(targetDate: targetDate, now: now)
            .formatted(.number.locale(calendarService.locale))
    }

    /// Preserves the semantic meaning that is intentionally omitted from the visual value.
    func widgetCountdownAccessibilityLabel(title: String, targetDate: Date, now: Date = .now) -> String {
        let days = countdownDayCount(targetDate: targetDate, now: now)
        let number = abs(days).formatted(.number.locale(calendarService.locale))
        if days == 0 { return String(localized: "0 days remaining until \(title)") }
        if days == 1 { return String(localized: "1 day remaining until \(title)") }
        if days > 1 { return String(localized: "\(number) days remaining until \(title)") }
        if days == -1 { return String(localized: "\(title) passed 1 day ago") }
        return String(localized: "\(title) passed \(number) days ago")
    }

    func countdownText(targetDate: Date, includesTime: Bool, now: Date = .now) -> String {
        let calendar = calendarService.calendar
        if !includesTime {
            let today = calendar.startOfDay(for: now)
            let target = calendar.startOfDay(for: targetDate)
            let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
            if days == 0 { return "Today" }
            if days < 0 { return "Passed \(-days) \((-days) == 1 ? "day" : "days") ago" }
            let parts = calendar.dateComponents([.month, .day], from: today, to: target)
            if let months = parts.month, months > 0 {
                let remainder = parts.day ?? 0
                return remainder == 0 ? "\(months) \(months == 1 ? "month" : "months")" :
                    "\(months) \(months == 1 ? "month" : "months"), \(remainder) \(remainder == 1 ? "day" : "days")"
            }
            return "\(days) \(days == 1 ? "day" : "days")"
        }

        let interval = targetDate.timeIntervalSince(now)
        if abs(interval) < 60 { return interval >= 0 ? "Now" : "Just passed" }
        if interval < 0 {
            let hours = Int(abs(interval) / 3_600)
            if hours < 24 { return "Passed \(hours) \(hours == 1 ? "hour" : "hours") ago" }
            let days = calendar.dateComponents([.day], from: targetDate, to: now).day ?? 0
            return "Passed \(days) \(days == 1 ? "day" : "days") ago"
        }
        if interval < 86_400 {
            let hours = max(1, Int(interval / 3_600))
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        }
        let parts = calendar.dateComponents([.month, .day], from: now, to: targetDate)
        if let months = parts.month, months > 0 {
            let days = parts.day ?? 0
            return days == 0 ? "\(months) \(months == 1 ? "month" : "months")" :
                "\(months) \(months == 1 ? "month" : "months"), \(days) \(days == 1 ? "day" : "days")"
        }
        let days = max(1, parts.day ?? 1)
        return "\(days) \(days == 1 ? "day" : "days")"
    }

    func dateText(_ date: Date, includesTime: Bool) -> String {
        date.formatted(includesTime
            ? Date.FormatStyle(date: .abbreviated, time: .shortened, locale: calendarService.locale,
                               calendar: calendarService.calendar, timeZone: calendarService.timeZone)
            : Date.FormatStyle(date: .abbreviated, time: .omitted, locale: calendarService.locale,
                               calendar: calendarService.calendar, timeZone: calendarService.timeZone))
    }
}
