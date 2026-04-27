import SwiftUI

struct ScrollReverserView: View {
    @AppStorage("srEnabled")         private var enabled        = false
    @AppStorage("srReverseMouse")    private var reverseMouse   = true
    @AppStorage("srReverseTrackpad") private var reverseTrackpad = false
    @State private var hasAccess = AXIsProcessTrusted()
    @State private var tapFailed  = false  // permission granted but tap still won't create
    private let permissionTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !hasAccess {
                accessPrompt
            } else if tapFailed {
                relaunchPrompt
            } else {
                rows
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { checkAccess() }
        .onReceive(permissionTimer) { _ in checkAccess() }
    }

    private func checkAccess() {
        let trusted = AXIsProcessTrusted()
        hasAccess = trusted
        guard trusted else { return }
        if enabled && ScrollReverserManager.shared.eventTapActive == false {
            ScrollReverserManager.shared.start()
            // Give it a moment, then check if tap actually started
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if enabled && !ScrollReverserManager.shared.eventTapActive {
                    tapFailed = true
                }
            }
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
                Text(enabled ? "Active" : "Inactive")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
            Toggle("", isOn: $enabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(!hasAccess)
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
            Text("Scroll Reverser intercepts scroll events system-wide.\nmacOS requires Accessibility permission for this.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 20)
            Button("Open System Settings") {
                ScrollReverserManager.shared.requestAccessibility()
            }
            .buttonStyle(.borderedProminent).controlSize(.small)
        }
        .padding(24).frame(maxWidth: .infinity)
    }

    private var relaunchPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 32)).foregroundStyle(Module.scrollReverser.accentColor)
            Text("Relaunch Required")
                .font(.system(size: 13, weight: .semibold))
            Text("macOS granted permission but requires a relaunch\nfor the event tap to activate.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 20)
            Button("Relaunch Vantage") {
                relaunch()
            }
            .buttonStyle(.borderedProminent).controlSize(.small)
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
