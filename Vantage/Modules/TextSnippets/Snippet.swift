import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var trigger: String
    var expansion: String
    var label: String
}
