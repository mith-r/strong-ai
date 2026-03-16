import Foundation

struct Workout: Codable {
    var name: String
    var exercises: [WorkoutExercise]

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }
    var estimatedMinutes: Int { totalSets * 3 }
}

struct WorkoutExercise: Codable {
    var name: String
    var muscleGroup: String
    var sets: [WorkoutSet]
}

struct WorkoutSet: Codable {
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var isWarmup: Bool

    init(reps: Int, weight: Double, restSeconds: Int, isWarmup: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.restSeconds = restSeconds
        self.isWarmup = isWarmup
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reps = try container.decode(Int.self, forKey: .reps)
        weight = try container.decode(Double.self, forKey: .weight)
        restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 90
        isWarmup = try container.decodeIfPresent(Bool.self, forKey: .isWarmup) ?? false
    }
}

// MARK: - Sample (placeholder until AI generates workouts)

extension Workout {
    static let sample = Workout(
        name: "Upper Body Push",
        exercises: [
            WorkoutExercise(name: "Bench Press", muscleGroup: "Chest", sets: [
                WorkoutSet(reps: 8, weight: 135, restSeconds: 90),
                WorkoutSet(reps: 8, weight: 135, restSeconds: 90),
                WorkoutSet(reps: 8, weight: 135, restSeconds: 90),
            ]),
            WorkoutExercise(name: "Overhead Press", muscleGroup: "Shoulders", sets: [
                WorkoutSet(reps: 10, weight: 65, restSeconds: 75),
                WorkoutSet(reps: 10, weight: 65, restSeconds: 75),
                WorkoutSet(reps: 10, weight: 65, restSeconds: 75),
            ]),
            WorkoutExercise(name: "Incline Dumbbell Press", muscleGroup: "Chest", sets: [
                WorkoutSet(reps: 12, weight: 40, restSeconds: 60),
                WorkoutSet(reps: 12, weight: 40, restSeconds: 60),
                WorkoutSet(reps: 12, weight: 40, restSeconds: 60),
            ]),
            WorkoutExercise(name: "Tricep Pushdown", muscleGroup: "Triceps", sets: [
                WorkoutSet(reps: 15, weight: 30, restSeconds: 45),
                WorkoutSet(reps: 15, weight: 30, restSeconds: 45),
                WorkoutSet(reps: 15, weight: 30, restSeconds: 45),
            ]),
        ]
    )
}
