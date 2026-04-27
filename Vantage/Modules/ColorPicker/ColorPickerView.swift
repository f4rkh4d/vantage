import SwiftUI
import AppKit

struct ColorPickerView: View {
    @ObservedObject private var manager = ColorPickerManager.shared
    @State private var selectedFormat: ColorPickerManager.CopyFormat = .hex
    @State private var copiedId: UUID?

    private let accent = Module.colorPicker.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            pickButton
            Divider()
            formatPicker
            Divider()
            historyGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.colorPicker.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Color Picker")
                    .font(.system(size: 13, weight: .semibold))
                Text(manager.history.isEmpty ? "No colors yet" : "\(manager.history.count) picked")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
            if !manager.history.isEmpty {
                Button("Clear") { manager.clear() }
                    .font(.system(size: 10))
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var pickButton: some View {
        Button {
            manager.pick()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: manager.isPicking ? "eyedropper.halffull" : "eyedropper")
                    .font(.system(size: 14, weight: .semibold))
                Text(manager.isPicking ? "Click anywhere…" : "Pick Color")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(accent.opacity(manager.isPicking ? 0.08 : 0.12))
            .foregroundStyle(accent)
        }
        .buttonStyle(.plain)
        .disabled(manager.isPicking)
    }

    private var formatPicker: some View {
        HStack(spacing: 0) {
            ForEach(ColorPickerManager.CopyFormat.allCases, id: \.self) { fmt in
                Button(fmt.rawValue) {
                    selectedFormat = fmt
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: selectedFormat == fmt ? .semibold : .regular))
                .foregroundStyle(selectedFormat == fmt ? accent : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedFormat == fmt ? accent.opacity(0.08) : Color.clear)
            }
        }
    }

    private var historyGrid: some View {
        Group {
            if manager.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "eyedropper")
                        .font(.system(size: 28)).foregroundStyle(.quaternary)
                    Text("Pick a color to start")
                        .font(.system(size: 11)).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 6), count: 8), spacing: 6) {
                        ForEach(manager.history) { color in
                            colorSwatch(color)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    private func colorSwatch(_ color: ColorPickerManager.PickedColor) -> some View {
        let isCopied = copiedId == color.id
        return Button {
            manager.copyToClipboard(color, format: selectedFormat)
            copiedId = color.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copiedId = nil }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(color.nsColor))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .help("\(color.hex)\n\(color.rgb)")
    }
}
