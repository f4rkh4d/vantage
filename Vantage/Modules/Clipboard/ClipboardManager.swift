import AppKit

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    private init() {}

    @Published var items: [ClipboardItem] = []
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let maxUnpinned = 200

    func start() {
        load()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    func copyToPasteboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        // Bubble to top
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            var moved = items.remove(at: idx)
            moved.isPinned = items[safe: 0]?.isPinned == true ? moved.isPinned : moved.isPinned
            items.insert(moved, at: 0)
        }
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        save()
    }

    func clearUnpinned() {
        items.removeAll { !$0.isPinned }
        save()
    }

    // MARK: Private

    private func poll() {
        let count = NSPasteboard.general.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count
        guard let str = NSPasteboard.general.string(forType: .string),
              !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              str != items.first(where: { !$0.isPinned })?.content else { return }
        let item = ClipboardItem(content: str)
        items.insert(item, at: 0)
        // Trim unpinned to max
        var unpinnedCount = 0
        items = items.filter { item in
            if item.isPinned { return true }
            unpinnedCount += 1
            return unpinnedCount <= maxUnpinned
        }
        save()
    }

    private var saveURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Vantage/clipboard.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let saved = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = saved
    }

    private func save() {
        let url = saveURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                  withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(items) { try? data.write(to: url) }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
