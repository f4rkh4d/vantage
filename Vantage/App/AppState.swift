import SwiftUI

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

    var icon: String {
        switch self {
        case .windowManager:   return "rectangle.split.2x2"
        case .clipboard:       return "doc.on.clipboard"
        case .systemMonitor:   return "chart.bar.xaxis"
        case .appLauncher:     return "magnifyingglass"
        case .focus:           return "timer"
        case .displayControls: return "display"
        case .textSnippets:    return "text.cursor"
        case .aiAssistant:     return "sparkles"
        case .networkTools:    return "network"
        case .battery:         return "battery.75percent"
        }
    }

    var accentColor: Color {
        switch self {
        case .windowManager:   return Color(red: 0.38, green: 0.55, blue: 1.0)   // indigo-blue
        case .clipboard:       return Color(red: 0.20, green: 0.78, blue: 0.64)  // teal
        case .systemMonitor:   return Color(red: 1.0,  green: 0.58, blue: 0.22)  // orange
        case .appLauncher:     return Color(red: 0.58, green: 0.40, blue: 1.0)   // purple
        case .focus:           return Color(red: 1.0,  green: 0.32, blue: 0.42)  // rose
        case .displayControls: return Color(red: 0.20, green: 0.70, blue: 1.0)   // sky blue
        case .textSnippets:    return Color(red: 0.25, green: 0.85, blue: 0.50)  // green
        case .aiAssistant:     return Color(red: 0.90, green: 0.50, blue: 1.0)   // violet
        case .networkTools:    return Color(red: 0.10, green: 0.75, blue: 0.80)  // cyan
        case .battery:         return Color(red: 0.45, green: 0.85, blue: 0.35)  // lime green
        }
    }
}

@Observable
final class AppState {
    var activeModule: Module = .windowManager
    var cpuUsage: Double = 0        // 0.0–1.0
    var ramUsage: Double = 0        // 0.0–1.0
    var batteryLevel: Double = 1.0  // 0.0–1.0
    var isCharging: Bool = false
}
