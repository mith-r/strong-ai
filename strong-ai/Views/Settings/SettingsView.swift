import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let new = UserProfile()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.custom("SpaceGrotesk-Bold", size: 36))
                    .tracking(-1.4)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        settingsSection("API KEY") {
                            SecureField("sk-ant-...", text: binding(\.apiKey))
                        }
                        settingsSection("GOALS") {
                            TextField("e.g. Build muscle, lose fat", text: binding(\.goals), axis: .vertical)
                                .lineLimit(3...6)
                        }
                        settingsSection("SCHEDULE") {
                            TextField("e.g. 4 days/week, Mon/Tue/Thu/Fri", text: binding(\.schedule), axis: .vertical)
                                .lineLimit(2...4)
                        }
                        settingsSection("EQUIPMENT") {
                            TextField("e.g. Full gym, home dumbbells only", text: binding(\.equipment), axis: .vertical)
                                .lineLimit(2...4)
                        }
                        settingsSection("INJURIES / LIMITATIONS") {
                            TextField("e.g. Bad left shoulder, avoid overhead", text: binding(\.injuries), axis: .vertical)
                                .lineLimit(2...4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.black.opacity(0.35))

            content()
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color(hex: 0xF5F5F5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { profile[keyPath: keyPath] = $0 }
        )
    }
}
