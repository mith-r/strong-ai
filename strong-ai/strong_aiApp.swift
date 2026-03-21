import SwiftUI
import SwiftData

@main
struct strong_aiApp: App {
    let container: ModelContainer

    init() {
        let container = try! ModelContainer(for: Exercise.self, WorkoutLog.self, UserProfile.self)
        self.container = container

        #if DEBUG
        let existingKey = (try? container.mainContext.fetch(FetchDescriptor<UserProfile>()))?.first?.apiKey ?? ""
        SeedData.clearAll(container.mainContext)
        SeedData.populate(container.mainContext)
        if let profile = try? container.mainContext.fetch(FetchDescriptor<UserProfile>()).first {
            profile.apiKey = existingKey
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
