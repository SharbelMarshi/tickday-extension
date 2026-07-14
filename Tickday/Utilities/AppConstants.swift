import Foundation

enum AppConstants {
    /// Replace these identifiers before signing the project for distribution.
    static let appGroupIdentifier = "JZH2954S3D.com.example.CountdownTasks"
    static let appBundleIdentifier = "com.example.Tickday"
    static let widgetBundleIdentifier = "com.example.Tickday.Widget"
    static let widgetKind = "TickdayDashboardWidget"
    static let urlScheme = "tickday"
    static let sharedStoreName = "Tickday.store"
    static let widgetPagePreferenceKey = "widget.selectedPage"
    static let widgetFirstPagePreferenceKey = "widget.firstPage"
    static let widgetRightToLeftPreferenceKey = "widget.rightToLeft"
    static let countdownPastBehaviorPreferenceKey = "countdown.pastBehavior"
    static let sharedPreferencesDirectoryName = "Preferences"
}
