import SwiftUI

struct RootView: View {
    @State var environment: AppEnvironment
    @AppStorage(AppConstants.widgetRightToLeftPreferenceKey) private var rightToLeft = false

    var body: some View {
        @Bindable var navigation = environment.navigation
        NavigationSplitView {
            List(AppSection.allCases, selection: $navigation.selection) { section in
                Label(section.title, systemImage: section.symbol).tag(section)
            }
            .navigationTitle("Tickday")
            .navigationSplitViewColumnWidth(min: 170, ideal: 200)
        } detail: {
            Group {
                switch navigation.selection {
                case .today: TodayView()
                case .countdowns: CountdownsView()
                case .tasks: TasksView()
                case .settings: SettingsView()
                }
            }
            .transformEnvironment(\.layoutDirection) { direction in
                if rightToLeft, navigation.selection == .countdowns || navigation.selection == .tasks {
                    direction = .rightToLeft
                }
            }
            .frame(minWidth: 620, minHeight: 500)
        }
        .environment(environment)
        .onOpenURL { navigation.handle($0) }
    }
}
