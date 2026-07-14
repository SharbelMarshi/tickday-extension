import SwiftUI

struct CountdownsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var events: [CountdownEvent] = []
    @State private var selected: CountdownEvent?
    @State private var search = ""
    @State private var sort: CountdownSort = .custom
    @State private var editorEvent: CountdownEvent?
    @State private var showingEditor = false
    @State private var confirmingDelete = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if events.isEmpty {
                ContentUnavailableView(search.isEmpty ? "No countdowns yet" : "No matching countdowns",
                                       systemImage: "hourglass", description: Text("Create a countdown for something worth looking forward to."))
            } else {
                List(selection: $selected) {
                    ForEach(events) { event in
                        CountdownRow(event: event, formatter: environment.dates)
                            .tag(event)
                            .contextMenu {
                                Button("Edit") { edit(event) }
                                Button("Duplicate") { duplicate(event) }
                                Divider()
                                Button("Delete", role: .destructive) { selected = event; confirmingDelete = true }
                            }
                    }
                    .onMove { offsets, destination in
                        guard sort == .custom else { return }
                        perform { try environment.countdowns.move(events, from: offsets, to: destination) }
                    }
                }
            }
        }
        .navigationTitle("Countdowns")
        .searchable(text: $search, prompt: "Search countdowns")
        .toolbar {
            ToolbarItem { Picker("Sort", selection: $sort) { ForEach(CountdownSort.allCases) { Text($0.title).tag($0) } }.fixedSize() }
            ToolbarItem { Button { newItem() } label: { Label("New Countdown", systemImage: "plus") } }
        }
        .sheet(isPresented: $showingEditor, onDismiss: load) { CountdownEditorView(event: editorEvent) }
        .alert("Delete countdown?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { if let selected { perform { try environment.countdowns.delete(selected) } } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
        .alert("Couldn’t complete the action", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "Unknown error") }
        .onAppear { load(); if environment.navigation.presentsNewCountdown { newItem(); environment.navigation.presentsNewCountdown = false } }
        .onChange(of: search) { load() }
        .onChange(of: sort) { load() }
        .onChange(of: environment.navigation.presentsNewCountdown) { if $1 { newItem(); environment.navigation.presentsNewCountdown = false } }
        .focusedValue(\.createCurrentItem, newItem)
        .focusedValue(\.deleteCurrentItem, selected == nil ? nil : { confirmingDelete = true })
    }

    private func newItem() { editorEvent = nil; showingEditor = true }
    private func edit(_ event: CountdownEvent) { editorEvent = event; showingEditor = true }
    private func duplicate(_ event: CountdownEvent) { perform { try environment.countdowns.duplicate(event) } }
    private func load() {
        perform {
            let raw = SharedPreferences.string(forKey: AppConstants.countdownPastBehaviorPreferenceKey)
            try environment.countdowns.applyPastBehavior(CountdownPastBehavior(rawValue: raw ?? "") ?? .keep)
            events = try environment.countdowns.fetch(search: search, sort: sort)
            if let id = environment.navigation.selectedCountdownID { selected = events.first { $0.id == id } }
        }
    }
    private func perform(_ operation: () throws -> Void) { do { try operation(); loadIfNeeded() } catch { errorMessage = error.localizedDescription } }
    private func loadIfNeeded() { do { events = try environment.countdowns.fetch(search: search, sort: sort) } catch { errorMessage = error.localizedDescription } }
}
