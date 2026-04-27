import AppKit

struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlags: Int  // NSEvent.ModifierFlags rawValue (deviceIndependent)

    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: UInt(modifierFlags)) }

    var displayString: String {
        var parts = ""
        let mods = modifiers
        if mods.contains(.control) { parts += "⌃" }
        if mods.contains(.option)  { parts += "⌥" }
        if mods.contains(.shift)   { parts += "⇧" }
        if mods.contains(.command) { parts += "⌘" }
        parts += keyCodeToString(keyCode)
        return parts
    }

    private func keyCodeToString(_ code: UInt16) -> String {
        switch code {
        case 123: return "←"; case 124: return "→"
        case 125: return "↓"; case 126: return "↑"
        case 36: return "↩"; case 48: return "⇥"
        case 49: return "Space"; case 51: return "⌫"
        case 53: return "Esc"
        default:
            if let chars = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true) {
                var len = 0
                var buf = [UniChar](repeating: 0, count: 4)
                chars.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &len, unicodeString: &buf)
                if len > 0 {
                    return String(utf16CodeUnits: Array(buf.prefix(len)), count: len).uppercased()
                }
            }
            return "(\(code))"
        }
    }
}

struct SnapZone: Identifiable, Equatable {
    let id: String
    let title: String
    let defaultShortcut: String
    let defaultKeyCode: UInt16
    let defaultModifiers: NSEvent.ModifierFlags
    let gridCol: Int
    let gridRow: Int
    let gridColSpan: Int
    let gridRowSpan: Int

    // Backwards compat
    var shortcut: String { customBinding?.displayString ?? defaultShortcut }
    var keyCode: UInt16  { customBinding?.keyCode ?? defaultKeyCode }

    var customBinding: HotkeyBinding? {
        get {
            guard let data = UserDefaults.standard.data(forKey: bindingKey),
                  let b = try? JSONDecoder().decode(HotkeyBinding.self, from: data) else { return nil }
            return b
        }
    }

    var effectiveKeyCode: UInt16 { customBinding?.keyCode ?? defaultKeyCode }
    var effectiveModifiers: NSEvent.ModifierFlags { customBinding?.modifiers ?? defaultModifiers }

    private var bindingKey: String { "hotkey_\(id)" }

    mutating func setCustomBinding(_ binding: HotkeyBinding?) {
        if let b = binding, let data = try? JSONEncoder().encode(b) {
            UserDefaults.standard.set(data, forKey: bindingKey)
        } else {
            UserDefaults.standard.removeObject(forKey: bindingKey)
        }
    }

    static func saveCustomBinding(zoneId: String, binding: HotkeyBinding?) {
        let key = "hotkey_\(zoneId)"
        if let b = binding, let data = try? JSONEncoder().encode(b) {
            UserDefaults.standard.set(data, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func axFrame(in screenFrame: CGRect) -> CGRect {
        let w = screenFrame.width, h = screenFrame.height
        let x = screenFrame.origin.x, y = screenFrame.origin.y
        let u = w / 3
        switch id {
        case "leftHalf":       return CGRect(x: x,       y: y,       width: w/2,  height: h)
        case "rightHalf":      return CGRect(x: x+w/2,   y: y,       width: w/2,  height: h)
        case "topHalf":        return CGRect(x: x,       y: y,       width: w,    height: h/2)
        case "bottomHalf":     return CGRect(x: x,       y: y+h/2,   width: w,    height: h/2)
        case "leftThird":      return CGRect(x: x,       y: y,       width: u,    height: h)
        case "centerThird":    return CGRect(x: x+u,     y: y,       width: u,    height: h)
        case "rightThird":     return CGRect(x: x+2*u,   y: y,       width: u,    height: h)
        case "leftTwoThirds":  return CGRect(x: x,       y: y,       width: 2*u,  height: h)
        case "rightTwoThirds": return CGRect(x: x+u,     y: y,       width: 2*u,  height: h)
        case "fullscreen":     return CGRect(x: x,       y: y,       width: w,    height: h)
        case "topLeft":        return CGRect(x: x,       y: y,       width: w/2,  height: h/2)
        case "topRight":       return CGRect(x: x+w/2,   y: y,       width: w/2,  height: h/2)
        case "bottomLeft":     return CGRect(x: x,       y: y+h/2,   width: w/2,  height: h/2)
        case "bottomRight":    return CGRect(x: x+w/2,   y: y+h/2,   width: w/2,  height: h/2)
        case "center":
            let m = w * 0.08
            return CGRect(x: x+m, y: y+m, width: w-2*m, height: h-2*m)
        default: return CGRect(x: x, y: y, width: w, height: h)
        }
    }
}

extension SnapZone {
    static let ctrlOpt: NSEvent.ModifierFlags = [.control, .option]

    static let all: [SnapZone] = [
        SnapZone(id:"topLeft",       title:"Top Left",       defaultShortcut:"⌃⌥U", defaultKeyCode:32,  defaultModifiers:ctrlOpt, gridCol:0, gridRow:0, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"topHalf",       title:"Top Half",       defaultShortcut:"⌃⌥↑", defaultKeyCode:126, defaultModifiers:ctrlOpt, gridCol:1, gridRow:0, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"topRight",      title:"Top Right",      defaultShortcut:"⌃⌥I", defaultKeyCode:34,  defaultModifiers:ctrlOpt, gridCol:2, gridRow:0, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"leftHalf",      title:"Left Half",      defaultShortcut:"⌃⌥←", defaultKeyCode:123, defaultModifiers:ctrlOpt, gridCol:0, gridRow:1, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"fullscreen",    title:"Fullscreen",     defaultShortcut:"⌃⌥F", defaultKeyCode:3,   defaultModifiers:ctrlOpt, gridCol:1, gridRow:1, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"rightHalf",     title:"Right Half",     defaultShortcut:"⌃⌥→", defaultKeyCode:124, defaultModifiers:ctrlOpt, gridCol:2, gridRow:1, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"bottomLeft",    title:"Bottom Left",    defaultShortcut:"⌃⌥J", defaultKeyCode:38,  defaultModifiers:ctrlOpt, gridCol:0, gridRow:2, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"bottomHalf",    title:"Bottom Half",    defaultShortcut:"⌃⌥↓", defaultKeyCode:125, defaultModifiers:ctrlOpt, gridCol:1, gridRow:2, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"bottomRight",   title:"Bottom Right",   defaultShortcut:"⌃⌥K", defaultKeyCode:40,  defaultModifiers:ctrlOpt, gridCol:2, gridRow:2, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"leftThird",     title:"Left ⅓",         defaultShortcut:"⌃⌥[", defaultKeyCode:33,  defaultModifiers:ctrlOpt, gridCol:0, gridRow:3, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"centerThird",   title:"Center ⅓",       defaultShortcut:"⌃⌥C", defaultKeyCode:8,   defaultModifiers:ctrlOpt, gridCol:1, gridRow:3, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"rightThird",    title:"Right ⅓",        defaultShortcut:"⌃⌥]", defaultKeyCode:30,  defaultModifiers:ctrlOpt, gridCol:2, gridRow:3, gridColSpan:1, gridRowSpan:1),
        SnapZone(id:"leftTwoThirds", title:"Left ⅔",         defaultShortcut:"⌃⌥,", defaultKeyCode:43,  defaultModifiers:ctrlOpt, gridCol:0, gridRow:4, gridColSpan:2, gridRowSpan:1),
        SnapZone(id:"rightTwoThirds",title:"Right ⅔",        defaultShortcut:"⌃⌥.", defaultKeyCode:47,  defaultModifiers:ctrlOpt, gridCol:1, gridRow:4, gridColSpan:2, gridRowSpan:1),
        SnapZone(id:"center",        title:"Center Float",   defaultShortcut:"⌃⌥Z", defaultKeyCode:6,   defaultModifiers:ctrlOpt, gridCol:0, gridRow:5, gridColSpan:3, gridRowSpan:1),
    ]
}
