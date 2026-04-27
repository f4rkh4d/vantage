import AppKit

struct HotkeyRegistration {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let handler: () -> Void
}

@MainActor
final class HotkeyEngine {
    static let shared = HotkeyEngine()
    private var monitor: Any?
    private var registrations: [HotkeyRegistration] = []

    private init() {}

    func register(keyCode: UInt16, modifiers: NSEvent.ModifierFlags = [.control, .option], handler: @escaping () -> Void) {
        registrations.append(HotkeyRegistration(keyCode: keyCode, modifiers: modifiers, handler: handler))
    }

    func unregisterAll() { registrations = [] }

    func start() {
        guard monitor == nil else { return }
        guard Permissions.isAccessibilityGranted() else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let code = event.keyCode
            Task { @MainActor in
                for reg in self.registrations where reg.keyCode == code && flags == reg.modifiers {
                    reg.handler()
                }
            }
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }

    func reload() {
        stop()
        start()
    }
}
