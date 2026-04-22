import Foundation
import AppKit

struct AppEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let url: URL
    var icon: NSImage?

    static func == (lhs: AppEntry, rhs: AppEntry) -> Bool { lhs.id == rhs.id }
}
