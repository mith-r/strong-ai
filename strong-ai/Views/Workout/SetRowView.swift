import SwiftUI

struct SetRowView: View {
    let setNumber: Int
    let logSet: LogSet
    let plannedSet: WorkoutSet?
    let isActive: Bool
    let onLog: (Double, Int, Int?) -> Void
    let onToggleWarmup: (() -> Void)?
    let onToggleFailure: (() -> Void)?

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpeText: String = ""
    @State private var didInit = false

    init(setNumber: Int, logSet: LogSet, plannedSet: WorkoutSet?, isActive: Bool,
         onLog: @escaping (Double, Int, Int?) -> Void,
         onToggleWarmup: (() -> Void)? = nil,
         onToggleFailure: (() -> Void)? = nil) {
        self.setNumber = setNumber
        self.logSet = logSet
        self.plannedSet = plannedSet
        self.isActive = isActive
        self.onLog = onLog
        self.onToggleWarmup = onToggleWarmup
        self.onToggleFailure = onToggleFailure
    }

    private var isCompleted: Bool { logSet.completedAt != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                setLabel
                    .frame(width: 40, alignment: .leading)

                Text(previousText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.3))
                    .frame(width: 72, alignment: .leading)

                if isCompleted {
                    completedRow
                } else if isActive {
                    activeRow
                } else {
                    futureRow
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            if isActive {
                HStack(spacing: 8) {
                    TagToggle(label: "Warmup", isOn: logSet.isWarmup) {
                        onToggleWarmup?()
                    }
                    TagToggle(label: "Failure", isOn: logSet.isFailure) {
                        onToggleFailure?()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .background(
            isActive
                ? RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x0A0A0A), lineWidth: 1.5).padding(.horizontal, 8)
                : nil
        )
        .onAppear {
            guard !didInit else { return }
            didInit = true
            if let ps = plannedSet {
                weightText = ps.weight > 0 ? "\(Int(ps.weight))" : ""
                repsText = "\(ps.reps)"
            }
        }
    }

    // MARK: - Set Label

    @ViewBuilder
    private var setLabel: some View {
        if logSet.isWarmup {
            Text("W")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.orange)
        } else {
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isCompleted ? Color(hex: 0x34C759) : Color.black.opacity(0.4))
        }
    }

    // MARK: - Completed

    private var completedRow: some View {
        Group {
            Text(weightText)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 76, alignment: .center)
            Text(repsText)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 64, alignment: .center)
            Text(rpeText.isEmpty ? "—" : rpeText)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 42, alignment: .center)

            Spacer()

            HStack(spacing: 4) {
                if logSet.isFailure {
                    Text("F")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0x34C759))
            }
            .padding(.trailing, 4)
        }
    }

    // MARK: - Active

    private var activeRow: some View {
        Group {
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 76)
                .padding(.vertical, 8)
                .background(Color(hex: 0xF5F5F5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 64)
                .padding(.vertical, 8)
                .background(Color(hex: 0xF5F5F5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            TextField("—", text: $rpeText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 42)
                .padding(.vertical, 8)
                .background(Color(hex: 0xF5F5F5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            Button {
                let weight = Double(weightText) ?? 0
                let reps = Int(repsText) ?? 0
                let rpe = Int(rpeText)
                onLog(weight, reps, rpe)
            } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.black.opacity(0.3))
            }
            .padding(.trailing, 4)
        }
    }

    // MARK: - Future

    private var futureRow: some View {
        Group {
            Text(plannedSet.map { "\(Int($0.weight))" } ?? "—")
                .font(.system(size: 14))
                .foregroundStyle(Color.black.opacity(0.2))
                .frame(width: 76, alignment: .center)
            Text(plannedSet.map { "\($0.reps)" } ?? "—")
                .font(.system(size: 14))
                .foregroundStyle(Color.black.opacity(0.2))
                .frame(width: 64, alignment: .center)
            Text("—")
                .font(.system(size: 14))
                .foregroundStyle(Color.black.opacity(0.2))
                .frame(width: 42, alignment: .center)

            Spacer()

            Circle()
                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .padding(.trailing, 4)
        }
    }

    private var previousText: String {
        guard let ps = plannedSet else { return "—" }
        return "\(Int(ps.weight))×\(ps.reps)"
    }
}

// MARK: - Tag Toggle

private struct TagToggle: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isOn ? .white : Color.black.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isOn ? Color(hex: 0x0A0A0A) : Color(hex: 0xF5F5F5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
