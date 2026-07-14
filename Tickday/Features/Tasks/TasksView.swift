import SwiftUI

struct TasksView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var occurrences: [TaskOccurrence] = []
    @State private var allOccurrences: [TaskOccurrence] = []
    @State private var selectedOccurrenceID: String?
    @State private var search = ""
    @State private var isSearching = false
    @FocusState private var searchFieldFocused: Bool
    @State private var filter: TaskCompletionFilter = .all
    @AppStorage("tasks.hideCompleted") private var hideCompleted = false
    @State private var showingEditor = false
    @State private var editorTask: TaskDefinition?
    @State private var confirmingDelete = false
    @State private var errorMessage: String?

    var body: some View {
        configuredContent
    }

    private var baseContent: AnyView {
        AnyView(taskContent
            .navigationTitle("Tasks")
            .toolbar { toolbarItems })
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if isSearching {
            ToolbarItem { searchField }
        } else {
            ToolbarItemGroup {
                Button { shiftDay(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous day")
                DatePicker("Date", selection: selectedDateBinding, displayedComponents: .date)
                    .labelsHidden()
                    .fixedSize()
                Button { shiftDay(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next day")
                Button("Today") { selectedDateBinding.wrappedValue = .now }
                    .disabled(Calendar.current.isDateInToday(environment.navigation.selectedDate))
                filterPicker
                Toggle(isOn: $hideCompleted) {
                    Label("Hide Completed", systemImage: hideCompleted ? "eye.slash" : "eye")
                }
                .help("Hide completed tasks")
                Button { isSearching = true } label: { Label("Search", systemImage: "magnifyingglass") }
                    .accessibilityLabel("Search tasks")
            }
        }
        ToolbarItem {
            Button { newItem() } label: { Label("New Task", systemImage: "plus") }
        }
    }

    private var searchField: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search tasks", text: $search)
                .textFieldStyle(.plain)
                .frame(width: 180)
                .focused($searchFieldFocused)
                .onAppear { searchFieldFocused = true }
            Button { closeSearch() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                .buttonStyle(.plain)
                .accessibilityLabel("Close search")
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 7))
        .onExitCommand { closeSearch() }
    }

    private func shiftDay(_ delta: Int) {
        selectedDateBinding.wrappedValue = Calendar.current.date(
            byAdding: .day, value: delta, to: environment.navigation.selectedDate
        ) ?? environment.navigation.selectedDate
    }

    private func closeSearch() {
        search = ""
        isSearching = false
    }

    private var presentedContent: AnyView {
        AnyView(baseContent
            .sheet(isPresented: $showingEditor, onDismiss: load) {
                TaskEditorView(task: editorTask, initialDate: environment.navigation.selectedDate)
            }
            .alert("Delete task?", isPresented: $confirmingDelete) {
                Button("Delete", role: .destructive) { deleteSelected() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("Deleting a recurring task also deletes its completion history.") })
    }

    private var configuredContent: some View {
        presentedContent
        .alert("Couldn’t complete the action", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "Unknown error") }
        .onAppear(perform: appeared)
        .onChange(of: environment.navigation.selectedDate) { load() }
        .onChange(of: search) { load() }
        .onChange(of: filter) { load() }
        .onChange(of: environment.navigation.presentsNewTask) { if $1 { newItem(); environment.navigation.presentsNewTask = false } }
        .focusedValue(\.createCurrentItem, newItem)
    }

    private var taskContent: some View {
        VStack(spacing: 0) {
            if visibleOccurrences.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                taskList
            }
        }
    }

    private var emptyState: some View {
        let state = TaskEmptyStateKind.resolve(
            totalCount: allOccurrences.count,
            completedCount: allOccurrences.filter(\.isCompleted).count,
            hideCompleted: hideCompleted
        )
        return ContentUnavailableView(state.title, systemImage: "checklist",
            description: Text(state.description))
    }

    private var selectedDateBinding: Binding<Date> {
        Binding(get: { environment.navigation.selectedDate }, set: { environment.navigation.selectedDate = $0 })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var visibleOccurrences: [TaskOccurrence] { hideCompleted ? occurrences.filter { !$0.isCompleted } : occurrences }

    private var filterPicker: some View {
        let selection = Binding<String>(
            get: { filter.rawValue },
            set: { filter = TaskCompletionFilter(rawValue: $0) ?? .all }
        )
        return Picker("Filter", selection: selection) {
            Text("All").tag("all")
            Text("Incomplete").tag("incomplete")
            Text("Completed").tag("completed")
        }
        .fixedSize()
    }

    private var taskList: some View {
        List(selection: $selectedOccurrenceID) {
            ForEach(visibleOccurrences) { occurrence in
                TaskListItem(
                    occurrence: occurrence,
                    toggle: { toggle(occurrence) },
                    edit: { edit(occurrence.task) },
                    delete: {
                        selectedOccurrenceID = occurrence.id
                        confirmingDelete = true
                    }
                )
                .tag(occurrence.id)
            }
            .onMove(perform: moveTasks)
        }
    }

    private func newItem() { editorTask = nil; showingEditor = true }
    private func appeared() {
        load()
        if environment.navigation.presentsNewTask { newItem(); environment.navigation.presentsNewTask = false }
    }
    private func edit(_ task: TaskDefinition) { editorTask = task; showingEditor = true }
    private func toggle(_ occurrence: TaskOccurrence) { perform { try environment.tasks.toggle(taskID: occurrence.task.id, on: occurrence.date) } }
    private func toggleSelected() { if let occurrence = occurrences.first(where: { $0.id == selectedOccurrenceID }) { toggle(occurrence) } }
    private func moveTasks(from offsets: IndexSet, to destination: Int) {
        perform { try environment.tasks.move(visibleOccurrences.map(\.task), from: offsets, to: destination) }
    }
    private func deleteSelected() { if let task = occurrences.first(where: { $0.id == selectedOccurrenceID })?.task { perform { try environment.tasks.delete(task) } } }
    private func load() {
        perform(reloadAfter: false) {
            try reloadOccurrences()
            if let id = environment.navigation.selectedTaskID {
                selectedOccurrenceID = occurrences.first(where: { $0.task.id == id })?.id
            }
        }
    }
    private func perform(reloadAfter: Bool = true, _ operation: () throws -> Void) {
        do { try operation(); if reloadAfter { try reloadOccurrences() } }
        catch { errorMessage = error.localizedDescription }
    }

    private func reloadOccurrences() throws {
        let date = environment.navigation.selectedDate
        allOccurrences = try environment.tasks.occurrences(on: date)
        occurrences = try environment.tasks.occurrences(on: date, search: search, filter: filter)
    }
}

enum TaskEmptyStateKind: Equatable {
    case noTasks
    case noMatches
    case allTasksCompletedHidden

    static func resolve(totalCount: Int, completedCount: Int, hideCompleted: Bool) -> Self {
        if totalCount == 0 { return .noTasks }
        if hideCompleted && completedCount == totalCount { return .allTasksCompletedHidden }
        return .noMatches
    }

    var title: String {
        switch self {
        case .noTasks: "No tasks"
        case .noMatches: "No matching tasks"
        case .allTasksCompletedHidden: "All tasks completed"
        }
    }

    var description: String {
        switch self {
        case .noTasks: "Nothing is scheduled for this day."
        case .noMatches: "Try changing the current filter."
        case .allTasksCompletedHidden: "Completed tasks are currently hidden."
        }
    }
}

private struct TaskListItem: View {
    let occurrence: TaskOccurrence
    let toggle: () -> Void
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        TaskRow(occurrence: occurrence, toggle: toggle)
            .contextMenu {
                Button("Edit Task", action: edit)
                Button(occurrence.isCompleted ? "Mark Incomplete" : "Mark Complete", action: toggle)
                Divider()
                Button("Delete Task", role: .destructive, action: delete)
            }
    }
}
