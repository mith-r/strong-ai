import Foundation
import UserNotifications

@Observable
final class TimerService {
    var remainingSeconds: Int = 0
    var isRunning: Bool = false

    private var timer: Timer?
    private var fireDate: Date?

    func start(seconds: Int) {
        stop()
        remainingSeconds = seconds
        isRunning = true
        fireDate = Date().addingTimeInterval(TimeInterval(seconds))

        scheduleNotification(seconds: seconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let left = Int(ceil((self.fireDate ?? .now).timeIntervalSince(.now)))
            if left <= 0 {
                self.stop()
            } else {
                self.remainingSeconds = left
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        fireDate = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest-timer"])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Over"
        content.body = "Time for your next set"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "rest-timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    var formattedTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
