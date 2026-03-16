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

    let workout: Workout
    @State private var viewModel: ActiveWorkoutViewModel
    @State private var showingCancelAlert = false
    @State private var showingDebrief = false
    @State private var finishedLog: WorkoutLog?
    @Environment(AppState.self) private var appState
    @State private var isChatInputActive = false
    @State private var chatInputText = ""
    @FocusState private var isChatBarFocused: Bool

    private var profile: UserProfile? { profiles.first }
    private var apiKey: String { profile?.apiKey ?? "" }

    init(workout: Workout) {
        self.workout = workout
        self._viewModel = State(initialValue: ActiveWorkoutViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
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
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }

            if appState.isChatDrawerOpen {
                @Bindable var state = appState
                ChatDrawerView(
                    isPresented: $state.isChatDrawerOpen,
                    pendingMessage: $state.pendingMessage,
                    workoutName: viewModel.workoutName,
                    elapsedTime: viewModel.elapsedFormatted,
                    exerciseProgress: "\(viewModel.completedSets) of \(viewModel.totalSets) sets",
                    onSend: { message in
                        await streamMidWorkoutChat(message)
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(duration: 0.35), value: appState.isChatDrawerOpen)
        .navigationTitle(viewModel.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if viewModel.completedSets > 0 {
                        showingCancelAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .alert("Discard Workout?", isPresented: $showingCancelAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("You've logged \(viewModel.completedSets) sets. This can't be undone.")
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
            viewModel.timerService.requestPermission()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.elapsedFormatted)
                    .font(.custom("SpaceGrotesk-Bold", size: 32))
                    .tracking(-1)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                    .contentTransition(.numericText())
                Text("\(viewModel.completedSets)/\(viewModel.totalSets) sets completed")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.35))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Timer

    @ViewBuilder
    private var timerSection: some View {
        if viewModel.timerService.isRunning {
            RestTimerView(timerService: viewModel.timerService)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Exercise Section

    private func exerciseSection(exerciseIndex: Int, entry: LogEntry) -> some View {
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
                        },
                        onToggleWarmup: {
                            viewModel.entries[exerciseIndex].sets[setIndex].isWarmup.toggle()
                        },
                        onToggleFailure: {
                            viewModel.entries[exerciseIndex].sets[setIndex].isFailure.toggle()
                        }
                    )
                    if setIndex < entry.sets.count - 1 {
                        Divider().padding(.leading, 20)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if !apiKey.isEmpty {
                HStack(spacing: 10) {
                    if isChatInputActive {
                        TextField("Add more tricep work...", text: $chatInputText, axis: .vertical)
                            .font(.system(size: 14))
                            .lineLimit(1...5)
                            .focused($isChatBarFocused)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color(hex: 0xF5F5F5))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .onSubmit { sendFromBar() }
                    } else {
                        Text("Add more tricep work...")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.black.opacity(0.3))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Color(hex: 0xF5F5F5))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .onTapGesture {
                                isChatInputActive = true
                                isChatBarFocused = true
                            }
                    }

                    Button {
                        if isChatInputActive {
                            sendFromBar()
                        } else {
                            isChatInputActive = true
                            isChatBarFocused = true
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                isChatInputActive && !chatInputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: 0x0A0A0A)
                                : Color.black.opacity(0.15)
                            )
                    }
                }
            }

            Button {
                finishWorkout()
            } label: {
                Text("Finish Workout")
                    .font(.custom("SpaceGrotesk-Bold", size: 17))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.completedSets > 0 ? Color(hex: 0x34C759) : Color.black.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.completedSets == 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func sendFromBar() {
        let text = chatInputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        appState.pendingMessage = text
        chatInputText = ""
        isChatInputActive = false
        appState.isChatDrawerOpen = true
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
                profile: profileSnapshot
            )

            // Wrap to intercept results and apply workout changes
            return AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        for try await event in stream {
                            if case .result(let result) = event {
                                viewModel.applyModifiedWorkout(result.workout)
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

    var elapsedSeconds: Int = 0

    var totalSets: Int { entries.reduce(0) { $0 + $1.sets.count } }
    var completedSets: Int { entries.flatMap(\.sets).filter { $0.completedAt != nil }.count }

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

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.elapsedSeconds = Int(Date().timeIntervalSince(self.startedAt))
            }
        }
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
        elapsedTimer?.invalidate()
        timerService.stop()

        let log = WorkoutLog(
            workoutName: workoutName,
            entries: entries,
            startedAt: startedAt
        )
        log.finishedAt = .now
        return log
    }
}
