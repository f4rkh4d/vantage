import SwiftUI

struct DisplayControlsView: View {
    @ObservedObject private var manager = DisplayControlsManager.shared
    private let accent = Module.displayControls.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            buttonRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { manager.refresh() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.displayControls.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Display Controls")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(manager.displays.count) display\(manager.displays.count == 1 ? "" : "s")")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if manager.displays.isEmpty {
                    Text("No displays detected")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .padding(14)
                } else {
                    ForEach(manager.displays) { display in
                        DisplayCard(display: display, accent: accent)
                    }
                }
            }
            .padding(14)
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 8) {
            Button {
                manager.openDisplaySettings()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "display").font(.system(size: 11))
                    Text("Display Settings")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button {
                manager.openNightShiftSettings()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "moon.fill").font(.system(size: 11))
                    Text("Night Shift")
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
        .padding(.horizontal, 14).padding(.vertical, 10)
    }
}

private struct DisplayCard: View {
    let display: DisplayInfo
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(display.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                if display.isMain {
                    badge("Main", color: accent)
                }
                if display.scaleFactor > 1 {
                    badge("Retina", color: .secondary)
                }
            }

            HStack(spacing: 16) {
                infoItem(label: "Resolution",
                         value: "\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                infoItem(label: "Scale", value: "\(Int(display.scaleFactor))×")
                infoItem(label: "Refresh", value: "\(Int(display.refreshRate)) Hz")
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9)).foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 11, weight: .medium))
        }
    }
}
