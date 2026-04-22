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
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let appState = AppState()
    private var pollingTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Permissions.requestAccessibilityIfNeeded()
        setupStatusItem()
        setupPopover()
        pollingTimer = StatusPoller.startPolling(appState: appState)
        setupWindowManagerHotkeys()
    }

    private func setupWindowManagerHotkeys() {
        let engine = HotkeyEngine.shared
        for zone in SnapZone.all {
            engine.register(keyCode: zone.keyCode) {
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
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenubarView().environment(appState)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pollingTimer?.invalidate()
    }
}
