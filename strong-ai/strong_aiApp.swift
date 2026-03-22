import SwiftUI
import SwiftData

@main
struct strong_aiApp: App {
    let container: ModelContainer

    init() {
        let container = try! ModelContainer(for: Exercise.self, WorkoutLog.self, UserProfile.self)
        self.container = container

        #if DEBUG
        SeedData.clearAll(container.mainContext)
        SeedData.populate(container.mainContext)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
