import Foundation

struct AIMessage: Identifiable, Equatable {
    let id: UUID = UUID()
    let role: String
    let content: String
}
