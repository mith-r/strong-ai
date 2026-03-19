import os
import SwiftUI
import SwiftData

private let logger = Logger(subsystem: "com.strong-ai", category: "ActiveWorkout")

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<WorkoutLog> { $0.finishedAt != nil },
        sort: \WorkoutLog.startedAt,
        order: .reverse
    ) private var recentLogs: [WorkoutLog]

    @Query private var profiles: [UserProfile]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    let workout: Workout
    @State private var viewModel: ActiveWorkoutViewModel
    @State private var showingCancelAlert = false
    @State private var showingFinishAlert = false
    @State private var showingDebrief = false
    @State private var finishedLog: WorkoutLog?
    @Environment(AppState.self) private var appState

    private var profile: UserProfile? { profiles.first }
    private var apiKey: String { profile?.apiKey ?? "" }

    init(workout: Workout) {
        self.workout = workout
        self._viewModel = State(initialValue: ActiveWorkoutViewModel(workout: workout))
    }

    var body: some View {
        @Bindable var state = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                timerSection

                ForEach(Array(viewModel.entries.enumerated()), id: \.offset) { exerciseIndex, entry in
                    exerciseSection(exerciseIndex: exerciseIndex, entry: entry)
                }
            }
            .padding(.bottom, 120)
        }
        .overlay {
            if !apiKey.isEmpty {
                ChatDrawerView(
                    isExpanded: $state.isChatDrawerOpen,
                    pendingMessage: $state.pendingMessage,
                    placeholder: "Add more tricep work...",
                    workoutName: viewModel.workoutName,
                    elapsedTime: viewModel.elapsedFormatted,
                    exerciseProgress: "\(viewModel.completedSets) of \(viewModel.totalSets) sets",
                    collapsedHeight: 140,
                    onSend: { message in
                        await streamMidWorkoutChat(message)
                    }
                ) {
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if viewModel.completedSets > 0 {
                        showingCancelAlert = true
                    } else {
                        viewModel.stop()
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    showingFinishAlert = true
                }
                .disabled(viewModel.completedSets == 0)
            }
        }
        .alert("Discard Workout?", isPresented: $showingCancelAlert) {
            Button("Discard", role: .destructive) { viewModel.stop(); dismiss() }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("You've logged \(viewModel.completedSets) sets. This can't be undone.")
        }
        .alert("Finish Workout?", isPresented: $showingFinishAlert) {
            Button("Finish") { finishWorkout() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save your workout with \(viewModel.completedSets) sets completed?")
        }
        .sheet(isPresented: $showingDebrief, onDismiss: { dismiss() }) {
            if let log = finishedLog {
                WorkoutDebriefView(
                    log: log,
                    recentLogs: recentLogs.prefix(5).map { l in
                        WorkoutLogSnapshot(
                            workoutName: l.workoutName,
                            startedAt: l.startedAt,
                            durationMinutes: l.durationMinutes,
                            totalVolume: l.totalVolume,
                            entries: l.entries
                        )
                    },
                    profile: UserProfileSnapshot(
                        goals: profile?.goals ?? "",
                        schedule: profile?.schedule ?? "",
                        equipment: profile?.equipment ?? "",
                        injuries: profile?.injuries ?? ""
                    ),
                    apiKey: apiKey
                )
            }
        }
        .onAppear {
            viewModel.start()
            viewModel.timerService.requestPermission()
            saveExercisesToLibrary(viewModel.currentWorkout.exercises)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.workoutName)
                .font(.custom("SpaceGrotesk-Bold", size: 28))
                .tracking(-0.84)
                .foregroundStyle(Color(hex: 0x0A0A0A))
            HStack(spacing: 12) {
                Text(viewModel.elapsedFormatted)
                    .font(.custom("SpaceGrotesk-Bold", size: 15))
                    .foregroundStyle(Color(hex: 0x34C759))
                    .contentTransition(.numericText())
                Text("\(viewModel.completedExercises) of \(viewModel.totalExercises) exercises")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }

    // MARK: - Timer

    private var timerSection: some View {
        RestTimerView(timerService: viewModel.timerService)
            .padding(.horizontal, 20)
    }

    // MARK: - Exercise Section

    private func exerciseSection(exerciseIndex: Int, entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.exerciseName)
                    .font(.custom("SpaceGrotesk-Bold", size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                Spacer()
                Text(entry.muscleGroup.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.72)
                    .foregroundStyle(Color.black.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)

            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 40, alignment: .leading)
                Text("PREV")
                    .frame(width: 72, alignment: .leading)
                Text("LBS")
                    .frame(width: 76, alignment: .center)
                Text("REPS")
                    .frame(width: 64, alignment: .center)
                Text("RPE")
                    .frame(width: 42, alignment: .center)
                Spacer()
            }
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Color.black.opacity(0.3))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(entry.sets.enumerated()), id: \.offset) { setIndex, set in
                    SetRowView(
                        setNumber: setIndex + 1,
                        logSet: set,
                        plannedSet: viewModel.plannedSet(exerciseIndex: exerciseIndex, setIndex: setIndex),
                        isActive: viewModel.isActiveSet(exerciseIndex: exerciseIndex, setIndex: setIndex),
                        onLog: { weight, reps, rpe in
                            viewModel.logSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: reps, rpe: rpe)
                        }
                    )
                    if setIndex < entry.sets.count - 1 {
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveExercisesToLibrary(_ workoutExercises: [WorkoutExercise]) {
        ExerciseLibraryService.persist(
            workoutExercises: workoutExercises,
            existingExercises: exercises,
            modelContext: modelContext
        )
    }


    private func finishWorkout() {
        let log = viewModel.finish()
        modelContext.insert(log)
        finishedLog = log
        showingDebrief = true
    }

    private func streamMidWorkoutChat(_ message: String) async -> AsyncThrowingStream<ChatStreamEvent, Error>? {
        let currentWorkout = viewModel.currentWorkout
        let profileSnapshot = UserProfileSnapshot(
            goals: profile?.goals ?? "",
            schedule: profile?.schedule ?? "",
            equipment: profile?.equipment ?? "",
            injuries: profile?.injuries ?? ""
        )

        do {
            let stream = try await ChatAIService.stream(
                apiKey: apiKey,
                message: message,
                currentWorkout: currentWorkout,
                profile: profileSnapshot,
                exercises: exercises.map { ExerciseSnapshot(name: $0.name, muscleGroup: $0.muscleGroup) }
            )

            // Wrap to intercept results and apply workout changes
            return AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        for try await event in stream {
                            if case .result(let result) = event {
                                viewModel.applyModifiedWorkout(result.workout)
                                saveExercisesToLibrary(result.workout.exercises)
                            }
                            continuation.yield(event)
                        }
                        continuation.finish()
                    } catch {
                        logger.error("Mid-workout chat stream failed: \(error)")
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        } catch {
            logger.error("Mid-workout chat setup failed: \(error)")
            return AsyncThrowingStream { continuation in
                continuation.yield(.text("Error: \(error.localizedDescription)"))
                continuation.finish()
            }
        }
    }
}

// MARK: - View Model

@Observable
final class ActiveWorkoutViewModel {
    var entries: [LogEntry]
    var startedAt: Date
    var workoutName: String
    let timerService = TimerService()

    private var workoutExercises: [WorkoutExercise]
    private var elapsedTimer: Timer?
    private var hasStarted = false

    var elapsedSeconds: Int = 0

    var totalSets: Int { entries.reduce(0) { $0 + $1.sets.count } }
    var completedSets: Int { entries.flatMap(\.sets).filter { $0.completedAt != nil }.count }
    var totalExercises: Int { entries.count }
    var completedExercises: Int {
        entries.reduce(0) { count, entry in
            entry.sets.allSatisfy { $0.completedAt != nil } ? count + 1 : count
        }
    }

    var elapsedFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var currentWorkout: Workout {
        Workout(
            name: workoutName,
            exercises: workoutExercises
        )
    }

    init(workout: Workout) {
        self.workoutName = workout.name
        self.workoutExercises = workout.exercises
        self.startedAt = .now

        self.entries = workout.exercises.map { exercise in
            LogEntry(
                exerciseName: exercise.name,
                muscleGroup: exercise.muscleGroup,
                sets: exercise.sets.map { plannedSet in
                    LogSet(reps: plannedSet.reps, weight: plannedSet.weight)
                }
            )
        }
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        startedAt = .now
        elapsedSeconds = 0
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.elapsedSeconds = Int(Date().timeIntervalSince(self.startedAt))
            }
        }
    }

    func stop() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        timerService.stop()
    }

    deinit {
        elapsedTimer?.invalidate()
    }

    func plannedSet(exerciseIndex: Int, setIndex: Int) -> WorkoutSet? {
        guard exerciseIndex < workoutExercises.count,
              setIndex < workoutExercises[exerciseIndex].sets.count else { return nil }
        return workoutExercises[exerciseIndex].sets[setIndex]
    }

    func isActiveSet(exerciseIndex: Int, setIndex: Int) -> Bool {
        if timerService.isRunning { return false }
        for (ei, entry) in entries.enumerated() {
            for (si, set) in entry.sets.enumerated() {
                if set.completedAt == nil {
                    return ei == exerciseIndex && si == setIndex
                }
            }
        }
        return false
    }

    func logSet(exerciseIndex: Int, setIndex: Int, weight: Double, reps: Int, rpe: Int?) {
        entries[exerciseIndex].sets[setIndex].weight = weight
        entries[exerciseIndex].sets[setIndex].reps = reps
        entries[exerciseIndex].sets[setIndex].rpe = rpe
        entries[exerciseIndex].sets[setIndex].completedAt = .now

        if let ps = plannedSet(exerciseIndex: exerciseIndex, setIndex: setIndex) {
            timerService.start(seconds: ps.restSeconds)
        }
    }

    func applyModifiedWorkout(_ newWorkout: Workout) {
        workoutName = newWorkout.name
        workoutExercises = newWorkout.exercises

        var updatedEntries: [LogEntry] = []

        for newExercise in newWorkout.exercises {
            if let existingIndex = entries.firstIndex(where: { $0.exerciseName == newExercise.name }) {
                let existing = entries[existingIndex]
                let completedSets = existing.sets.filter { $0.completedAt != nil }

                if !completedSets.isEmpty {
                    var sets = completedSets
                    let remainingCount = max(0, newExercise.sets.count - completedSets.count)
                    for i in 0..<remainingCount {
                        let setIndex = completedSets.count + i
                        if setIndex < newExercise.sets.count {
                            let planned = newExercise.sets[setIndex]
                            sets.append(LogSet(reps: planned.reps, weight: planned.weight))
                        }
                    }
                    updatedEntries.append(LogEntry(
                        exerciseName: existing.exerciseName,
                        muscleGroup: existing.muscleGroup,
                        sets: sets
                    ))
                } else {
                    updatedEntries.append(LogEntry(
                        exerciseName: newExercise.name,
                        muscleGroup: newExercise.muscleGroup,
                        sets: newExercise.sets.map { LogSet(reps: $0.reps, weight: $0.weight) }
                    ))
                }
            } else {
                updatedEntries.append(LogEntry(
                    exerciseName: newExercise.name,
                    muscleGroup: newExercise.muscleGroup,
                    sets: newExercise.sets.map { LogSet(reps: $0.reps, weight: $0.weight) }
                ))
            }
        }

        entries = updatedEntries
    }

    func finish() -> WorkoutLog {
        stop()

        let log = WorkoutLog(
            workoutName: workoutName,
            entries: entries,
            startedAt: startedAt
        )
        log.finishedAt = .now
        return log
    }
}
