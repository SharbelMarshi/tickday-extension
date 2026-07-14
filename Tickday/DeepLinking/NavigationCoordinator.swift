import Foundation
import Observation

enum AppSection: String, CaseIterable, Identifiable {
    case today, countdowns, tasks, settings
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .today: "sun.max"
        case .countdowns: "hourglass"
        case .tasks: "checklist"
        case .settings: "gearshape"
        }
    }
}

@MainActor @Observable
final class NavigationCoordinator {
    var selection: AppSection = .today
    var selectedDate = Date.now
    var selectedCountdownID: UUID?
    var selectedTaskID: UUID?
    var presentsNewCountdown = false
    var presentsNewTask = false

    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == AppConstants.urlScheme else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let action = url.host ?? url.pathComponents.dropFirst().first ?? ""
        let id = components?.queryItems?.first(where: { $0.name == "id" })?.value.flatMap(UUID.init(uuidString:))
        switch action {
        case "today": selection = .today
        case "countdowns": selection = .countdowns
        case "tasks": selection = .tasks; selectedDate = .now
        case "countdown": selection = .countdowns; selectedCountdownID = id
        case "task": selection = .tasks; selectedTaskID = id
        case "new-countdown": selection = .countdowns; presentsNewCountdown = true
        case "new-task": selection = .tasks; presentsNewTask = true
        default: break
        }
    }
}
