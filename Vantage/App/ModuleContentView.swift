import SwiftUI

struct ModuleContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            switch appState.activeModule {
            case .windowManager:   WindowManagerView()
            case .clipboard:       ClipboardView()
            case .systemMonitor:   SystemMonitorView()
            case .appLauncher:     AppLauncherView()
            case .focus:           FocusView()
            case .displayControls: DisplayControlsView()
            case .textSnippets:    TextSnippetsView()
            case .aiAssistant:     AIAssistantView()
            case .networkTools:    NetworkToolsView()
            case .battery:         BatteryView()
            case .scrollReverser:  ScrollReverserView()
            case .colorPicker:     ColorPickerView()
            case .quickToggles:    QuickTogglesView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.activeModule)
    }
}
