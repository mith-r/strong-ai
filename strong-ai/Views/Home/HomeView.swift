import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(
        filter: #Predicate<WorkoutLog> { $0.finishedAt != nil },
        sort: \WorkoutLog.startedAt,
        order: .reverse
    ) private var recentLogs: [WorkoutLog]

    @Query private var profiles: [UserProfile]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var todayWorkout: Workout?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var healthContext: HealthContext?

    private var profile: UserProfile? { profiles.first }
    private var apiKey: String { profile?.apiKey ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        statCards

                        if isLoading {
                            loadingSection
                        } else if let error = errorMessage {
                            errorSection(error)
                        } else if let workout = todayWorkout {
                            workoutSection(workout)
                        } else {
                            emptyWorkoutSection
                        }
                    }
                    .padding(.bottom, 100)
                }
                .safeAreaInset(edge: .bottom) {
                    chatBarButton
                }

                if appState.isChatDrawerOpen {
                    @Bindable var state = appState
                    ChatDrawerView(
                        isPresented: $state.isChatDrawerOpen,
                        onSend: { message in
                            await streamChat(message)
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(duration: 0.35), value: appState.isChatDrawerOpen)
            .task {
                await generateWorkoutIfNeeded()
            }
        }
    }

    // MARK: - AI Generation

    private func generateWorkoutIfNeeded() async {
        guard todayWorkout == nil, !apiKey.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        if HealthKitService.shared.isAvailable {
            try? await HealthKitService.shared.requestAuthorization()
            healthContext = try? await HealthKitService.shared.fetchRecentHealthData()
        }

        do {
            let workout = try await WorkoutAIService.generateDailyWorkout(
                apiKey: apiKey,
                profile: profileSnapshot,
                recentLogs: logSnapshots,
                exercises: exerciseSnapshots,
                healthContext: healthContext
            )
            todayWorkout = workout
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func streamChat(_ message: String) async -> AsyncThrowingStream<ChatStreamEvent, Error>? {
        guard !apiKey.isEmpty else { return nil }

        do {
            let stream = try await ChatAIService.stream(
                apiKey: apiKey,
                message: message,
                currentWorkout: todayWorkout,
                profile: profileSnapshot
            )

            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        for try await event in stream {
                            if case .result(let result) = event {
                                todayWorkout = result.workout
                                errorMessage = nil
                            }
                            continuation.yield(event)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.yield(.text("Error: \(error.localizedDescription)"))
                continuation.finish()
            }
        }
    }

    // MARK: - Snapshots

    private var profileSnapshot: UserProfileSnapshot {
        UserProfileSnapshot(
            goals: profile?.goals ?? "",
            schedule: profile?.schedule ?? "",
            equipment: profile?.equipment ?? "",
            injuries: profile?.injuries ?? ""
        )
    }

    private var logSnapshots: [WorkoutLogSnapshot] {
        recentLogs.prefix(10).map { log in
            WorkoutLogSnapshot(
                workoutName: log.workoutName,
                startedAt: log.startedAt,
                durationMinutes: log.durationMinutes,
                totalVolume: log.totalVolume,
                entries: log.entries
            )
        }
    }

    private var exerciseSnapshots: [ExerciseSnapshot] {
        exercises.map { ExerciseSnapshot(name: $0.name, muscleGroup: $0.muscleGroup) }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Color.black.opacity(0.35))
            Text(greeting)
                .font(.custom("SpaceGrotesk-Bold", size: 36))
                .tracking(-1.4)
                .foregroundStyle(Color(hex: 0x0A0A0A))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 10) {
            StatCard(title: "WORKOUTS", value: "\(recentLogs.count)")
            StatCard(title: "THIS WEEK", value: "\(workoutsThisWeek)")
            StatCard(title: "STREAK", value: "\(streak)", highlight: streak > 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var workoutsThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return recentLogs.filter { $0.startedAt >= startOfWeek }.count
    }

    private var streak: Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: .now)
        var count = 0
        let logDates = Set(recentLogs.map { calendar.startOfDay(for: $0.startedAt) })

        while logDates.contains(currentDate) {
            count += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        return count
    }

    // MARK: - Loading / Error States

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Generating your workout...")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)

            if apiKey.isEmpty {
                Text("Add your Claude API key in Settings to get AI-generated workouts.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry") {
                    Task { await generateWorkoutIfNeeded() }
                }
                .font(.system(size: 14, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Workout Section

    private func workoutSection(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today's Workout")
                .font(.custom("SpaceGrotesk-Bold", size: 20))
                .tracking(-0.4)
                .foregroundStyle(Color(hex: 0x0A0A0A))
                .padding(.horizontal, 20)
                .padding(.top, 28)

            HStack(spacing: 8) {
                Text(workout.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.6))
                Text("\(workout.totalSets) sets · ~\(workout.estimatedMinutes) min")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            exerciseList(workout.exercises)
            startButton(workout)
        }
    }

    private func exerciseList(_ exercises: [WorkoutExercise]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                if index > 0 {
                    Divider().padding(.horizontal, 16)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x0A0A0A))
                        Text("\(exercise.sets.count) sets · \(exercise.sets.first.map { "\($0.reps) reps · \(Int($0.weight)) lbs" } ?? "")")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.black.opacity(0.35))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Color(hex: 0xF5F5F5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func startButton(_ workout: Workout) -> some View {
        NavigationLink {
            ActiveWorkoutView(workout: workout)
        } label: {
            Text("Start Workout")
                .font(.custom("SpaceGrotesk-Bold", size: 17))
                .tracking(-0.2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: 0x0A0A0A))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var emptyWorkoutSection: some View {
        VStack(spacing: 12) {
            if apiKey.isEmpty {
                Text("Add your API key in Settings")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Or use the chat below to describe a workout.")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No workout planned")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Ask the AI to generate one.")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Chat Bar Button

    private var chatBarButton: some View {
        VStack(spacing: 0) {
            // Drag handle hint
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                Text("I only have 30 min today...")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.black.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color(hex: 0xF5F5F5))
                    .clipShape(RoundedRectangle(cornerRadius: 21))

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color(hex: 0x0A0A0A))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .background(.ultraThinMaterial)
        .onTapGesture {
            appState.isChatDrawerOpen = true
        }
    }
}

// MARK: - Color Helper

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
