import Foundation

@MainActor
final class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()

    @Published var messages: [AIMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "openai_api_key") }
    }

    private init() {
        apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }

    func send(userText: String) {
        guard !apiKey.isEmpty else { errorMessage = "Enter your OpenAI API key first."; return }
        messages.append(AIMessage(role: "user", content: userText))
        isLoading = true
        errorMessage = nil

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                if let error { self.errorMessage = error.localizedDescription; return }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let msg = choices.first?["message"] as? [String: Any],
                      let content = msg["content"] as? String else {
                    self.errorMessage = "Invalid response from API."
                    return
                }
                self.messages.append(AIMessage(role: "assistant", content: content))
            }
        }.resume()
    }

    func clearHistory() { messages = [] }
}
