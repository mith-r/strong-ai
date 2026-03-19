import Charts
import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Query(
        filter: #Predicate<WorkoutLog> { $0.finishedAt != nil },
        sort: \WorkoutLog.startedAt,
        order: .reverse
    ) private var allLogs: [WorkoutLog]

    private var exerciseLogs: [(date: Date, entry: LogEntry)] {
        allLogs.compactMap { log in
            guard let entry = log.entries.first(where: { $0.exerciseName == exercise.name }) else { return nil }
            guard entry.sets.contains(where: { $0.completedAt != nil }) else { return nil }
            return (log.startedAt, entry)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleArea
                exerciseImage
                descriptionSection
                howToSection
                statsSection
                progressChartSection
                recentHistorySection
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Title Area

    private var titleArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.custom("SpaceGrotesk-Bold", size: 28))
                .tracking(-0.56)
                .foregroundStyle(Color(hex: 0x1A1A1A))
            Text(exercise.muscleGroup.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.52)
                .foregroundStyle(Color(hex: 0x3CB371))
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Exercise Image

    private var exerciseImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(hex: 0xF7F8F7))
            .frame(height: 200)
            .overlay {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(hex: 0x999999).opacity(0.5))
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = exercise.exerciseDescription, !description.isEmpty {
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(7)
                .foregroundStyle(Color(hex: 0x444444))
                .padding(.top, 20)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - How to Perform

    @ViewBuilder
    private var howToSection: some View {
        let steps = exercise.instructions
        if !steps.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Perform")
                    .font(.custom("SpaceGrotesk-Bold", size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(Color(hex: 0x1A1A1A))

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color(hex: 0x1A1A1A))
                            .clipShape(Circle())

                        Text(step)
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(6)
                            .foregroundStyle(Color(hex: 0x444444))
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Stats

    private var bestWeight: Double {
        exerciseLogs.flatMap { $0.entry.sets }.filter { $0.completedAt != nil }.map(\.weight).max() ?? 0
    }

    private var sessionCount: Int { exerciseLogs.count }

    private var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.entry.sets.filter { $0.completedAt != nil }.count }
    }

    private var weightChange: Double {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
        let recentLogs = exerciseLogs.filter { $0.date >= threeMonthsAgo }
        guard let oldest = recentLogs.last, let newest = recentLogs.first else { return 0 }
        let oldMax = oldest.entry.sets.filter { $0.completedAt != nil }.map(\.weight).max() ?? 0
        let newMax = newest.entry.sets.filter { $0.completedAt != nil }.map(\.weight).max() ?? 0
        return newMax - oldMax
    }

    @ViewBuilder
    private var statsSection: some View {
        if !exerciseLogs.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your Stats")
                    .font(.custom("SpaceGrotesk-Bold", size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(Color(hex: 0x1A1A1A))

                HStack(spacing: 0) {
                    exerciseStat(value: "\(Int(bestWeight))", label: "Best (lbs)")
                    exerciseStat(value: "\(sessionCount)", label: "Sessions")
                    exerciseStat(value: "\(totalSets)", label: "Total Sets")
                    let change = weightChange
                    exerciseStat(
                        value: "\(change >= 0 ? "+" : "")\(Int(change))",
                        label: "lbs / 3 mo",
                        color: Color(hex: 0x3CB371)
                    )
                }
            }
            .padding(.top, 28)
            .padding(.horizontal, 20)
        }
    }

    private func exerciseStat(value: String, label: String, color: Color = Color(hex: 0x1A1A1A)) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("SpaceGrotesk-Bold", size: 26))
                .tracking(-0.52)
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(0.66)
                .foregroundStyle(Color(hex: 0x999999))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weight Progression Chart

    private var chartDataPoints: [(date: Date, weight: Double)] {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
        return exerciseLogs
            .filter { $0.date >= threeMonthsAgo }
            .compactMap { log in
                let maxWeight = log.entry.sets.filter { $0.completedAt != nil }.map(\.weight).max()
                guard let weight = maxWeight else { return nil }
                return (log.date, weight)
            }
            .reversed()
    }

    @ViewBuilder
    private var progressChartSection: some View {
        if chartDataPoints.count >= 2 {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Weight Progression")
                        .font(.custom("SpaceGrotesk-Bold", size: 18))
                        .tracking(-0.18)
                        .foregroundStyle(Color(hex: 0x1A1A1A))
                    Spacer()
                    Text("3 months")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: 0x999999))
                }

                Chart {
                    ForEach(chartDataPoints, id: \.date) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0x3CB371).opacity(0.15), Color(hex: 0x3CB371).opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color(hex: 0x3CB371))
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color(hex: 0x3CB371))
                        .symbolSize(30)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel()
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x999999))
                        AxisGridLine()
                            .foregroundStyle(Color(hex: 0xF0F0F0))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x999999))
                    }
                }
                .frame(height: 148)
                .padding(16)
                .background(Color(hex: 0xFAFAFA))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Recent History

    @ViewBuilder
    private var recentHistorySection: some View {
        if !exerciseLogs.isEmpty {
            let recentEntries = Array(exerciseLogs.prefix(4))

            VStack(alignment: .leading, spacing: 0) {
                Text("Recent History")
                    .font(.custom("SpaceGrotesk-Bold", size: 18))
                    .tracking(-0.18)
                    .foregroundStyle(Color(hex: 0x1A1A1A))
                    .padding(.bottom, 12)

                ForEach(Array(recentEntries.enumerated()), id: \.offset) { index, log in
                    let completedMaxWeight = log.entry.sets
                        .filter { $0.completedAt != nil }
                        .map(\.weight)
                        .max() ?? 0

                    historyRow(date: log.date, entry: log.entry, isPR: index == 0 && bestWeight == completedMaxWeight)

                    if index < recentEntries.count - 1 {
                        Divider()
                            .background(Color(hex: 0xF0F0F0))
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
        }
    }

    private func historyRow(date: Date, entry: LogEntry, isPR: Bool) -> some View {
        let completedSets = entry.sets.filter { $0.completedAt != nil }
        let maxWeight = completedSets.map(\.weight).max() ?? 0
        let totalReps = completedSets.first?.reps ?? 0

        return HStack {
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: 0x999999))
                    Text(date.formatted(.dateTime.day()))
                        .font(.custom("SpaceGrotesk-Bold", size: 20))
                        .foregroundStyle(Color(hex: 0x1A1A1A))
                }
                .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(completedSets.count) sets · \(totalReps) reps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0x1A1A1A))
                    Text("\(Int(maxWeight)) lbs · \(entry.muscleGroup)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(hex: 0x999999))
                }
            }

            Spacer()

            if isPR {
                Text("PR")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x3CB371))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xE8F5E9))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, 10)
    }
}
