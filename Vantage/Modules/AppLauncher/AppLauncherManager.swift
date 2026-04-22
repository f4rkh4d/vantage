import Foundation
import AppKit

@MainActor
final class AppLauncherManager: ObservableObject {
    static let shared = AppLauncherManager()
    private init() {}

    @Published var apps: [AppEntry] = []
    @Published var searchText: String = ""
    @Published var recentAppIDs: [String] = []

    var filtered: [AppEntry] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func load() {
        let ws = NSWorkspace.shared
        var found: [AppEntry] = []
        let searchDirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ]
        for dir in searchDirs {
            let urls = (try? FileManager.default.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: [.isApplicationKey], options: [.skipsHiddenFiles]
            )) ?? []
            for url in urls where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url),
                      let id = bundle.bundleIdentifier else { continue }
                let name = (bundle.infoDictionary?["CFBundleName"] as? String)
                    ?? (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                let icon = ws.icon(forFile: url.path)
                found.append(AppEntry(id: id, name: name, url: url, icon: icon))
            }
        }
        apps = found.sorted { $0.name < $1.name }
    }

    func launch(_ app: AppEntry) {
        NSWorkspace.shared.open(app.url)
        recentAppIDs.removeAll { $0 == app.id }
        recentAppIDs.insert(app.id, at: 0)
        if recentAppIDs.count > 5 { recentAppIDs = Array(recentAppIDs.prefix(5)) }
    }
}
