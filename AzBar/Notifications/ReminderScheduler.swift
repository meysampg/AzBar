import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler {
    private static let identifiers = (0..<7).map { "review-reminder-\($0)" }

    init() {}

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Replaces the 7 pending one-shot reminders (ids `review-reminder-0…6`).
    func reschedule(enabled: Bool, hour: Int, minute: Int, store: ProgressStore) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: Self.identifiers)
        guard enabled else { return }

        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let streak = store.currentStreak(now: now)

        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: today),
                  let fire = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            let due = store.dueCount(on: day)
            if offset == 0 {
                if fire <= now { continue }
                if store.hasActivity(on: day) && due == 0 { continue }
            }
            let content = UNMutableNotificationContent()
            content.title = "وقت مرور"
            if due > 0 {
                content.body = "\(due.fa) بیت آمادهٔ مرور است. زنجیرهٔ \(streak.fa) روزه‌تان را نگه دارید."
            } else {
                content.body = "چند دقیقه با حافظ؛ بیتی تازه از بر کنید."
            }
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: Self.identifiers[offset], content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
