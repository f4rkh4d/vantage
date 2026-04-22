import Foundation

enum Module: String, CaseIterable, Identifiable {
    case windowManager
    case clipboard
    case systemMonitor
    case appLauncher
    case focus
    case displayControls
    case textSnippets
    case aiAssistant
    case networkTools
    case battery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .windowManager:   return "Window Manager"
        case .clipboard:       return "Clipboard"
        case .systemMonitor:   return "System Monitor"
        case .appLauncher:     return "App Launcher"
        case .focus:           return "Focus"
        case .displayControls: return "Display Controls"
        case .textSnippets:    return "Text Snippets"
        case .aiAssistant:     return "AI Assistant"
        case .networkTools:    return "Network Tools"
        case .battery:         return "Battery & Power"
        }
    }
}

@MainActor
@Observable
final class AppState {
    var activeModule: Module = .windowManager
    var cpuUsage: Double = 0        // 0.0–1.0
    var ramUsage: Double = 0        // 0.0–1.0
    var batteryLevel: Double = 1.0  // starts full until first poll; 0.0–1.0
    var isCharging: Bool = false
}
