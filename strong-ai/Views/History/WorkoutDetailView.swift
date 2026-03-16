import SwiftUI

struct WorkoutDetailView: View {
    let log: WorkoutLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                statsHeader
                ForEach(Array(log.entries.enumerated()), id: \.offset) { _, entry in
                    exerciseSection(entry)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(log.workoutName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 10) {
            StatCard(title: "DURATION", value: "\(log.durationMinutes)m")
            StatCard(title: "SETS", value: "\(log.totalSets)")
            StatCard(title: "VOLUME", value: "\(Int(log.totalVolume).formatted())")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Exercise Section

    private func exerciseSection(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.exerciseName)
                .font(.custom("SpaceGrotesk-Bold", size: 17))
                .tracking(-0.3)
                .foregroundStyle(Color(hex: 0x0A0A0A))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

            Text(entry.muscleGroup.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Color.black.opacity(0.35))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            // Column headers
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 40, alignment: .leading)
                Text("LBS")
                    .frame(width: 72, alignment: .leading)
                Text("REPS")
                    .frame(width: 64, alignment: .leading)
                Spacer()
            }
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Color.black.opacity(0.3))
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                ForEach(Array(entry.sets.enumerated()), id: \.offset) { setIndex, set in
                    HStack(spacing: 0) {
                        Text("\(setIndex + 1)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(set.completedAt != nil ? Color(hex: 0x34C759) : Color.black.opacity(0.3))
                            .frame(width: 40, alignment: .leading)

                        Text("\(Int(set.weight))")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 72, alignment: .leading)

                        Text("\(set.reps)")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 64, alignment: .leading)

                        Spacer()

                        if set.isWarmup {
                            TagBadge(text: "W", color: .orange)
                        }
                        if set.isFailure {
                            TagBadge(text: "F", color: .red)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    if setIndex < entry.sets.count - 1 {
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
    }
}

// MARK: - Tag Badge

private struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Stat Card (reuse from Home — making it internal)

struct StatCard: View {
    let title: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("SpaceGrotesk-Bold", size: 28))
                .tracking(-0.5)
                .foregroundStyle(highlight ? Color(hex: 0x34C759) : Color(hex: 0x0A0A0A))
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.black.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: 0xF5F5F5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
