import Foundation
import AnthropicSwiftSDK

struct ClaudeAPIService: Sendable {
    var apiKey: String

    private var client: Anthropic { Anthropic(apiKey: apiKey) }

    func send(systemPrompt: String, userMessage: String) async throws -> String {
        let response = try await client.messages.createMessage(
            [Message(role: .user, content: [.text(userMessage)])],
            model: .custom("claude-sonnet-4-6-20250514"),
            system: [.text(systemPrompt, nil)],
            maxTokens: 2048
        )

        for content in response.content {
            if case .text(let text, _) = content {
                return text
            }
        }
        throw APIError.invalidResponse
    }

    func stream(systemPrompt: String, userMessage: String) async throws -> AsyncThrowingStream<String, Error> {
        let stream = try await client.messages.streamMessage(
            [Message(role: .user, content: [.text(userMessage)])],
            model: .custom("claude-sonnet-4-6-20250514"),
            system: [.text(systemPrompt, nil)],
            maxTokens: 2048
        )

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await chunk in stream {
                        if let delta = chunk as? StreamingContentBlockDeltaResponse,
                           delta.delta.type == .text,
                           let text = delta.delta.text {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    enum APIError: LocalizedError {
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                "Invalid response from Claude API"
            }
        }
    }
}
