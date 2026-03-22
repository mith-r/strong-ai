import SwiftData

enum UserProfileService {
    static func loadAPIKey() -> String {
        UserProfile.loadSavedAPIKey()
    }

    @discardableResult
    static func ensureProfile(existingProfile: UserProfile?, modelContext: ModelContext) -> UserProfile {
        if let existingProfile {
            return existingProfile
        }

        let profile = UserProfile()
        modelContext.insert(profile)
        return profile
    }

    static func saveAPIKey(_ apiKey: String, for profile: UserProfile?, modelContext: ModelContext) throws {
        let createdProfile = profile == nil
        _ = ensureProfile(existingProfile: profile, modelContext: modelContext)
        try UserProfile.saveAPIKey(apiKey)

        if createdProfile {
            try modelContext.save()
        }
    }
}
