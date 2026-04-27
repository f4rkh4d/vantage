import SwiftUI
import AppKit

struct WindowManagerView: View {
    @Environment(AppState.self) private var appState
    @State private var tab: Tab = .grid
    @State private var hoveredZone: SnapZone? = nil
    @State private var flashedZone: SnapZone? = nil
    @State private var noWindowAlert = false
    @State private var axGranted = Permissions.isAccessibilityGranted()
    @State private var zones = SnapZone.all
    private let manager = WindowManagerManager.shared
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    enum Tab { case grid, shortcuts }

    var body: some View {
        VStack(spacing: 0) {
            if !axGranted {
                permissionBanner
                Divider()
            }
            header
            Divider()
            tabPicker
            Divider()
            if tab == .grid {
                zoneGrid.padding(14)
                Divider()
                shortcutHint
            } else {
                shortcutList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            axGranted = Permissions.isAccessibilityGranted()
            zones = SnapZone.all
        }
        .alert("No window found", isPresented: $noWindowAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Grant Accessibility access and focus a window first.")
        }
    }

    // MARK: - Subviews

    private var permissionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield").foregroundStyle(.orange).font(.system(size: 13))
            Text("Accessibility access required").font(.system(size: 11, weight: .medium))
            Spacer()
            Button("Grant") {
                Permissions.requestAccessibilityIfNeeded()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    axGranted = Permissions.isAccessibilityGranted()
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.orange).buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color.orange.opacity(0.08))
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Module.windowManager.accentColor.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.windowManager.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Module.windowManager.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Window Manager").font(.system(size: 13, weight: .semibold))
                Text(tab == .grid ? "Click to snap · or use a hotkey" : "Click shortcut to rebind")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabBtn("Grid", tag: .grid)
            Divider().frame(height: 28)
            tabBtn("Shortcuts", tag: .shortcuts)
        }
    }

    private func tabBtn(_ label: String, tag: Tab) -> some View {
        Button(label) { tab = tag }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: tab == tag ? .semibold : .regular))
            .foregroundStyle(tab == tag ? Module.windowManager.accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(tab == tag ? Module.windowManager.accentColor.opacity(0.07) : Color.clear)
    }

    // MARK: - Grid

    private var zoneGrid: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(zones.filter { $0.gridRow <= 2 }) { zone in
                    ZoneButton(zone: zone, isHovered: hoveredZone == zone, isFlashed: flashedZone == zone) {
                        triggerSnap(zone)
                    }
                    .onHover { hoveredZone = $0 ? zone : nil }
                }
            }
            HStack(spacing: 6) {
                ForEach(zones.filter { $0.gridRow == 3 }) { zone in
                    ZoneButton(zone: zone, isHovered: hoveredZone == zone, isFlashed: flashedZone == zone) {
                        triggerSnap(zone)
                    }
                    .onHover { hoveredZone = $0 ? zone : nil }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 6) {
                let row4 = zones.filter { $0.gridRow == 4 }
                ForEach(row4) { zone in
                    ZoneButton(zone: zone, isHovered: hoveredZone == zone, isFlashed: flashedZone == zone) {
                        triggerSnap(zone)
                    }
                    .onHover { hoveredZone = $0 ? zone : nil }
                    .frame(maxWidth: .infinity)
                }
            }
            if let center = zones.first(where: { $0.id == "center" }) {
                ZoneButton(zone: center, isHovered: hoveredZone == center, isFlashed: flashedZone == center) {
                    triggerSnap(center)
                }
                .onHover { hoveredZone = $0 ? center : nil }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var shortcutHint: some View {
        HStack {
            Image(systemName: "keyboard").font(.system(size: 9)).foregroundStyle(.tertiary)
            Text("Global hotkeys active · Tap Shortcuts to rebind")
                .font(.system(size: 9)).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Shortcuts list

    private var shortcutList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(zones) { zone in
                    ShortcutRow(zone: zone) {
                        zones = SnapZone.all
                        reloadHotkeys()
                    }
                    if zone.id != zones.last?.id {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Actions

    private func triggerSnap(_ zone: SnapZone) {
        guard manager.snap(to: zone) else { noWindowAlert = true; return }
        withAnimation(.easeOut(duration: 0.1)) { flashedZone = zone }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation { flashedZone = nil }
        }
    }

    private func reloadHotkeys() {
        let engine = HotkeyEngine.shared
        engine.unregisterAll()
        for zone in SnapZone.all {
            engine.register(keyCode: zone.effectiveKeyCode, modifiers: zone.effectiveModifiers) {
                WindowManagerManager.shared.snap(to: zone)
            }
        }
        engine.reload()
    }
}

// MARK: - ShortcutRow

private struct ShortcutRow: View {
    let zone: SnapZone
    let onSave: () -> Void

    @State private var isRecording = false
    @State private var keyMonitor: Any?
    @State private var currentBinding: String

    init(zone: SnapZone, onSave: @escaping () -> Void) {
        self.zone = zone
        self.onSave = onSave
        _currentBinding = State(initialValue: zone.shortcut)
    }

    private let accent = Module.windowManager.accentColor

    var body: some View {
        HStack(spacing: 12) {
            Text(zone.title)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if isRecording { stopRecording() } else { startRecording() }
            } label: {
                Text(isRecording ? "Press a key…" : currentBinding)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRecording ? .primary : accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isRecording ? accent.opacity(0.12) : accent.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isRecording ? accent.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isRecording)

            if zone.customBinding != nil {
                Button {
                    SnapZone.saveCustomBinding(zoneId: zone.id, binding: nil)
                    currentBinding = zone.defaultShortcut
                    onSave()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Reset to default")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !mods.isEmpty, event.keyCode != 53 else {
                stopRecording()
                return nil
            }
            let binding = HotkeyBinding(keyCode: event.keyCode, modifierFlags: Int(mods.rawValue))
            SnapZone.saveCustomBinding(zoneId: zone.id, binding: binding)
            currentBinding = binding.displayString
            stopRecording()
            onSave()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
}

// MARK: - ZoneButton

private struct ZoneButton: View {
    let zone: SnapZone; let isHovered: Bool; let isFlashed: Bool; let action: () -> Void
    private let accent = Module.windowManager.accentColor

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZonePreview(zone: zone, isHovered: isHovered, isFlashed: isFlashed).frame(height: 38)
                Text(zone.shortcut)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(isHovered ? AnyShapeStyle(accent) : AnyShapeStyle(.tertiary))
            }
            .padding(6).frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isFlashed ? accent.opacity(0.2) : (isHovered ? accent.opacity(0.08) : Color.secondary.opacity(0.06)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isHovered ? accent.opacity(0.3) : Color.clear, lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain).help(zone.title)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isFlashed)
    }
}

// MARK: - ZonePreview

private struct ZonePreview: View {
    let zone: SnapZone; let isHovered: Bool; let isFlashed: Bool
    private let accent = Module.windowManager.accentColor

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                let r = zoneRect(in: CGSize(width: w, height: h))
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isFlashed ? accent.opacity(0.9) : (isHovered ? accent.opacity(0.6) : accent.opacity(0.25)))
                    .frame(width: r.width, height: r.height)
                    .offset(x: r.origin.x, y: r.origin.y)
            }
        }
    }

    private func zoneRect(in size: CGSize) -> CGRect {
        let w = size.width; let h = size.height; let u = w / 3
        switch zone.id {
        case "leftHalf":       return CGRect(x:0,     y:0,   width:w/2, height:h)
        case "rightHalf":      return CGRect(x:w/2,   y:0,   width:w/2, height:h)
        case "topHalf":        return CGRect(x:0,     y:0,   width:w,   height:h/2)
        case "bottomHalf":     return CGRect(x:0,     y:h/2, width:w,   height:h/2)
        case "leftThird":      return CGRect(x:0,     y:0,   width:u,   height:h)
        case "centerThird":    return CGRect(x:u,     y:0,   width:u,   height:h)
        case "rightThird":     return CGRect(x:2*u,   y:0,   width:u,   height:h)
        case "leftTwoThirds":  return CGRect(x:0,     y:0,   width:2*u, height:h)
        case "rightTwoThirds": return CGRect(x:u,     y:0,   width:2*u, height:h)
        case "fullscreen":     return CGRect(x:0,     y:0,   width:w,   height:h)
        case "topLeft":        return CGRect(x:0,     y:0,   width:w/2, height:h/2)
        case "topRight":       return CGRect(x:w/2,   y:0,   width:w/2, height:h/2)
        case "bottomLeft":     return CGRect(x:0,     y:h/2, width:w/2, height:h/2)
        case "bottomRight":    return CGRect(x:w/2,   y:h/2, width:w/2, height:h/2)
        case "center":
            let m = w * 0.08
            return CGRect(x:m, y:m*(h/w), width:w-2*m, height:h-2*m*(h/w))
        default: return CGRect(x:0, y:0, width:w, height:h)
        }
    }
}
