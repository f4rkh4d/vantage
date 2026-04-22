import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let date: Date
    var isPinned: Bool

    init(content: String) {
        id = UUID()
        self.content = content
        date = Date()
        isPinned = false
    }
}
