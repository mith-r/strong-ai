import Foundation
import SwiftData

enum SeedData {
    static func clearAll(_ context: ModelContext) {
        try? context.delete(model: Exercise.self)
        try? context.delete(model: WorkoutLog.self)
    }

    static func populate(_ context: ModelContext) {
        // MARK: - Exercises

        let exercises = [
            Exercise(name: "Bench Press", muscleGroup: "Chest",
                     exerciseDescription: "Barbell flat bench press",
                     instructions: ["Lie on bench with eyes under bar", "Grip bar slightly wider than shoulders", "Lower to mid-chest, press up"]),
            Exercise(name: "Incline Dumbbell Press", muscleGroup: "Chest",
                     exerciseDescription: "Dumbbell press on 30-45° incline",
                     instructions: ["Set bench to 30-45°", "Press dumbbells from shoulder level", "Lower with control"]),
            Exercise(name: "Overhead Press", muscleGroup: "Shoulders",
                     exerciseDescription: "Standing barbell overhead press",
                     instructions: ["Grip bar at shoulder width", "Press overhead to lockout", "Keep core braced throughout"]),
            Exercise(name: "Lateral Raise", muscleGroup: "Shoulders",
                     exerciseDescription: "Dumbbell lateral raise for side delts",
                     instructions: ["Hold dumbbells at sides", "Raise to shoulder height with slight bend in elbows", "Lower slowly"]),
            Exercise(name: "Barbell Row", muscleGroup: "Back",
                     exerciseDescription: "Bent-over barbell row",
                     instructions: ["Hinge at hips, back flat", "Pull bar to lower chest", "Squeeze shoulder blades at top"]),
            Exercise(name: "Pull-Up", muscleGroup: "Back",
                     exerciseDescription: "Bodyweight pull-up",
                     instructions: ["Hang with palms facing away", "Pull chin over bar", "Lower with control"]),
            Exercise(name: "Squat", muscleGroup: "Legs",
                     exerciseDescription: "Barbell back squat",
                     instructions: ["Bar on upper back, feet shoulder width", "Squat to parallel or below", "Drive through heels to stand"]),
            Exercise(name: "Romanian Deadlift", muscleGroup: "Legs",
                     exerciseDescription: "Barbell Romanian deadlift for hamstrings",
                     instructions: ["Hold bar at hip level", "Hinge at hips, slight knee bend", "Lower until stretch in hamstrings, return to top"]),
            Exercise(name: "Tricep Pushdown", muscleGroup: "Triceps",
                     exerciseDescription: "Cable tricep pushdown",
                     instructions: ["Grip cable attachment at chest height", "Extend arms fully", "Keep elbows pinned to sides"]),
            Exercise(name: "Barbell Curl", muscleGroup: "Biceps",
                     exerciseDescription: "Standing barbell curl",
                     instructions: ["Grip bar at shoulder width", "Curl to shoulder height", "Lower with control, no swinging"]),
        ]

        for exercise in exercises {
            context.insert(exercise)
        }

        // MARK: - User Profile

        let profile = UserProfile(
            goals: "Build muscle, improve strength",
            schedule: "4 days per week, 60 minute sessions",
            equipment: "Full gym — barbell, dumbbells, cables, pull-up bar",
            injuries: ""
        )
        context.insert(profile)

        // MARK: - Workout Logs (8 workouts over ~4 weeks)

        let now = Date.now
        func daysAgo(_ days: Int) -> Date { now.addingTimeInterval(Double(-days) * 86400) }
        func minutesAfter(_ date: Date, _ minutes: Int) -> Date { date.addingTimeInterval(Double(minutes) * 60) }

        let logs: [(String, Int, [LogEntry])] = [
            // Week 4 (oldest)
            ("Upper Body Push", 25, [
                LogEntry(exerciseName: "Bench Press", muscleGroup: "Chest", sets: [
                    LogSet(reps: 8, weight: 125, rpe: 7, completedAt: daysAgo(25)),
                    LogSet(reps: 8, weight: 125, rpe: 8, completedAt: daysAgo(25)),
                    LogSet(reps: 7, weight: 125, rpe: 9, completedAt: daysAgo(25)),
                ]),
                LogEntry(exerciseName: "Overhead Press", muscleGroup: "Shoulders", sets: [
                    LogSet(reps: 10, weight: 55, rpe: 7, completedAt: daysAgo(25)),
                    LogSet(reps: 10, weight: 55, rpe: 8, completedAt: daysAgo(25)),
                    LogSet(reps: 9, weight: 55, rpe: 9, completedAt: daysAgo(25)),
                ]),
                LogEntry(exerciseName: "Tricep Pushdown", muscleGroup: "Triceps", sets: [
                    LogSet(reps: 15, weight: 25, completedAt: daysAgo(25)),
                    LogSet(reps: 15, weight: 25, completedAt: daysAgo(25)),
                ]),
            ]),
            ("Upper Body Pull", 23, [
                LogEntry(exerciseName: "Barbell Row", muscleGroup: "Back", sets: [
                    LogSet(reps: 8, weight: 115, rpe: 7, completedAt: daysAgo(23)),
                    LogSet(reps: 8, weight: 115, rpe: 8, completedAt: daysAgo(23)),
                    LogSet(reps: 8, weight: 115, rpe: 8, completedAt: daysAgo(23)),
                ]),
                LogEntry(exerciseName: "Pull-Up", muscleGroup: "Back", sets: [
                    LogSet(reps: 8, weight: 0, rpe: 8, completedAt: daysAgo(23)),
                    LogSet(reps: 7, weight: 0, rpe: 9, completedAt: daysAgo(23)),
                    LogSet(reps: 6, weight: 0, rpe: 9, completedAt: daysAgo(23)),
                ]),
                LogEntry(exerciseName: "Barbell Curl", muscleGroup: "Biceps", sets: [
                    LogSet(reps: 12, weight: 45, completedAt: daysAgo(23)),
                    LogSet(reps: 12, weight: 45, completedAt: daysAgo(23)),
                ]),
            ]),
            // Week 3
            ("Lower Body", 18, [
                LogEntry(exerciseName: "Squat", muscleGroup: "Legs", sets: [
                    LogSet(reps: 8, weight: 155, rpe: 7, completedAt: daysAgo(18)),
                    LogSet(reps: 8, weight: 155, rpe: 8, completedAt: daysAgo(18)),
                    LogSet(reps: 7, weight: 155, rpe: 9, completedAt: daysAgo(18)),
                ]),
                LogEntry(exerciseName: "Romanian Deadlift", muscleGroup: "Legs", sets: [
                    LogSet(reps: 10, weight: 115, rpe: 7, completedAt: daysAgo(18)),
                    LogSet(reps: 10, weight: 115, rpe: 8, completedAt: daysAgo(18)),
                    LogSet(reps: 10, weight: 115, rpe: 8, completedAt: daysAgo(18)),
                ]),
            ]),
            ("Upper Body Push", 16, [
                LogEntry(exerciseName: "Bench Press", muscleGroup: "Chest", sets: [
                    LogSet(reps: 8, weight: 130, rpe: 7, completedAt: daysAgo(16)),
                    LogSet(reps: 8, weight: 130, rpe: 8, completedAt: daysAgo(16)),
                    LogSet(reps: 8, weight: 130, rpe: 8, completedAt: daysAgo(16)),
                ]),
                LogEntry(exerciseName: "Incline Dumbbell Press", muscleGroup: "Chest", sets: [
                    LogSet(reps: 10, weight: 40, rpe: 7, completedAt: daysAgo(16)),
                    LogSet(reps: 10, weight: 40, rpe: 8, completedAt: daysAgo(16)),
                    LogSet(reps: 10, weight: 40, rpe: 8, completedAt: daysAgo(16)),
                ]),
                LogEntry(exerciseName: "Lateral Raise", muscleGroup: "Shoulders", sets: [
                    LogSet(reps: 15, weight: 15, completedAt: daysAgo(16)),
                    LogSet(reps: 15, weight: 15, completedAt: daysAgo(16)),
                ]),
            ]),
            // Week 2
            ("Upper Body Pull", 11, [
                LogEntry(exerciseName: "Barbell Row", muscleGroup: "Back", sets: [
                    LogSet(reps: 8, weight: 120, rpe: 7, completedAt: daysAgo(11)),
                    LogSet(reps: 8, weight: 120, rpe: 8, completedAt: daysAgo(11)),
                    LogSet(reps: 8, weight: 120, rpe: 8, completedAt: daysAgo(11)),
                ]),
                LogEntry(exerciseName: "Pull-Up", muscleGroup: "Back", sets: [
                    LogSet(reps: 9, weight: 0, rpe: 7, completedAt: daysAgo(11)),
                    LogSet(reps: 8, weight: 0, rpe: 8, completedAt: daysAgo(11)),
                    LogSet(reps: 7, weight: 0, rpe: 9, completedAt: daysAgo(11)),
                ]),
                LogEntry(exerciseName: "Barbell Curl", muscleGroup: "Biceps", sets: [
                    LogSet(reps: 12, weight: 50, completedAt: daysAgo(11)),
                    LogSet(reps: 12, weight: 50, completedAt: daysAgo(11)),
                ]),
            ]),
            ("Lower Body", 9, [
                LogEntry(exerciseName: "Squat", muscleGroup: "Legs", sets: [
                    LogSet(reps: 8, weight: 165, rpe: 7, completedAt: daysAgo(9)),
                    LogSet(reps: 8, weight: 165, rpe: 8, completedAt: daysAgo(9)),
                    LogSet(reps: 7, weight: 165, rpe: 9, completedAt: daysAgo(9)),
                ]),
                LogEntry(exerciseName: "Romanian Deadlift", muscleGroup: "Legs", sets: [
                    LogSet(reps: 10, weight: 125, rpe: 7, completedAt: daysAgo(9)),
                    LogSet(reps: 10, weight: 125, rpe: 8, completedAt: daysAgo(9)),
                    LogSet(reps: 10, weight: 125, rpe: 9, completedAt: daysAgo(9)),
                ]),
            ]),
            // Week 1 (most recent)
            ("Upper Body Push", 4, [
                LogEntry(exerciseName: "Bench Press", muscleGroup: "Chest", sets: [
                    LogSet(reps: 8, weight: 135, rpe: 7, completedAt: daysAgo(4)),
                    LogSet(reps: 8, weight: 135, rpe: 8, completedAt: daysAgo(4)),
                    LogSet(reps: 8, weight: 135, rpe: 8, completedAt: daysAgo(4)),
                ]),
                LogEntry(exerciseName: "Overhead Press", muscleGroup: "Shoulders", sets: [
                    LogSet(reps: 10, weight: 65, rpe: 7, completedAt: daysAgo(4)),
                    LogSet(reps: 10, weight: 65, rpe: 8, completedAt: daysAgo(4)),
                    LogSet(reps: 9, weight: 65, rpe: 9, completedAt: daysAgo(4)),
                ]),
                LogEntry(exerciseName: "Tricep Pushdown", muscleGroup: "Triceps", sets: [
                    LogSet(reps: 15, weight: 30, completedAt: daysAgo(4)),
                    LogSet(reps: 15, weight: 30, completedAt: daysAgo(4)),
                ]),
            ]),
            ("Upper Body Pull", 2, [
                LogEntry(exerciseName: "Barbell Row", muscleGroup: "Back", sets: [
                    LogSet(reps: 8, weight: 125, rpe: 7, completedAt: daysAgo(2)),
                    LogSet(reps: 8, weight: 125, rpe: 7, completedAt: daysAgo(2)),
                    LogSet(reps: 8, weight: 125, rpe: 8, completedAt: daysAgo(2)),
                ]),
                LogEntry(exerciseName: "Pull-Up", muscleGroup: "Back", sets: [
                    LogSet(reps: 10, weight: 0, rpe: 7, completedAt: daysAgo(2)),
                    LogSet(reps: 9, weight: 0, rpe: 8, completedAt: daysAgo(2)),
                    LogSet(reps: 8, weight: 0, rpe: 9, completedAt: daysAgo(2)),
                ]),
                LogEntry(exerciseName: "Barbell Curl", muscleGroup: "Biceps", sets: [
                    LogSet(reps: 12, weight: 55, completedAt: daysAgo(2)),
                    LogSet(reps: 12, weight: 55, completedAt: daysAgo(2)),
                ]),
            ]),
        ]

        for (name, daysBack, entries) in logs {
            let start = daysAgo(daysBack)
            let log = WorkoutLog(workoutName: name, entries: entries, startedAt: start)
            log.finishedAt = minutesAfter(start, 55)
            context.insert(log)
        }
    }
}
