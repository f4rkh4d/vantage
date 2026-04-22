import SwiftUI

struct StatusBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 16) {
            // CPU
            StatusMetric(
                icon: "cpu",
                label: "CPU",
                value: appState.cpuUsage,
                gradient: Gradient(colors: [Color(red: 0.25, green: 0.85, blue: 0.55),
                                            Color(red: 0.10, green: 0.75, blue: 0.65)])
            )

            // RAM
            StatusMetric(
                icon: "memorychip",
                label: "RAM",
                value: appState.ramUsage,
                gradient: Gradient(colors: [Color(red: 0.38, green: 0.55, blue: 1.0),
                                            Color(red: 0.55, green: 0.35, blue: 0.90)])
            )

            Spacer()

            // Battery
            BatteryWidget(level: appState.batteryLevel, isCharging: appState.isCharging)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.5)
        }
    }
}

private struct StatusMetric: View {
    let icon: String
    let label: String
    let value: Double       // 0.0–1.0
    let gradient: Gradient

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 12)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))

                    Capsule()
                        .fill(LinearGradient(gradient: gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * value))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
                }
            }
            .frame(width: 44, height: 3)

            Text(String(format: "%2.0f%%", value * 100))
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .trailing)
        }
    }
}

private struct BatteryWidget: View {
    let level: Double
    let isCharging: Bool

    private var barColor: Color {
        if isCharging { return Color(red: 0.25, green: 0.85, blue: 0.55) }
        if level < 0.20 { return .red }
        if level < 0.40 { return .orange }
        return Color(red: 0.25, green: 0.85, blue: 0.55)
    }

    var body: some View {
        HStack(spacing: 4) {
            // Battery body
            ZStack(alignment: .leading) {
                // Shell
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 0.75)
                    .frame(width: 22, height: 11)

                // Fill
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(barColor)
                    .frame(width: max(2, 20 * level), height: 8)
                    .padding(.leading, 1)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: level)

                // Bolt icon overlay when charging
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 22, height: 11)
                }
            }
            // Battery nub
            .overlay(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 2, height: 5)
                    .offset(x: 3)
            }
            .padding(.trailing, 3)

            Text(String(format: "%2.0f%%", level * 100))
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
