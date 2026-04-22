import AppKit

// Listens for global keyboard shortcuts when app is in background.
// Requires Accessibility permission.
@MainActor
final class HotkeyEngine {
    static let shared = HotkeyEngine()
    private var monitor: Any?
    private var handlers: [UInt16: () -> Void] = [:]

    private init() {}

    func register(keyCode: UInt16, handler: @escaping () -> Void) {
        handlers[keyCode] = handler
    }

    func start() {
        guard monitor == nil else { return }
        guard Permissions.isAccessibilityGranted() else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            // Check ⌃⌥ modifier (control + option)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.control, .option] {
                Task { @MainActor in
                    self.handlers[event.keyCode]?()
                }
            }
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
    }
}
