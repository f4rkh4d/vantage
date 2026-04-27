import AppKit
import CoreGraphics

final class ScrollReverserManager {
    static let shared = ScrollReverserManager()
    private init() {}

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Cached values read inside the hot event-tap callback — avoids UserDefaults I/O per scroll event.
    fileprivate var cachedReverseMouse: Bool = true
    fileprivate var cachedReverseTrackpad: Bool = false

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "srEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "srEnabled")
            if newValue { startTap() } else { stopTap() }
        }
    }

    // Reverse mouse (no scroll phase = hardware mouse wheel)
    var reverseMouse: Bool {
        get { UserDefaults.standard.object(forKey: "srReverseMouse") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "srReverseMouse")
            cachedReverseMouse = newValue
        }
    }

    // Reverse trackpad (has scroll phase = gesture-based)
    var reverseTrackpad: Bool {
        get { UserDefaults.standard.bool(forKey: "srReverseTrackpad") }
        set {
            UserDefaults.standard.set(newValue, forKey: "srReverseTrackpad")
            cachedReverseTrackpad = newValue
        }
    }

    @discardableResult
    func start() -> Bool {
        cachedReverseMouse = UserDefaults.standard.object(forKey: "srReverseMouse") as? Bool ?? true
        cachedReverseTrackpad = UserDefaults.standard.bool(forKey: "srReverseTrackpad")
        guard isEnabled else { return true }
        return startTap()
    }

    func stop() { stopTap() }

    var hasAccessibility: Bool { AXIsProcessTrusted() }
    var eventTapActive: Bool { eventTap != nil }

    func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    // Returns true if tap was successfully created, false if permission missing.
    @discardableResult
    func startTap() -> Bool {
        guard eventTap == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: scrollCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap else { return false }
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    private func stopTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func handle(event: CGEvent) -> Unmanaged<CGEvent>? {
        let scrollPhase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        let isMouse = scrollPhase == 0 && momentumPhase == 0
        guard isMouse ? cachedReverseMouse : cachedReverseTrackpad else {
            return Unmanaged.passRetained(event)
        }
        let d1  = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let d2  = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
        let fp1 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let fp2 = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        let pt1 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        let pt2 = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1,      value: -d1)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2,      value: -d2)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -fp1)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2, value: -fp2)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1,  value: -pt1)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2,  value: -pt2)
        return Unmanaged.passRetained(event)
    }
}

private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard type == .scrollWheel, let ptr = userInfo else {
        return Unmanaged.passRetained(event)
    }
    let manager = Unmanaged<ScrollReverserManager>.fromOpaque(ptr).takeUnretainedValue()
    return manager.handle(event: event)
}
