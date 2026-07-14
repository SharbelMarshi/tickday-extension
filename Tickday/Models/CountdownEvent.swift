import Foundation
import SwiftData

@Model
final class CountdownEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var targetDate: Date
    var includesTime: Bool
    var symbolName: String?
    var colorIdentifier: String?
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int
    var isArchived: Bool

    init(id: UUID = UUID(), title: String, targetDate: Date, includesTime: Bool = false,
         symbolName: String? = nil, colorIdentifier: String? = nil, createdAt: Date = .now,
         updatedAt: Date = .now, sortOrder: Int = 0, isArchived: Bool = false) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.targetDate = targetDate
        self.includesTime = includesTime
        self.symbolName = symbolName
        self.colorIdentifier = colorIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
        self.isArchived = isArchived
    }
}
