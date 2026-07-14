import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment
    let task: TaskDefinition?
    @State private var title: String
    @State private var notes: String
    @State private var date: Date
    @State private var includesTime: Bool
    @State private var time: Date
    @State private var recurrence: TaskRecurrenceType
    @State private var weekdays: Set<Weekday>
    @State private var interval: Int
    @State private var priority: TaskPriority
    @State private var errorMessage: String?

    init(task: TaskDefinition? = nil, initialDate: Date = .now) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _date = State(initialValue: task?.startDate ?? initialDate)
        _includesTime = State(initialValue: task?.scheduledTime != nil)
        _time = State(initialValue: task?.scheduledTime ?? initialDate)
        _recurrence = State(initialValue: task?.recurrenceType ?? .none)
        _weekdays = State(initialValue: task?.selectedWeekdays ?? [])
        _interval = State(initialValue: max(1, task?.recurrenceInterval ?? 2))
        _priority = State(initialValue: task?.priority ?? .none)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Task", text: $title).textFieldStyle(.roundedBorder).accessibilityIdentifier("task.title")
                TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Schedule a time", isOn: $includesTime)
                if includesTime { DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute) }
                Picker("Repeat", selection: $recurrence) {
                    ForEach(TaskRecurrenceType.allCases) { Text($0.title).tag($0) }
                }
                if recurrence == .weekly {
                    HStack {
                        Text("On")
                        ForEach(Weekday.allCases) { weekday in
                            Toggle(weekday.shortTitle, isOn: Binding(
                                get: { weekdays.contains(weekday) },
                                set: { isSelected in
                                    if isSelected { weekdays.insert(weekday) }
                                    else { weekdays.remove(weekday) }
                                }
                            )).toggleStyle(.button)
                        }
                    }
                }
                if recurrence == .customInterval {
                    Stepper("Every \(interval) days", value: $interval, in: 1...365)
                }
                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.segmented)
                if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
            }.formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save", action: save).keyboardShortcut("s", modifiers: .command).buttonStyle(.borderedProminent)
                    .disabled(!isValid)
            }.padding()
        }
        .frame(width: 520, height: recurrence == .weekly ? 540 : 480)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (recurrence != .weekly || !weekdays.isEmpty)
    }

    private func save() {
        guard isValid else { errorMessage = "Enter a title and select at least one weekday when required."; return }
        do {
            if let task {
                try environment.tasks.update(task, title: title, notes: notes, startDate: date,
                    scheduledTime: includesTime ? time : nil, recurrenceType: recurrence,
                    selectedWeekdays: weekdays, recurrenceInterval: recurrence == .customInterval ? interval : nil,
                    priority: priority)
            } else {
                try environment.tasks.add(title: title, notes: notes, startDate: date,
                    scheduledTime: includesTime ? time : nil, recurrenceType: recurrence,
                    selectedWeekdays: weekdays, recurrenceInterval: recurrence == .customInterval ? interval : nil,
                    priority: priority)
            }
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
