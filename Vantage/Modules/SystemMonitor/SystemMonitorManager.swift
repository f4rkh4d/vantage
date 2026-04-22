import Foundation
import AppKit

@MainActor
final class SystemMonitorManager: ObservableObject {
    static let shared = SystemMonitorManager()
    private init() {}

    @Published var processes: [ProcessEntry] = []
    @Published var diskUsedGB: Double = 0
    @Published var diskTotalGB: Double = 0
    @Published var netInKBs: Double = 0
    @Published var netOutKBs: Double = 0
    private var timer: Timer?
    private var lastNetIn: UInt64 = 0
    private var lastNetOut: UInt64 = 0

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    func kill(pid: Int32) {
        Foundation.kill(pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.refresh() }
    }

    private func refresh() {
        refreshProcesses()
        refreshDisk()
        refreshNetwork()
    }

    private func refreshProcesses() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axo", "pid,pcpu,rss,comm"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return }
        var entries: [ProcessEntry] = []
        for line in output.components(separatedBy: "\n").dropFirst() {
            let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            guard parts.count >= 4,
                  let pid = Int32(parts[0]),
                  let cpu = Double(parts[1]),
                  let rss = Double(parts[2]) else { continue }
            let name = String(parts[3].split(separator: "/").last ?? parts[3])
                .trimmingCharacters(in: .whitespaces)
            entries.append(ProcessEntry(pid: pid, name: name,
                                       cpuPercent: cpu, memoryMB: rss / 1024))
        }
        processes = entries.sorted { $0.cpuPercent > $1.cpuPercent }.prefix(50).map { $0 }
    }

    private func refreshDisk() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
              let total = attrs[.systemSize] as? Int64,
              let free = attrs[.systemFreeSize] as? Int64 else { return }
        diskTotalGB = Double(total) / 1e9
        diskUsedGB = Double(total - free) / 1e9
    }

    private func refreshNetwork() {
        // Read cumulative bytes from netstat
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        task.arguments = ["-ib"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return }
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        for line in output.components(separatedBy: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            // netstat -ib: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes ...
            guard parts.count >= 10,
                  !String(parts[0]).contains("*"),
                  String(parts[0]) != "lo0",
                  let ibytes = UInt64(parts[6]),
                  let obytes = UInt64(parts[9]) else { continue }
            totalIn += ibytes
            totalOut += obytes
        }
        if lastNetIn > 0 {
            netInKBs = Double(totalIn > lastNetIn ? totalIn - lastNetIn : 0) / 3000.0
            netOutKBs = Double(totalOut > lastNetOut ? totalOut - lastNetOut : 0) / 3000.0
        }
        lastNetIn = totalIn; lastNetOut = totalOut
    }
}
