import SwiftUI

struct ScrollReverserView: View {
    @AppStorage("srEnabled")         private var enabled        = false
    @AppStorage("srReverseMouse")    private var reverseMouse   = true
    @AppStorage("srReverseTrackpad") private var reverseTrackpad = false

    // Derived from whether the CGEventTap actually created successfully.
    @State private var hasPermission = ScrollReverserManager.shared.eventTapActive
    private let retryTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !hasPermission {
                accessPrompt
            } else {
                rows
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { probe() }
        .onReceive(retryTimer) { _ in
            if !hasPermission { probe() }
        }
    }

    // Try to start the tap; use the result as the permission indicator.
    private func probe() {
        if enabled {
            let ok = ScrollReverserManager.shared.start()
            hasPermission = ok
        } else {
            // Even if disabled, test by attempting a tap and tearing it down immediately.
            let ok = ScrollReverserManager.shared.startTap()
            if ok && !enabled { ScrollReverserManager.shared.stop() }
            hasPermission = ok
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Module.scrollReverser.accentColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: Module.scrollReverser.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Module.scrollReverser.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Scroll Reverser")
                    .font(.system(size: 13, weight: .semibold))
                Text(enabled && hasPermission ? "Active" : "Inactive")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
            Toggle("", isOn: $enabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(!hasPermission)
                .onChange(of: enabled) { _, new in
                    ScrollReverserManager.shared.isEnabled = new
                }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            Divider().opacity(0)
            row(icon: "computermouse", title: "Mouse",
                subtitle: "Reverse scroll wheel direction",
                binding: $reverseMouse) { ScrollReverserManager.shared.reverseMouse = $0 }

            Divider().padding(.leading, 48)

            row(icon: "hand.point.up", title: "Trackpad",
                subtitle: "Reverse two-finger scroll",
                binding: $reverseTrackpad) { ScrollReverserManager.shared.reverseTrackpad = $0 }

            Divider().padding(.leading, 48)

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11)).foregroundStyle(.tertiary)
                Text("Mouse = no scroll phase · Trackpad = gesture with phases")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
    }

    private func row(icon: String, title: String, subtitle: String,
                     binding: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundStyle(.secondary).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch).labelsHidden()
                .disabled(!enabled)
                .onChange(of: binding.wrappedValue) { _, new in onChange(new) }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .opacity(enabled ? 1 : 0.4)
    }

    private var accessPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.shield")
                .font(.system(size: 32)).foregroundStyle(.secondary)
            Text("Accessibility Access Required")
                .font(.system(size: 13, weight: .semibold))
            Text("Scroll Reverser needs Accessibility permission\nto intercept scroll events system-wide.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 20)
            Button("Open System Settings") {
                let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                AXIsProcessTrustedWithOptions(opts)
            }
            .buttonStyle(.borderedProminent).controlSize(.small)
            Text("After granting, relaunch Vantage once.")
                .font(.system(size: 10)).foregroundStyle(.tertiary)
            Button("Relaunch Now") { relaunch() }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Module.scrollReverser.accentColor)
        }
        .padding(24).frame(maxWidth: .infinity)
    }

    private func relaunch() {
        guard let url = Bundle.main.bundleURL as URL? else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [url.path]
        try? task.run()
        NSApp.terminate(nil)
    }
}
