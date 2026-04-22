import SwiftUI

struct MenubarView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SidebarView(showSettings: $showSettings)

                Rectangle()
                    .fill(.separator.opacity(0.5))
                    .frame(width: 0.5)
                    .padding(.vertical, 8)

                ModuleContentView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            StatusBarView()
        }
        .frame(width: 400, height: 520)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
