import AppKit

struct DisplayInfo: Identifiable {
    var id: String { name }
    let name: String
    let resolution: CGSize
    let scaleFactor: CGFloat
    let refreshRate: Double
    let isMain: Bool
}

@MainActor
final class DisplayControlsManager: ObservableObject {
    static let shared = DisplayControlsManager()
    private init() {}

    @Published var displays: [DisplayInfo] = []

    func refresh() {
        displays = NSScreen.screens.map { screen in
            let res = screen.frame.size
            let scale = screen.backingScaleFactor
            let name = screen.localizedName
            let isMain = screen == NSScreen.main
            var refreshRate: Double = 0
            if let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                if let cvMode = CGDisplayCopyDisplayMode(displayID) {
                    refreshRate = cvMode.refreshRate
                    if refreshRate == 0 { refreshRate = 60 }
                }
            }
            return DisplayInfo(name: name, resolution: res, scaleFactor: scale, refreshRate: refreshRate, isMain: isMain)
        }
    }

    func openDisplaySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")!)
    }

    func openNightShiftSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")!)
    }
}
