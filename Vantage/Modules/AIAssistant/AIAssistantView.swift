import SwiftUI

struct AIAssistantView: View {
    @ObservedObject private var manager = AIAssistantManager.shared
    private let accent = Module.aiAssistant.accentColor

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if showSettings {
                ProviderSettingsPanel(accent: accent)
            } else if manager.currentKey.isEmpty {
                keySetupView
            } else {
                chatView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: Module.aiAssistant.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text("AI Assistant")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            // Provider picker
            providerPicker

            // Gear button
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: showSettings ? "gearshape.fill" : "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(showSettings ? accent : .secondary)
            }
            .buttonStyle(.plain)

            // Clear button (only visible when chatting)
            if !manager.currentKey.isEmpty && !showSettings {
                Button("Clear") {
                    manager.clearHistory()
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var providerPicker: some View {
        Picker("", selection: Binding(
            get: { manager.selectedProvider },
            set: { newProvider in
                manager.selectedProvider = newProvider
                manager.clearHistory()
            }
        )) {
            ForEach(AIProvider.allCases) { provider in
                HStack(spacing: 4) {
                    Circle()
                        .fill(providerColor(provider))
                        .frame(width: 7, height: 7)
                    Text(provider.displayName)
                }
                .tag(provider)
            }
        }
        .pickerStyle(.menu)
        .font(.system(size: 11))
        .labelsHidden()
        .frame(maxWidth: 100)
    }

    private func providerColor(_ provider: AIProvider) -> Color {
        switch provider {
        case .openAI: return .green
        case .anthropic: return .orange
        case .gemini: return .blue
        }
    }

    // MARK: - Key setup

    private var keySetupView: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(providerColor(manager.selectedProvider).opacity(0.12))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "key.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(providerColor(manager.selectedProvider).opacity(0.7))
                )

            VStack(spacing: 6) {
                Text("\(manager.selectedProvider.displayName) API Key Required")
                    .font(.system(size: 13, weight: .semibold))
                Text("Enter your API key to start chatting.\nStored locally in UserDefaults.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text(keyHintText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            InlineKeyField(provider: manager.selectedProvider, accent: providerColor(manager.selectedProvider))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }

    private var keyHintText: String {
        switch manager.selectedProvider {
        case .openAI: return "Get your key at platform.openai.com"
        case .anthropic: return "Get your key at console.anthropic.com"
        case .gemini: return "Get your key at aistudio.google.com"
        }
    }

    // MARK: - Chat

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

// MARK: - MessageBubble

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

// MARK: - ChatInputBar

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
                    .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.secondary.opacity(0.3)
                        : accent)
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

// MARK: - InlineKeyField (single provider, shown on setup screen)

private struct InlineKeyField: View {
    let provider: AIProvider
    let accent: Color
    @ObservedObject private var manager = AIAssistantManager.shared
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 8) {
            SecureField(provider.keyPrompt, text: $draft)
                .font(.system(size: 12, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)

            Button("Save Key") {
                saveKey()
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

    private func saveKey() {
        switch provider {
        case .openAI: manager.openAIKey = draft
        case .anthropic: manager.anthropicKey = draft
        case .gemini: manager.geminiKey = draft
        }
    }
}

// MARK: - ProviderSettingsPanel (all three keys, shown via gear)

private struct ProviderSettingsPanel: View {
    let accent: Color
    @ObservedObject private var manager = AIAssistantManager.shared

    @State private var draftOpenAI = ""
    @State private var draftAnthropic = ""
    @State private var draftGemini = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("API Keys")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.bottom, 2)

                providerKeyRow(
                    label: "OpenAI",
                    color: .green,
                    placeholder: AIProvider.openAI.keyPrompt,
                    draft: $draftOpenAI,
                    saved: manager.openAIKey,
                    onSave: { manager.openAIKey = draftOpenAI }
                )

                providerKeyRow(
                    label: "Anthropic",
                    color: .orange,
                    placeholder: AIProvider.anthropic.keyPrompt,
                    draft: $draftAnthropic,
                    saved: manager.anthropicKey,
                    onSave: { manager.anthropicKey = draftAnthropic }
                )

                providerKeyRow(
                    label: "Gemini",
                    color: .blue,
                    placeholder: AIProvider.gemini.keyPrompt,
                    draft: $draftGemini,
                    saved: manager.geminiKey,
                    onSave: { manager.geminiKey = draftGemini }
                )

                Text("Keys are stored locally in UserDefaults.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .padding(16)
        }
        .onAppear {
            draftOpenAI = manager.openAIKey
            draftAnthropic = manager.anthropicKey
            draftGemini = manager.geminiKey
        }
    }

    private func providerKeyRow(
        label: String,
        color: Color,
        placeholder: String,
        draft: Binding<String>,
        saved: String,
        onSave: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                if !saved.isEmpty {
                    Text("saved")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            HStack(spacing: 8) {
                SecureField(placeholder, text: draft)
                    .font(.system(size: 11, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                Button("Save") {
                    onSave()
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(draft.wrappedValue.isEmpty ? Color.secondary.opacity(0.3) : color)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .buttonStyle(.plain)
                .disabled(draft.wrappedValue.isEmpty)
            }
        }
    }
}
