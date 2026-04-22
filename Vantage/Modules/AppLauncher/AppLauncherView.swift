import SwiftUI
import AppKit

struct AppLauncherView: View {
    @ObservedObject private var manager = AppLauncherManager.shared
    @FocusState private var searchFocused: Bool

    var recentApps: [AppEntry] {
        manager.recentAppIDs.compactMap { id in manager.apps.first { $0.id == id } }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            if manager.filtered.isEmpty && !manager.searchText.isEmpty {
                emptyState
            } else {
                appList
            }
            Divider()
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if manager.apps.isEmpty { manager.load() }
            searchFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Module.appLauncher.accentColor.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.appLauncher.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Module.appLauncher.accentColor)
            }
            Text("App Launcher")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.tertiary)
            TextField("Search apps…", text: $manager.searchText)
                .font(.system(size: 12))
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .accentColor(Module.appLauncher.accentColor)
            if !manager.searchText.isEmpty {
                Button { manager.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundStyle(.tertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .padding(.horizontal, 10).padding(.vertical, 8)
    }

    private var appList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if manager.searchText.isEmpty && !recentApps.isEmpty {
                    Section {
                        ForEach(recentApps) { app in
                            AppRow(app: app)
                            Divider().padding(.leading, 42)
                        }
                    } header: {
                        sectionHeader("Recent")
                    }

                    Section {
                        ForEach(manager.apps) { app in
                            AppRow(app: app)
                            Divider().padding(.leading, 42)
                        }
                    } header: {
                        sectionHeader("All Apps")
                    }
                } else {
                    ForEach(manager.filtered) { app in
                        AppRow(app: app)
                        Divider().padding(.leading, 42)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 28)).foregroundStyle(.tertiary)
            Text("No apps found")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("\(manager.apps.count) apps")
                .font(.system(size: 9.5)).foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
    }
}

private struct AppRow: View {
    let app: AppEntry
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
            }
            Text(app.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isHovered {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(isHovered ? Color.secondary.opacity(0.06) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            AppLauncherManager.shared.launch(app)
            NSApp.keyWindow?.close()
        }
    }
}
