import SwiftUI
import SwiftData

private struct ExerciseStats {
    var timesPerformed: Int = 0
    var bestWeight: Double = 0
}

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(filter: #Predicate<WorkoutLog> { $0.finishedAt != nil }) private var workoutLogs: [WorkoutLog]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingSearch = false

    // MARK: - Computed Properties

    private var exerciseStatsMap: [String: ExerciseStats] {
        var map: [String: ExerciseStats] = [:]
        for log in workoutLogs {
            for entry in log.entries {
                var stats = map[entry.exerciseName, default: ExerciseStats()]
                stats.timesPerformed += 1
                let maxWeight = entry.sets.compactMap({ $0.completedAt != nil ? $0.weight : nil }).max() ?? 0
                if maxWeight > stats.bestWeight { stats.bestWeight = maxWeight }
                map[entry.exerciseName] = stats
            }
        }
        return map
    }

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty { return exercises }
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.muscleGroup.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedExercises: [(String, [Exercise])] {
        Dictionary(grouping: filteredExercises, by: \.muscleGroup)
            .sorted { $0.key < $1.key }
    }

    private var muscleGroupCount: Int {
        Set(exercises.map(\.muscleGroup)).count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                headerSection

                List {
                    ForEach(groupedExercises, id: \.0) { group, groupExercises in
                        Section {
                            ForEach(groupExercises) { exercise in
                                exerciseRow(exercise)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    modelContext.delete(groupExercises[index])
                                }
                            }
                        } header: {
                            sectionHeader(group)
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if exercises.isEmpty {
                        ContentUnavailableView("No Exercises", systemImage: "dumbbell.fill", description: Text("Add exercises to build your library."))
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Library")
                    .font(.custom("SpaceGrotesk-Bold", size: 28))
                    .tracking(-0.56)
                    .foregroundStyle(Color(hex: 0x1A1A1A))

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.15)) { showingSearch.toggle() }
                    if !showingSearch { searchText = "" }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: 0x1A1A1A))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: 0xF0F0F0))
                        .clipShape(Circle())
                }

            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            Text("\(exercises.count) exercises across \(muscleGroupCount) muscle groups")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x6B6B6B))
                .padding(.top, 8)
                .padding(.bottom, 16)
                .padding(.horizontal, 20)

            if showingSearch {
                TextField("Search exercises...", text: $searchText)
                    .font(.system(size: 15))
                    .padding(10)
                    .background(Color(hex: 0xF5F5F5))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.88)
            .foregroundStyle(Color(hex: 0x6B6B6B))
            .padding(.bottom, 4)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 0, trailing: 20))
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        let stats = exerciseStatsMap[exercise.name]
        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: 0x1A1A1A))

                    if let stats, stats.timesPerformed > 0 {
                        Text(stats.bestWeight > 0
                             ? "\(stats.timesPerformed) times · Best: \(Int(stats.bestWeight)) lbs"
                             : "\(stats.timesPerformed) times")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x999999))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.2))
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color(hex: 0xF0F0F0))
                .frame(height: 1)
        }
    }
}
