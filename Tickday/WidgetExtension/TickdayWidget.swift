import SwiftUI
import WidgetKit

struct TickdayWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: TickdayWidgetConfigurationIntent
    let page: WidgetPage
    let countdowns: [CountdownSnapshot]
    let tasks: [TaskSnapshot]
    let totalTaskCount: Int
    let errorDescription: String?
    var forcesRightToLeft = false
    var firstPage: WidgetPage = .countdowns
}

struct TickdayWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TickdayWidgetEntry {
        TickdayWidgetEntry(date: .now, configuration: .init(), page: .countdowns,
            countdowns: [CountdownSnapshot(id: UUID(), title: "Summer holiday", targetDate: .now.addingTimeInterval(864_000), includesTime: false, symbolName: "airplane")],
            tasks: [], totalTaskCount: 0, errorDescription: nil)
    }

    func snapshot(for configuration: TickdayWidgetConfigurationIntent, in context: Context) async -> TickdayWidgetEntry {
        await entry(configuration: configuration)
    }

    func timeline(for configuration: TickdayWidgetConfigurationIntent, in context: Context) async -> Timeline<TickdayWidgetEntry> {
        let entry = await entry(configuration: configuration)
        let calendar = Calendar.autoupdatingCurrent
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now.addingTimeInterval(3_600)
        let nextTimedEvent = entry.countdowns.filter(\.includesTime).map(\.targetDate).filter { $0 > .now }.min()
        let refresh = min(midnight, nextTimedEvent ?? midnight)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func entry(configuration: TickdayWidgetConfigurationIntent) async -> TickdayWidgetEntry {
        let rightToLeft = SharedPreferences.string(forKey: AppConstants.widgetRightToLeftPreferenceKey) == "true"
        let firstPageSetting = SharedPreferences.string(forKey: AppConstants.widgetFirstPagePreferenceKey)
            .flatMap(WidgetPage.init(rawValue:))
        let firstPage = firstPageSetting ?? .countdowns
        let fallbackPage = firstPageSetting ?? configuration.defaultPage
        do {
            let data = try await WidgetDataLoader.load(configuration: configuration)
            let stored = SharedPreferences.string(forKey: AppConstants.widgetPagePreferenceKey)
            let page = stored.flatMap(WidgetPage.init(rawValue:)) ?? fallbackPage
            return TickdayWidgetEntry(date: .now, configuration: configuration, page: page,
                                      countdowns: data.countdowns, tasks: data.tasks,
                                      totalTaskCount: data.totalTaskCount, errorDescription: nil,
                                      forcesRightToLeft: rightToLeft, firstPage: firstPage)
        } catch {
            return TickdayWidgetEntry(date: .now, configuration: configuration, page: fallbackPage,
                                      countdowns: [], tasks: [], totalTaskCount: 0,
                                      errorDescription: error.localizedDescription,
                                      forcesRightToLeft: rightToLeft, firstPage: firstPage)
        }
    }
}

struct TickdayWidgetEntryView: View {
    @Environment(\.widgetFamily) private var environmentFamily
    @ScaledMetric(relativeTo: .largeTitle) private var primaryNumberSize = 42
    let entry: TickdayWidgetEntry
    private let previewFamily: WidgetFamily?
    private let formatter = DateFormattingService()

    init(entry: TickdayWidgetEntry, previewFamily: WidgetFamily? = nil) {
        self.entry = entry
        self.previewFamily = previewFamily
    }

    var body: some View {
        ZStack {
            if let error = entry.errorDescription {
                ContentUnavailableView("Data unavailable", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                pageContent
                    .padding(.horizontal, contentHorizontalPadding)
                    .padding(.vertical, 2)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(deepLink(entry.page == .tasks ? "tickday://tasks" : "tickday://countdowns"))
        .transformEnvironment(\.layoutDirection) { direction in
            if entry.forcesRightToLeft { direction = .rightToLeft }
        }
    }

    @ViewBuilder private var pageContent: some View {
        switch entry.page {
        case .countdowns: countdownPage
        case .tasks: taskPage
        }
    }

    private var countdownPage: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 8) {
            if let primaryCountdown {
                primaryCountdownView(primaryCountdown)
                ForEach(secondaryCountdowns) { item in
                    secondaryCountdownView(item)
                }
                Spacer(minLength: 0)
            } else {
                Link(destination: deepLink("tickday://new-countdown")) {
                    VStack(spacing: 6) { Image(systemName: "plus.circle"); Text("No countdowns yet") }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            pageNavigation
        }
    }

    private var taskPage: some View {
        VStack(alignment: .leading, spacing: 7) {
            if entry.tasks.isEmpty {
                Link(destination: deepLink("tickday://new-task")) {
                    VStack(spacing: 6) { Image(systemName: "checkmark.circle"); Text("No tasks today") }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ForEach(entry.tasks.prefix(limit)) { task in
                    Toggle(isOn: task.isCompleted,
                           intent: ToggleTaskIntent(taskID: task.id, occurrenceDate: entry.date, completed: !task.isCompleted)) {
                        HStack {
                            Text(task.title).lineLimit(1).strikethrough(task.isCompleted)
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            Spacer(minLength: 2)
                            if let time = task.scheduledTime { Text(time, style: .time).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }.toggleStyle(WidgetCheckboxStyle())
                }
                if entry.totalTaskCount > limit {
                    Link("\(entry.totalTaskCount - limit) more", destination: deepLink("tickday://tasks"))
                        .font(.caption).frame(maxWidth: .infinity, alignment: .trailing)
                }
                Spacer(minLength: 0)
            }
            pageNavigation
        }
    }

    @ViewBuilder
    private func primaryCountdownView(_ item: CountdownSnapshot) -> some View {
        Link(destination: countdownURL(item)) {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 4) {
                    countdownTitle(item, primary: true)
                    countdownNumber(item, primary: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    countdownTitle(item, primary: true)
                    Spacer(minLength: 6)
                    countdownNumber(item, primary: true)
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(formatter.widgetCountdownAccessibilityLabel(
            title: item.title, targetDate: item.targetDate, now: entry.date
        )))
        .accessibilityHint("Open countdown")
    }

    private func secondaryCountdownView(_ item: CountdownSnapshot) -> some View {
        Link(destination: countdownURL(item)) {
            HStack(spacing: 7) {
                Image(systemName: item.symbolName ?? "calendar")
                    .frame(width: 16)
                    .foregroundStyle(.secondary)
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                countdownNumber(item, primary: false)
                    .layoutPriority(1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(formatter.widgetCountdownAccessibilityLabel(
            title: item.title, targetDate: item.targetDate, now: entry.date
        )))
        .accessibilityHint("Open countdown")
    }

    private func countdownTitle(_ item: CountdownSnapshot, primary: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: item.symbolName ?? "calendar")
                .foregroundStyle(.secondary)
            Text(item.title)
                .font(primary ? (family == .systemSmall ? .headline : .title3) : .subheadline)
                .fontWeight(primary ? .semibold : .regular)
                .lineLimit(family == .systemLarge ? 2 : 1)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
        }
    }

    private func countdownNumber(_ item: CountdownSnapshot, primary: Bool) -> some View {
        Text(formatter.widgetCountdownNumber(targetDate: item.targetDate, now: entry.date))
            .font(primary
                ? .system(size: primaryNumberPointSize, weight: .heavy, design: .rounded)
                : .system(.title3, design: .rounded, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
    }

    private func countdownURL(_ item: CountdownSnapshot) -> URL {
        deepLink("tickday://countdown?id=\(item.id.uuidString)")
    }

    private func deepLink(_ value: String) -> URL {
        URL(string: value) ?? URL(fileURLWithPath: "/")
    }

    private var orderedCountdowns: [CountdownSnapshot] {
        let sorted: [CountdownSnapshot]
        if entry.configuration.countdownOrder == .custom {
            sorted = entry.countdowns
        } else {
            sorted = entry.countdowns.sorted {
                let lhsDays = formatter.countdownDayCount(targetDate: $0.targetDate, now: entry.date)
                let rhsDays = formatter.countdownDayCount(targetDate: $1.targetDate, now: entry.date)
                if (lhsDays >= 0) != (rhsDays >= 0) { return lhsDays >= 0 }
                if lhsDays >= 0 { return $0.targetDate < $1.targetDate }
                return $0.targetDate > $1.targetDate
            }
        }
        guard let primary = sorted
            .filter({ formatter.countdownDayCount(targetDate: $0.targetDate, now: entry.date) >= 0 })
            .min(by: { $0.targetDate < $1.targetDate }) ?? sorted.max(by: { $0.targetDate < $1.targetDate })
        else { return [] }
        return [primary] + sorted.filter { $0.id != primary.id }
    }

    private var primaryCountdown: CountdownSnapshot? { orderedCountdowns.first }

    private var secondaryCountdowns: [CountdownSnapshot] {
        Array(orderedCountdowns.dropFirst().prefix(max(0, limit - 1)))
    }

    private var secondPage: WidgetPage { entry.firstPage == .countdowns ? .tasks : .countdowns }

    private func pageAccessibilityLabel(_ page: WidgetPage) -> String {
        page == .countdowns ? "Show countdowns" : "Show today’s tasks"
    }

    /// Bottom navigation pinned to left-to-right so the page order never flips
    /// with right-to-left content: the configured first page stays first.
    private var pageNavigation: some View {
        HStack {
            if entry.page == secondPage {
                Button(intent: ChangeWidgetPageIntent(page: entry.firstPage)) { Image(systemName: "chevron.backward") }
                    .buttonStyle(.plain)
                    .padding(2)
                    .accessibilityLabel(pageAccessibilityLabel(entry.firstPage))
            } else { Color.clear.frame(width: 14, height: 14) }
            Spacer(minLength: 4)
            pageDots
            Spacer(minLength: 4)
            if entry.page == entry.firstPage {
                Button(intent: ChangeWidgetPageIntent(page: secondPage)) { Image(systemName: "chevron.forward") }
                    .buttonStyle(.plain)
                    .padding(2)
                    .accessibilityLabel(pageAccessibilityLabel(secondPage))
            } else { Color.clear.frame(width: 14, height: 14) }
        }
        .font(.caption.bold())
        .foregroundStyle(.secondary)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var pageDots: some View {
        HStack(spacing: 4) {
            Circle().fill(entry.page == entry.firstPage ? Color.primary : Color.secondary.opacity(0.35)).frame(width: 4, height: 4)
            Circle().fill(entry.page == secondPage ? Color.primary : Color.secondary.opacity(0.35)).frame(width: 4, height: 4)
        }.accessibilityHidden(true)
    }

    private var limit: Int {
        min(entry.configuration.maximumItems, family == .systemSmall ? 1 : family == .systemMedium ? 3 : 7)
    }

    private var contentHorizontalPadding: CGFloat { family == .systemSmall ? 8 : 14 }

    private var primaryNumberPointSize: CGFloat {
        family == .systemLarge ? primaryNumberSize * 1.15 : primaryNumberSize
    }

    private var family: WidgetFamily { previewFamily ?? environmentFamily }
}

private struct WidgetCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 7) {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(configuration.isOn ? Color.secondary : Color.accentColor)
            configuration.label
        }.contentShape(Rectangle())
    }
}

struct TickdayWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: AppConstants.widgetKind,
                               intent: TickdayWidgetConfigurationIntent.self,
                               provider: TickdayWidgetProvider()) { entry in
            TickdayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tickday")
        .description("View countdowns and complete today’s tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct TickdayWidgetBundle: WidgetBundle {
    var body: some Widget { TickdayWidget() }
}
