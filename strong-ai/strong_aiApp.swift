import SwiftUI
import SwiftData

@main
struct strong_aiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Exercise.self,
            WorkoutLog.self,
            UserProfile.self,
        ])
    }
}
