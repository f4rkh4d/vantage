import SwiftUI

struct AIAssistantView: View {
    @ObservedObject private var manager = AIAssistantManager.shared
    private let accent = Module.aiAssistant.accentColor

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if manager.apiKey.isEmpty {
                apiKeySetup
            } else {
                chatView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.aiAssistant.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("AI Assistant")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if !manager.apiKey.isEmpty {
                Button("Clear") { manager.clearHistory() }
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var apiKeySetup: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 28))
                .foregroundStyle(accent.opacity(0.6))

            VStack(spacing: 6) {
                Text("OpenAI API Key Required")
                    .font(.system(size: 13, weight: .semibold))
                Text("Enter your API key to start chatting.\nStored locally in UserDefaults.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            APIKeyField(accent: accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            if let err = manager.errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.05))
            }

            messageList

            Divider()
            inputBar
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(manager.messages) { msg in
                        MessageBubble(message: msg, accent: accent)
                            .id(msg.id)
                    }
                    if manager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.6)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .id("loading")
                    }
                }
                .padding(.vertical, 10)
            }
            .onChange(of: manager.messages.count) { _, _ in
                if let last = manager.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: manager.isLoading) { _, loading in
                if loading {
                    withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        ChatInputBar(accent: accent) { text in
            manager.send(userText: text)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
    }
}

private struct MessageBubble: View {
    let message: AIMessage
    let accent: Color

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.content)
                .font(.system(size: 12))
                .foregroundStyle(isUser ? .white : .primary)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(isUser ? accent : Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)
            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 14)
    }
}

private struct ChatInputBar: View {
    let accent: Color
    let onSend: (String) -> Void

    @State private var text = ""

    var body: some View {
        HStack(spacing: 8) {
            TextField("Ask anything…", text: $text, axis: .vertical)
                .font(.system(size: 12))
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit {
                    send()
                }

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.3) : accent)
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        text = ""
        onSend(trimmed)
    }
}

private struct APIKeyField: View {
    let accent: Color
    @ObservedObject private var manager = AIAssistantManager.shared
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 8) {
            SecureField("sk-...", text: $draft)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)

            Button("Save Key") {
                manager.apiKey = draft
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 6)
            .background(draft.isEmpty ? Color.secondary.opacity(0.3) : accent)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .buttonStyle(.plain)
            .disabled(draft.isEmpty)
        }
    }
}
