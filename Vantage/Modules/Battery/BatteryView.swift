import SwiftUI

struct BatteryView: View {
    @ObservedObject private var manager = BatteryPowerManager.shared
    private let accent = Module.battery.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            levelSection
            Divider()
            detailRows
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { BatteryPowerManager.shared.start() }
        .onDisappear { BatteryPowerManager.shared.stop() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.battery.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("Battery & Power")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var statusLabel: String {
        if manager.isCharging { return "Charging" }
        if manager.isPluggedIn { return "Full" }
        return "On Battery"
    }

    private var levelSection: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.0f%%", manager.level * 100))
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(levelColor)

            Text(statusLabel)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(levelColor)
                        .frame(width: geo.size.width * manager.level, height: 6)
                        .animation(.spring(response: 0.6), value: manager.level)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    private var levelColor: Color {
        if manager.isCharging { return accent }
        if manager.level > 0.20 { return accent }
        if manager.level > 0.10 { return .yellow }
        return .red
    }

    private var detailRows: some View {
        VStack(spacing: 0) {
            if let timeInterval = manager.isCharging ? manager.timeToFull : manager.timeToEmpty {
                InfoRow(
                    label: manager.isCharging ? "Time to full" : "Time to empty",
                    value: formatTime(timeInterval)
                )
                Divider().padding(.leading, 14)
            }

            InfoRow(label: "Battery Health", value: String(format: "%.0f%%", manager.health * 100),
                    valueColor: healthColor)
            Divider().padding(.leading, 14)

            InfoRow(label: "Cycle Count", value: "\(manager.cycleCount)")
            Divider().padding(.leading, 14)

            InfoRow(label: "Temperature", value: String(format: "%.1f °C", manager.temperature))
            Divider().padding(.leading, 14)

            InfoRow(label: "Capacity",
                    value: "\(manager.currentCapacityMAh) / \(manager.designCapacityMAh) mAh")
            Divider().padding(.leading, 14)

            InfoRow(label: "Power Source", value: manager.powerSource)
        }
    }

    private var healthColor: Color {
        if manager.health > 0.80 { return accent }
        if manager.health > 0.60 { return .yellow }
        return .red
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}
