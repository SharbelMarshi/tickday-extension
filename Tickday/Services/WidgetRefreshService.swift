import WidgetKit

struct WidgetRefreshService {
    func reload() { WidgetCenter.shared.reloadTimelines(ofKind: AppConstants.widgetKind) }
}
