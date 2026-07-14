import SwiftUI

struct TodayView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var tasks: [TaskOccurrence] = []
    @State private var countdowns: [CountdownEvent] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    SummaryTile(title: "Incomplete", value: String(tasks.filter { !$0.isCompleted }.count), symbol: "checklist")
                    SummaryTile(title: "Countdowns", value: String(countdowns.count), symbol: "hourglass")
                    SummaryTile(title: "Nearest", value: countdowns.first.map { environment.dates.countdownText(targetDate: $0.targetDate, includesTime: $0.includesTime) } ?? "None", symbol: "calendar")
                }
                section("Today’s Tasks") {
                    if tasks.isEmpty { Text("No tasks today").foregroundStyle(.secondary).padding(.vertical, 8) }
                    ForEach(tasks) { occurrence in
                        TaskRow(occurrence: occurrence) { toggle(occurrence) }
                        if occurrence.id != tasks.last?.id { Divider() }
                    }
                }
                section("Upcoming Countdowns") {
                    if countdowns.isEmpty { Text("No countdowns yet").foregroundStyle(.secondary).padding(.vertical, 8) }
                    ForEach(countdowns.prefix(5)) { CountdownRow(event: $0, formatter: environment.dates) }
                }
            }.padding(24)
        }
        .navigationTitle("Today")
        .toolbar { ToolbarItem { Button { load() } label: { Label("Refresh", systemImage: "arrow.clockwise") } } }
        .onAppear(perform: load)
        .alert("Couldn’t load Today", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "Unknown error") }
    }

    @ViewBuilder private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        GroupBox { VStack(alignment: .leading, spacing: 6) { content() }.frame(maxWidth: .infinity, alignment: .leading) }
            label: { Text(title).font(.headline) }
    }
    private func load() {
        do {
            tasks = try environment.tasks.occurrences(on: .now)
            let raw = SharedPreferences.string(forKey: AppConstants.countdownPastBehaviorPreferenceKey)
            try environment.countdowns.applyPastBehavior(CountdownPastBehavior(rawValue: raw ?? "") ?? .keep)
            countdowns = try environment.countdowns.fetch(sort: .nearest)
        } catch { errorMessage = error.localizedDescription }
    }
    private func toggle(_ occurrence: TaskOccurrence) {
        do { try environment.tasks.toggle(taskID: occurrence.task.id, on: occurrence.date); load() }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        GroupBox {
            HStack { Image(systemName: symbol).foregroundStyle(.tint); Spacer(); Text(value).font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.7) }
            Text(title).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
        }.frame(maxWidth: .infinity)
    }
}
