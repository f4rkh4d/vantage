import SwiftUI

struct WindowManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var hoveredZone: SnapZone? = nil
    @State private var flashedZone: SnapZone? = nil
    @State private var noWindowAlert = false
    private let manager = WindowManagerManager.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            zoneGrid
                .padding(14)
            Divider()
            shortcutHint
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("No window found", isPresented: $noWindowAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Grant Accessibility access and focus a window first.")
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Module.windowManager.accentColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: Module.windowManager.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Module.windowManager.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Window Manager")
                    .font(.system(size: 13, weight: .semibold))
                Text("Click a zone to snap the front window")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var zoneGrid: some View {
        VStack(spacing: 6) {
            // 3×3 main grid (rows 0-2)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(SnapZone.all.filter { $0.gridRow <= 2 }) { zone in
                    ZoneButton(zone: zone, isHovered: hoveredZone == zone,
                               isFlashed: flashedZone == zone) {
                        triggerSnap(zone)
                    }
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            hoveredZone = isHovered ? zone : nil
                        }
                    }
                }
            }

            // Thirds row (row 3)
            HStack(spacing: 6) {
                ForEach(SnapZone.all.filter { $0.gridRow == 3 }) { zone in
                    ZoneButton(zone: zone, isHovered: hoveredZone == zone,
                               isFlashed: flashedZone == zone) {
                        triggerSnap(zone)
                    }
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            hoveredZone = isHovered ? zone : nil
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Two-thirds row (row 4)
            HStack(spacing: 6) {
                let zones = SnapZone.all.filter { $0.gridRow == 4 }
                if let z0 = zones.first {
                    ZoneButton(zone: z0, isHovered: hoveredZone == z0,
                               isFlashed: flashedZone == z0) { triggerSnap(z0) }
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.12)) { hoveredZone = isHovered ? z0 : nil }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(idealWidth: .infinity)
                }
                if zones.count > 1 {
                    let z1 = zones[1]
                    ZoneButton(zone: z1, isHovered: hoveredZone == z1,
                               isFlashed: flashedZone == z1) { triggerSnap(z1) }
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.12)) { hoveredZone = isHovered ? z1 : nil }
                        }
                        .frame(maxWidth: .infinity)
                }
            }

            // Center float (row 5) — full width
            if let centerZone = SnapZone.all.first(where: { $0.id == "center" }) {
                ZoneButton(zone: centerZone, isHovered: hoveredZone == centerZone,
                           isFlashed: flashedZone == centerZone) {
                    triggerSnap(centerZone)
                }
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        hoveredZone = isHovered ? centerZone : nil
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var shortcutHint: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Text("Hold ⌃⌥ + shortcut key to snap from anywhere")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func triggerSnap(_ zone: SnapZone) {
        let success = manager.snap(to: zone)
        if success {
            withAnimation(.easeOut(duration: 0.1)) { flashedZone = zone }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation { flashedZone = nil }
            }
        } else {
            noWindowAlert = true
        }
    }
}

// MARK: - ZoneButton

private struct ZoneButton: View {
    let zone: SnapZone
    let isHovered: Bool
    let isFlashed: Bool
    let action: () -> Void

    private let accent = Module.windowManager.accentColor

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZonePreview(zone: zone, isHovered: isHovered, isFlashed: isFlashed)
                    .frame(height: 38)
                Text(zone.shortcut)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(isHovered ? AnyShapeStyle(accent) : AnyShapeStyle(.tertiary))
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isFlashed
                          ? accent.opacity(0.2)
                          : (isHovered ? accent.opacity(0.08) : Color.secondary.opacity(0.06)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isHovered ? accent.opacity(0.3) : Color.clear, lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .help(zone.title)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isFlashed)
    }
}

// MARK: - ZonePreview (mini screen diagram)

private struct ZonePreview: View {
    let zone: SnapZone
    let isHovered: Bool
    let isFlashed: Bool

    private let accent = Module.windowManager.accentColor

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                // Screen outline
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )

                // Highlighted zone
                let zoneRect = zoneRect(in: CGSize(width: w, height: h))
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        isFlashed
                            ? accent.opacity(0.9)
                            : (isHovered ? accent.opacity(0.6) : accent.opacity(0.25))
                    )
                    .frame(width: zoneRect.width, height: zoneRect.height)
                    .offset(x: zoneRect.origin.x, y: zoneRect.origin.y)
            }
        }
    }

    // Maps the zone to a pixel rect inside the preview bounds
    private func zoneRect(in size: CGSize) -> CGRect {
        let w = size.width
        let h = size.height
        let u = w / 3
        switch zone.id {
        case "leftHalf":        return CGRect(x: 0,     y: 0,   width: w/2,  height: h)
        case "rightHalf":       return CGRect(x: w/2,   y: 0,   width: w/2,  height: h)
        case "topHalf":         return CGRect(x: 0,     y: 0,   width: w,    height: h/2)
        case "bottomHalf":      return CGRect(x: 0,     y: h/2, width: w,    height: h/2)
        case "leftThird":       return CGRect(x: 0,     y: 0,   width: u,    height: h)
        case "centerThird":     return CGRect(x: u,     y: 0,   width: u,    height: h)
        case "rightThird":      return CGRect(x: 2*u,   y: 0,   width: u,    height: h)
        case "leftTwoThirds":   return CGRect(x: 0,     y: 0,   width: 2*u,  height: h)
        case "rightTwoThirds":  return CGRect(x: u,     y: 0,   width: 2*u,  height: h)
        case "fullscreen":      return CGRect(x: 0,     y: 0,   width: w,    height: h)
        case "topLeft":         return CGRect(x: 0,     y: 0,   width: w/2,  height: h/2)
        case "topRight":        return CGRect(x: w/2,   y: 0,   width: w/2,  height: h/2)
        case "bottomLeft":      return CGRect(x: 0,     y: h/2, width: w/2,  height: h/2)
        case "bottomRight":     return CGRect(x: w/2,   y: h/2, width: w/2,  height: h/2)
        case "center":
            let margin = w * 0.08
            return CGRect(x: margin, y: margin * (h / w), width: w - 2*margin, height: h - 2*margin*(h/w))
        default:                return CGRect(x: 0,     y: 0,   width: w,    height: h)
        }
    }
}
