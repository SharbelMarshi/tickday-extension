import SwiftUI

struct CountdownEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment
    let event: CountdownEvent?
    @State private var title: String
    @State private var targetDate: Date
    @State private var includesTime: Bool
    @State private var symbolName: String
    @State private var colorIdentifier: String
    @State private var errorMessage: String?

    private let symbols = ["calendar", "gift", "airplane", "graduationcap", "heart", "star", "flag", "briefcase", "house", "sparkles"]
    private let colors = ["blue", "red", "orange", "green", "purple"]

    init(event: CountdownEvent? = nil) {
        self.event = event
        _title = State(initialValue: event?.title ?? "")
        _targetDate = State(initialValue: event?.targetDate ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now)
        _includesTime = State(initialValue: event?.includesTime ?? false)
        _symbolName = State(initialValue: event?.symbolName ?? "calendar")
        _colorIdentifier = State(initialValue: event?.colorIdentifier ?? "blue")
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("countdown.title")
                DatePicker("Date", selection: $targetDate, displayedComponents: .date)
                Toggle("Include a specific time", isOn: $includesTime)
                if includesTime { DatePicker("Time", selection: $targetDate, displayedComponents: .hourAndMinute) }
                Picker("Icon", selection: $symbolName) {
                    ForEach(symbols, id: \.self) { Image(systemName: $0).tag($0) }
                }.pickerStyle(.palette)
                Picker("Color", selection: $colorIdentifier) {
                    ForEach(colors, id: \.self) { Text($0.capitalized).tag($0) }
                }.pickerStyle(.segmented)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).font(.caption) }
            }
            .formStyle(.grouped)
            Divider()
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save", action: save).keyboardShortcut("s", modifiers: .command).buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.padding()
        }
        .frame(width: 480, height: 440)
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = "A title is required."; return }
        do {
            if let event {
                try environment.countdowns.update(event, title: title, targetDate: targetDate, includesTime: includesTime,
                                                  symbolName: symbolName, colorIdentifier: colorIdentifier)
            } else {
                try environment.countdowns.add(title: title, targetDate: targetDate, includesTime: includesTime,
                                               symbolName: symbolName, colorIdentifier: colorIdentifier)
            }
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
