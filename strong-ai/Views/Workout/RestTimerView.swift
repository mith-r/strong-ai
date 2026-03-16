import SwiftUI

struct RestTimerView: View {
    let timerService: TimerService

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("REST")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color.black.opacity(0.35))
                Text(timerService.formattedTime)
                    .font(.custom("SpaceGrotesk-Bold", size: 28))
                    .tracking(-0.5)
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                    .contentTransition(.numericText())
            }

            Spacer()

            Button {
                timerService.stop()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0A0A0A))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xF5F5F5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color(hex: 0x34C759).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
