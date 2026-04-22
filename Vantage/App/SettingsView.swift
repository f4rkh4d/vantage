import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Vantage Settings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Module.allCases) { module in
                        SettingsRow(module: module)
                    }
                }
            }
        }
        .frame(width: 520, height: 440)
        .background(.ultraThinMaterial)
    }
}

private struct SettingsRow: View {
    let module: Module
    @State private var isEnabled = true

    var body: some View {
        HStack(spacing: 14) {
            // Module icon with accent tint
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(module.accentColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: module.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(module.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(module.title)
                    .font(.system(size: 13, weight: .medium))
                Text("Module settings coming soon")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.8)
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        Divider().padding(.leading, 66)
    }
}
