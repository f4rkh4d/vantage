import SwiftUI

struct NetworkToolsView: View {
    @ObservedObject private var manager = NetworkToolsManager.shared
    @State private var selectedTab = 0
    private let accent = Module.networkTools.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            tabPicker
            Divider()
            Group {
                switch selectedTab {
                case 0: InterfacesTab(manager: manager, accent: accent)
                case 1: PingTab(manager: manager, accent: accent)
                default: DNSTab(manager: manager, accent: accent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            manager.refreshInterfaces()
            manager.refreshDNS()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.networkTools.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("Network Tools")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            Text("Interfaces").tag(0)
            Text("Ping").tag(1)
            Text("DNS").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}

private struct InterfacesTab: View {
    @ObservedObject var manager: NetworkToolsManager
    let accent: Color

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if manager.interfaces.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "network.slash")
                            .font(.system(size: 28)).foregroundStyle(.tertiary)
                        Text("No active interfaces")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    ForEach(manager.interfaces) { iface in
                        InterfaceCard(interface: iface, accent: accent)
                    }
                }
            }
            .padding(14)
        }
    }
}

private struct InterfaceCard: View {
    let interface: NetworkInterface
    let accent: Color
    @State private var copiedField: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(interface.displayName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)

            ipRow(label: "IPv4", value: interface.ipv4)
            if !interface.ipv6.isEmpty {
                ipRow(label: "IPv6", value: interface.ipv6)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func ipRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9)).foregroundStyle(.tertiary)
                .frame(width: 28, alignment: .leading)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
                copiedField = label
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if copiedField == label { copiedField = nil }
                }
            } label: {
                Image(systemName: copiedField == label ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 9))
                    .foregroundStyle(copiedField == label ? accent : Color.secondary)
            }
            .buttonStyle(.plain)
            .help("Copy")
        }
    }
}

private struct PingTab: View {
    @ObservedObject var manager: NetworkToolsManager
    let accent: Color
    @State private var host = "8.8.8.8"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Host or IP", text: $host)
                    .font(.system(size: 12))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onSubmit { if !manager.isPinging { manager.ping(host: host) } }

                Button {
                    manager.ping(host: host)
                } label: {
                    if manager.isPinging {
                        ProgressView().scaleEffect(0.6).frame(width: 48)
                    } else {
                        Text("Ping")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(accent)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .buttonStyle(.plain)
                .disabled(manager.isPinging || host.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)

            Divider()

            if manager.pingResults.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 24)).foregroundStyle(.tertiary)
                    Text("No results yet")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(manager.pingResults) { result in
                            PingRow(result: result, accent: accent)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct PingRow: View {
    let result: PingResult
    let accent: Color

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: result.timestamp)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.host)
                    .font(.system(size: 11, weight: .medium))
                Text(timeString)
                    .font(.system(size: 9)).foregroundStyle(.tertiary)
            }
            Spacer()
            if let ms = result.latency {
                Text(String(format: "%.0f ms", ms))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ms < 100 ? accent : Color.orange)
            } else {
                Text("Timeout")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
    }
}

private struct DNSTab: View {
    @ObservedObject var manager: NetworkToolsManager
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Active DNS Servers")
                    .font(.system(size: 11, weight: .semibold))

                if manager.activeDNS.isEmpty {
                    Text("Unable to read DNS configuration")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                } else {
                    Text(manager.activeDNS)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(accent)
                        .textSelection(.enabled)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                manager.openNetworkSettings()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "network").font(.system(size: 11))
                    Text("Network Settings")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
