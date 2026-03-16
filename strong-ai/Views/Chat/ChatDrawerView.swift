import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    var isApplied: Bool = false

    enum Role {
        case user, assistant
    }
}

struct ChatDrawerView: View {
    @Binding var isPresented: Bool
    var workoutName: String?
    var elapsedTime: String?
    var exerciseProgress: String?
    var onSend: (String) async -> AsyncThrowingStream<ChatStreamEvent, Error>?

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Drawer
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                // Header
                HStack {
                    Text("Chat")
                        .font(.custom("SpaceGrotesk-Bold", size: 20))
                        .tracking(-0.4)
                        .foregroundStyle(Color(hex: 0x0A0A0A))
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.4))
                            .frame(width: 28, height: 28)
                            .background(Color(hex: 0xF5F5F5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                Divider()

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                messageView(message)
                            }

                            if isSending && (messages.isEmpty || messages.last?.role == .user) {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Thinking...")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("loading")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: messages.last?.text) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isSending) {
                        if isSending {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input
                HStack(spacing: 12) {
                    TextField("Ask anything...", text: $inputText)
                        .font(.system(size: 15))
                        .focused($isInputFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color(hex: 0xF5F5F5))
                        .clipShape(RoundedRectangle(cornerRadius: 21))
                        .onSubmit { Task { await send() } }
                        .disabled(isSending)

                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(
                                inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending
                                ? Color.black.opacity(0.15)
                                : Color(hex: 0x0A0A0A)
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.white)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        }
    }

    // MARK: - Message Views

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 60)
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0x2C2C2E))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(Color(hex: 0x0A0A0A).opacity(0.85))

                if message.isApplied {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Changes applied to your workout")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: 0x34C759))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Send

    private func send() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: text))
        inputText = ""
        isSending = true

        guard let stream = await onSend(text) else {
            isSending = false
            return
        }

        // Add an empty assistant message that we'll stream into
        let assistantIndex = messages.count
        messages.append(ChatMessage(role: .assistant, text: ""))

        do {
            for try await event in stream {
                switch event {
                case .text(let delta):
                    messages[assistantIndex].text += delta
                case .result(let result):
                    // Replace with the clean parsed explanation and mark applied
                    if !result.explanation.isEmpty {
                        messages[assistantIndex].text = result.explanation
                    }
                    messages[assistantIndex].isApplied = true
                }
            }
        } catch {
            if messages[assistantIndex].text.isEmpty {
                messages[assistantIndex].text = "Error: \(error.localizedDescription)"
            } else {
                messages[assistantIndex].text += "\n\nError: \(error.localizedDescription)"
            }
        }

        isSending = false
    }
}
