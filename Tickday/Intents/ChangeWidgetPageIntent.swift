import AppIntents
import Foundation
import WidgetKit

struct ChangeWidgetPageIntent: AppIntent {
    static let title: LocalizedStringResource = "Change Tickday Widget Page"
    static let openAppWhenRun = false

    @Parameter(title: "Page") var page: WidgetPage
    init() {}
    init(page: WidgetPage) { self.page = page }

    func perform() async throws -> some IntentResult {
        try SharedPreferences.set(page.rawValue, forKey: AppConstants.widgetPagePreferenceKey)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConstants.widgetKind)
        return .result()
    }
}
