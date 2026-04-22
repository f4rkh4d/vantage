import AppKit
import ApplicationServices

@MainActor
final class WindowManagerManager: ObservableObject {
    static let shared = WindowManagerManager()
    private init() {}

    // Height of the primary screen — single source of truth for NS↔AX flip math
    private var primaryScreenHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 900
    }

    func frontmostWindow() -> AXUIElement? {
        guard Permissions.isAccessibilityGranted() else { return nil }
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef)
        guard result == .success, let window = windowRef else { return nil }
        return (window as! AXUIElement) // safe: AX API guarantees AXUIElement for kAXFocusedWindowAttribute
    }

    func screenFrameForFrontmostWindow() -> CGRect {
        if let window = frontmostWindow(), let nsFrame = windowNSFrame(window) {
            let center = CGPoint(x: nsFrame.midX, y: nsFrame.midY)
            for screen in NSScreen.screens where screen.frame.contains(center) {
                return toAXFrame(screen.visibleFrame)
            }
        }
        let visible = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return toAXFrame(visible)
    }

    @discardableResult
    func snap(to zone: SnapZone) -> Bool {
        guard let window = frontmostWindow() else { return false }
        let target = zone.axFrame(in: screenFrameForFrontmostWindow())
        return setWindowFrame(window, to: target)
    }

    // MARK: - Private helpers

    private func windowNSFrame(_ window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posRef, let sizeRef else { return nil }
        // CF types bridge unconditionally; AXValueGetValue validates the actual AXValue type internally
        let posAX = posRef as! AXValue
        let sizeAX = sizeRef as! AXValue
        var axPos = CGPoint.zero
        var axSize = CGSize.zero
        guard AXValueGetValue(posAX, .cgPoint, &axPos),
              AXValueGetValue(sizeAX, .cgSize, &axSize) else { return nil }
        let nsY = primaryScreenHeight - axPos.y - axSize.height
        return CGRect(x: axPos.x, y: nsY, width: axSize.width, height: axSize.height)
    }

    @discardableResult
    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) -> Bool {
        var origin = frame.origin
        var size = frame.size
        guard let posValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else { return false }
        let posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        return posResult == .success && sizeResult == .success
    }

    private func toAXFrame(_ nsFrame: CGRect) -> CGRect {
        let axY = primaryScreenHeight - nsFrame.origin.y - nsFrame.height
        return CGRect(x: nsFrame.origin.x, y: axY, width: nsFrame.width, height: nsFrame.height)
    }
}
