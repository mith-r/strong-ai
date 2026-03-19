import SwiftUI

struct RestTimerView: View {
    let timerService: TimerService

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text(timerService.formattedTime)
                    .font(.custom("SpaceGrotesk-Bold", size: 22))
                    .tracking(-0.22)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                if timerService.isRunning {
                    Text("of \(timerService.formattedTotal)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            if timerService.isRunning {
                Button {
                    timerService.stop()
                } label: {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(hex: 0x0A0A0A))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
