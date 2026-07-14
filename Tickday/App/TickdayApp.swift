import SwiftUI
import SwiftData

@main
struct TickdayApp: App {
    private let startup: Result<AppEnvironment, Error>

    init() {
        startup = Result { try SharedModelContainer.make() }.map { container in
            MainActor.assumeIsolated { AppEnvironment(container: container) }
        }
    }

    var body: some Scene {
        WindowGroup {
            switch startup {
            case .success(let environment):
                RootView(environment: environment)
                    .modelContainer(environment.container)
            case .failure(let error):
                PersistenceFailureView(error: error)
            }
        }
        .defaultSize(width: 980, height: 680)
        .commands { TickdayCommands() }

        Settings {
            switch startup {
            case .success(let environment): SettingsView().environment(environment)
            case .failure(let error): PersistenceFailureView(error: error)
            }
        }
    }
}

private struct PersistenceFailureView: View {
    let error: Error
    var body: some View {
        ContentUnavailableView("Tickday couldn’t open its data", systemImage: "externaldrive.badge.exclamationmark",
                               description: Text(error.localizedDescription))
            .frame(minWidth: 520, minHeight: 320)
    }
}
