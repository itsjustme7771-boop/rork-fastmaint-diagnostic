import Foundation
import SwiftData

@Model
final class ManualDocument {
    @Attribute(.unique) var id: UUID
    var title: String
    var fileName: String
    var addedAt: Date
    var pageCount: Int
    var equipmentHint: String
    var extractedText: String
    var indexed: Bool

    init(
        id: UUID = UUID(),
        title: String,
        fileName: String,
        addedAt: Date = .now,
        pageCount: Int = 0,
        equipmentHint: String = "",
        extractedText: String = "",
        indexed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.fileName = fileName
        self.addedAt = addedAt
        self.pageCount = pageCount
        self.equipmentHint = equipmentHint
        self.extractedText = extractedText
        self.indexed = indexed
    }
}
