import SwiftData

extension ModelContainer {
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: Exercise.self, WorkoutLog.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        SeedData.populate(container.mainContext)
        return container
    }
}
