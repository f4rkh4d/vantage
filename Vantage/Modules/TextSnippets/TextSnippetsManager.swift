import AppKit

@MainActor
final class TextSnippetsManager: ObservableObject {
    static let shared = TextSnippetsManager()
    private init() { load() }

    @Published var snippets: [Snippet] = []

    func add(label: String, trigger: String, expansion: String) {
        snippets.append(Snippet(trigger: trigger, expansion: expansion, label: label))
        save()
    }

    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        save()
    }

    func update(_ snippet: Snippet) {
        if let idx = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[idx] = snippet
            save()
        }
    }

    func copyToClipboard(_ snippet: Snippet) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.expansion, forType: .string)
    }

    private var saveURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Vantage/snippets.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let saved = try? JSONDecoder().decode([Snippet].self, from: data) else {
            snippets = Snippet.defaults
            return
        }
        snippets = saved
    }

    private func save() {
        let url = saveURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(snippets) { try? data.write(to: url) }
    }
}

extension Snippet {
    static let defaults: [Snippet] = [
        Snippet(trigger: "@@email", expansion: "your@email.com", label: "Email"),
        Snippet(trigger: "@@addr", expansion: "123 Main St, City, State 12345", label: "Address"),
        Snippet(trigger: "@@sig", expansion: "Best regards,\nYour Name", label: "Signature"),
    ]
}
