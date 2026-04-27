import SwiftUI

struct QuickTogglesView: View {
    @ObservedObject private var manager = QuickTogglesManager.shared
    private let accent = Module.quickToggles.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            toggleList
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { manager.refresh() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.quickToggles.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Quick Toggles")
                    .font(.system(size: 13, weight: .semibold))
                Text("System preferences, one click")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
            Button { manager.refresh() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var toggleList: some View {
        VStack(spacing: 0) {
            toggleRow(
                icon: "moon.fill",
                title: "Dark Mode",
                subtitle: manager.isDarkMode ? "Dark" : "Light",
                isOn: manager.isDarkMode,
                color: Color(red: 0.4, green: 0.3, blue: 0.9)
            ) { manager.toggleDarkMode() }

            Divider().padding(.leading, 48)

            toggleRow(
                icon: "eye",
                title: "Hidden Files",
                subtitle: manager.hiddenFiles ? "Visible" : "Hidden",
                isOn: manager.hiddenFiles,
                color: Color(red: 1.0, green: 0.6, blue: 0.1)
            ) { manager.toggleHiddenFiles() }

            Divider().padding(.leading, 48)

            toggleRow(
                icon: "rectangle.fill.on.rectangle.fill",
                title: "Desktop Icons",
                subtitle: manager.desktopIcons ? "Shown" : "Hidden",
                isOn: manager.desktopIcons,
                color: Color(red: 0.2, green: 0.7, blue: 1.0)
            ) { manager.toggleDesktopIcons() }

            Divider().padding(.leading, 48)

            toggleRow(
                icon: "doc.badge.ellipsis",
                title: "File Extensions",
                subtitle: manager.showExtensions ? "Visible" : "Hidden",
                isOn: manager.showExtensions,
                color: Color(red: 0.3, green: 0.85, blue: 0.5)
            ) { manager.toggleExtensions() }

            Divider().padding(.leading, 48)

            toggleRow(
                icon: "hare",
                title: "Reduce Motion",
                subtitle: manager.reducedMotion ? "Reduced" : "Full animations",
                isOn: manager.reducedMotion,
                color: Color(red: 0.9, green: 0.3, blue: 0.4)
            ) { manager.toggleReducedMotion() }
        }
    }

    private func toggleRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 12, weight: .medium))
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(.tertiary)
                }
                Spacer()
                Circle()
                    .fill(isOn ? color : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
