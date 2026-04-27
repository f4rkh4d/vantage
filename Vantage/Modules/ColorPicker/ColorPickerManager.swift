import AppKit

@MainActor
final class ColorPickerManager: ObservableObject {
    static let shared = ColorPickerManager()
    private init() { loadHistory() }

    @Published var history: [PickedColor] = []
    @Published var isPicking = false

    private let maxHistory = 16
    private let historyKey = "colorPickerHistory"

    struct PickedColor: Identifiable, Codable, Equatable {
        let id: UUID
        let r: Double; let g: Double; let b: Double; let a: Double
        init(id: UUID = UUID(), r: Double, g: Double, b: Double, a: Double = 1) {
            self.id = id; self.r = r; self.g = g; self.b = b; self.a = a
        }
        var hex: String {
            let ri = Int(r * 255); let gi = Int(g * 255); let bi = Int(b * 255)
            return String(format: "#%02X%02X%02X", ri, gi, bi)
        }
        var rgb: String { "rgb(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)))" }
        var hsl: String {
            let (h, s, l) = toHSL()
            return String(format: "hsl(%d, %d%%, %d%%)", Int(h * 360), Int(s * 100), Int(l * 100))
        }
        var hsb: String {
            let (h, s, b) = toHSB()
            return String(format: "hsb(%d, %d%%, %d%%)", Int(h * 360), Int(s * 100), Int(b * 100))
        }
        var nsColor: NSColor { NSColor(red: r, green: g, blue: b, alpha: a) }

        private func toHSL() -> (Double, Double, Double) {
            let max = Swift.max(r, g, b), min = Swift.min(r, g, b)
            let l = (max + min) / 2
            guard max != min else { return (0, 0, l) }
            let d = max - min
            let s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
            let h: Double
            switch max {
            case r: h = (g - b) / d + (g < b ? 6 : 0)
            case g: h = (b - r) / d + 2
            default: h = (r - g) / d + 4
            }
            return (h / 6, s, l)
        }
        private func toHSB() -> (Double, Double, Double) {
            let max = Swift.max(r, g, b), min = Swift.min(r, g, b)
            let v = max; let d = max - min
            let s = max == 0 ? 0.0 : d / max
            guard max != min else { return (0, s, v) }
            let h: Double
            switch max {
            case r: h = (g - b) / d + (g < b ? 6 : 0)
            case g: h = (b - r) / d + 2
            default: h = (r - g) / d + 4
            }
            return (h / 6, s, v)
        }
    }

    enum CopyFormat: String, CaseIterable {
        case hex = "HEX", rgb = "RGB", hsl = "HSL", hsb = "HSB"
    }

    func pick() {
        isPicking = true
        NSColorSampler().show { [weak self] color in
            guard let self else { return }
            Task { @MainActor in
                self.isPicking = false
                guard let c = color?.usingColorSpace(.sRGB) else { return }
                let picked = PickedColor(r: c.redComponent, g: c.greenComponent,
                                        b: c.blueComponent, a: c.alphaComponent)
                self.history.insert(picked, at: 0)
                if self.history.count > self.maxHistory { self.history.removeLast() }
                self.saveHistory()
                self.copyToClipboard(picked, format: .hex)
            }
        }
    }

    func copyToClipboard(_ color: PickedColor, format: CopyFormat) {
        let text: String
        switch format {
        case .hex: text = color.hex
        case .rgb: text = color.rgb
        case .hsl: text = color.hsl
        case .hsb: text = color.hsb
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func clear() { history = []; saveHistory() }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([PickedColor].self, from: data) else { return }
        history = decoded
    }
}
