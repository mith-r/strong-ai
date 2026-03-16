import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExercise = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Library")
                    .font(.custom("SpaceGrotesk-Bold", size: 36))
                    .tracking(-1.4)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                List {
                    ForEach(exercises) { exercise in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.system(size: 15, weight: .semibold))
                            Text(exercise.muscleGroup.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(exercises[index])
                        }
                    }
                }
                .overlay {
                    if exercises.isEmpty {
                        ContentUnavailableView("No Exercises", systemImage: "dumbbell.fill", description: Text("Add exercises to build your library."))
                    }
                }
            }
            .toolbar {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseSheet()
            }
        }
    }
}

private struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscleGroup = ""

    private let commonGroups = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Forearms"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)
                Section("Muscle Group") {
                    TextField("Or type your own...", text: $muscleGroup)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(commonGroups, id: \.self) { group in
                                Button(group) {
                                    muscleGroup = group
                                }
                                .buttonStyle(.bordered)
                                .tint(muscleGroup == group ? .green : .secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = Exercise(name: name.trimmingCharacters(in: .whitespaces), muscleGroup: muscleGroup)
                        modelContext.insert(exercise)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || muscleGroup.isEmpty)
                }
            }
        }
    }
}
