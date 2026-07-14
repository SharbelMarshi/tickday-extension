import SwiftUI

struct TaskRow: View {
    let occurrence: TaskOccurrence
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggle) {
                Image(systemName: occurrence.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(occurrence.isCompleted ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(occurrence.isCompleted ? "Mark \(occurrence.task.title) incomplete" : "Mark \(occurrence.task.title) complete")
            VStack(alignment: .leading, spacing: 2) {
                Text(occurrence.task.title)
                    .strikethrough(occurrence.isCompleted)
                    .foregroundStyle(occurrence.isCompleted ? .secondary : .primary)
                if let notes = occurrence.task.notes, !notes.isEmpty {
                    Text(notes).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if occurrence.task.priority != .none {
                Image(systemName: "flag.fill")
                    .foregroundStyle(occurrence.task.priority == .high ? .red : .secondary)
                    .accessibilityLabel("\(occurrence.task.priority.title) priority")
            }
            if let time = occurrence.task.scheduledTime {
                Text(time, style: .time).font(.caption).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
