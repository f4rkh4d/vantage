import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Gemini"
    var id: String { rawValue }

    var keyPrompt: String {
        switch self {
        case .openAI: return "sk-..."
        case .anthropic: return "sk-ant-..."
        case .gemini: return "AIza..."
        }
    }

    var displayName: String { rawValue }
    var modelName: String {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .anthropic: return "claude-haiku-4-5-20251001"
        case .gemini: return "gemini-1.5-flash"
        }
    }
}

@MainActor
final class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()

    @Published var messages: [AIMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published var selectedProvider: AIProvider {
        didSet { UserDefaults.standard.set(selectedProvider.rawValue, forKey: "ai_provider") }
    }

    @Published var openAIKey: String { didSet { UserDefaults.standard.set(openAIKey, forKey: "key_openai") } }
    @Published var anthropicKey: String { didSet { UserDefaults.standard.set(anthropicKey, forKey: "key_anthropic") } }
    @Published var geminiKey: String { didSet { UserDefaults.standard.set(geminiKey, forKey: "key_gemini") } }

    var currentKey: String {
        switch selectedProvider {
        case .openAI: return openAIKey
        case .anthropic: return anthropicKey
        case .gemini: return geminiKey
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "ai_provider") ?? ""
        selectedProvider = AIProvider(rawValue: saved) ?? .openAI
        openAIKey = UserDefaults.standard.string(forKey: "key_openai") ?? ""
        anthropicKey = UserDefaults.standard.string(forKey: "key_anthropic") ?? ""
        geminiKey = UserDefaults.standard.string(forKey: "key_gemini") ?? ""
    }

    func send(userText: String) {
        guard !currentKey.isEmpty else {
            errorMessage = "Enter your \(selectedProvider.displayName) API key first."
            return
        }
        messages.append(AIMessage(role: "user", content: userText))
        isLoading = true
        errorMessage = nil

        let task: URLSessionDataTask
        switch selectedProvider {
        case .openAI: task = makeOpenAIRequest()
        case .anthropic: task = makeAnthropicRequest()
        case .gemini: task = makeGeminiRequest()
        }
        task.resume()
    }

    func clearHistory() { messages = [] }

    // MARK: - Request builders

    private func makeOpenAIRequest() -> URLSessionDataTask {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": AIProvider.openAI.modelName,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            Task { @MainActor [weak self] in
                self?.isLoading = false
                if let error { self?.errorMessage = error.localizedDescription; return }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let msg = choices.first?["message"] as? [String: Any],
                      let content = msg["content"] as? String
                else { self?.errorMessage = "Invalid response from OpenAI."; return }
                self?.messages.append(AIMessage(role: "assistant", content: content))
            }
        }
    }

    private func makeAnthropicRequest() -> URLSessionDataTask {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(anthropicKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": AIProvider.anthropic.modelName,
            "max_tokens": 1024,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            Task { @MainActor [weak self] in
                self?.isLoading = false
                if let error { self?.errorMessage = error.localizedDescription; return }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let contentArr = json["content"] as? [[String: Any]],
                      let text = contentArr.first?["text"] as? String
                else { self?.errorMessage = "Invalid response from Anthropic."; return }
                self?.messages.append(AIMessage(role: "assistant", content: text))
            }
        }
    }

    private func makeGeminiRequest() -> URLSessionDataTask {
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(AIProvider.gemini.modelName):generateContent?key=\(geminiKey)"
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let contents = messages.map { msg -> [String: Any] in
            let role = msg.role == "assistant" ? "model" : "user"
            return ["role": role, "parts": [["text": msg.content]]]
        }
        let body: [String: Any] = ["contents": contents]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            Task { @MainActor [weak self] in
                self?.isLoading = false
                if let error { self?.errorMessage = error.localizedDescription; return }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let candidates = json["candidates"] as? [[String: Any]],
                      let content = candidates.first?["content"] as? [String: Any],
                      let parts = content["parts"] as? [[String: Any]],
                      let text = parts.first?["text"] as? String
                else { self?.errorMessage = "Invalid response from Gemini."; return }
                self?.messages.append(AIMessage(role: "assistant", content: text))
            }
        }
    }
}
