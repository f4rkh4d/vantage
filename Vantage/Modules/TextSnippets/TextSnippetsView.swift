import SwiftUI

struct TextSnippetsView: View {
    @ObservedObject private var manager = TextSnippetsManager.shared
    @State private var showAddSheet = false
    @State private var copiedID: UUID? = nil

    private let accent = Module.textSnippets.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if manager.snippets.isEmpty {
                emptyState
            } else {
                snippetList
            }
            Divider()
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddSheet) {
            AddSnippetSheet(accent: accent) { label, trigger, expansion in
                manager.add(label: label, trigger: trigger, expansion: expansion)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.textSnippets.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Text Snippets")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(manager.snippets.count) snippet\(manager.snippets.count == 1 ? "" : "s")")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 24, height: 24)
                    .background(accent.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var snippetList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.snippets) { snippet in
                    SnippetRow(snippet: snippet, accent: accent, copiedID: $copiedID) {
                        manager.copyToClipboard(snippet)
                        copiedID = snippet.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if copiedID == snippet.id { copiedID = nil }
                        }
                    } onDelete: {
                        manager.delete(snippet)
                    }
                    Divider().padding(.leading, 42)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.cursor")
                .font(.system(size: 28)).foregroundStyle(.tertiary)
            Text("No snippets yet")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            Button("Add your first snippet") { showAddSheet = true }
                .font(.system(size: 11))
                .foregroundStyle(accent)
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("Tap any snippet to copy")
                .font(.system(size: 9.5)).foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
    }
}

private struct SnippetRow: View {
    let snippet: Snippet
    let accent: Color
    @Binding var copiedID: UUID?
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    private var isCopied: Bool { copiedID == snippet.id }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text(snippet.trigger)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                }
            }
            .frame(width: 72, alignment: .leading)
            .animation(.easeInOut(duration: 0.2), value: isCopied)

            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.label)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(snippet.expansion)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(isHovered ? Color.secondary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onCopy)
        .help("Click to copy")
    }
}

private struct AddSnippetSheet: View {
    let accent: Color
    let onAdd: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var trigger = ""
    @State private var expansion = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Snippet")
                .font(.system(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("Label").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("e.g. Email", text: $label)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Trigger").font(.system(size: 11)).foregroundStyle(.secondary)
                TextField("e.g. @@email", text: $trigger)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Expansion").font(.system(size: 11)).foregroundStyle(.secondary)
                TextEditor(text: $expansion)
                    .font(.system(size: 12))
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                Spacer()
                Button("Add") {
                    guard !label.isEmpty, !trigger.isEmpty, !expansion.isEmpty else { return }
                    onAdd(label, trigger, expansion)
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
                .disabled(label.isEmpty || trigger.isEmpty || expansion.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}
