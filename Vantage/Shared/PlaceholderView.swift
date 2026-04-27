import SwiftUI

struct ModulePlaceholderView: View {
    let module: Module
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Subtle accent tint background
            module.accentColor.opacity(0.04)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Glowing icon
                ZStack {
                    // Glow halo
                    Circle()
                        .fill(module.accentColor.opacity(isPulsing ? 0.18 : 0.08))
                        .frame(width: 96, height: 96)
                        .blur(radius: 12)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)

                    // Icon container
                    Circle()
                        .fill(module.accentColor.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(module.accentColor.opacity(0.25), lineWidth: 1)
                        )

                    Image(systemName: module.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [module.accentColor, module.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                }

                VStack(spacing: 6) {
                    Text(module.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(moduleDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Coming soon badge
                Text("Coming soon")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(module.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(module.accentColor.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(module.accentColor.opacity(0.25), lineWidth: 0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { isPulsing = true }
    }

    private var moduleDescription: String {
        switch module {
        case .windowManager:   return "Snap windows to any zone\nwith keyboard shortcuts"
        case .clipboard:       return "Search and paste from\nyour full clipboard history"
        case .systemMonitor:   return "Real-time CPU, RAM\nand process monitoring"
        case .appLauncher:     return "Launch any app instantly\nwith a keystroke"
        case .focus:           return "Pomodoro timer with\nwebsite blocking"
        case .displayControls: return "Brightness, Night Shift\nand display layout"
        case .textSnippets:    return "Type shortcuts that expand\ninto full text"
        case .aiAssistant:     return "Rewrite, translate and\nsummarize selected text"
        case .networkTools:    return "Network stats, DNS switcher\nand VPN controls"
        case .battery:         return "Battery health, charge limit\nand power mode"
        case .scrollReverser:  return "Reverse mouse and trackpad\nscroll independently"
        case .colorPicker:     return "Pick any color on screen,\ncopy HEX · RGB · HSL"
        case .quickToggles:    return "Dark mode, hidden files,\ndesktop icons — one click"
        }
    }
}
