import SwiftUI

struct ClipboardView: View {
    @State private var searchText = ""
    @ObservedObject private var manager = ClipboardManager.shared

    private var filtered: [ClipboardItem] {
        if searchText.isEmpty { return manager.items }
        return manager.items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            if filtered.isEmpty {
                emptyState
            } else {
                itemList
            }
            Divider()
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Module.clipboard.accentColor.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.clipboard.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Module.clipboard.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Clipboard History")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(manager.items.count) items")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(.tertiary)
            TextField("Search clipboard…", text: $searchText)
                .font(.system(size: 12))
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundStyle(.tertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .padding(.horizontal, 10).padding(.vertical, 8)
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { item in
                    ClipboardRow(item: item)
                    Divider().padding(.leading, 42)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard").font(.system(size: 28)).foregroundStyle(.tertiary)
            Text(searchText.isEmpty ? "Nothing copied yet" : "No matches")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("\(filtered.count) item\(filtered.count == 1 ? "" : "s")")
                .font(.system(size: 9.5)).foregroundStyle(.tertiary)
            Spacer()
            Button("Clear all") { ClipboardManager.shared.clearUnpinned() }
                .font(.system(size: 9.5)).foregroundStyle(.tertiary).buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
    }
}

private struct ClipboardRow: View {
    let item: ClipboardItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Type icon
            Image(systemName: "doc.plaintext")
                .font(.system(size: 11)).foregroundStyle(.tertiary).frame(width: 20)

            // Content preview
            Text(item.content)
                .font(.system(size: 11))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isHovered {
                HStack(spacing: 2) {
                    // Pin
                    Button {
                        ClipboardManager.shared.togglePin(item)
                    } label: {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .foregroundStyle(item.isPinned ? Module.clipboard.accentColor : .secondary)
                    }.buttonStyle(.plain)

                    // Delete
                    Button {
                        ClipboardManager.shared.delete(item)
                    } label: {
                        Image(systemName: "trash").font(.system(size: 10)).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
            } else if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9)).foregroundStyle(Module.clipboard.accentColor)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(isHovered ? Color.secondary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { ClipboardManager.shared.copyToPasteboard(item) }
        .help("Click to copy")
    }
}
