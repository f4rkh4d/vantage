import Foundation

struct SnapZone: Identifiable, Equatable {
    let id: String
    let title: String
    let shortcut: String        // display string, e.g. "⌃⌥←"
    let keyCode: UInt16         // CGKeyCode value
    let gridCol: Int            // column in 3×3 grid (0-based)
    let gridRow: Int            // row in 3×3 grid (0-based)
    let gridColSpan: Int
    let gridRowSpan: Int

    // Returns the target frame in AX coordinates (top-left origin, y↓)
    // screenFrame: the usable screen frame already in AX coordinates
    func axFrame(in screenFrame: CGRect) -> CGRect {
        let w = screenFrame.width
        let h = screenFrame.height
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y
        let unit = w / 3

        switch id {
        case "leftHalf":
            return CGRect(x: x, y: y, width: w / 2, height: h)
        case "rightHalf":
            return CGRect(x: x + w / 2, y: y, width: w / 2, height: h)
        case "topHalf":
            return CGRect(x: x, y: y, width: w, height: h / 2)
        case "bottomHalf":
            return CGRect(x: x, y: y + h / 2, width: w, height: h / 2)
        case "leftThird":
            return CGRect(x: x, y: y, width: unit, height: h)
        case "centerThird":
            return CGRect(x: x + unit, y: y, width: unit, height: h)
        case "rightThird":
            return CGRect(x: x + 2 * unit, y: y, width: unit, height: h)
        case "leftTwoThirds":
            return CGRect(x: x, y: y, width: 2 * unit, height: h)
        case "rightTwoThirds":
            return CGRect(x: x + unit, y: y, width: 2 * unit, height: h)
        case "fullscreen":
            return CGRect(x: x, y: y, width: w, height: h)
        case "topLeft":
            return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case "topRight":
            return CGRect(x: x + w / 2, y: y, width: w / 2, height: h / 2)
        case "bottomLeft":
            return CGRect(x: x, y: y + h / 2, width: w / 2, height: h / 2)
        case "bottomRight":
            return CGRect(x: x + w / 2, y: y + h / 2, width: w / 2, height: h / 2)
        case "center":
            let margin: CGFloat = 40
            return CGRect(x: x + margin, y: y + margin,
                         width: w - 2 * margin, height: h - 2 * margin)
        default:
            return CGRect(x: x, y: y, width: w, height: h)
        }
    }
}

extension SnapZone {
    // All zones in display order (used for the grid UI)
    static let all: [SnapZone] = [
        SnapZone(id: "topLeft",       title: "Top Left",      shortcut: "⌃⌥U", keyCode: 32, gridCol: 0, gridRow: 0, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "topHalf",       title: "Top Half",      shortcut: "⌃⌥↑", keyCode: 126, gridCol: 1, gridRow: 0, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "topRight",      title: "Top Right",     shortcut: "⌃⌥I", keyCode: 34, gridCol: 2, gridRow: 0, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "leftHalf",      title: "Left Half",     shortcut: "⌃⌥←", keyCode: 123, gridCol: 0, gridRow: 1, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "fullscreen",    title: "Fullscreen",    shortcut: "⌃⌥F", keyCode: 3,   gridCol: 1, gridRow: 1, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "rightHalf",     title: "Right Half",    shortcut: "⌃⌥→", keyCode: 124, gridCol: 2, gridRow: 1, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "bottomLeft",    title: "Bottom Left",   shortcut: "⌃⌥J", keyCode: 38, gridCol: 0, gridRow: 2, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "bottomHalf",    title: "Bottom Half",   shortcut: "⌃⌥↓", keyCode: 125, gridCol: 1, gridRow: 2, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "bottomRight",   title: "Bottom Right",  shortcut: "⌃⌥K", keyCode: 40, gridCol: 2, gridRow: 2, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "leftThird",     title: "Left ⅓",        shortcut: "⌃⌥[", keyCode: 33, gridCol: 0, gridRow: 3, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "centerThird",   title: "Center ⅓",      shortcut: "⌃⌥C", keyCode: 8,  gridCol: 1, gridRow: 3, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "rightThird",    title: "Right ⅓",       shortcut: "⌃⌥]", keyCode: 30, gridCol: 2, gridRow: 3, gridColSpan: 1, gridRowSpan: 1),
        SnapZone(id: "leftTwoThirds", title: "Left ⅔",        shortcut: "⌃⌥,", keyCode: 43, gridCol: 0, gridRow: 4, gridColSpan: 2, gridRowSpan: 1),
        SnapZone(id: "rightTwoThirds",title: "Right ⅔",       shortcut: "⌃⌥.", keyCode: 47, gridCol: 1, gridRow: 4, gridColSpan: 2, gridRowSpan: 1),
        SnapZone(id: "center",        title: "Center Float",  shortcut: "⌃⌥Z", keyCode: 6,  gridCol: 0, gridRow: 5, gridColSpan: 3, gridRowSpan: 1),
    ]
}
