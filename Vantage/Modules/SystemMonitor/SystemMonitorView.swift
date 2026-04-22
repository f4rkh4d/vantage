import SwiftUI

struct SystemMonitorView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var searchText = ""
    @ObservedObject private var manager = SystemMonitorManager.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Picker("", selection: $selectedTab) {
                Text("Processes").tag(0)
                Text("Disk").tag(1)
                Text("Network").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            Divider()
            switch selectedTab {
            case 0: processList
            case 1: diskView
            default: networkView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { SystemMonitorManager.shared.start() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Module.systemMonitor.accentColor.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.systemMonitor.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Module.systemMonitor.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("System Monitor")
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 8) {
                    Text(String(format: "CPU %.0f%%", appState.cpuUsage * 100))
                    Text(String(format: "RAM %.0f%%", appState.ramUsage * 100))
                }
                .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var processList: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.tertiary)
                TextField("Filter processes…", text: $searchText)
                    .font(.system(size: 12)).textFieldStyle(.plain)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .padding(.horizontal, 10).padding(.vertical, 6)

            Divider()

            // Header
            HStack {
                Text("Process").font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary)
                Spacer()
                Text("CPU").font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary).frame(width: 36)
                Text("MEM").font(.system(size: 9, weight: .medium)).foregroundStyle(.tertiary).frame(width: 44)
            }
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(Color.secondary.opacity(0.05))

            let filtered = searchText.isEmpty ? manager.processes
                : manager.processes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { proc in
                        ProcessRow(entry: proc)
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
    }

    private var diskView: some View {
        VStack(spacing: 20) {
            let used = manager.diskUsedGB
            let total = manager.diskTotalGB
            let fraction = total > 0 ? used / total : 0

            ZStack {
                Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                Circle().trim(from: 0, to: fraction)
                    .stroke(
                        AngularGradient(colors: [Module.systemMonitor.accentColor,
                                                 Module.systemMonitor.accentColor.opacity(0.5)],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: fraction)
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", fraction * 100))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("used").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            .padding(.top, 16)

            HStack(spacing: 24) {
                DiskStat(label: "Used", value: String(format: "%.1f GB", used), color: Module.systemMonitor.accentColor)
                DiskStat(label: "Free", value: String(format: "%.1f GB", total - used), color: .secondary)
                DiskStat(label: "Total", value: String(format: "%.0f GB", total), color: .secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var networkView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                NetStat(label: "↓ Download", value: String(format: "%.1f KB/s", manager.netInKBs),
                        color: Color(red: 0.20, green: 0.78, blue: 0.64))
                NetStat(label: "↑ Upload", value: String(format: "%.1f KB/s", manager.netOutKBs),
                        color: Color(red: 0.38, green: 0.55, blue: 1.0))
            }
            .padding(.top, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProcessRow: View {
    let entry: ProcessEntry
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(format: "%.1f%%", entry.cpuPercent))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(entry.cpuPercent > 50 ? .red : .secondary)
                .frame(width: 36)
            Text(String(format: "%.0fM", entry.memoryMB))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary).frame(width: 44)
            if isHovered {
                Button {
                    SystemMonitorManager.shared.kill(pid: entry.pid)
                } label: {
                    Image(systemName: "xmark.circle").font(.system(size: 10)).foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Force quit")
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(isHovered ? Color.secondary.opacity(0.06) : .clear)
        .onHover { isHovered = $0 }
    }
}

private struct DiskStat: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(color)
            Text(label).font(.system(size: 9)).foregroundStyle(.tertiary)
        }
    }
}

private struct NetStat: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(color)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
