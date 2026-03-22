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

struct ChatDrawerView<CollapsedExtra: View>: View {
    @Binding var isExpanded: Bool
    @Binding var pendingMessage: String?
    var placeholder: String
    var workoutName: String?
    var elapsedTime: String?
    var exerciseProgress: String?
    var collapsedHeight: CGFloat = 80
    var onSend: (String) async -> AsyncThrowingStream<ChatStreamEvent, Error>?
    @ViewBuilder var collapsedExtra: () -> CollapsedExtra

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool
    @State private var barText = ""

    var body: some View {
        VStack {
            Spacer()
            collapsedBar
                .background {
                    Color.white
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                        .ignoresSafeArea(.container, edges: .bottom)
                }
        }
        .sheet(isPresented: $isExpanded) {
            expandedContent
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(16)
                .presentationBackground(.white)
        }
    }

    // MARK: - Collapsed Bar

    private var collapsedBar: some View {
        VStack(spacing: 10) {
            // Grab handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.15))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .contentShape(Rectangle())
                .onTapGesture { isExpanded = true }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            if value.translation.height < -30 {
                                isExpanded = true
                            }
                        }
                )

            HStack(spacing: 12) {
                TextField(placeholder, text: $barText, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: 0xF5F5F5))
                    .clipShape(RoundedRectangle(cornerRadius: 21))
                    .onSubmit { sendFromBar() }

                Button {
                    sendFromBar()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(
                            !barText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(hex: 0x0A0A0A)
                            : Color.black.opacity(0.15)
                        )
                }
                .disabled(barText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            collapsedExtra()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat")
                    .font(.custom("SpaceGrotesk-Bold", size: 20))
                    .tracking(-0.4)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                Spacer()
                Button { isExpanded = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: 0xF5F5F5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

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
                .scrollDismissesKeyboard(.interactively)
            }

            Divider()

            // Input
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $inputText, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: 0xF5F5F5))
                    .clipShape(RoundedRectangle(cornerRadius: 21))
                    .onSubmit { Task { await send() } }

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
            .task(id: isExpanded) {
                guard isExpanded, let message = pendingMessage else { return }
                pendingMessage = nil
                messages.append(ChatMessage(role: .user, text: message))
                await streamResponse(for: message)
            }
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

    // MARK: - Actions

    private func sendFromBar() {
        let text = barText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        pendingMessage = text
        barText = ""
        isExpanded = true
    }

    private func send() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: text))
        inputText = ""
        await streamResponse(for: text)
    }

    private func streamResponse(for text: String) async {
        isSending = true

        guard let stream = await onSend(text) else {
            isSending = false
            return
        }

        let assistantIndex = messages.count
        messages.append(ChatMessage(role: .assistant, text: ""))

        do {
            for try await event in stream {
                switch event {
                case .text(let delta):
                    messages[assistantIndex].text += delta
                case .result(let result):
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
