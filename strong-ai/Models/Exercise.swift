import Foundation
import os
import SwiftData

private let logger = Logger(subsystem: "com.strong-ai", category: "Exercise")

@Model
final class Exercise {
    var name: String
    var muscleGroup: String
    var exerciseDescription: String?
    var instructionsData: Data?

    var instructions: [String] {
        get {
            guard let data = instructionsData else { return [] }
            do {
                return try JSONDecoder().decode([String].self, from: data)
            } catch {
                logger.error("Failed to decode instructions: \(error)")
                return []
            }
        }
        set {
            do {
                instructionsData = try JSONEncoder().encode(newValue)
            } catch {
                logger.error("Failed to encode instructions: \(error)")
            }
        }
    }

    init(name: String, muscleGroup: String, exerciseDescription: String? = nil, instructions: [String] = []) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.exerciseDescription = exerciseDescription
        if !instructions.isEmpty {
            do {
                self.instructionsData = try JSONEncoder().encode(instructions)
            } catch {
                logger.error("Failed to encode initial instructions: \(error)")
            }
        }
    }
}
