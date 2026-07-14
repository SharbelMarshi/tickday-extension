import SwiftUI

struct CountdownRow: View {
    let event: CountdownEvent
    let formatter: DateFormattingService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.symbolName ?? "calendar")
                .frame(width: 28)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(.headline)
                Text(formatter.dateText(event.targetDate, includesTime: event.includesTime))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatter.countdownText(targetDate: event.targetDate, includesTime: event.includesTime))
                .font(.headline).foregroundStyle(statusColor)
                .accessibilityLabel("Time remaining: \(formatter.countdownText(targetDate: event.targetDate, includesTime: event.includesTime))")
        }
        .padding(.vertical, 5)
    }

    private var tint: Color {
        switch event.colorIdentifier {
        case "red": .red
        case "orange": .orange
        case "green": .green
        case "purple": .purple
        default: .accentColor
        }
    }
    private var statusColor: Color {
        if Calendar.current.isDateInToday(event.targetDate) { return .orange }
        return event.targetDate < .now ? .secondary : .primary
    }
}
