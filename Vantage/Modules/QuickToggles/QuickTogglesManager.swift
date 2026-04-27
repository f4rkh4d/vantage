import AppKit

@MainActor
final class QuickTogglesManager: ObservableObject {
    static let shared = QuickTogglesManager()
    private init() { refresh() }

    @Published var isDarkMode    = false
    @Published var hiddenFiles   = false
    @Published var desktopIcons  = true
    @Published var showExtensions = true
    @Published var reducedMotion = false

    func refresh() {
        isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        Task.detached { [weak self] in
            let hidden     = self?.readDefaultsBool("com.apple.finder", key: "AppleShowAllFiles") ?? false
            let desktop    = self?.readDefaultsBool("com.apple.finder", key: "CreateDesktop") ?? true
            let extensions = self?.readDefaultsBool("com.apple.finder", key: "AppleShowAllExtensions") ?? true
            let motion     = self?.readDefaultsBool("com.apple.universalaccess", key: "reduceMotion") ?? false
            await MainActor.run { [weak self] in
                self?.hiddenFiles    = hidden
                self?.desktopIcons   = desktop
                self?.showExtensions = extensions
                self?.reducedMotion  = motion
            }
        }
    }

    func toggleDarkMode() {
        let script = "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"
        Task.detached { NSAppleScript(source: script)?.executeAndReturnError(nil) }
        isDarkMode.toggle()
    }

    func toggleHiddenFiles() {
        let next = !hiddenFiles
        hiddenFiles = next
        Task.detached {
            self.shell("defaults", "write", "com.apple.finder", "AppleShowAllFiles", next ? "YES" : "NO")
            self.shell("killall", "Finder")
        }
    }

    func toggleDesktopIcons() {
        let next = !desktopIcons
        desktopIcons = next
        Task.detached {
            self.shell("defaults", "write", "com.apple.finder", "CreateDesktop", next ? "true" : "false")
            self.shell("killall", "Finder")
        }
    }

    func toggleExtensions() {
        let next = !showExtensions
        showExtensions = next
        Task.detached {
            // AppleShowAllExtensions false = hidden, true = shown
            self.shell("defaults", "write", "com.apple.finder", "AppleShowAllExtensions", next ? "YES" : "NO")
            self.shell("killall", "Finder")
        }
    }

    func toggleReducedMotion() {
        let next = !reducedMotion
        reducedMotion = next
        Task.detached {
            self.shell("defaults", "write", "com.apple.universalaccess", "reduceMotion", "-bool", next ? "YES" : "NO")
        }
    }

    func openFinderSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.general")!)
    }

    // MARK: - Private

    @discardableResult
    private nonisolated func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/" + args[0]
        if !FileManager.default.fileExists(atPath: task.launchPath!) {
            task.launchPath = "/bin/" + args[0]
        }
        if !FileManager.default.fileExists(atPath: task.launchPath!) {
            task.launchPath = "/usr/bin/env"
            task.arguments = Array(args)
        } else {
            task.arguments = Array(args.dropFirst())
        }
        try? task.run()
        task.waitUntilExit()
        return task.terminationStatus
    }

    fileprivate nonisolated func readDefaultsBool(_ domain: String, key: String) -> Bool? {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", domain, key]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch str.lowercased() {
        case "1", "yes", "true": return true
        case "0", "no", "false": return false
        default: return nil
        }
    }
}
