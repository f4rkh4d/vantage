import AppKit
import ApplicationServices

@MainActor
final class WindowManagerManager: ObservableObject {
    static let shared = WindowManagerManager()
    private init() {}

    // Returns the frontmost window's AXUIElement, or nil if inaccessible
    func frontmostWindow() -> AXUIElement? {
        guard Permissions.isAccessibilityGranted() else { return nil }
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef)
        guard result == .success, let window = windowRef else { return nil }
        // swiftlint:disable:next force_cast
        return (window as! AXUIElement)
    }

    // Returns the screen the frontmost window is on, in AX coordinates (top-left origin, y↓)
    func screenFrameForFrontmostWindow() -> CGRect {
        // Try to find which screen the frontmost window's center is on
        if let window = frontmostWindow(), let nsFrame = windowNSFrame(window) {
            let center = CGPoint(x: nsFrame.midX, y: nsFrame.midY)
            for screen in NSScreen.screens {
                if screen.frame.contains(center) {
                    return toAXFrame(screen.visibleFrame)
                }
            }
        }
        // Fall back to main screen
        let visible = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return toAXFrame(visible)
    }

    // Moves + resizes the frontmost window to the given snap zone
    @discardableResult
    func snap(to zone: SnapZone) -> Bool {
        guard let window = frontmostWindow() else { return false }
        let screenFrame = screenFrameForFrontmostWindow()
        let targetFrame = zone.axFrame(in: screenFrame)
        setWindowFrame(window, to: targetFrame)
        return true
    }

    // MARK: - Private helpers

    private func windowNSFrame(_ window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let posValue = posRef, let sizeValue = sizeRef else { return nil }
        var axPos = CGPoint.zero
        var axSize = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &axPos)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &axSize)
        // Convert from AX (top-left origin) to NS (bottom-left origin) for screen matching
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let nsY = primaryHeight - axPos.y - axSize.height
        return CGRect(x: axPos.x, y: nsY, width: axSize.width, height: axSize.height)
    }

    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) {
        var origin = frame.origin
        var size = frame.size
        if let posValue = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }

    // Convert NSScreen.visibleFrame (bottom-left origin) to AX coordinates (top-left origin)
    private func toAXFrame(_ nsFrame: CGRect) -> CGRect {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? nsFrame.height
        let axY = primaryHeight - nsFrame.origin.y - nsFrame.height
        return CGRect(x: nsFrame.origin.x, y: axY,
                     width: nsFrame.width, height: nsFrame.height)
    }
}
