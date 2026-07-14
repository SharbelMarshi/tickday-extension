import AppIntents

enum WidgetCountdownOrder: String, AppEnum {
    case nearest, custom
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Countdown Order")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .nearest: "Nearest date", .custom: "Custom order"
    ]
}

struct TickdayWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Tickday Dashboard"
    static let description = IntentDescription("Choose the initial page and amount of Tickday information to show.")

    @Parameter(title: "Default Page", default: .countdowns) var defaultPage: WidgetPage
    @Parameter(title: "Maximum Items", default: 3, inclusiveRange: (1, 8)) var maximumItems: Int
    @Parameter(title: "Include Completed Tasks", default: true) var includeCompletedTasks: Bool
    @Parameter(title: "Countdown Order", default: .nearest) var countdownOrder: WidgetCountdownOrder

    static var parameterSummary: some ParameterSummary {
        Summary("Configure Tickday") {
            \.$defaultPage
            \.$maximumItems
            \.$includeCompletedTasks
            \.$countdownOrder
        }
    }
}
