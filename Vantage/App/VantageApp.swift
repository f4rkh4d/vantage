import SwiftUI
import AppKit

@main
struct VantageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let appState = AppState()
    private var pollingTimer: Timer?
    private var rightClickMonitor: Any?
    private var lastPopoverCloseTime: Date = .distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
        pollingTimer = StatusPoller.startPolling(appState: appState)
        setupWindowManagerHotkeys()
        ClipboardManager.shared.start()
        SystemMonitorManager.shared.start()
        ScrollReverserManager.shared.start()
    }

    private func setupWindowManagerHotkeys() {
        let engine = HotkeyEngine.shared
        for zone in SnapZone.all {
            engine.register(keyCode: zone.effectiveKeyCode, modifiers: zone.effectiveModifiers) {
                WindowManagerManager.shared.snap(to: zone)
            }
        }
        engine.start()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "square.grid.2x2.fill",
                            accessibilityDescription: "Vantage")
        image?.isTemplate = true
        button.image = image
        button.action = #selector(handleStatusItemClick)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseDown])
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MenubarView().environment(appState)
        )
    }

    func popoverDidClose(_ notification: Notification) {
        lastPopoverCloseTime = Date()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Vantage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        guard let button = statusItem.button else { return }
        // popUp blocks until dismissed — no recursion, no state corruption
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseDown {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Guard against bounce: transient dismiss fires popoverDidClose, then the
            // same click triggers this — skip if popover closed < 150 ms ago.
            guard Date().timeIntervalSince(lastPopoverCloseTime) > 0.15 else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollingTimer?.invalidate()
        HotkeyEngine.shared.stop()
        ClipboardManager.shared.stop()
        SystemMonitorManager.shared.stop()
        ScrollReverserManager.shared.stop()
        if let m = rightClickMonitor { NSEvent.removeMonitor(m) } // kept for safety
    }
}
