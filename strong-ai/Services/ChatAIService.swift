import Foundation

enum ChatStreamEvent: Sendable {
    case text(String)
    case result(ChatResult)
}

struct ChatResult: Sendable, Codable {
    var workout: Workout
    var explanation: String
}

struct ChatAIService {

    static func stream(
        apiKey: String,
        message: String,
        currentWorkout: Workout?,
        profile: UserProfileSnapshot
    ) async throws -> AsyncThrowingStream<ChatStreamEvent, Error> {
        let api = ClaudeAPIService(apiKey: apiKey)

        let mode = currentWorkout != nil ? "modify" : "create"

        let systemPrompt = """
        You are an expert strength coach. The user is asking you to \(mode) a workout via natural language.

        Respond in this EXACT format — explanation first, then JSON after a separator:

        Write 1-2 sentences explaining what you did and why.
        ---JSON
        {
          "name": "Workout Name",
          "exercises": [
            {
              "name": "Exercise Name",
              "muscleGroup": "Muscle Group",
              "sets": [
                { "reps": 8, "weight": 135, "restSeconds": 90, "isWarmup": false }
              ]
            }
          ]
        }

        \(currentWorkout != nil ? "The user has an existing workout. Modify it based on their request — keep exercises they didn't mention, adjust what they asked about." : "Create a new workout from scratch based on the user's request.")

        User context:
        Goals: \(profile.goals.isEmpty ? "Not specified" : profile.goals)
        Equipment: \(profile.equipment.isEmpty ? "Not specified" : profile.equipment)
        Injuries: \(profile.injuries.isEmpty ? "None" : profile.injuries)
        """

        var userMessage = message
        if let workout = currentWorkout,
           let json = try? JSONEncoder().encode(workout),
           let str = String(data: json, encoding: .utf8) {
            userMessage += "\n\nCurrent workout:\n\(str)"
        }

        let tokenStream = try await api.stream(systemPrompt: systemPrompt, userMessage: userMessage)

        return AsyncThrowingStream { continuation in
            Task {
                var accumulated = ""
                var sentExplanationUpTo = 0

                do {
                    for try await token in tokenStream {
                        accumulated += token

                        // Stream explanation text (everything before ---JSON)
                        if let separatorRange = accumulated.range(of: "---JSON") {
                            let explanation = String(accumulated[accumulated.startIndex..<separatorRange.lowerBound])
                            if explanation.count > sentExplanationUpTo {
                                let new = String(explanation.dropFirst(sentExplanationUpTo))
                                continuation.yield(.text(new))
                                sentExplanationUpTo = explanation.count
                            }
                        } else {
                            // Haven't hit separator yet — stream everything so far
                            if accumulated.count > sentExplanationUpTo {
                                let new = String(accumulated.dropFirst(sentExplanationUpTo))
                                continuation.yield(.text(new))
                                sentExplanationUpTo = accumulated.count
                            }
                        }
                    }

                    // Parse the final result
                    let result = try parseResult(from: accumulated)
                    continuation.yield(.result(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private static func parseResult(from response: String) throws -> ChatResult {
        let explanation: String
        let jsonString: String

        if let separatorRange = response.range(of: "---JSON") {
            explanation = response[response.startIndex..<separatorRange.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let afterSeparator = String(response[separatorRange.upperBound...])
            jsonString = extractJSON(from: afterSeparator)
        } else {
            // Fallback: try to find JSON in the whole response
            explanation = ""
            jsonString = extractJSON(from: response)
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw WorkoutAIService.ParseError.invalidJSON
        }

        let workout = try JSONDecoder().decode(Workout.self, from: data)
        return ChatResult(workout: workout, explanation: explanation)
    }

    private static func extractJSON(from text: String) -> String {
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.lowerBound])
        }
        return text
    }
}
