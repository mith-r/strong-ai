import SwiftUI

struct WorkoutDebriefView: View {
    let log: WorkoutLog
    let recentLogs: [WorkoutLogSnapshot]
    let profile: UserProfileSnapshot
    let apiKey: String

    @Environment(\.dismiss) private var dismiss
    @State private var debrief: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats summary
                    HStack(spacing: 10) {
                        StatCard(title: "DURATION", value: "\(log.durationMinutes)m")
                        StatCard(title: "SETS", value: "\(log.totalSets)")
                        StatCard(title: "VOLUME", value: "\(Int(log.totalVolume).formatted())")
                    }
                    .padding(.top, 8)

                    if isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Analyzing your workout...")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    } else if let debrief {
                        Text(debrief)
                            .font(.system(size: 16, weight: .regular))
                            .lineSpacing(4)
                            .foregroundStyle(Color(hex: 0x0A0A0A).opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.custom("SpaceGrotesk-Bold", size: 17))
                        .tracking(-0.2)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: 0x0A0A0A))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadDebrief()
            }
        }
    }

    private func loadDebrief() async {
        guard !apiKey.isEmpty else {
            debrief = "Great workout! Add your API key in Settings to get personalized AI analysis."
            isLoading = false
            return
        }

        do {
            let logSnapshot = WorkoutLogSnapshot(
                workoutName: log.workoutName,
                startedAt: log.startedAt,
                durationMinutes: log.durationMinutes,
                totalVolume: log.totalVolume,
                entries: log.entries
            )
            debrief = try await WorkoutAIService.generateDebrief(
                apiKey: apiKey,
                log: logSnapshot,
                recentLogs: recentLogs,
                profile: profile
            )
        } catch {
            debrief = "Nice work finishing \(log.workoutName)! \(log.totalSets) sets, \(Int(log.totalVolume).formatted()) lbs total volume in \(log.durationMinutes) minutes."
        }

        isLoading = false
    }
}
