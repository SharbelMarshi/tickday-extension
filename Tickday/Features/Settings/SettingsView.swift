import SwiftUI

struct SettingsView: View {
    @State private var behaviorRaw = CountdownPastBehavior.keep.rawValue
    @State private var widgetFirstPageRaw = WidgetPage.countdowns.rawValue
    @AppStorage(AppConstants.widgetRightToLeftPreferenceKey) private var rightToLeft = false
    @AppStorage("tasks.hideCompleted") private var hideCompleted = false

    var body: some View {
        Form {
            Picker("When a countdown passes", selection: $behaviorRaw) {
                ForEach(CountdownPastBehavior.allCases) { Text($0.title).tag($0.rawValue) }
            }
            Toggle("Hide completed tasks by default", isOn: $hideCompleted)
            Picker("First widget page", selection: $widgetFirstPageRaw) {
                Text("Countdowns").tag(WidgetPage.countdowns.rawValue)
                Text("Tasks").tag(WidgetPage.tasks.rawValue)
            }
            Toggle("Right-to-left layout", isOn: $rightToLeft)
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(minWidth: 520, minHeight: 360)
        .onAppear {
            behaviorRaw = SharedPreferences.string(
                forKey: AppConstants.countdownPastBehaviorPreferenceKey
            ) ?? CountdownPastBehavior.keep.rawValue
            widgetFirstPageRaw = SharedPreferences.string(
                forKey: AppConstants.widgetFirstPagePreferenceKey
            ) ?? WidgetPage.countdowns.rawValue
            if SharedPreferences.string(forKey: AppConstants.widgetRightToLeftPreferenceKey) == "true" {
                rightToLeft = true
            }
        }
        .onChange(of: behaviorRaw) { _, newValue in
            SharedPreferences.store(newValue, forKey: AppConstants.countdownPastBehaviorPreferenceKey)
            WidgetRefreshService().reload()
        }
        .onChange(of: widgetFirstPageRaw) { _, newValue in
            SharedPreferences.store(newValue, forKey: AppConstants.widgetFirstPagePreferenceKey)
            SharedPreferences.store(newValue, forKey: AppConstants.widgetPagePreferenceKey)
            WidgetRefreshService().reload()
        }
        .onChange(of: rightToLeft) { _, newValue in
            SharedPreferences.store(newValue ? "true" : "false", forKey: AppConstants.widgetRightToLeftPreferenceKey)
            WidgetRefreshService().reload()
        }
    }
}
