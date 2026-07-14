import SwiftData
import Observation

@MainActor @Observable
final class AppEnvironment {
    let container: ModelContainer
    let countdowns: CountdownRepository
    let tasks: TaskRepository
    let navigation = NavigationCoordinator()
    let dates = DateFormattingService()

    init(container: ModelContainer) {
        self.container = container
        countdowns = CountdownRepository(container: container)
        tasks = TaskRepository(container: container)
    }
}
