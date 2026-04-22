import Foundation

struct ProcessEntry: Identifiable {
    let pid: Int32
    let name: String
    let cpuPercent: Double
    let memoryMB: Double

    var id: Int32 { pid }
}
