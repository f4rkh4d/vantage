import Darwin
import Foundation
import AppKit

struct NetworkInterface: Identifiable {
    var id: String { name }
    let name: String
    let displayName: String
    let ipv4: String
    let ipv6: String
    let isUp: Bool
}

struct PingResult: Identifiable {
    var id = UUID()
    let host: String
    let latency: Double?
    let timestamp: Date
}

@MainActor
final class NetworkToolsManager: ObservableObject {
    static let shared = NetworkToolsManager()
    private init() {}

    @Published var interfaces: [NetworkInterface] = []
    @Published var pingResults: [PingResult] = []
    @Published var isPinging: Bool = false
    @Published var activeDNS: String = ""

    func refreshInterfaces() {
        var addrs = [String: (String, String, Bool)]()

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            let flags = current.pointee.ifa_flags
            let isUp = (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_LOOPBACK)) == 0
            if let sa = current.pointee.ifa_addr {
                if sa.pointee.sa_family == UInt8(AF_INET) {
                    var addr = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    if let sin = UnsafeRawPointer(sa)?.assumingMemoryBound(to: sockaddr_in.self) {
                        var a = sin.pointee.sin_addr
                        inet_ntop(AF_INET, &a, &addr, socklen_t(INET_ADDRSTRLEN))
                        let ip = String(cString: addr)
                        let existing = addrs[name] ?? ("", "", isUp)
                        addrs[name] = (ip, existing.1, isUp)
                    }
                } else if sa.pointee.sa_family == UInt8(AF_INET6) {
                    var addr = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                    if let sin6 = UnsafeRawPointer(sa)?.assumingMemoryBound(to: sockaddr_in6.self) {
                        var a = sin6.pointee.sin6_addr
                        inet_ntop(AF_INET6, &a, &addr, socklen_t(INET6_ADDRSTRLEN))
                        let ip = String(cString: addr)
                        let existing = addrs[name] ?? ("", "", isUp)
                        addrs[name] = (existing.0, ip, isUp)
                    }
                }
            }
            ptr = current.pointee.ifa_next
        }

        interfaces = addrs.compactMap { name, info in
            guard info.2, !info.0.isEmpty else { return nil }
            let display = name.hasPrefix("en") ? "Wi-Fi/Ethernet (\(name))" : name
            return NetworkInterface(name: name, displayName: display, ipv4: info.0, ipv6: info.1, isUp: info.2)
        }.sorted { $0.name < $1.name }
    }

    func ping(host: String) {
        isPinging = true
        let start = Date()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "2", host]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPinging = false
                let elapsed = Date().timeIntervalSince(start) * 1000
                let success = proc.terminationStatus == 0
                self.pingResults.insert(PingResult(host: host, latency: success ? elapsed : nil, timestamp: Date()), at: 0)
                if self.pingResults.count > 10 { self.pingResults = Array(self.pingResults.prefix(10)) }
            }
        }
        try? process.run()
    }

    func refreshDNS() {
        if let content = try? String(contentsOfFile: "/etc/resolv.conf") {
            let servers = content.components(separatedBy: "\n")
                .filter { $0.hasPrefix("nameserver") }
                .compactMap { $0.components(separatedBy: " ").last }
            activeDNS = servers.joined(separator: ", ")
        }
    }

    func openNetworkSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension")!)
    }
}
